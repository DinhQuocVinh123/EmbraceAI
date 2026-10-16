// Bốn lĩnh vực nội dung của Ask EmbraceAI (biên bản họp, mục 3) và bộ từ khoá
// chọn lĩnh vực cho mỗi câu hỏi. Mỗi lần model chỉ đọc tài liệu của một lĩnh
// vực, nên kệ tổng cộng dài được gấp nhiều lần mà prompt vẫn vừa khung 4.096
// token (xem maxShelfCharacters trong ask_prompts.ts).
//
// Bộ từ khoá là BẢN NHÁP để nhóm nghiên cứu sửa: thêm, bớt từ ở đây rồi chạy
// tools/ai-lab/ask.mjs để xem câu hỏi mẫu có vào đúng lĩnh vực không.
//
// Chỉ dùng kiểu TypeScript xoá được, để bộ thử Node import thẳng file này.

import { foldVietnamese } from './emergency.ts';

export type AskDomain = 'app' | 'health' | 'wellbeing' | 'lifestyle';

/**
 * Thứ tự cũng là thứ tự ưu tiên khi hai lĩnh vực bằng điểm. Ba lĩnh vực sức
 * khoẻ đứng trước app; tâm lý đứng đầu vì lời dặn của nó gồm cả lời dặn sức
 * khoẻ (ask_prompts.ts), như "lo lắng về tim" vẫn được nhắc chuyện thuốc men.
 */
export const askDomains: AskDomain[] = ['wellbeing', 'health', 'lifestyle', 'app'];

/** Lĩnh vực sức khoẻ: câu trả lời luôn kèm dòng nhắc "không phải chẩn đoán". */
export function isHealthDomain(domain: AskDomain): boolean {
  return domain !== 'app';
}

interface Keywords {
  /** Khớp đầu từ, không phân biệt hoa thường: "swell" khớp "swelling". */
  en: string[];
  /** Khớp nguyên cụm có dấu; cụm từ hai chữ trở lên cũng khớp khi gõ không dấu. */
  vi: string[];
}

export const domainKeywords: Record<AskDomain, Keywords> = {
  health: {
    en: [
      'symptom', 'breath', 'breathless', 'out of breath', 'short of breath', 'chest', 'heart', 'heartbeat', 'palpitation',
      'racing', 'flutter', 'skipping', 'irregular', 'dizzy', 'dizziness', 'light-headed',
      'lightheaded', 'faint', 'swell', 'swollen', 'ankle', 'fluid', 'tired',
      'fatigue', 'exhausted', 'energy', 'cough', 'pain', 'ache', 'numb', 'blood pressure',
      'pulse', 'heart rate', 'medicine', 'medication', 'tablet', 'pill', 'side effect',
      'dose', 'missed dose', 'forgot', 'forget', 'pill organiser', 'pill organizer',
      'pharmacist', 'doctor', 'nurse', 'appointment', 'hospital', 'emergency', 'stroke',
      'test result', 'blood test', 'reading', 'diagnosis',
    ],
    vi: [
      'triệu chứng', 'khó thở', 'hụt hơi', 'thở dốc', 'ngực', 'tim', 'nhịp tim',
      'tim đập nhanh', 'hồi hộp', 'đánh trống ngực', 'chóng mặt', 'choáng', 'xây xẩm',
      'phù', 'sưng', 'mắt cá', 'mệt', 'mệt mỏi', 'kiệt sức', 'năng lượng', 'ho', 'đau',
      'tê', 'huyết áp', 'mạch', 'thuốc', 'uống thuốc', 'quên uống', 'tác dụng phụ', 'liều',
      'dược sĩ', 'bác sĩ', 'y tá', 'xét nghiệm', 'kết quả', 'chẩn đoán',
      'buổi khám', 'bệnh viện', 'cấp cứu', 'đột quỵ',
    ],
  },
  wellbeing: {
    en: [
      'stress', 'anxious', 'anxiety', 'worry', 'worried', 'nervous', 'fear', 'afraid',
      'scared', 'panic', 'sad', 'low mood', 'down', 'depressed', 'depression',
      'hopeless', 'lonely', 'alone', 'isolated', 'sleep', 'insomnia', 'angry', 'anger',
      'frustrated', 'overwhelmed', 'mood', 'feeling', 'emotion', 'cope', 'coping', 'calm',
    ],
    vi: [
      'căng thẳng', 'lo lắng', 'lo âu', 'lo', 'sợ', 'hoảng', 'buồn', 'chán', 'trầm cảm',
      'tuyệt vọng', 'cô đơn', 'một mình', 'mất ngủ', 'khó ngủ', 'ngủ', 'tức giận', 'bực',
      'áp lực', 'tâm trạng', 'cảm xúc', 'cảm giác', 'bình tĩnh', 'bình tâm',
    ],
  },
  lifestyle: {
    en: [
      'diet', 'eat', 'food', 'meal', 'salt', 'sodium', 'sugar', 'fat', 'fruit',
      'vegetable', 'drink', 'water', 'fluid', 'alcohol', 'wine', 'beer', 'smoke', 'smoking',
      'cigarette', 'physical activity', 'exercise', 'walk', 'gym', 'swim',
      'weight', 'healthy', 'lifestyle', 'cholesterol', 'rehab', 'rehabilitation', 'rest',
    ],
    vi: [
      'ăn', 'ăn uống', 'chế độ ăn', 'thức ăn', 'món', 'muối', 'mặn', 'đồ ngọt', 'ngọt', 'mỡ',
      'trái cây', 'hoa quả', 'rau', 'uống', 'nước', 'rượu', 'bia', 'hút thuốc', 'thuốc lá',
      'vận động', 'tập thể dục', 'thể dục', 'đi bộ', 'bơi', 'cân nặng', 'lành mạnh',
      'lối sống', 'cholesterol', 'phục hồi chức năng', 'nghỉ ngơi',
    ],
  },
  app: {
    en: [
      'app', 'session', 'practice', 'practise', 'journal', 'insight', 'sign in', 'log in',
      'login', 'access key', 'participant id', 'link', 'qr', 'caption', 'subtitle', 'voice',
      'narrator', 'sound', 'video', 'setting', 'text size', 'bigger', 'screen', 'button',
      'tab', 'questionnaire', 'consent', 'save', 'skip', 'grounding', 'breathing',
      'follow the breath', 'study', 'research', 'privacy', 'data', 'password', 'install',
    ],
    vi: [
      'ứng dụng', 'app', 'buổi tập', 'bài tập', 'nhật ký', 'thống kê', 'đăng nhập',
      'khoá truy cập', 'khóa truy cập', 'mã người tham gia', 'đường link', 'phụ đề',
      'giọng', 'âm thanh', 'âm nền', 'video', 'cài đặt', 'cỡ chữ', 'màn hình', 'nút',
      'bảng hỏi', 'bảng câu hỏi', 'đồng ý', 'lưu', 'tiếp đất', 'hơi thở', 'nghiên cứu',
      'dữ liệu', 'quyền riêng tư', 'mật khẩu',
    ],
  },
};

const escape = (text: string) => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Từ tiếng Việt đứng riêng: không phải một phần của từ khác ("ho" không khớp
// "học", "tim" không khớp "tìm" vì so trên chữ có dấu).
const viBoundary = (word: string) =>
  new RegExp(`(^|[^\\p{L}])${escape(word)}(?=$|[^\\p{L}])`, 'u');

interface Matcher {
  /** Khớp trên câu đã viết thường. */
  exact: RegExp;
  /** Khớp trên câu đã bỏ dấu, chỉ với cụm tiếng Việt từ hai chữ trở lên. */
  folded?: RegExp;
}

const compiled = Object.fromEntries(
  askDomains.map((domain) => {
    const { en, vi } = domainKeywords[domain];
    const matchers: Matcher[] = [
      // Nguyên từ, cho phép đuôi số nhiều hay thì: "swell" khớp "swelling",
      // nhưng "fat" không khớp "fatigue".
      ...en.map((word) => ({
        exact: new RegExp(`\\b${escape(word.toLowerCase())}(s|es|d|ed|ing|ness)?\\b`),
      })),
      ...vi.map((word) => {
        const lower = word.normalize('NFC').toLowerCase();
        // Gõ không dấu: một chữ không dấu dễ trùng ("tim" là "tim" hay "tìm"?).
        return {
          exact: viBoundary(lower),
          folded: lower.includes(' ') ? viBoundary(foldVietnamese(lower)) : undefined,
        };
      }),
    ];
    return [domain, matchers];
  }),
) as Record<AskDomain, Matcher[]>;

/** Số từ khoá của mỗi lĩnh vực có trong câu hỏi. */
export function domainScores(question: string): Record<AskDomain, number> {
  const text = question.normalize('NFC').toLowerCase();
  const folded = foldVietnamese(text);
  const scores = {} as Record<AskDomain, number>;
  for (const domain of askDomains) {
    scores[domain] = compiled[domain].filter(
      ({ exact, folded: plain }) => exact.test(text) || (plain?.test(folded) ?? false),
    ).length;
  }
  return scores;
}

/**
 * Các lĩnh vực hợp với câu hỏi nhất, theo thứ tự ưu tiên của askDomains (sức
 * khoẻ trước). Nhiều lĩnh vực cùng điểm cao nhất thì trả về cả, để gửi kèm nếu
 * còn vừa prompt. Không khớp từ nào thì là câu về app, vì phần lớn câu hỏi
 * trong nghiên cứu là về cách dùng app.
 */
export function rankDomains(question: string): AskDomain[] {
  const scores = domainScores(question);
  const best = Math.max(...askDomains.map((domain) => scores[domain]));
  if (best === 0) return ['app'];
  return askDomains.filter((domain) => scores[domain] === best);
}

/** Lĩnh vực chính của câu hỏi: quyết định lời dặn và dòng nhắc trong app. */
export function routeQuestion(question: string): AskDomain {
  return rankDomains(question)[0];
}

/**
 * Các đoạn gửi cho model: mọi đoạn của lĩnh vực chính, rồi thêm lĩnh vực cùng
 * điểm tiếp theo nếu tổng vẫn không quá [maxCharacters].
 */
export function shelfForDomains<T extends { domain: AskDomain }>(
  passages: T[],
  domains: AskDomain[],
  size: (passages: T[]) => number,
  maxCharacters: number,
): T[] {
  let chosen = passages.filter((passage) => passage.domain === domains[0]);
  for (const domain of domains.slice(1)) {
    const wider = [...chosen, ...passages.filter((passage) => passage.domain === domain)];
    if (size(wider) <= maxCharacters) chosen = wider;
  }
  return chosen;
}
