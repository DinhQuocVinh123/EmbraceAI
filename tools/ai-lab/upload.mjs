// Đưa các đoạn trong content/ lên kệ trên Supabase qua Edge Function
// ai-ingest. Cắt đoạn giống hệt ingest.mjs; vector do Supabase tự lập.
// Cần tài khoản staff admin: tự đặt STAFF_EMAIL và STAFF_PASSWORD trong
// terminal của bạn (không lưu vào file, không gửi qua chat), rồi chạy:
//   node upload.mjs
import { readdir, readFile } from 'node:fs/promises';

import { chunkMarkdown } from './shelf.mjs';

const BATCH = 5;

const config = JSON.parse(await readFile('../../config/supabase.json', 'utf8'));
const { SUPABASE_URL: url, SUPABASE_PUBLISHABLE_KEY: apikey } = config;
const { STAFF_EMAIL: email, STAFF_PASSWORD: password } = process.env;
if (!email || !password) {
  console.error('Set STAFF_EMAIL and STAFF_PASSWORD in this terminal first.');
  process.exit(1);
}

const signIn = await fetch(`${url}/auth/v1/token?grant_type=password`, {
  method: 'POST',
  headers: { apikey, 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password }),
});
if (!signIn.ok) {
  console.error(`Staff sign-in failed (${signIn.status}).`);
  process.exit(1);
}
const { access_token: token } = await signIn.json();

const manifest = JSON.parse(await readFile('content/manifest.json', 'utf8'));
for (const file of (await readdir('content')).filter((f) => f.endsWith('.md'))) {
  const slug = file.replace(/\.md$/, '');
  const meta = manifest[slug];
  if (!meta) {
    console.warn(`Skipped ${file}: add it to content/manifest.json first.`);
    continue;
  }
  const markdown = await readFile(`content/${file}`, 'utf8');
  const chunks = chunkMarkdown(markdown, slug).map((c) => ({
    key: c.id.split('#')[1],
    heading: c.heading,
    content: c.text,
  }));
  for (let i = 0; i < chunks.length; i += BATCH) {
    const res = await fetch(`${url}/functions/v1/ai-ingest`, {
      method: 'POST',
      headers: { apikey, Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        document: { slug, ...meta },
        replace: i === 0,
        chunks: chunks.slice(i, i + BATCH),
      }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
      console.error(`${slug}: ${res.status} ${body.error ?? ''}`);
      process.exit(1);
    }
    console.log(`${slug}: ${Math.min(i + BATCH, chunks.length)}/${chunks.length} passages`);
  }
}
