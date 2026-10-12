// Luật khẩn cấp của ask-embrace, chạy thẳng trên file thật
// (supabase/functions/_shared/emergency.ts). Câu khớp không bao giờ tới model.
// Dùng: npm test   (từ tools/ai-lab)
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { isEmergency } from '../../../supabase/functions/_shared/emergency.ts';

test('English emergencies are caught', () => {
  for (const question of [
    'I have chest pain right now',
    'I feel like I might faint',
    'I think I am having a stroke',
    'I want to kill myself',
  ]) {
    assert.equal(isEmergency(question), true, question);
  }
});

test('Vietnamese emergencies are caught, with or without accents', () => {
  for (const question of [
    'Tôi đang bị đau ngực',
    'Tôi thấy tức ngực và khó thở quá',
    'Bố tôi vừa bị đột quỵ',
    'Tôi sắp ngất',
    'Tôi muốn tự tử',
    'Tôi không muốn sống nữa',
    'TÔI ĐAU NGỰC',
    'toi bi dau nguc',
    'kho tho qua',
    'toi muon chet',
    // Bàn phím gõ dấu tách rời (NFD).
    'Tôi đau ngực'.normalize('NFD'),
  ]) {
    assert.equal(isEmergency(question), true, question);
  }
});

test('everyday questions are not mistaken for emergencies', () => {
  for (const question of [
    // "từ từ" (chậm rãi) chỉ khác "tự tử" ở dấu.
    'Tôi thở từ từ như vậy có đúng không?',
    'tho tu tu co dung khong',
    'Cho tôi xem thêm một xíu',
    'Làm sao để chữ to hơn?',
    'Buổi tập kéo dài bao lâu?',
    'How do I turn on captions?',
    'Can I pause the video?',
  ]) {
    assert.equal(isEmergency(question), false, question);
  }
});
