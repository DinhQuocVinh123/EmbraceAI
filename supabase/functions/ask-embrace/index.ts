import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';

import {
  answerFormat,
  answerTypes,
  type AskLanguage,
  maxShelfCharacters,
  otherQuestionCheck,
  passagesMessage,
  shelfCharacters,
  systemPrompt,
  withVietnameseNames,
} from '../_shared/ask_prompts.ts';
import {
  type AskDomain,
  askDomains,
  isHealthDomain,
  rankDomains,
  shelfForDomains,
} from '../_shared/ask_domains.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { isEmergency } from '../_shared/emergency.ts';

// "Lễ tân" của Ask EmbraceAI: kiểm tra người hỏi, chặn khẩn cấp, gửi cả kệ
// tài liệu cho model tự host, kiểm tra kết quả và ghi log. Quy trình giống hệt
// bộ thử nghiệm tools/ai-lab/ask.mjs, và lời dặn model nằm chung một file.

// Số câu mỗi tài khoản được hỏi trong 24 giờ. Secret AI_DAILY_LIMIT=0 tạm bỏ
// giới hạn khi thử nghiệm; xoá secret đó là về lại 20.
const configuredLimit = Number.parseInt(Deno.env.get('AI_DAILY_LIMIT') ?? '', 10);
const dailyLimit = Number.isFinite(configuredLimit) ? configuredLimit : 20;
const maxQuestionLength = 500;
// Kệ ít khi đổi: đọc lại từ database mỗi phút là đủ.
const shelfCacheMs = 60_000;
// Máy GPU hỏi việc ít nhất 20 giây một lần, trừ lúc đang trả lời một câu.
const workerSilenceMs = 120_000;
const answerWaitMs = 60_000;
const otherCheckWaitMs = 15_000;
// Máy GPU trả lời khoảng 72 câu mỗi phút (song song 16, đo ngày 12/10 bằng
// tools/ai-lab/capacity.mjs, mỗi câu hỏi một khác): 100 người hỏi cùng lúc thì
// 61-64 người xong trong 60 giây. Số đó đo khi còn tra 6 đoạn cho mỗi câu; từ
// khi gửi cả kệ thì cần đo lại. Ngưỡng 55 chừa chỗ cho lúc máy chậm hơn. Hàng
// dài hơn thì báo bận ngay, thay vì để người hỏi chờ trọn 60 giây rồi mới báo.
// Secret AI_MAX_QUEUE đổi ngưỡng.
const configuredQueue = Number.parseInt(Deno.env.get('AI_MAX_QUEUE') ?? '', 10);
const maxQueue = Number.isFinite(configuredQueue) && configuredQueue > 0 ? configuredQueue : 55;
// Lần hỏi phụ của câu y tế chỉ chạy khi hàng còn ngắn, để không làm hàng dài thêm.
const otherCheckMaxQueue = 10;
const queueFullMessage = 'Many people are asking right now. Please try again in a minute.';

interface Chunk {
  id: string;
  domain: AskDomain;
  document_title: string;
  heading: string;
  content: string;
}

interface ModelReply {
  type: string;
  answer: string;
  used_sources: string[];
  question_english?: string;
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
// Số câu đang chờ hoặc đang được máy GPU trả lời. Câu chờ quá 90 giây không được
// nhận nữa (claim_ai_jobs), nên không tính.
async function queueLength(admin: SupabaseClient): Promise<number> {
  const since = new Date(Date.now() - 90_000).toISOString();
  const { count } = await admin
    .from('ai_jobs')
    .select('id', { count: 'exact', head: true })
    .in('status', ['queued', 'working'])
    .gte('created_at', since);
  return count ?? 0;
}

async function askedSomethingElse(admin: SupabaseClient, question: string): Promise<boolean> {
  try {
    if ((await queueLength(admin)) > otherCheckMaxQueue) return false;
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
  language: AskLanguage,
  domain: AskDomain,
  user: string,
): Promise<ModelReply> {
  const content = await runModel(
    admin,
    modelRequest(systemPrompt(language, domain), user, answerFormat(language)),
    answerWaitMs,
  );

  // Chỉ nhận JSON đúng khuôn và đúng loại được phép.
  try {
    const parsed = JSON.parse(
      content.slice(content.indexOf('{'), content.lastIndexOf('}') + 1),
    ) as ModelReply;
    if (!answerTypes.includes(parsed.type) || typeof parsed.answer !== 'string') {
      throw new Error(`unexpected reply type ${parsed.type}`);
    }
    if (language === 'vi') parsed.answer = withVietnameseNames(parsed.answer);
    // Câu sức khoẻ mà tài liệu không nói tới: chỉ cho người hỏi tới nhóm chăm
    // sóc thay vì "chưa có thông tin". Thử trên model, câu về số đo của chính
    // người hỏi ("huyết áp tôi 150/95 có sao không?") hay rơi vào not_found.
    if (isHealthDomain(domain) && parsed.type === 'not_found') parsed.type = 'medical_redirect';
    return parsed;
  } catch (error) {
    throw new ModelError('error', `Invalid model reply: ${error}`);
  }
}

let shelfCache: { at: number; chunks: Chunk[] } | null = null;

// Cả kệ, theo thứ tự đã nạp, mỗi đoạn mang lĩnh vực của tài liệu. Mỗi câu hỏi
// chỉ gửi đoạn của lĩnh vực hợp nhất (ask_domains.ts); cùng lĩnh vực thì phần
// đầu prompt giống hệt nhau giữa các câu hỏi.
async function loadShelf(admin: SupabaseClient): Promise<Chunk[]> {
  if (shelfCache && Date.now() - shelfCache.at < shelfCacheMs) return shelfCache.chunks;
  const { data, error } = await admin
    .from('ai_chunks')
    .select('chunk_key, heading, content, ai_documents(slug, title, domain)')
    .order('id');
  if (error) throw new Error(`Shelf lookup failed: ${error.message}`);
  const chunks = (data ?? []).map((row) => {
    const document = row.ai_documents as unknown as {
      slug: string;
      title: string;
      domain: string;
    };
    return {
      id: `${document.slug}#${row.chunk_key}`,
      domain: (askDomains as string[]).includes(document.domain)
        ? document.domain as AskDomain
        : 'app' as const,
      document_title: document.title,
      heading: row.heading,
      content: row.content,
    };
  });
  shelfCache = { at: Date.now(), chunks };
  return chunks;
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
  // Ngôn ngữ app đang dùng: câu trả lời và tên nút trong đó theo đúng màn hình.
  const language: AskLanguage = body.language === 'vi' ? 'vi' : 'en';

  if (dailyLimit > 0) {
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { count } = await admin
      .from('ai_interactions')
      .select('id', { count: 'exact', head: true })
      .eq('participant_code', code)
      // Thẻ chuẩn bị câu hỏi cho buổi khám có giới hạn riêng.
      .eq('feature', 'ask')
      .gte('created_at', since);
    if ((count ?? 0) >= dailyLimit) {
      return json(200, {
        type: 'busy',
        answer: `You have asked ${dailyLimit} questions today. Please try again tomorrow.`,
        sources: [],
      });
    }
  }

  // Lĩnh vực của câu hỏi (biên bản họp, mục 3); ghi vào nhật ký.
  let domain: AskDomain | null = null;
  const log = async (
    resultType: string,
    answer: string,
    sources: string[],
    questionEnglish: string | null = null,
  ) => {
    await admin.from('ai_interactions').insert({
      participant_code: code,
      question,
      language,
      // Câu tiếng Việt kèm bản dịch của model, để nhóm nghiên cứu đọc được.
      question_english: questionEnglish?.slice(0, 1000) || null,
      result_type: resultType,
      answer: answer.slice(0, 4000),
      sources,
      domain,
      model: Deno.env.get('MODEL_NAME') ?? 'gpt-oss:20b',
      latency_ms: Date.now() - started,
    });
  };

  // Bước 2: luật cứng chạy trước, câu khẩn cấp không bao giờ tới model.
  if (isEmergency(question)) {
    await log('emergency', '', []);
    return json(200, { type: 'emergency', answer: '', sources: [] });
  }

  // Hàng chờ đã quá dài: báo bận ngay, trước khi tốn công đọc kệ.
  const waiting = await queueLength(admin);
  if (waiting >= maxQueue) {
    await log('busy', `Queue full: ${waiting} questions waiting`, []);
    return json(200, { type: 'busy', answer: queueFullMessage, sources: [] });
  }

  // Bước 3–4: tài liệu của lĩnh vực hợp nhất đi kèm câu hỏi, cùng lĩnh vực
  // bằng điểm nếu còn vừa. Quá dài thì Ollama sẽ lặng lẽ cắt mất lời dặn, nên
  // dừng hẳn ở đây.
  let shelf: Chunk[];
  const domains = rankDomains(question);
  domain = domains[0];
  try {
    shelf = shelfForDomains(await loadShelf(admin), domains, shelfCharacters, maxShelfCharacters);
  } catch (error) {
    await log('error', String(error).slice(0, 500), []);
    return json(200, { type: 'error', answer: '', sources: [] });
  }
  if (!shelf.length || shelfCharacters(shelf) > maxShelfCharacters) {
    await log('error', `Shelf does not fit one prompt: ${shelfCharacters(shelf)} characters`, []);
    return json(200, { type: 'error', answer: '', sources: [] });
  }

  // Bước 5–6: model xếp loại và viết câu trả lời, rồi kiểm tra.
  try {
    const reply = await callModel(admin, language, domain, passagesMessage(shelf, question));
    // Nguồn chỉ được là những đoạn có thật trên kệ.
    const used = shelf.filter((chunk) => (reply.used_sources ?? []).includes(chunk.id));
    await log(reply.type, reply.answer, used.map((chunk) => chunk.id), reply.question_english);
    return json(200, {
      type: reply.type,
      // App hiện thêm dòng nhắc "thông tin chung, không phải chẩn đoán".
      domain,
      answer: shownAnswer(reply),
      // Câu tiếng Việt: lần hỏi phụ đọc bản dịch của chính model, đáng tin hơn.
      also_asked: reply.type === 'medical_redirect' &&
        await askedSomethingElse(admin, reply.question_english || question),
      sources: reply.type === 'answer'
        ? used.map((chunk) => ({
          title: chunk.document_title,
          heading: chunk.heading,
        }))
        : [],
    });
  } catch (error) {
    const resultType = error instanceof ModelError ? error.resultType : 'error';
    await log(resultType, String(error).slice(0, 500), []);
    return json(200, { type: resultType, answer: '', sources: [] });
  }
});
