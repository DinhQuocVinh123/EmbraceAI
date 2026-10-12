// "Lễ tân" của ask-embrace chép sang máy: luật khẩn cấp, kệ tài liệu và khuôn
// yêu cầu gửi model. Lời dặn và luật khẩn cấp dùng thẳng file của ask-embrace
// (supabase/functions/_shared), nên không thể lệch. ask.mjs dùng nó để hỏi
// thử, capacity.mjs dùng nó để dựng câu hỏi thật cho bài đo tải.
import { readFile } from 'node:fs/promises';

import {
  answerFormat,
  maxShelfCharacters,
  otherQuestionCheck,
  passagesMessage,
  shelfCharacters,
  systemPrompt,
} from '../../supabase/functions/_shared/ask_prompts.ts';
import { isEmergency } from '../../supabase/functions/_shared/emergency.ts';

export const MODEL = process.env.MODEL ?? 'gpt-oss:20b';
// Chỉ để thử: THINK=true|false|low|medium|high thay cách ask-embrace bật suy nghĩ.
const THINK = process.env.THINK;
export const OTHER_QUESTION_CHECK = otherQuestionCheck;

// Cả kệ, theo đúng thứ tự ask-embrace đọc từ database.
export const shelf = JSON.parse(await readFile(new URL('data/shelf.json', import.meta.url), 'utf8'))
  .map((chunk) => ({ id: chunk.id, content: chunk.text }));
if (shelfCharacters(shelf) > maxShelfCharacters) {
  throw new Error(`The shelf has ${shelfCharacters(shelf)} characters, more than ${maxShelfCharacters} fit in one prompt`);
}

/** Thân yêu cầu gửi model, giống modelRequest của ask-embrace. */
export function modelRequest(system, user, schema) {
  return {
    model: MODEL,
    stream: false,
    options: { temperature: 0 },
    ...(THINK ? { think: THINK === 'true' || (THINK !== 'false' && THINK) }
      : MODEL.startsWith('gpt-oss') ? { think: 'low' } : { think: false }),
    format: schema,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: user },
    ],
  };
}

/**
 * Bước 2–4 của ask-embrace. Câu khẩn cấp dừng ở đây và không bao giờ tới
 * model; câu khác được gửi kèm cả kệ, theo ngôn ngữ app đang dùng.
 */
export async function prepare(question, language = 'en') {
  if (isEmergency(question)) return { emergency: true };
  return {
    language,
    system: systemPrompt(language),
    user: passagesMessage(shelf, question),
    schema: answerFormat(language),
  };
}
