// Chạy: npx deno test supabase/functions/_shared/transcript_test.ts
import { cleanTranscript } from './transcript.ts';

function assertEquals(actual: string, expected: string) {
  if (actual !== expected) throw new Error(`expected "${expected}", got "${actual}"`);
}

Deno.test('joins Whisper lines into one sentence', () => {
  assertEquals(
    cleanTranscript(' Bạn không cần có kinh nghiệm trước, không có gì phải đạt được cả\n Bạn chỉ cần làm theo\n'),
    'Bạn không cần có kinh nghiệm trước, không có gì phải đạt được cả Bạn chỉ cần làm theo',
  );
});

Deno.test('drops the phrases Whisper invents for silence', () => {
  assertEquals(cleanTranscript(' Hãy subscribe cho kênh Ghiền Mì Gõ để không bỏ lỡ những video hấp dẫn\n'), '');
  assertEquals(cleanTranscript(' Thanks for watching!\n'), '');
  assertEquals(cleanTranscript('[BLANK_AUDIO]'), '');
  assertEquals(cleanTranscript(' (music)\n I feel calmer now.\n'), 'I feel calmer now.');
});

Deno.test('keeps ordinary speech untouched', () => {
  assertEquals(cleanTranscript(' My chest felt tight this morning.'), 'My chest felt tight this morning.');
});
