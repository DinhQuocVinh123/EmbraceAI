import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';
import { isEmergency } from '../_shared/emergency.ts';
import { chatRequest, ModelBusy, queueLength, runModel } from '../_shared/model_queue.ts';
import {
  joinPrepReply,
  maxConcernLength,
  maxQuestionLength,
  ownQuestions,
  type PrepLanguage,
  type PrepReply,
  prepFormat,
  prepSystemPrompt,
  prepTopics,
  prepUserMessage,
  usableQuestion,
  withQuestion,
} from '../_shared/prep_prompts.ts';

// Thẻ "chuẩn bị câu hỏi cho buổi khám" (biên bản họp, mục 2): người tham gia kể
// điều họ lo và chọn điều muốn hỏi; model tự host viết lại thành đoạn câu hỏi
// ngắn để đọc cho bác sĩ. Model chỉ sắp xếp và diễn đạt lại, không chẩn đoán,
// không khuyên về thuốc (_shared/prep_prompts.ts). Câu có dấu hiệu khẩn cấp dừng
// ở đây và không tới model. Mọi lượt được ghi vào ai_interactions như Ask.

// Mỗi tài khoản được viết lại chừng này lần trong 24 giờ (kể cả "thử cách khác").
const dailyLimit = 30;
const waitMs = 45_000;
const maxQueue = 55;

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
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

  // Giống Ask EmbraceAI: người tham gia đang hoạt động, còn hạn, được bật AI.
  const { data: participant } = await admin
    .from('participants')
    .select('participant_code, status, expires_at, ai_enabled')
    .eq('auth_user_id', authData.user.id)
    .maybeSingle();
  if (
    !participant || participant.status !== 'active' || !participant.ai_enabled ||
    new Date(participant.expires_at).getTime() <= Date.now()
  ) {
    return json(403, { error: 'Question help is not enabled for this account' });
  }
  const code = participant.participant_code as string;

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'Invalid request body' });
  }
  const concern = String(body.concern ?? '').trim();
  const topics = Array.isArray(body.topics)
    ? prepTopics.filter((topic) => (body.topics as unknown[]).includes(topic))
    : [];
  const previous = typeof body.previous === 'string'
    ? body.previous.trim().slice(0, maxQuestionLength)
    : '';
  if (!concern || concern.length > maxConcernLength) {
    return json(400, { error: 'Please describe your concern in a few words' });
  }
  const language: PrepLanguage = body.language === 'vi' ? 'vi' : 'en';

  const log = async (resultType: string, answer: string, english: string | null = null) => {
    await admin.from('ai_interactions').insert({
      participant_code: code,
      feature: 'appointment_prep',
      question: concern,
      language,
      question_english: english?.slice(0, 1000) || null,
      result_type: resultType,
      answer: answer.slice(0, 4000),
      sources: [],
      model: Deno.env.get('MODEL_NAME') ?? 'gpt-oss:20b',
      latency_ms: Date.now() - started,
    });
  };

  // Luật cứng chạy trước: câu khẩn cấp không tới model, app dừng thẻ và chỉ
  // đường tới trợ giúp y tế.
  if (isEmergency(concern)) {
    await log('emergency', '');
    return json(200, { type: 'emergency' });
  }

  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { count } = await admin
    .from('ai_interactions')
    .select('id', { count: 'exact', head: true })
    .eq('participant_code', code)
    .eq('feature', 'appointment_prep')
    .gte('created_at', since);
  if ((count ?? 0) >= dailyLimit || (await queueLength(admin)) >= maxQueue) {
    await log('busy', 'Daily limit or queue full');
    return json(200, { type: 'busy' });
  }

  try {
    const content = await runModel(
      admin,
      chatRequest(
        prepSystemPrompt(language),
        prepUserMessage(concern, topics, previous || undefined),
        prepFormat(language),
        // "Thử cách viết khác" cần cách viết khác hẳn, nên cho model tự do hơn.
        previous ? 0.7 : 0,
      ),
      waitMs,
    );
    const reply = JSON.parse(
      content.slice(content.indexOf('{'), content.lastIndexOf('}') + 1),
    ) as PrepReply;
    const question = withQuestion(joinPrepReply(reply, ownQuestions(concern)), language);
    if (!usableQuestion(question)) throw new Error(`Unusable reply: ${content.slice(0, 300)}`);
    const english = typeof reply.english === 'string' ? reply.english : null;
    await log('rephrased', question, english);
    return json(200, { type: 'question', question });
  } catch (error) {
    const busy = error instanceof ModelBusy;
    await log(busy ? 'busy' : 'error', String(error).slice(0, 500));
    return json(200, { type: busy ? 'busy' : 'error' });
  }
});
