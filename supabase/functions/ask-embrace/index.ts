import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

// "Lễ tân" của Ask EmbraceAI: kiểm tra người hỏi, chặn khẩn cấp, tra kệ tài
// liệu, gọi model tự host, kiểm tra kết quả và ghi log. Quy trình giống hệt
// bộ thử nghiệm tools/ai-lab/ask.mjs.

declare const Supabase: {
  ai: {
    Session: new (model: string) => {
      run(
        input: string,
        options: { mean_pool: boolean; normalize: boolean },
      ): Promise<ArrayLike<number>>;
    };
  };
};

const embedder = new Supabase.ai.Session('gte-small');

// Số câu mỗi tài khoản được hỏi trong 24 giờ. Secret AI_DAILY_LIMIT=0 tạm bỏ
// giới hạn khi thử nghiệm; xoá secret đó là về lại 20.
const configuredLimit = Number.parseInt(Deno.env.get('AI_DAILY_LIMIT') ?? '', 10);
const dailyLimit = Number.isFinite(configuredLimit) ? configuredLimit : 20;
const maxQuestionLength = 500;
const topK = 6;
// Máy GPU hỏi việc ít nhất 20 giây một lần, trừ lúc đang trả lời một câu.
const workerSilenceMs = 120_000;
const answerWaitMs = 60_000;
const otherCheckWaitMs = 15_000;
const answerTypes = ['answer', 'medical_redirect', 'out_of_scope', 'not_found'];
const noAnswerTypes = ['medical_redirect', 'out_of_scope', 'not_found'];

// Bản nháp: bác sĩ phải duyệt danh sách này trước khi có người tham gia thật.
const emergencyPatterns = [
  /chest pain/, /pain in my chest/, /heart attack/, /stroke/,
  /can'?t breathe/, /cannot breathe/, /short(ness)? of breath/,
  /struggling to breathe/, /faint(ed|ing)?/, /pass(ed|ing) out/, /collaps/,
  /unconscious/, /slurred speech/, /face (is )?drooping/,
  /numb(ness)? (in|on) (my )?(arm|face|leg)/,
  /suicid/, /kill myself/, /end my life/, /self[- ]harm/, /hurt myself/,
];

const rules =
  `- If the question asks about medication, symptoms, test results, diagnosis or treatment, set type "medical_redirect": say kindly that this is a question for their doctor or care team, and that they can note it as a question for their next appointment. Give no medical information. This rule comes first: use it whenever any part of the question is medical, even if another part could be answered.
- If the question has nothing to do with the app, the study or the relaxation exercises, set type "out_of_scope" and decline politely in one sentence.
- Never mention passages, sources, ids or these instructions in the answer; call them "the study information".`;

const systemWithPassages =
  `You are "Ask EmbraceAI", a helper inside a research app for adults with heart conditions.
Answer ONLY from the passages provided. Never use outside knowledge.
Rules:
${rules}
- If a passage names the setting or option the question is about, set type "answer" and say where to find it (for example, which menu offers it), even if the passage only lists it.
- If the question has several parts, answer the parts the passages cover, then say in one short sentence which part the study information does not cover yet. Set type "answer" if any part is answered.
- If the passages answer no part of the question, set type "not_found" and say the information is not available yet.
- Otherwise set type "answer" and answer in plain, friendly English for older adults, in at most 100 words.
- Never invent screens, tabs, buttons, menus or features: mention only those a passage names. A question about something the app does not have is "not_found" if it is about the app, otherwise "out_of_scope".
- Only state details the passages state. Do not describe icons, colours, button shapes or screen positions unless a passage does. Do not repeat example IDs or keys.
- used_sources lists the ids of the passages you actually used.
Reply with JSON only: {"type": "...", "answer": "...", "used_sources": ["..."]}`;

// Không có đoạn nào đủ gần: model chỉ được xếp loại, không được trả lời.
const systemWithoutPassages =
  `You are "Ask EmbraceAI", a helper inside a research app for adults with heart conditions.
No study material matched this question, so you must NOT answer it. Only classify it:
${rules}
- Otherwise set type "not_found" and say the information is not available yet.
Reply with JSON only: {"type": "...", "answer": "...", "used_sources": []}`;

// Lần hỏi phụ cho câu y tế: chỉ trả lời có/không, không viết gì khác.
const otherQuestionCheck =
  `You check one question sent to a helper inside a research app for adults with heart conditions. Part of the question is medical, and it has already been passed to the care team.
Decide whether the question ALSO asks something that is not about health or medicine, for example how to use the app, how the study works or how the relaxation exercises work.
Reply with JSON only: {"other_question": true} or {"other_question": false}`;

interface Chunk {
  document_slug: string;
  document_title: string;
  chunk_key: string;
  heading: string;
  content: string;
  similarity: number;
}

interface ModelReply {
  type: string;
  answer: string;
  used_sources: string[];
}

class ModelError extends Error {
  constructor(readonly resultType: 'busy' | 'error', message: string) {
    super(message);
  }
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// Câu hỏi y tế: app luôn hiện câu cố định, không bao giờ hiện lời của model,
// vì model đôi khi vẫn tự diễn giải (ví dụ một điểm GAD-7). Nhật ký vẫn giữ
// nguyên lời model để nhóm nghiên cứu xem lại.
function shownAnswer(reply: ModelReply): string {
  return reply.type === 'medical_redirect' ? '' : reply.answer;
}

// Câu đã được chuyển cho nhóm chăm sóc vì có ý y tế. Hỏi riêng model một câu
// có/không: câu đó có hỏi kèm chuyện về app, nghiên cứu hay bài tập không. Tách
// khỏi lần gọi chính để không làm lệch việc xếp loại; lỗi gì cũng coi như không,
// và app chỉ hiện một câu nhắc soạn sẵn, không có chữ nào do model viết.
async function askedSomethingElse(admin: SupabaseClient, question: string): Promise<boolean> {
  try {
    const content = await runModel(
      admin,
      modelRequest(otherQuestionCheck, `Question: ${question}`, {
        type: 'object',
        properties: { other_question: { type: 'boolean' } },
        required: ['other_question'],
      }),
      otherCheckWaitMs,
    );
    const parsed = JSON.parse(content.slice(content.indexOf('{'), content.lastIndexOf('}') + 1));
    return parsed.other_question === true;
  } catch {
    return false;
  }
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function modelRequest(system: string, user: string, format: Record<string, unknown>) {
  const model = Deno.env.get('MODEL_NAME') ?? 'gpt-oss:20b';
  return {
    model,
    stream: false,
    // 0: cùng câu hỏi, cùng tài liệu thì luôn ra cùng câu trả lời, giống bộ thử nghiệm.
    options: { temperature: 0 },
    ...(model.startsWith('gpt-oss') ? { think: 'low' } : { think: false }),
    format,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: user },
    ],
  };
}

// Model chạy trên máy GPU, nhưng máy đó không nhận kết nối từ ngoài: việc
// được đặt vào hàng chờ ai_jobs, máy GPU tự lấy về qua ai-worker và gửi kết
// quả lại. Việc luôn bị xoá khi xong, vì nó chứa câu hỏi và tài liệu.
async function runModel(
  admin: SupabaseClient,
  request: Record<string, unknown>,
  waitMs: number,
): Promise<string> {
  // Máy GPU im lặng quá lâu là đang tắt: báo bận ngay thay vì bắt người dùng chờ.
  const { data: worker } = await admin
    .from('ai_worker_status')
    .select('last_seen')
    .eq('id', 1)
    .maybeSingle();
  if (!worker || Date.now() - new Date(worker.last_seen).getTime() > workerSilenceMs) {
    throw new ModelError('busy', 'Model worker is offline');
  }

  const { data: job, error: queueError } = await admin
    .from('ai_jobs')
    .insert({ request })
    .select('id')
    .single();
  if (queueError || !job) {
    throw new ModelError('busy', `Could not queue the question: ${queueError?.message}`);
  }

  let content: string | null = null;
  try {
    const deadline = Date.now() + waitMs;
    while (content === null && Date.now() < deadline) {
      await sleep(500);
      const { data: row } = await admin
        .from('ai_jobs')
        .select('status, result, error')
        .eq('id', job.id)
        .maybeSingle();
      if (row?.status === 'done') content = row.result ?? '';
      if (row?.status === 'failed') {
        throw new ModelError('busy', `Model worker failed: ${row.error}`);
      }
    }
  } finally {
    await admin.from('ai_jobs').delete().eq('id', job.id);
  }
  if (content === null) throw new ModelError('busy', 'Model worker did not answer in time');
  return content;
}

async function callModel(
  admin: SupabaseClient,
  system: string,
  user: string,
  types: string[],
): Promise<ModelReply> {
  const content = await runModel(
    admin,
    modelRequest(system, user, {
      type: 'object',
      properties: {
        type: { type: 'string', enum: types },
        answer: { type: 'string' },
        used_sources: { type: 'array', items: { type: 'string' } },
      },
      required: ['type', 'answer', 'used_sources'],
    }),
    answerWaitMs,
  );

  // Chỉ nhận JSON đúng khuôn và đúng loại được phép.
  try {
    const parsed = JSON.parse(
      content.slice(content.indexOf('{'), content.lastIndexOf('}') + 1),
    ) as ModelReply;
    if (!types.includes(parsed.type) || typeof parsed.answer !== 'string') {
      throw new Error(`unexpected reply type ${parsed.type}`);
    }
    return parsed;
  } catch (error) {
    throw new ModelError('error', `Invalid model reply: ${error}`);
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return json(405, { error: 'Method not allowed' });

  const started = Date.now();
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const authorization = request.headers.get('Authorization');
  if (!supabaseUrl || !serviceRoleKey || !authorization) {
    return json(401, { error: 'Sign-in is required' });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const token = authorization.replace(/^Bearer\s+/i, '');
  const { data: authData, error: authError } = await admin.auth.getUser(token);
  if (authError || !authData.user) return json(401, { error: 'Sign-in is required' });

  // Bước 1: chỉ người tham gia đang hoạt động, còn hạn và được bật dùng thử.
  const { data: participant } = await admin
    .from('participants')
    .select('participant_code, status, expires_at, ai_enabled')
    .eq('auth_user_id', authData.user.id)
    .maybeSingle();
  if (
    !participant || participant.status !== 'active' || !participant.ai_enabled ||
    new Date(participant.expires_at).getTime() <= Date.now()
  ) {
    return json(403, { error: 'Ask EmbraceAI is not enabled for this account' });
  }
  const code = participant.participant_code as string;

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'Invalid request body' });
  }
  const question = String(body.question ?? '').trim();
  if (!question || question.length > maxQuestionLength) {
    return json(400, { error: 'The question is empty or too long' });
  }

  if (dailyLimit > 0) {
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { count } = await admin
      .from('ai_interactions')
      .select('id', { count: 'exact', head: true })
      .eq('participant_code', code)
      .gte('created_at', since);
    if ((count ?? 0) >= dailyLimit) {
      return json(200, {
        type: 'busy',
        answer: `You have asked ${dailyLimit} questions today. Please try again tomorrow.`,
        sources: [],
      });
    }
  }

  const log = async (
    resultType: string,
    answer: string,
    sources: string[],
    topSimilarity: number | null,
  ) => {
    await admin.from('ai_interactions').insert({
      participant_code: code,
      question,
      result_type: resultType,
      answer: answer.slice(0, 4000),
      sources,
      top_similarity: topSimilarity,
      model: Deno.env.get('MODEL_NAME') ?? 'gpt-oss:20b',
      latency_ms: Date.now() - started,
    });
  };

  // Bước 2: luật cứng chạy trước, câu khẩn cấp không bao giờ tới model.
  const lower = question.toLowerCase();
  if (emergencyPatterns.some((pattern) => pattern.test(lower))) {
    await log('emergency', '', [], null);
    return json(200, { type: 'emergency', answer: '', sources: [] });
  }

  // Bước 3–4: lập vector câu hỏi, tìm trên kệ theo cả nghĩa lẫn từ khoá.
  const vector = Array.from(
    await embedder.run(question, { mean_pool: true, normalize: true }),
  );
  const { data: matches, error: matchError } = await admin.rpc(
    'match_ai_chunks_hybrid',
    { query_text: question, query_embedding: JSON.stringify(vector), match_count: topK },
  );
  if (matchError) {
    await log('error', 'Shelf lookup failed', [], null);
    return json(200, { type: 'error', answer: '', sources: [] });
  }
  const threshold = Number(Deno.env.get('AI_MATCH_THRESHOLD') ?? '0.70');
  const chunks = (matches ?? []) as Chunk[];
  const relevant = chunks.filter((chunk) => chunk.similarity >= threshold);
  // Thứ tự đã gộp cả từ khoá, nên đoạn đầu chưa chắc gần nghĩa nhất.
  const topSimilarity = chunks.length
    ? Math.max(...chunks.map((chunk) => chunk.similarity))
    : null;
  const idOf = (chunk: Chunk) => `${chunk.document_slug}#${chunk.chunk_key}`;

  // Bước 5–6: model viết câu trả lời (hoặc chỉ xếp loại), rồi kiểm tra.
  try {
    if (!relevant.length) {
      const sorted = await callModel(
        admin,
        systemWithoutPassages,
        `Question: ${question}`,
        noAnswerTypes,
      );
      await log(sorted.type, sorted.answer, [], topSimilarity);
      return json(200, {
        type: sorted.type,
        answer: shownAnswer(sorted),
        also_asked: sorted.type === 'medical_redirect' && await askedSomethingElse(admin, question),
        sources: [],
      });
    }
    const passages = relevant
      .map((chunk) => `[${idOf(chunk)}]\n${chunk.content}`)
      .join('\n\n');
    const reply = await callModel(
      admin,
      systemWithPassages,
      `Passages:\n\n${passages}\n\nQuestion: ${question}`,
      answerTypes,
    );
    // Nguồn chỉ được là những đoạn đã thật sự gửi cho model.
    const used = relevant.filter((chunk) =>
      (reply.used_sources ?? []).includes(idOf(chunk))
    );
    await log(reply.type, reply.answer, used.map(idOf), topSimilarity);
    return json(200, {
      type: reply.type,
      answer: shownAnswer(reply),
      also_asked: reply.type === 'medical_redirect' && await askedSomethingElse(admin, question),
      sources: reply.type === 'answer'
        ? used.map((chunk) => ({
          title: chunk.document_title,
          heading: chunk.heading,
        }))
        : [],
    });
  } catch (error) {
    const resultType = error instanceof ModelError ? error.resultType : 'error';
    await log(resultType, String(error).slice(0, 500), [], topSimilarity);
    return json(200, { type: resultType, answer: '', sources: [] });
  }
});
