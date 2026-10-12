// Hàng chờ trên Supabase chia câu hỏi cho máy GPU thế nào: chạy đúng các file
// migration của ai_jobs trên một Postgres ngay trong máy (PGlite).
// Dùng: npm test   (từ tools/ai-lab)
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { before, beforeEach, test } from 'node:test';

import { PGlite } from '@electric-sql/pglite';

const MIGRATIONS = [
  '20261008000300_ai_jobs.sql',
  '20261011000100_ai_jobs_batch.sql',
  '20261011000200_claim_ai_jobs_limit.sql',
  '20261011000300_ai_jobs_requeue.sql',
  '20261012000100_ai_worker_stats.sql',
];

let db;

before(async () => {
  db = new PGlite();
  // Các role Supabase có sẵn mà migration cấp quyền cho.
  await db.exec('create role anon; create role authenticated; create role service_role;');
  for (const file of MIGRATIONS) {
    await db.exec(await readFile(new URL(`../../../supabase/migrations/${file}`, import.meta.url), 'utf8'));
  }
});

beforeEach(() => db.exec('delete from ai_jobs'));

/** Xếp n câu hỏi đã chờ chừng ấy giây; câu sau đến sau câu trước 10 ms. */
async function queue(n, waitedSeconds = 5) {
  await db.query(
    `insert into ai_jobs (request, created_at)
     select jsonb_build_object('n', g), now() - make_interval(secs => $2) + g * interval '10 ms'
     from generate_series(1, $1) g`,
    [n, waitedSeconds],
  );
}

/** Máy GPU hỏi xin tối đa max câu; trả về số thứ tự các câu nhận được. */
async function claim(max) {
  const { rows } = await db.query(`select (request->>'n')::int as n from claim_ai_jobs($1)`, [max]);
  return rows.map((r) => r.n);
}

async function statuses() {
  const { rows } = await db.query('select status, count(*)::int as n from ai_jobs group by status');
  return Object.fromEntries(rows.map((r) => [r.status, r.n]));
}

test('90 people at once: each fetch takes only as many as the GPU machine has free, oldest first', async () => {
  await queue(90);
  assert.deepEqual(await claim(4), [1, 2, 3, 4]);
  assert.deepEqual(await claim(4), [5, 6, 7, 8]);
  assert.deepEqual(await statuses(), { queued: 82, working: 8 });
});

test('one fetch takes at most 8 questions and at least 1', async () => {
  await queue(20);
  assert.equal((await claim(99)).length, 8);
  assert.equal((await claim(0)).length, 1);
});

test('a question older than 90 seconds is skipped: its asker has stopped waiting', async () => {
  await queue(1, 120);
  await db.query(`insert into ai_jobs (request) values ('{"n": 2}')`);
  assert.deepEqual(await claim(4), [2]);
});

test('a question stuck for 40 seconds goes back to the queue', async () => {
  await queue(3);
  assert.deepEqual(await claim(2), [1, 2]);
  // Câu 1 nhận đã 45 giây mà chưa xong (kết nối đứt), câu 2 mới nhận 10 giây.
  await db.exec(`
    update ai_jobs set claimed_at = now() - interval '45 seconds' where request->>'n' = '1';
    update ai_jobs set claimed_at = now() - interval '10 seconds' where request->>'n' = '2';`);
  assert.deepEqual(await claim(4), [1, 3]);
});

test('questions left for 10 minutes are deleted', async () => {
  await queue(5, 11 * 60);
  assert.deepEqual(await claim(4), []);
  assert.deepEqual(await statuses(), {});
});
