import { createClient } from 'npm:@supabase/supabase-js@2';

// Cửa duy nhất mà chương trình trên máy GPU (tools/model-server/model-worker.ps1)
// dùng: lấy việc trong hàng chờ ai_jobs và gửi câu trả lời của model về.
// Máy GPU chỉ đi ra internet, không mở cổng nào. Khoá MODEL_SERVER_KEY dùng
// chung với máy GPU; không cần đăng nhập Supabase nên verify_jwt = false.

const longPollMs = 20_000;
const pollEveryMs = 1_000;

function json(status: number, body: Record<string, unknown>): Response {
  // Ghi rõ UTF-8: PowerShell 5.1 trên máy GPU đọc sai chữ có dấu nếu thiếu.
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  });
}

// So khoá trong thời gian không đổi, để không đoán dần được từng ký tự.
async function sameSecret(a: string, b: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const [x, y] = await Promise.all(
    [a, b].map((value) => crypto.subtle.digest('SHA-256', encoder.encode(value))),
  );
  const left = new Uint8Array(x);
  const right = new Uint8Array(y);
  let difference = 0;
  for (let i = 0; i < left.length; i++) difference |= left[i] ^ right[i];
  return difference === 0;
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json(405, { error: 'Method not allowed' });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const workerKey = Deno.env.get('MODEL_SERVER_KEY');
  if (!supabaseUrl || !serviceRoleKey || !workerKey) {
    return json(503, { error: 'The model worker is not configured' });
  }
  const authorization = request.headers.get('Authorization') ?? '';
  if (!(await sameSecret(authorization, `Bearer ${workerKey}`))) {
    return json(401, { error: 'Unauthorized' });
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'Invalid request body' });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Bộ cài hỏi xem chương trình chạy nền đã kết nối chưa; không tính là "đã thấy".
  if (body.action === 'status') {
    const { data } = await admin
      .from('ai_worker_status')
      .select('last_seen')
      .eq('id', 1)
      .maybeSingle();
    const secondsSinceSeen = data
      ? Math.round((Date.now() - new Date(data.last_seen).getTime()) / 1000)
      : null;
    return json(200, { ok: true, seconds_since_seen: secondsSinceSeen });
  }

  await admin
    .from('ai_worker_status')
    .upsert({ id: 1, last_seen: new Date().toISOString() });

  if (body.action === 'next') {
    // max: số chỗ đang trống trên máy GPU; trả về tới chừng đó việc một lần.
    // Không có max là chương trình chạy nền bản cũ: một việc, khuôn cũ.
    const max = typeof body.max === 'number' && Number.isInteger(body.max)
      ? Math.min(Math.max(body.max, 1), 8)
      : null;
    // Giữ yêu cầu tối đa 20 giây, cứ mỗi giây xem có việc mới chưa.
    const deadline = Date.now() + longPollMs;
    while (true) {
      const { data, error } = max
        ? await admin.rpc('claim_ai_jobs', { max_jobs: max })
        : await admin.rpc('claim_ai_job');
      if (error) return json(500, { error: 'Could not read the queue' });
      const jobs = ((data ?? []) as { id: string; request: unknown }[])
        .map((job) => ({ id: job.id, body: JSON.stringify(job.request) }));
      if (jobs.length) return json(200, max ? { jobs } : jobs[0]);
      if (Date.now() + pollEveryMs > deadline) {
        return json(200, max ? { jobs: [] } : { id: null });
      }
      await sleep(pollEveryMs);
    }
  }

  if (body.action === 'result' || body.action === 'fail') {
    const id = String(body.id ?? '');
    if (!/^[0-9a-f-]{36}$/.test(id)) return json(400, { error: 'Invalid job id' });
    const update = body.action === 'result'
      ? { status: 'done', result: String(body.content ?? '').slice(0, 20000) }
      : { status: 'failed', error: String(body.error ?? '').slice(0, 1000) };
    // Người hỏi đã thôi chờ thì việc đã bị xoá; khi đó không cập nhật gì cả.
    await admin
      .from('ai_jobs')
      .update({ ...update, finished_at: new Date().toISOString() })
      .eq('id', id)
      .eq('status', 'working');
    return json(200, { ok: true });
  }

  return json(400, { error: 'Unknown action' });
});
