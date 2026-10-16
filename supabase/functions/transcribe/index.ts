import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';
import { cleanTranscript } from '../_shared/transcript.ts';

// Nói thay vì gõ: app gửi một đoạn ghi âm WAV 16 kHz (tối đa 30 giây), hàm này
// đặt nó vào hàng chờ ai_jobs dưới dạng việc 'transcribe', máy GPU đưa cho
// Whisper (whisper.cpp) rồi gửi chữ về. Giống ask-embrace: máy GPU không nhận kết
// nối từ ngoài, và việc bị xoá ngay khi xong, nên đoạn ghi âm không nằm lại đâu.
// Không ghi log nội dung.

// 30 giây WAV 16 kHz 16-bit một kênh là 960 KB, tức khoảng 1,28 triệu ký tự
// base64. Chừa thêm một chút cho phần đầu file.
const maxAudioCharacters = 1_400_000;
const workerSilenceMs = 120_000;
const waitMs = 45_000;
// Giống ngưỡng mặc định của ask-embrace: hàng dài thì báo bận ngay.
const maxQueue = 55;

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

const busy = () => json(503, { error: 'Voice typing is busy right now' });
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

async function workerOnline(admin: SupabaseClient): Promise<boolean> {
  const { data } = await admin
    .from('ai_worker_status')
    .select('last_seen')
    .eq('id', 1)
    .maybeSingle();
  return !!data && Date.now() - new Date(data.last_seen).getTime() <= workerSilenceMs;
}

async function queueLength(admin: SupabaseClient): Promise<number> {
  const since = new Date(Date.now() - 90_000).toISOString();
  const { count } = await admin
    .from('ai_jobs')
    .select('id', { count: 'exact', head: true })
    .in('status', ['queued', 'working'])
    .gte('created_at', since);
  return count ?? 0;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return json(405, { error: 'Method not allowed' });

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

  // Mọi người tham gia đang hoạt động, còn hạn: đây là hỗ trợ nhập liệu, không
  // phải tính năng dùng thử như Ask EmbraceAI.
  const { data: participant } = await admin
    .from('participants')
    .select('status, expires_at')
    .eq('auth_user_id', authData.user.id)
    .maybeSingle();
  if (
    !participant || participant.status !== 'active' ||
    new Date(participant.expires_at).getTime() <= Date.now()
  ) {
    return json(403, { error: 'Voice typing is not available for this account' });
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'Invalid request body' });
  }
  const audio = typeof body.audio === 'string' ? body.audio : '';
  // "UklGR" là "RIFF" (đầu file WAV) viết bằng base64.
  if (!audio.startsWith('UklGR') || audio.length > maxAudioCharacters || !/^[A-Za-z0-9+/]+=*$/.test(audio)) {
    return json(400, { error: 'The recording is missing or too long' });
  }
  const language = body.language === 'vi' ? 'vi' : 'en';

  if (!(await workerOnline(admin)) || (await queueLength(admin)) >= maxQueue) return busy();

  const { data: job, error: queueError } = await admin
    .from('ai_jobs')
    .insert({ kind: 'transcribe', request: { audio, language } })
    .select('id')
    .single();
  if (queueError || !job) return busy();

  let text: string | null = null;
  try {
    const deadline = Date.now() + waitMs;
    while (text === null && Date.now() < deadline) {
      await sleep(500);
      const { data: row } = await admin
        .from('ai_jobs')
        .select('status, result')
        .eq('id', job.id)
        .maybeSingle();
      if (row?.status === 'done') text = row.result ?? '';
      if (row?.status === 'failed') return busy();
    }
  } finally {
    await admin.from('ai_jobs').delete().eq('id', job.id);
  }
  if (text === null) return busy();
  return json(200, { text: cleanTranscript(text) });
});
