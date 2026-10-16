import type { SupabaseClient } from 'npm:@supabase/supabase-js@2';

// Gửi một yêu cầu cho model tự host qua hàng chờ ai_jobs và chờ kết quả, giống
// runModel của ask-embrace: máy GPU không nhận kết nối từ ngoài mà tự lấy việc
// qua ai-worker. Việc luôn bị xoá khi xong, vì nó chứa lời người tham gia.

// Máy GPU hỏi việc ít nhất 20 giây một lần, trừ lúc đang trả lời.
const workerSilenceMs = 120_000;

export class ModelBusy extends Error {}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/** Số việc đang chờ hoặc đang làm (việc chờ quá 90 giây không được nhận nữa). */
export async function queueLength(admin: SupabaseClient): Promise<number> {
  const since = new Date(Date.now() - 90_000).toISOString();
  const { count } = await admin
    .from('ai_jobs')
    .select('id', { count: 'exact', head: true })
    .in('status', ['queued', 'working'])
    .gte('created_at', since);
  return count ?? 0;
}

export function chatRequest(
  system: string,
  user: string,
  format: Record<string, unknown>,
  temperature = 0,
): Record<string, unknown> {
  const model = Deno.env.get('MODEL_NAME') ?? 'gpt-oss:20b';
  return {
    model,
    stream: false,
    options: { temperature },
    ...(model.startsWith('gpt-oss') ? { think: 'low' } : { think: false }),
    format,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: user },
    ],
  };
}

/** Nội dung model trả về; ném [ModelBusy] khi máy GPU tắt, lỗi hoặc quá giờ. */
export async function runModel(
  admin: SupabaseClient,
  request: Record<string, unknown>,
  waitMs: number,
): Promise<string> {
  const { data: worker } = await admin
    .from('ai_worker_status')
    .select('last_seen')
    .eq('id', 1)
    .maybeSingle();
  if (!worker || Date.now() - new Date(worker.last_seen).getTime() > workerSilenceMs) {
    throw new ModelBusy('Model worker is offline');
  }
  const { data: job, error } = await admin
    .from('ai_jobs')
    .insert({ request })
    .select('id')
    .single();
  if (error || !job) throw new ModelBusy(`Could not queue the request: ${error?.message}`);

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
      if (row?.status === 'failed') throw new ModelBusy(`Model worker failed: ${row.error}`);
    }
  } finally {
    await admin.from('ai_jobs').delete().eq('id', job.id);
  }
  if (content === null) throw new ModelBusy('Model worker did not answer in time');
  return content;
}
