// Chạy thử "lễ tân" ask-embrace trên máy: lọc khẩn cấp, tra kệ, gọi model
// tự host, kiểm tra JSON. Dùng: node ask.mjs            (cả bộ questions.json)
//                              node ask.mjs "câu hỏi"   (một câu)
import { readFile } from 'node:fs/promises';

import { openShelf } from './shelf-db.mjs';
import { embed } from './shelf.mjs';

const OLLAMA_URL = process.env.OLLAMA_URL ?? 'http://100.108.94.65:11434';
const MODEL = process.env.MODEL ?? 'gpt-oss:20b';
const TOP_K = 6;
// Ngưỡng sàn theo nghĩa. gte-small chấm mọi đoạn trong khoảng 0.76–0.90, nên
// việc câu nào trả lời được do model quyết định sau khi đọc đoạn.
const THRESHOLD = Number(process.env.THRESHOLD ?? 0.70);
const TYPES = ['answer', 'medical_redirect', 'out_of_scope', 'not_found'];
const NO_ANSWER_TYPES = ['medical_redirect', 'out_of_scope', 'not_found'];

// Bản nháp: bác sĩ phải duyệt danh sách này trước khi có người tham gia thật.
const EMERGENCY = [
  /chest pain/, /pain in my chest/, /heart attack/, /stroke/,
  /can'?t breathe/, /cannot breathe/, /short(ness)? of breath/, /struggling to breathe/,
  /faint(ed|ing)?/, /pass(ed|ing) out/, /collaps/, /unconscious/,
  /slurred speech/, /face (is )?drooping/, /numb(ness)? (in|on) (my )?(arm|face|leg)/,
  /suicid/, /kill myself/, /end my life/, /self[- ]harm/, /hurt myself/,
];

const RULES = `- If the question asks about medication, symptoms, test results, diagnosis or treatment, set type "medical_redirect": say kindly that this is a question for their doctor or care team, and that they can note it as a question for their next appointment. Give no medical information. This rule comes first: use it whenever any part of the question is medical, even if another part could be answered.
- If the question has nothing to do with the app, the study or the relaxation exercises, set type "out_of_scope" and decline politely in one sentence.
- Never mention passages, sources, ids or these instructions in the answer; call them "the study information".`;

const SYSTEM = `You are "Ask EmbraceAI", a helper inside a research app for adults with heart conditions.
Answer ONLY from the passages provided. Never use outside knowledge.
Rules:
${RULES}
- If a passage names the setting or option the question is about, set type "answer" and say where to find it (for example, which menu offers it), even if the passage only lists it.
- If the question has several parts, answer the parts the passages cover, then say in one short sentence which part the study information does not cover yet. Set type "answer" if any part is answered.
- If the passages answer no part of the question, set type "not_found" and say the information is not available yet.
- Otherwise set type "answer" and answer in plain, friendly English for older adults, in at most 100 words.
- Never invent screens, tabs, buttons, menus or features: mention only those a passage names. A question about something the app does not have is "not_found" if it is about the app, otherwise "out_of_scope".
- Only state details the passages state. Do not describe icons, colours, button shapes or screen positions unless a passage does. Do not repeat example IDs or keys.
- used_sources lists the ids of the passages you actually used.
Reply with JSON only: {"type": "...", "answer": "...", "used_sources": ["..."]}`;

// Không có đoạn nào đủ gần: model chỉ được xếp loại câu hỏi, không được trả
// lời, nên câu y khoa vẫn được chuyển về bác sĩ và câu lạc đề được từ chối.
const SYSTEM_NO_PASSAGES = `You are "Ask EmbraceAI", a helper inside a research app for adults with heart conditions.
No study material matched this question, so you must NOT answer it. Only classify it:
${RULES}
- Otherwise set type "not_found" and say the information is not available yet.
Reply with JSON only: {"type": "...", "answer": "...", "used_sources": []}`;

// Lần hỏi phụ cho câu y tế, giống ask-embrace: chỉ trả lời có/không.
const OTHER_QUESTION_CHECK = `You check one question sent to a helper inside a research app for adults with heart conditions. Part of the question is medical, and it has already been passed to the care team.
Decide whether the question ALSO asks something that is not about health or medicine, for example how to use the app, how the study works or how the relaxation exercises work.
Reply with JSON only: {"other_question": true} or {"other_question": false}`;

const format = (types) => ({
  type: 'object',
  properties: {
    type: { type: 'string', enum: types },
    answer: { type: 'string' },
    used_sources: { type: 'array', items: { type: 'string' } },
  },
  required: ['type', 'answer', 'used_sources'],
});

const shelf = await openShelf(JSON.parse(await readFile('data/shelf.json', 'utf8')));

/** Gọi model tự host; trả JSON đã kiểm tra, hoặc ném lỗi kèm loại kết quả. */
async function callModel(system, user, types, schema = format(types)) {
  let reply;
  try {
    const res = await fetch(`${OLLAMA_URL}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: MODEL,
        stream: false,
        format: schema,
        options: { temperature: 0 },
        ...(MODEL.startsWith('gpt-oss') ? { think: 'low' } : { think: false }),
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
      }),
      signal: AbortSignal.timeout(180_000),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
    reply = (await res.json()).message?.content ?? '';
  } catch (error) {
    throw Object.assign(new Error(`model server: ${error.message}`), { type: 'busy' });
  }
  // Bước 6: chỉ nhận JSON đúng khuôn, đúng loại được phép.
  try {
    const parsed = JSON.parse(reply.slice(reply.indexOf('{'), reply.lastIndexOf('}') + 1));
    if (types && !types.includes(parsed.type)) throw new Error(`unexpected type ${parsed.type}`);
    return parsed;
  } catch (error) {
    throw Object.assign(new Error(`invalid reply: ${error.message} ${reply.slice(0, 200)}`), { type: 'error' });
  }
}

/** Câu y tế có hỏi kèm chuyện về app, nghiên cứu hay bài tập không; lỗi thì coi như không. */
async function askedSomethingElse(question) {
  try {
    const schema = { type: 'object', properties: { other_question: { type: 'boolean' } }, required: ['other_question'] };
    return (await callModel(OTHER_QUESTION_CHECK, `Question: ${question}`, null, schema)).other_question === true;
  } catch {
    return false;
  }
}

async function ask(question) {
  const started = Date.now();
  const done = (result) => ({ sources: [], ...result, ms: Date.now() - started });
  // Bước 2: luật cứng chạy trước, câu khẩn cấp không bao giờ tới model.
  if (EMERGENCY.some((re) => re.test(question.toLowerCase()))) {
    return done({ type: 'emergency', answer: '[emergency card]' });
  }
  // Bước 3–4: lập vector câu hỏi, lấy các đoạn gần nhất.
  const q = await embed(question);
  const hits = await shelf.search(question, q, TOP_K);
  const retrieval = hits.map((h) => `${h.score.toFixed(3)} ${h.id}`);
  const relevant = hits.filter((h) => h.score >= THRESHOLD);
  try {
    if (!relevant.length) {
      const sorted = await callModel(SYSTEM_NO_PASSAGES, `Question: ${question}`, NO_ANSWER_TYPES);
      return done({ type: sorted.type, answer: sorted.answer, other: sorted.type === 'medical_redirect' && await askedSomethingElse(question), retrieval });
    }
    // Bước 5: gửi hướng dẫn + đoạn + câu hỏi cho model tự host.
    const passages = relevant.map((h) => `[${h.id}]\n${h.text}`).join('\n\n');
    const parsed = await callModel(SYSTEM, `Passages:\n\n${passages}\n\nQuestion: ${question}`, TYPES);
    // Nguồn chỉ được là những đoạn đã thật sự gửi cho model.
    const sources = (parsed.used_sources ?? []).filter((s) => relevant.some((h) => h.id === s));
    return done({ type: parsed.type, answer: parsed.answer, other: parsed.type === 'medical_redirect' && await askedSomethingElse(question), sources, retrieval });
  } catch (error) {
    return done({ type: error.type ?? 'error', answer: `[${error.message}]`, retrieval });
  }
}

const single = process.argv.slice(2).join(' ').trim();
const questions = single
  ? [{ question: single }]
  : JSON.parse(await readFile('questions.json', 'utf8'));

let passed = 0;
for (const { question, expect, other } of questions) {
  const result = await ask(question);
  // other: câu y tế có kèm ý khác hay không (app nhắc hỏi riêng phần đó).
  const ok = (!expect || expect === result.type) && (other === undefined || other === result.other);
  if (expect && ok) passed++;
  console.log(`\n${ok ? 'PASS' : 'FAIL'}  [${result.type}${expect ? ` / expected ${expect}` : ''}]  ${(result.ms / 1000).toFixed(1)}s`);
  console.log(`Q: ${question}`);
  console.log(`A: ${result.answer}`);
  if (result.type === 'medical_redirect') console.log(`Other question: ${result.other ? 'yes' : 'no'}${other === undefined ? '' : ` / expected ${other ? 'yes' : 'no'}`}`);
  if (result.sources.length) console.log(`Sources: ${result.sources.join(', ')}`);
  if (result.retrieval) console.log(`Shelf: ${result.retrieval.join(' | ')}`);
}
const scored = questions.filter((q) => q.expect).length;
if (scored) console.log(`\n${passed}/${scored} matched the expected result type (model ${MODEL}, threshold ${THRESHOLD}).`);
