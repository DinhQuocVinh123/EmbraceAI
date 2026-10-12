// Kiểm tra hệ thống thật có trả lời kịp N người hỏi cùng một lúc không.
// Dựng N câu hỏi y như ask-embrace (câu trong questions.json, kèm cả kệ),
// đặt cả N vào hàng chờ ai_jobs trên Supabase trong cùng một khoảnh khắc, chờ
// máy GPU làm, rồi đếm số câu xong trong 60 giây: ask-embrace chỉ chờ chừng đó
// trước khi báo bận. Bài đo bỏ qua ngưỡng báo bận AI_MAX_QUEUE để thấy sức thật
// của máy GPU, và luôn xoá các câu thử khi xong. Đạt khi cả N câu xong trong
// 60 giây; không đạt thì cho biết hệ thống kịp được bao nhiêu người.
//
// Dùng: node capacity.mjs [N=55] [en|vi|mix=mix]   (từ tools/ai-lab; cần Supabase CLI đã link
// project, như khi chạy `npx supabase db push`, và máy GPU đang chạy). Chạy lúc
// không ai đang thử app: trong khoảng hai phút, người hỏi thật phải xếp sau
// các câu thử.
import { execSync } from 'node:child_process';
import { readFile, rm, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

import { modelRequest, prepare } from './frontdesk.mjs';

const REPO = fileURLToPath(new URL('../..', import.meta.url));
const SQL_FILE = fileURLToPath(new URL('data/capacity.sql', import.meta.url));
// ask-embrace chờ 60 giây; máy GPU bỏ qua câu đã chờ quá 90 giây.
const ANSWER_WAIT_S = 60;
const SKIP_AFTER_S = 90;
// Giống maxQueue trong ask-embrace.
const DEFAULT_MAX_QUEUE = 55;

// Mặc định là ngưỡng báo bận: hệ thống hứa trả lời mọi người dưới ngưỡng đó.
const count = Number(process.argv[2] ?? DEFAULT_MAX_QUEUE);
// Câu tiếng Việt kèm bản dịch tiếng Anh nên tốn máy hơn một chút; mặc định
// trộn hai thứ tiếng như ngoài đời.
const language = process.argv[3] ?? 'mix';
if (!Number.isInteger(count) || count < 1 || count > 300 || !['en', 'vi', 'mix'].includes(language)) {
  console.error('Usage: node capacity.mjs [number of questions, 1-300] [en|vi|mix]');
  process.exit(1);
}

/** Chạy SQL trên database thật qua Supabase CLI (dùng phiên đăng nhập của CLI). */
async function sql(text) {
  await writeFile(SQL_FILE, text);
  const out = execSync(`npx supabase db query --linked -o json -f "${SQL_FILE}"`, {
    cwd: REPO,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    maxBuffer: 64 * 1024 * 1024,
  });
  return rowsOf(out);
}

/**
 * CLI in kết quả thành một mảng các dòng; khi chạy dưới một AI agent nó bọc
 * mảng đó trong { boundary, rows }. Có thể có vài dòng thông báo phía trước.
 */
function rowsOf(out) {
  const start = out.search(/^[[{]/m);
  if (start < 0) return [];
  const parsed = JSON.parse(out.slice(start));
  return Array.isArray(parsed) ? parsed : parsed.rows ?? [];
}

/** Cột json có thể về dạng đối tượng hoặc dạng chuỗi. */
const asObject = (value) => (typeof value === 'string' ? JSON.parse(value) : value ?? {});

// 1. Dựng câu hỏi thật: lời dặn, cả kệ và câu hỏi, như ask-embrace gửi đi.
const samples = [];
for (const q of JSON.parse(await readFile(new URL('questions.json', import.meta.url), 'utf8'))) {
  const lang = q.language ?? 'en';
  if (language !== 'mix' && lang !== language) continue;
  const call = await prepare(q.question, lang);
  if (!call.emergency) samples.push(modelRequest(call.system, call.user, call.schema));
}
// Mỗi người hỏi một câu khác nhau: một dòng mã riêng ngay trước câu hỏi để
// Ollama không dùng lại được phần đã đọc của một câu giống hệt. Lời dặn và cả
// kệ đứng trước dòng đó, giống nhau giữa mọi người hỏi, nên vẫn dùng lại được,
// như ngoài đời.
const runTag = Date.now().toString(36);
const requests = Array.from({ length: count }, (_, i) => {
  const sample = samples[i % samples.length];
  const [system, user] = sample.messages;
  const content = user.content.replace('\n\nQuestion: ', `\n\nRef ${runTag}-${i}\n\nQuestion: `);
  return JSON.stringify({ ...sample, messages: [system, { ...user, content }] });
});
if (requests.some((r) => r.includes('$capacity$'))) throw new Error('a question contains the SQL quote tag');

// 2. Chỉ đo khi máy GPU đang chạy và không có ai đang hỏi thật.
const [state = {}] = await sql(`select
  (select extract(epoch from now() - last_seen)::int from public.ai_worker_status where id = 1) as silent_s,
  (select stats from public.ai_worker_status where id = 1) as stats,
  (select count(*)::int from public.ai_jobs
   where status in ('queued', 'working') and created_at > now() - interval '${SKIP_AFTER_S} seconds') as waiting`);
if (state.silent_s == null || state.silent_s > 30) {
  console.error(`The GPU machine has not asked for work for ${state.silent_s ?? '?'} s: start it and try again.`);
  process.exit(1);
}
if (state.waiting > 0) {
  console.error(`${state.waiting} real questions are waiting: try again when nobody is using Ask EmbraceAI.`);
  process.exit(1);
}
const slots = asObject(state.stats).slots;
console.log(slots
  ? `The GPU machine answers up to ${slots} questions at once.`
  : 'The GPU machine does not report its numbers yet: install the latest kit on it to see how busy the GPU gets.');

// 3. Đặt cả N câu trong một lệnh: cùng một giờ tạo, như N người bấm gửi cùng lúc.
const queued = await sql(
  `insert into public.ai_jobs (request) values\n${requests.map((r) => `($capacity$${r}$capacity$::jsonb)`).join(',\n')}\nreturning id`,
);
const ids = queued.map((r) => `'${r.id}'`).join(',');
const insertedAt = Date.now();
console.log(`${count} questions (${language}, from ${samples.length} sample questions) queued at ${new Date().toLocaleTimeString()}.`);

let cleaned = false;
async function cleanUp() {
  if (cleaned) return;
  cleaned = true;
  await sql(`delete from public.ai_jobs where id in (${ids})`);
  await rm(SQL_FILE, { force: true });
}
process.on('SIGINT', () => cleanUp().finally(() => process.exit(130)));

let rows;
// Số đo GPU từ lúc máy GPU đã nhận đủ chỗ cho tới khi hết người xếp hàng, tức
// lúc nó lẽ ra phải làm hết sức. Lần đọc trước đó rơi vào một hai giây khởi
// động, khi chưa câu nào tới GPU.
const busyReadings = [];
let mostAtOnce = 0;
let fullSince = null;
try {
  // 4. Chờ tới khi không còn câu nào máy GPU sẽ làm: xong hết, hoặc câu còn lại đã quá 90 giây.
  for (;;) {
    await new Promise((r) => setTimeout(r, 2000));
    const [now = {}] = await sql(`select
      (select json_object_agg(status, n) from (
        select status, count(*)::int as n from public.ai_jobs where id in (${ids}) group by status) s) as progress,
      (select stats from public.ai_worker_status where id = 1) as stats,
      extract(epoch from now())::float as polled_at`);
    const progress = asObject(now.progress);
    const stats = asObject(now.stats);
    mostAtOnce = Math.max(mostAtOnce, progress.working ?? 0);
    if (fullSince === null && (progress.working ?? 0) >= (slots ?? 1)) fullSince = now.polled_at;
    const fresh = fullSince !== null && Date.parse(stats.at) / 1000 > fullSince && stats.at !== busyReadings.at(-1)?.at;
    if (progress.queued && stats.gpu_util != null && fresh) busyReadings.push(stats);
    const elapsed = (Date.now() - insertedAt) / 1000;
    const gpu = stats.gpu_util != null ? `  GPU busy ${stats.gpu_util}%` : '';
    console.log(`  ${elapsed.toFixed(0).padStart(3)} s  done ${progress.done ?? 0}  answering ${progress.working ?? 0}  waiting ${progress.queued ?? 0}${gpu}`);
    const open = (progress.queued ?? 0) + (progress.working ?? 0);
    if (!open || (!progress.working && elapsed > SKIP_AFTER_S + 5) || elapsed > 300) break;
  }
  rows = await sql(`select status, extract(epoch from finished_at - created_at)::float as seconds
    from public.ai_jobs where id in (${ids})`);
} finally {
  await cleanUp();
}

// 5. Kết quả.
const times = rows.filter((r) => r.status === 'done').map((r) => r.seconds).sort((a, b) => a - b);
const within = (s) => times.filter((t) => t <= s).length;
const capacity = within(ANSWER_WAIT_S);
const pct = (p) => times[Math.min(times.length - 1, Math.floor(p * times.length))]?.toFixed(1) ?? '-';
console.log(`\nAnswered: ${times.length}/${count}, failed: ${rows.filter((r) => r.status === 'failed').length}`);
console.log(`Answered within 10 s: ${within(10)}, within 30 s: ${within(30)}, within ${ANSWER_WAIT_S} s: ${capacity}`);
if (times.length) {
  console.log(`Wait: median ${pct(0.5)} s, 90% within ${pct(0.9)} s, last ${times.at(-1).toFixed(1)} s`);
  console.log(`Speed: about ${Math.round((times.length / times.at(-1)) * 60)} answers a minute`);
}

// GPU đã chạm trần chưa: lúc còn người xếp hàng mà GPU vẫn có lúc rảnh thì chỗ
// nghẽn nằm ở chỗ khác; GPU bận gần như liên tục thì thêm câu cùng lúc cũng
// không làm nó nhanh hơn.
console.log(`\nGPU machine: answers up to ${slots ?? '?'} at once; most seen answering at the same time: ${mostAtOnce}`);
if (busyReadings.length) {
  const avg = (key) => busyReadings.reduce((a, r) => a + r[key], 0) / busyReadings.length;
  const has = (key) => busyReadings.every((r) => typeof r[key] === 'number');
  const util = avg('gpu_util');
  const parts = [`busy ${util.toFixed(0)}% of the time on average (lowest ${Math.min(...busyReadings.map((r) => r.gpu_util))}%)`];
  // Viết câu trả lời nghẽn ở tốc độ đọc bộ nhớ (đọc lại cả model cho mỗi chữ),
  // nên con số này cho thấy GPU còn sức hay không rõ hơn cả điện năng.
  if (has('gpu_mem_busy')) parts.push(`memory reading or writing ${avg('gpu_mem_busy').toFixed(0)}% of the time`);
  if (has('gpu_power_w') && has('gpu_power_limit_w')) {
    parts.push(`power ${avg('gpu_power_w').toFixed(0)} of ${avg('gpu_power_limit_w').toFixed(0)} W (${(100 * avg('gpu_power_w') / avg('gpu_power_limit_w')).toFixed(0)}% of its limit)`);
  }
  if (has('gpu_mem_used_mb') && has('gpu_mem_total_mb')) {
    parts.push(`memory ${(Math.max(...busyReadings.map((r) => r.gpu_mem_used_mb)) / 1024).toFixed(1)} of ${(avg('gpu_mem_total_mb') / 1024).toFixed(1)} GB`);
  }
  if (has('gpu_clock_mhz') && has('gpu_clock_max_mhz')) {
    parts.push(`clock ${avg('gpu_clock_mhz').toFixed(0)} of ${avg('gpu_clock_max_mhz').toFixed(0)} MHz`);
  }
  if (has('gpu_temp_c')) parts.push(`up to ${Math.max(...busyReadings.map((r) => r.gpu_temp_c))} °C`);
  console.log(`GPU while people were still waiting (${busyReadings.length} readings): ${parts.join(', ')}`);
  // Phần Ollama làm trên CPU (xếp lượt, chọn từng chữ theo khuôn JSON) có thể
  // bắt GPU chờ; 1 nhân = một luồng chạy hết sức.
  if (has('ollama_cpu_cores')) {
    const cores = busyReadings.map((r) => r.ollama_cpu_cores);
    console.log(`CPU: Ollama used ${avg('ollama_cpu_cores').toFixed(2)} cores on average (most ${Math.max(...cores).toFixed(2)}) of the ${busyReadings[0].cpu_count} on the machine`);
  }
  console.log(util >= 95
    ? '=> The GPU had no idle time: it is at its ceiling, and more questions at once cannot make it faster.'
    : util >= 80
      ? '=> The GPU was nearly always busy but not fully: it is close to its ceiling, and something else also holds it back.'
      : '=> The GPU still had idle time while people waited: the limit is somewhere else (Ollama on the CPU, the network or the worker), not the GPU.');
} else {
  console.log('No GPU readings while people were waiting: install the latest kit on the GPU machine.');
}
if (capacity === count) {
  console.log(`\nPASS: all ${count} people asking at once were answered within ${ANSWER_WAIT_S} s.`);
  console.log('Run again with a bigger number to find where the limit is.');
} else {
  process.exitCode = 1;
  console.log(`\nFAIL: only ${capacity} of ${count} people asking at once were answered within ${ANSWER_WAIT_S} s.`);
  console.log(`The system answers about ${capacity} people at once in time; from person ${capacity + 1} on, the wait is over ${ANSWER_WAIT_S} s.`);
  console.log(capacity < DEFAULT_MAX_QUEUE
    ? `The busy limit (AI_MAX_QUEUE, ${DEFAULT_MAX_QUEUE} unless set) is above that: lower it to about ${capacity}.`
    : `The busy limit (AI_MAX_QUEUE, ${DEFAULT_MAX_QUEUE} unless set) is within that: everyone past it is told straight away to try again.`);
}
