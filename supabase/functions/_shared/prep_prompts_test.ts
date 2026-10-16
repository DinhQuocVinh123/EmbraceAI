// Chạy: npx deno test supabase/functions/_shared/prep_prompts_test.ts
import { joinPrepReply, ownQuestions, prepUserMessage, usableQuestion, withQuestion } from './prep_prompts.ts';

function assertEquals(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

Deno.test("keeps the participant's own questions word for word", () => {
  assertEquals(
    ownQuestions('Feeling very tired all the time since my new tablets. Should I stop them?'),
    ['Should I stop them?'],
  );
  assertEquals(
    ownQuestions('Từ khi đổi thuốc mới tôi mệt suốt ngày. Có nên ngưng thuốc không?'),
    ['Có nên ngưng thuốc không?'],
  );
  assertEquals(ownQuestions('is my machine wrong?\nalso my ankles swell'), ['Is my machine wrong?']);
  assertEquals(ownQuestions('No question here.'), []);
});

Deno.test('the participant question comes before the topic questions, never twice', () => {
  const text = joinPrepReply(
    { observation: 'I feel tired since my new tablets.', questions: ['Should I stop them?', 'Why might this be happening.'] },
    ['Should I stop them?'],
  );
  assertEquals(text, 'I feel tired since my new tablets. Should I stop them? Why might this be happening?');
});

Deno.test('a reply without a question cannot be saved', () => {
  assertEquals(usableQuestion('I want to know if I can swim.'), false);
  assertEquals(usableQuestion('Can I go back to swimming?'), true);
  assertEquals(usableQuestion(joinPrepReply({ observation: '', questions: [] }, [])), false);
});

Deno.test('the prompt carries the chosen topics and the earlier wording', () => {
  const message = prepUserMessage('my ankles swell', ['monitor', 'nonsense'], 'Old wording?');
  if (!message.includes('what I should monitor') || message.includes('nonsense')) {
    throw new Error(message);
  }
  if (!message.includes('Old wording?')) throw new Error('previous wording missing');
});

Deno.test('a reply that only restates the concern still ends with a question', () => {
  assertEquals(withQuestion('I feel less energy.', 'en'), 'I feel less energy. Could we talk about this at my appointment?');
  assertEquals(
    withQuestion('Tôi thấy ít năng lượng.', 'vi'),
    'Tôi thấy ít năng lượng. Chúng ta có thể trao đổi về điều này trong buổi khám không?',
  );
  assertEquals(withQuestion('Why might this be happening?', 'en'), 'Why might this be happening?');
  assertEquals(usableQuestion(withQuestion('I feel less energy.', 'en')), true);
  assertEquals(withQuestion('', 'en'), '');
});
