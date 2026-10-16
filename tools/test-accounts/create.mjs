// Tạo tài khoản người tham gia mới tinh cho buổi test của nhóm, mỗi tài khoản
// kèm link đăng nhập cố định, rồi ghi ra một file CSV mở được bằng Excel.
// Dùng đúng các Edge Function mà cổng nhân viên dùng (create-participant,
// participant-sign-in-link), nên tài khoản giống hệt tài khoản tạo bằng tay.
//
// Cần tài khoản staff admin hoặc coordinator: tự đặt STAFF_EMAIL và
// STAFF_PASSWORD trong terminal của bạn (không lưu vào file, không gửi qua
// chat), rồi chạy trong thư mục này:
//   node create.mjs              20 tài khoản, Study ID TEAM-TEST, 90 ngày
//   node create.mjs 5 --days 30 --study TEAM-TEST-2
//
// File CSV chứa link và khoá truy cập: ai có nó là vào được các tài khoản.
// Nó nằm trong out/ (không vào git); gửi riêng từng dòng cho từng người.
import { mkdir, readFile, writeFile } from 'node:fs/promises';

const args = process.argv.slice(2);
const option = (name, fallback) => {
  const index = args.indexOf(`--${name}`);
  return index === -1 ? fallback : args[index + 1];
};
const count = Number(args.find((arg) => /^\d+$/.test(arg)) ?? 20);
const days = Number(option('days', 90));
const studyId = option('study', 'TEAM-TEST');
const group = option('group', 'Unassigned');
if (!Number.isInteger(count) || count < 1 || count > 50) {
  console.error('Number of accounts must be between 1 and 50.');
  process.exit(1);
}

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

async function call(name, body) {
  const response = await fetch(`${url}/functions/v1/${name}`, {
    method: 'POST',
    headers: {
      apikey,
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(`${name}: ${data.error ?? response.status}`);
  return data;
}

const csv = (value) => `"${String(value).replace(/"/g, '""')}"`;
const rows = [['#', 'Participant ID', 'Sign-in link', 'Access key', 'Expires']];
for (let index = 1; index <= count; index++) {
  try {
    const account = await call('create-participant', { studyId, group, validForDays: days });
    const link = await call('participant-sign-in-link', {
      participantCode: account.participantCode,
    });
    rows.push([index, account.participantCode, link.linkUrl, account.accessKey, account.expiresAt.slice(0, 10)]);
    console.log(`${index}/${count}  ${account.participantCode}`);
  } catch (error) {
    // Dừng ở lỗi đầu tiên nhưng vẫn ghi những tài khoản đã tạo được.
    console.error(`${index}/${count}  failed: ${error.message}`);
    break;
  }
}

await mkdir('out', { recursive: true });
const stamp = new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-');
const file = `out/${studyId}-${stamp}.csv`;
// BOM để Excel đọc đúng UTF-8.
await writeFile(file, '﻿' + rows.map((row) => row.map(csv).join(',')).join('\r\n') + '\r\n');
console.log(`\n${rows.length - 1} account(s) written to tools/test-accounts/${file}`);
