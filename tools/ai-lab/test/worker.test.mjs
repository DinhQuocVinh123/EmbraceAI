// Chương trình trên máy GPU (model-worker.ps1) chạy thật, nhưng nói chuyện với
// một Supabase giả và một Ollama giả: mỗi câu Ollama giả mất 1,5 giây. Đếm số
// câu nó giữ cùng lúc so với số chỗ (-Slots, bộ cài đặt bằng OLLAMA_NUM_PARALLEL). Chỉ chạy trên Windows, nơi có PowerShell 5.1.
// Dùng: npm test   (từ tools/ai-lab)
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import http from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const WORKER = fileURLToPath(new URL('../../model-server/model-worker.ps1', import.meta.url));
const KEY = 'test-key';
const skip = process.platform !== 'win32' && 'needs Windows PowerShell';

const readJson = async (req) => {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
};
const reply = (res, body) => {
  res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
};
const listen = (server) =>
  new Promise((resolve) => server.listen(0, '127.0.0.1', () => resolve(`http://127.0.0.1:${server.address().port}`)));

/** Chạy worker tới khi trả lời xong `count` câu; trả về những gì hai máy giả thấy. */
async function runWorker({ count, slots = 4, dropFirstFetch = false }) {
  const questions = new Map();
  for (let i = 1; i <= count; i++) {
    // Có chữ có dấu: PowerShell 5.1 từng làm hỏng chúng.
    questions.set(`00000000-0000-0000-0000-${String(i).padStart(12, '0')}`, `Câu hỏi số ${i} — café`);
  }
  const waiting = [...questions.keys()];
  const answers = new Map();
  const asked = [];
  const reported = [];
  let inFlight = 0;
  let peak = 0;
  let dropped = false;

  const supabase = http.createServer(async (req, res) => {
    if (req.headers.authorization !== `Bearer ${KEY}`) return res.writeHead(401).end('{}');
    const body = await readJson(req);
    if (body.action === 'next') {
      if (dropFirstFetch && !dropped) {
        dropped = true;
        return req.socket.destroy();
      }
      asked.push(body.max);
      reported.push(body.stats);
      // Như ai-worker: tối đa 8 việc mỗi lần lấy.
      const jobs = waiting.splice(0, Math.min(body.max, 8)).map((id) => ({
        id,
        body: JSON.stringify({ model: 'test', messages: [{ role: 'user', content: questions.get(id) }] }),
      }));
      if (!jobs.length) await new Promise((r) => setTimeout(r, 300));
      return reply(res, { jobs });
    }
    if (body.action === 'result') answers.set(body.id, body.content);
    if (body.action === 'fail') answers.set(body.id, `failed: ${body.error}`);
    reply(res, { ok: true });
  });

  const ollama = http.createServer(async (req, res) => {
    const body = await readJson(req);
    peak = Math.max(peak, ++inFlight);
    await new Promise((r) => setTimeout(r, 1500));
    inFlight--;
    reply(res, { message: { content: body.messages[0].content } });
  });

  const configDir = await mkdtemp(join(tmpdir(), 'embrace-worker-'));
  try {
    await writeFile(join(configDir, 'worker-key.txt'), KEY);
    await writeFile(join(configDir, 'supabase-url.txt'), await listen(supabase));
    const ollamaUrl = await listen(ollama);
    const started = Date.now();
    const exitCode = await new Promise((resolve, reject) => {
      const child = spawn('powershell.exe', [
        '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', WORKER,
        '-ConfigDir', configDir, '-OllamaUrl', ollamaUrl, '-Slots', String(slots), '-StopAfter', String(count),
      ], { stdio: 'ignore' });
      const timer = setTimeout(() => { child.kill(); reject(new Error('worker did not finish in 60 s')); }, 60_000);
      child.on('error', reject);
      child.on('exit', (code) => { clearTimeout(timer); resolve(code); });
    });
    return { exitCode, questions, answers, asked, reported, peak, seconds: (Date.now() - started) / 1000 };
  } finally {
    supabase.close();
    ollama.close();
    await rm(configDir, { recursive: true, force: true });
  }
}

test('the GPU machine answers 16 questions at once, never more', { skip }, async () => {
  const run = await runWorker({ count: 48, slots: 16 });
  assert.equal(run.exitCode, 0);
  // Supabase đưa tối đa 8 câu mỗi lần, nên phải lấy hai lần mới đủ 16 chỗ.
  assert.equal(run.peak, 16, 'questions Ollama was answering at the same moment');
  assert.ok(run.asked.every((max) => max >= 1 && max <= 16), `asked for ${run.asked.join(', ')}`);
  // 48 câu, 16 câu một lượt, mỗi lượt 1,5 giây: ít nhất 3 lượt.
  assert.ok(run.seconds >= 4.5, `took ${run.seconds} s`);
  // Mỗi câu trả lời về đúng câu hỏi của nó, chữ có dấu còn nguyên.
  assert.deepEqual(run.answers, run.questions);
});

test('a dropped connection does not stop the GPU machine', { skip }, async () => {
  const run = await runWorker({ count: 6, dropFirstFetch: true });
  assert.equal(run.exitCode, 0);
  assert.deepEqual(run.answers, run.questions);
});

test('the GPU machine reports its slots, CPU and, where nvidia-smi exists, GPU numbers', { skip }, async (t) => {
  const run = await runWorker({ count: 4, slots: 4 });
  assert.equal(run.exitCode, 0);
  // Mỗi số đo chỉ đi kèm một lần hỏi việc; lần đầu luôn có, để báo số chỗ ngay.
  assert.ok(run.reported[0], 'the first fetch carries the numbers');
  const reports = run.reported.filter(Boolean);
  t.diagnostic(`last report: ${JSON.stringify(reports.at(-1))}`);
  for (const stats of reports) {
    assert.equal(stats.slots, 4);
    // Mục GPU không báo (như "[N/A]") thì vắng mặt, không phải số sai.
    if ('gpu_util' in stats) assert.ok(stats.gpu_util >= 0 && stats.gpu_util <= 100, `gpu_util ${stats.gpu_util}`);
    if ('gpu_mem_busy' in stats) assert.ok(stats.gpu_mem_busy >= 0 && stats.gpu_mem_busy <= 100);
    if ('gpu_mem_total_mb' in stats) assert.ok(stats.gpu_mem_used_mb <= stats.gpu_mem_total_mb);
    for (const value of Object.values(stats)) assert.equal(typeof value, 'number');
  }
});
