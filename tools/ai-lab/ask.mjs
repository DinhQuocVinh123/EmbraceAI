// Chạy thử "lễ tân" ask-embrace trên máy: lọc khẩn cấp, gửi cả kệ cho model
// tự host, kiểm tra JSON. Dùng: node ask.mjs                 (cả bộ questions.json)
//                              node ask.mjs --vi            (chỉ các câu tiếng Việt)
//                              node ask.mjs "câu hỏi"        (một câu, app tiếng Anh)
//                              node ask.mjs --vi "câu hỏi"   (một câu, app tiếng Việt)
import { readFile } from 'node:fs/promises';

import { isHealthDomain } from '../../supabase/functions/_shared/ask_domains.ts';
import { answerTypes, withVietnameseNames } from '../../supabase/functions/_shared/ask_prompts.ts';
import { MODEL, OTHER_QUESTION_CHECK, modelRequest, prepare, shelf } from './frontdesk.mjs';

const OLLAMA_URL = process.env.OLLAMA_URL ?? 'http://100.108.94.65:11434';
// Khung của model là 4.096 token; câu trả lời dài nhất cần khoảng 350 token.
const PROMPT_BUDGET = 3_700;

/** Gọi model tự host; trả JSON đã kiểm tra, hoặc ném lỗi kèm loại kết quả. */
async function callModel(system, user, schema, types) {
  let reply;
  let promptTokens = 0;
  try {
    const res = await fetch(`${OLLAMA_URL}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(modelRequest(system, user, schema)),
      signal: AbortSignal.timeout(180_000),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
    const body = await res.json();
    reply = body.message?.content ?? '';
    promptTokens = body.prompt_eval_count ?? 0;
  } catch (error) {
    throw Object.assign(new Error(`model server: ${error.message}`), { type: 'busy' });
  }
  // Bước 6: chỉ nhận JSON đúng khuôn, đúng loại được phép.
  try {
    const parsed = JSON.parse(reply.slice(reply.indexOf('{'), reply.lastIndexOf('}') + 1));
    if (types && !types.includes(parsed.type)) throw new Error(`unexpected type ${parsed.type}`);
    return { ...parsed, promptTokens };
  } catch (error) {
    throw Object.assign(new Error(`invalid reply: ${error.message} ${reply.slice(0, 200)}`), { type: 'error' });
  }
}

/** Câu y tế có hỏi kèm chuyện về app, nghiên cứu hay bài tập không; lỗi thì coi như không. */
async function askedSomethingElse(question) {
  try {
    const schema = { type: 'object', properties: { other_question: { type: 'boolean' } }, required: ['other_question'] };
    return (await callModel(OTHER_QUESTION_CHECK, `Question: ${question}`, schema)).other_question === true;
  } catch {
    return false;
  }
}

async function ask(question, language) {
  const started = Date.now();
  const done = (result) => ({ sources: [], ...result, ms: Date.now() - started });
  // Bước 2–4: luật cứng chạy trước, câu khẩn cấp không bao giờ tới model;
  // câu khác được gửi kèm cả kệ.
  const call = await prepare(question, language);
  if (call.emergency) return done({ type: 'emergency', answer: '[emergency card]' });
  try {
    // Bước 5: gửi hướng dẫn + cả kệ + câu hỏi cho model tự host.
    const parsed = await callModel(call.system, call.user, call.schema, answerTypes);
    // Giống ask-embrace: câu sức khoẻ tài liệu không nói tới thì chỉ tới nhóm chăm sóc.
    if (isHealthDomain(call.domain) && parsed.type === 'not_found') parsed.type = 'medical_redirect';
    // Nguồn chỉ được là những đoạn có thật trên kệ.
    const sources = (parsed.used_sources ?? []).filter((id) => shelf.some((chunk) => chunk.id === id));
    return done({
      domains: call.domains,
      type: parsed.type,
      answer: language === 'vi' ? withVietnameseNames(parsed.answer) : parsed.answer,
      english: parsed.question_english,
      promptTokens: parsed.promptTokens,
      // Câu tiếng Việt: lần hỏi phụ đọc bản dịch của chính model, đáng tin hơn.
      other: parsed.type === 'medical_redirect' && await askedSomethingElse(parsed.question_english || question),
      sources,
    });
  } catch (error) {
    return done({ type: error.type ?? 'error', answer: `[${error.message}]` });
  }
}

const args = process.argv.slice(2);
const only = ['--en', '--vi'].includes(args[0]) ? args.shift().slice(2) : null;
const single = args.join(' ').trim();
const questions = single
  ? [{ question: single, language: only ?? 'en' }]
  : JSON.parse(await readFile('questions.json', 'utf8'))
    .filter((q) => !only || (q.language ?? 'en') === only);

const score = {};
let largestPrompt = 0;
for (const { question, expect, other, domain, language = 'en' } of questions) {
  const result = await ask(question, language);
  largestPrompt = Math.max(largestPrompt, result.promptTokens ?? 0);
  // other: câu y tế có kèm ý khác hay không (app nhắc hỏi riêng phần đó).
  const ok = (!expect || expect === result.type) && (other === undefined || other === result.other) &&
    (!domain || !result.domains || result.domains[0] === domain);
  if (expect) {
    score[language] ??= { passed: 0, total: 0 };
    score[language].total++;
    if (ok) score[language].passed++;
  }
  console.log(`\n${ok ? 'PASS' : 'FAIL'}  [${language}] [${result.type}${expect ? ` / expected ${expect}` : ''}]  ${(result.ms / 1000).toFixed(1)}s`);
  console.log(`Q: ${question}`);
  if (result.domains) console.log(`Domain: ${result.domains.join(' + ')}${domain ? ` / expected ${domain}` : ''}`);
  if (result.english) console.log(`English: ${result.english}`);
  console.log(`A: ${result.answer}`);
  if (result.type === 'medical_redirect') console.log(`Other question: ${result.other ? 'yes' : 'no'}${other === undefined ? '' : ` / expected ${other ? 'yes' : 'no'}`}`);
  if (result.sources.length) console.log(`Sources: ${result.sources.join(', ')}`);
}
console.log('');
for (const [language, { passed, total }] of Object.entries(score)) {
  console.log(`${language}: ${passed}/${total} matched the expected result type (model ${MODEL}).`);
}
if (largestPrompt) {
  console.log(`Largest prompt: ${largestPrompt} tokens of ${PROMPT_BUDGET} allowed (window 4096).`);
  if (largestPrompt > PROMPT_BUDGET) {
    console.log('WARNING: the prompt leaves too little room for the answer; the shelf needs search again.');
    process.exitCode = 1;
  }
}
