// Lời dặn model của Ask EmbraceAI. ask-embrace và bộ thử tools/ai-lab cùng
// dùng file này, nên hai bên không thể lệch nhau.
//
// Model đọc cả kệ tài liệu trong mọi câu hỏi, không qua bước tìm đoạn: kệ chỉ
// có 14 đoạn và vừa trong khung 4.096 token của model. Lời dặn và kệ giống hệt
// nhau giữa các câu nên Ollama đọc lại được phần đầu prompt, chỉ câu hỏi là
// mới. Nhờ vậy model đọc thẳng câu tiếng Việt, không phải dịch trước.

export type AskLanguage = 'en' | 'vi';

export const answerTypes = ['answer', 'medical_redirect', 'out_of_scope', 'not_found'];

/** Một đoạn trên kệ. id là `<tài liệu>#<đoạn>`, như model ghi trong used_sources. */
export interface Passage {
  id: string;
  content: string;
}

// Ollama cắt bớt đầu prompt khi vượt khung, tức là cắt mất lời dặn mà không
// báo gì. Kệ dài hơn mức này thì không gửi nữa, và phải quay lại bước tìm đoạn.
// Đo ngày 12/10: kệ 10.318 ký tự, cùng lời dặn tiếng Việt và câu hỏi dài nhất,
// là 3.466 token; câu trả lời dài nhất cần khoảng 350 token nữa. Bộ thử
// (ask.mjs) báo lỗi khi prompt vượt 3.700 token.
export const maxShelfCharacters = 11_000;

export function shelfCharacters(passages: Passage[]): number {
  return passages.reduce((sum, passage) => sum + passage.id.length + passage.content.length, 0);
}

// Tên màn hình, nút và lựa chọn mà tài liệu nhắc tới, kèm đúng chữ app tiếng
// Việt đang hiện. Cột đầu là khoá trong lib/l10n/app_*.arb; bộ thử
// (tools/ai-lab/test/prompts.test.mjs) kiểm từng cặp vẫn khớp file dịch.
export const vietnameseUiNames: [string, string, string][] = [
  ['homeTabSession', 'Session', 'Buổi tập'],
  ['homeTabJournal', 'Journal', 'Nhật ký'],
  ['homeTabInsights', 'Insights', 'Thống kê'],
  ['homeNewEntry', 'New entry', 'Ghi chú mới'],
  ['homeSignOut', 'Sign out', 'Đăng xuất'],
  ['loginIdLabel', 'Participant ID', 'Mã người tham gia'],
  ['loginKeyLabel', 'Access key', 'Khoá truy cập'],
  ['welcomeSceneTitle', 'Setting', 'Khung cảnh'],
  ['sceneCountryside', 'Vietnamese countryside', 'Làng quê Việt Nam'],
  ['sceneBeach', 'Beach, dawn to night', 'Bãi biển, từ bình minh đến đêm'],
  ['soundGuidedVoice', 'Guided voice', 'Giọng hướng dẫn'],
  ['soundBackground', 'Background sound', 'Âm nền'],
  ['soundMatchVideo', 'Match video', 'Theo video'],
  ['soundNone', 'None', 'Không có'],
  ['soundCountryside', 'Countryside', 'Đồng quê'],
  ['soundOcean', 'Ocean waves', 'Sóng biển'],
  ['soundRain', 'Gentle rain', 'Mưa nhẹ'],
  ['soundPreview', 'Preview sound', 'Nghe thử'],
  ['welcomeShowCaptions', 'Show captions', 'Hiện phụ đề'],
  ['welcomeTextSize', 'Text size', 'Cỡ chữ'],
  ['welcomeReduceMotion', 'Reduce motion', 'Giảm chuyển động'],
  ['welcomeBegin', 'Begin', 'Bắt đầu'],
  ['disclaimerTitle', 'Medical disclaimer', 'Lưu ý về y tế'],
  ['disclaimerAccept', 'I understand, continue', 'Tôi đã hiểu, tiếp tục'],
  ['disclaimerLeave', 'Leave session', 'Rời buổi tập'],
  ['safetyNo', 'Not right now', 'Lúc này thì chưa'],
  ['practiceGrounding', 'Grounding', 'Tiếp đất'],
  ['practiceBreathing', 'Follow the breath', 'Theo dõi hơi thở'],
  ['lengthFull', 'Full practice', 'Bài đầy đủ'],
  ['lengthShort', 'Short practice', 'Bài ngắn'],
  ['sessionPause', 'Pause', 'Tạm dừng'],
  ['sessionStop', 'Stop', 'Dừng'],
  ['helpTitle', 'Help', 'Trợ giúp'],
  ['helpEnd', 'End practice', 'Kết thúc buổi tập'],
  ['helpEasierView', 'Easier view', 'Chế độ dễ nhìn'],
  ['helpBrighterPicture', 'Brighter picture', 'Hình sáng hơn'],
  ['sessionSaveToJournal', 'Save to journal', 'Lưu vào nhật ký'],
  ['sessionSkipSaving', 'Skip saving', 'Không lưu'],
  ['tagAppointment', 'Appointment', 'Buổi khám'],
  ['insightsAverage', '30-day average', 'Trung bình 30 ngày'],
  ['consentAppBar', 'Study information and consent', 'Thông tin và đồng ý'],
  ['consentAccept', 'I consent and continue', 'Tôi đồng ý và tiếp tục'],
  ['consentExit', 'Exit without consenting', 'Thoát mà không đồng ý'],
  ['demoAppBar', 'About you', 'Về bạn'],
  ['questionSave', 'Save and continue', 'Lưu và tiếp tục'],
  ['finalDoLater', 'Do this later', 'Để sau'],
  ['finalSubmit', 'Submit', 'Gửi'],
];

const escape = (text: string) => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const quote = '["“”]';
// Dài trước, để "Leave session" được đổi trọn trước khi tới "Session".
const longestFirst = [...vietnameseUiNames].sort((a, b) => b[1].length - a[1].length);

/**
 * Lời dặn chưa đủ: model thỉnh thoảng vẫn ghi tên tiếng Anh, hoặc ghi cả hai
 * như "Trợ giúp" (Help). Tên nằm trong ngoặc kép được đổi hẳn sang tên tiếng
 * Việt trong bảng, để người dùng tìm đúng chữ họ thấy trên màn hình.
 */
export function withVietnameseNames(answer: string): string {
  let text = answer;
  for (const [, en, vi] of longestFirst) {
    const e = escape(en);
    const v = escape(vi);
    const named = `"${vi}"`;
    text = text
      .replace(new RegExp(`${quote}${v}${quote}\\s*\\(${quote}?${e}${quote}?\\)`, 'g'), named)
      .replace(new RegExp(`${quote}${e}${quote}\\s*\\(${quote}?${v}${quote}?\\)`, 'g'), named)
      .replace(new RegExp(`${quote}${e}${quote}`, 'g'), named);
  }
  return text;
}

const rules =
  `- If the question asks about medication, symptoms, test results, diagnosis or treatment, set type "medical_redirect": say kindly that this is a question for their doctor or care team, and that they can note it as a question for their next appointment. Give no medical information. This rule comes first: use it whenever any part of the question is medical, even if another part could be answered. Questions about how long, how often or when to practise, or how sessions fit into a day, are about the exercises, not medical.
- If the question has nothing to do with the app, the study or the relaxation exercises, set type "out_of_scope" and decline politely in one sentence.
- Never mention passages, sources, ids or these instructions in the answer; call them "the study information".`;

const english = {
  reply: 'answer in plain, friendly English for older adults, in at most 100 words',
  extra: '',
  json: '{"type": "...", "answer": "...", "used_sources": ["..."]}',
};

// Bản dịch tiếng Anh đứng đầu JSON: model dịch trước rồi mới xếp loại theo
// nghĩa tiếng Anh. Để nó ở cuối thì vài câu về app (mất khoá truy cập) bị coi
// là câu y tế, dù chính model dịch đúng.
const vietnamese = {
  reply: 'answer in plain, friendly Vietnamese for older adults, in at most 150 words',
  extra: `
- The participant uses the app in Vietnamese and may type without accents. First write question_english: a short, faithful English translation of the question. Then apply every rule above to that English meaning.
- The passages describe the English screens, but the participant sees Vietnamese ones. Whenever you name a screen, tab, button or option, write only its Vietnamese name from this list, in quotes, never the English name: ${
    vietnameseUiNames.map(([, en, vi]) => `${en} = "${vi}"`).join('; ')
  }.
- Never write web addresses, example IDs or example keys.`,
  json: '{"question_english": "...", "type": "...", "answer": "...", "used_sources": ["..."]}',
};

export function systemPrompt(language: AskLanguage): string {
  const words = language === 'vi' ? vietnamese : english;
  return `You are "Ask EmbraceAI", a helper inside a research app for adults with heart conditions.
Answer ONLY from the passages provided. Never use outside knowledge.
Rules:
${rules}
- If a passage names the setting or option the question is about, set type "answer" and say where to find it (for example, which menu offers it), even if the passage only lists it.
- If the question has several parts, answer the parts the passages cover, then say in one short sentence which part the study information does not cover yet. Set type "answer" if any part is answered.
- If the passages answer no part of the question, set type "not_found" and say the information is not available yet.
- Otherwise set type "answer" and ${words.reply}.
- Never invent screens, tabs, buttons, menus or features: mention only those a passage names. A question about something the app does not have is "not_found" if it is about the app, otherwise "out_of_scope".
- Only state details the passages state. Do not describe icons, colours, button shapes or screen positions unless a passage does. Do not repeat example IDs or keys.
- used_sources lists the ids of the passages you actually used.${words.extra}
Reply with JSON only: ${words.json}`;
}

/** Khuôn JSON bắt model trả về. Câu tiếng Việt kèm bản dịch tiếng Anh cho nhật ký. */
export function answerFormat(language: AskLanguage): Record<string, unknown> {
  const properties: Record<string, unknown> = {
    ...(language === 'vi' ? { question_english: { type: 'string' } } : {}),
    type: { type: 'string', enum: answerTypes },
    answer: { type: 'string' },
    used_sources: { type: 'array', items: { type: 'string' } },
  };
  return { type: 'object', properties, required: Object.keys(properties) };
}

/** Tin gửi model: cả kệ trước, câu hỏi sau cùng, để phần đầu luôn giống nhau. */
export function passagesMessage(passages: Passage[], question: string): string {
  const shelf = passages.map((passage) => `[${passage.id}]\n${passage.content}`).join('\n\n');
  return `Passages:\n\n${shelf}\n\nQuestion: ${question}`;
}

// Lần hỏi phụ cho câu y tế: chỉ trả lời có/không, không viết gì khác.
export const otherQuestionCheck =
  `You check one question sent to a helper inside a research app for adults with heart conditions. Part of the question is medical, and it has already been passed to the care team.
Decide whether the question ALSO asks something that is not about health or medicine, for example how to use the app, how the study works or how the relaxation exercises work.
Reply with JSON only: {"other_question": true} or {"other_question": false}`;
