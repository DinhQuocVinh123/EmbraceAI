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
import { rankDomains, shelfForDomains } from '../../supabase/functions/_shared/ask_domains.ts';
import { isEmergency } from '../../supabase/functions/_shared/emergency.ts';
import { chunkMarkdown } from './shelf.mjs';

export const MODEL = process.env.MODEL ?? 'gpt-oss:20b';
// Chỉ để thử: THINK=true|false|low|medium|high thay cách ask-embrace bật suy nghĩ.
const THINK = process.env.THINK;
export const OTHER_QUESTION_CHECK = otherQuestionCheck;

// Cả kệ, cắt từ tài liệu gốc đúng như upload.mjs đưa lên, mỗi đoạn mang lĩnh
// vực của tài liệu (content/manifest.json). Mỗi lĩnh vực phải vừa một prompt.
const manifest = JSON.parse(await readFile(new URL('content/manifest.json', import.meta.url), 'utf8'));
export const shelf = [];
for (const [slug, meta] of Object.entries(manifest)) {
  const markdown = await readFile(new URL(`content/${slug}.md`, import.meta.url), 'utf8');
  for (const chunk of chunkMarkdown(markdown, slug)) {
    shelf.push({ id: chunk.id, content: chunk.text, domain: meta.domain ?? 'app' });
  }
}
for (const domain of new Set(shelf.map((passage) => passage.domain))) {
  const size = shelfCharacters(shelf.filter((passage) => passage.domain === domain));
  if (size > maxShelfCharacters) {
    throw new Error(`The ${domain} shelf has ${size} characters, more than ${maxShelfCharacters} fit in one prompt`);
  }
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
 * model; câu khác được gửi kèm tài liệu của lĩnh vực hợp nhất (ask_domains.ts),
 * theo ngôn ngữ app đang dùng.
 */
export async function prepare(question, language = 'en') {
  if (isEmergency(question)) return { emergency: true };
  const domains = rankDomains(question);
  const passages = shelfForDomains(shelf, domains, shelfCharacters, maxShelfCharacters);
  return {
    language,
    domain: domains[0],
    domains: [...new Set(passages.map((passage) => passage.domain))],
    system: systemPrompt(language, domains[0]),
    user: passagesMessage(passages, question),
    schema: answerFormat(language),
  };
}
