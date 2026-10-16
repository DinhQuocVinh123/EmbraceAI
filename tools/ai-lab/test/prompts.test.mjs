// Lời dặn model dùng chung (supabase/functions/_shared/ask_prompts.ts): bảng
// tên nút tiếng Việt phải khớp file dịch của app, và cả kệ phải vừa một prompt.
// Dùng: npm test   (từ tools/ai-lab)
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';

import {
  answerFormat,
  maxShelfCharacters,
  shelfCharacters,
  systemPrompt,
  vietnameseUiNames,
  withVietnameseNames,
} from '../../../supabase/functions/_shared/ask_prompts.ts';
import { routeQuestion, shelfForDomains } from '../../../supabase/functions/_shared/ask_domains.ts';
import { chunkMarkdown } from '../shelf.mjs';

const arb = async (name) =>
  JSON.parse(await readFile(new URL(`../../../lib/l10n/${name}`, import.meta.url), 'utf8'));

test('every Vietnamese screen name matches what the app shows', async () => {
  const en = await arb('app_en.arb');
  const vi = await arb('app_vi.arb');
  for (const [key, english, vietnamese] of vietnameseUiNames) {
    assert.equal(en[key], english, `${key} in app_en.arb`);
    assert.equal(vi[key], vietnamese, `${key} in app_vi.arb`);
  }
});

test('only the Vietnamese prompt carries the screen names and the translation', () => {
  const vi = systemPrompt('vi');
  assert.match(vi, /"Hiện phụ đề"/);
  assert.match(vi, /plain, friendly Vietnamese/);
  assert.doesNotMatch(systemPrompt('en'), /Hiện phụ đề|question_english/);
  // Bản dịch đứng đầu: model dịch trước rồi mới xếp loại.
  assert.deepEqual(answerFormat('vi').required, ['question_english', 'type', 'answer', 'used_sources']);
  assert.deepEqual(answerFormat('en').required, ['type', 'answer', 'used_sources']);
});

test('English screen names left in a Vietnamese answer are replaced', () => {
  // Các câu model đã thật sự viết khi thử ngày 12/10.
  assert.equal(
    withVietnameseNames('Trong buổi tập, nhấn vào "Trợ giúp" (Help) và chọn "Cỡ chữ" (Text size).'),
    'Trong buổi tập, nhấn vào "Trợ giúp" và chọn "Cỡ chữ".',
  );
  assert.equal(
    withVietnameseNames('nhấn nút "Help" (Trợ giúp), chọn "Text size" (Cỡ chữ)'),
    'nhấn nút "Trợ giúp", chọn "Cỡ chữ"',
  );
  assert.equal(
    withVietnameseNames('chọn "Guided voice" và nhấn “Pause”, rồi “Leave session”'),
    'chọn "Giọng hướng dẫn" và nhấn "Tạm dừng", rồi "Rời buổi tập"',
  );
  // Chữ thường, không nằm trong ngoặc kép thì giữ nguyên.
  assert.equal(withVietnameseNames('Bạn có thể pause video.'), 'Bạn có thể pause video.');
});

test('every domain fits in one prompt', async () => {
  // Cắt đoạn từ tài liệu gốc, đúng như upload.mjs đưa lên kệ; mỗi câu hỏi chỉ
  // gửi tài liệu của một lĩnh vực (ask_domains.ts).
  const content = new URL('../content/', import.meta.url);
  const manifest = JSON.parse(await readFile(new URL('manifest.json', content), 'utf8'));
  const byDomain = {};
  for (const [slug, meta] of Object.entries(manifest)) {
    assert.ok(['app', 'health', 'wellbeing', 'lifestyle'].includes(meta.domain), slug);
    for (const chunk of chunkMarkdown(await readFile(new URL(`${slug}.md`, content), 'utf8'), slug)) {
      (byDomain[meta.domain] ??= []).push({ id: chunk.id, content: chunk.text });
    }
  }
  assert.deepEqual(Object.keys(byDomain).sort(), ['app', 'health', 'lifestyle', 'wellbeing']);
  for (const [domain, passages] of Object.entries(byDomain)) {
    assert.ok(
      shelfCharacters(passages) <= maxShelfCharacters,
      `${domain}: ${shelfCharacters(passages)} characters`,
    );
  }
});

test('questions go to the domain whose documents answer them', () => {
  const cases = {
    'How do I turn on captions?': 'app',
    'Làm sao để bật phụ đề?': 'app',
    'Đường link đăng nhập hết hạn': 'app',
    'My ankles are swollen in the evening': 'health',
    'I get out of breath walking up stairs': 'health',
    'Tôi quên uống thuốc thì sao?': 'health',
    'toi bi kho tho khi leo cau thang': 'health',
    'I feel so worried and cannot sleep': 'wellbeing',
    'Tôi thấy lo lắng và khó ngủ': 'wellbeing',
    'How much salt can I eat?': 'lifestyle',
    'Tôi có nên tập thể dục không?': 'lifestyle',
    'I feel fatigue': 'health',
  };
  for (const [question, domain] of Object.entries(cases)) {
    assert.equal(routeQuestion(question), domain, question);
  }
});

test('an equal second domain is added only while the prompt still fits', () => {
  const passages = [
    { domain: 'health', content: 'a'.repeat(60) },
    { domain: 'wellbeing', content: 'b'.repeat(30) },
    { domain: 'app', content: 'c'.repeat(30) },
  ];
  const size = (list) => list.reduce((n, p) => n + p.content.length, 0);
  assert.equal(shelfForDomains(passages, ['health', 'wellbeing'], size, 100).length, 2);
  assert.equal(shelfForDomains(passages, ['health', 'wellbeing'], size, 80).length, 1);
  assert.equal(shelfForDomains(passages, ['app'], size, 100)[0].domain, 'app');
});
