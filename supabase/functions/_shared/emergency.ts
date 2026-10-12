// Câu khẩn cấp: luật cứng chạy trước mọi thứ khác. Câu khớp không bao giờ tới
// model; app hiện thẻ hướng dẫn cố định. Bản nháp: bác sĩ phải duyệt danh sách
// này (cả tiếng Anh lẫn tiếng Việt) trước khi có người tham gia thật.
//
// Chỉ dùng kiểu TypeScript xoá được, để bộ thử nghiệm Node trong tools/ai-lab
// import thẳng file này thay vì giữ một bản chép.

const englishPatterns: RegExp[] = [
  /chest pain/, /pain in my chest/, /heart attack/, /stroke/,
  /can'?t breathe/, /cannot breathe/, /short(ness)? of breath/,
  /struggling to breathe/, /faint(ed|ing)?/, /pass(ed|ing) out/, /collaps/,
  /unconscious/, /slurred speech/, /face (is )?drooping/,
  /numb(ness)? (in|on) (my )?(arm|face|leg)/,
  /suicid/, /kill myself/, /end my life/, /self[- ]harm/, /hurt myself/,
];

// So trên câu viết thường, giữ dấu: "tự tử" và "từ từ" chỉ khác nhau ở dấu.
const vietnamesePatterns: RegExp[] = [
  /đau (ở )?ngực/, /tức ngực/, /thắt ngực/, /nhồi máu cơ tim/, /đau tim/,
  /đột quỵ/, /tai biến/, /méo miệng/, /(liệt|tê|yếu) nửa người/,
  /khó thở/, /không thở được/, /thở không (nổi|được)/, /ngạt thở/,
  /ngất/, /xỉu/, /bất tỉnh/, /mất ý thức/, /ngã quỵ/,
  /tự tử/, /tự sát/, /tự vẫn/, /muốn chết/, /không muốn sống/,
  /tự (làm )?hại/, /tự làm đau/,
];

// Câu gõ không dấu: chỉ những cụm không lẫn với lời nói thường ngày. "tu tu"
// có thể là "từ từ", "xiu" có thể là "xíu", nên không có ở đây.
const unaccentedPatterns: RegExp[] = [
  /dau nguc/, /tuc nguc/, /nhoi mau co tim/, /dot quy/, /kho tho/,
  /khong tho duoc/, /ngat xiu/, /bat tinh/, /tu sat/, /muon chet/,
  /khong muon song/,
];

/** Bỏ dấu tiếng Việt: "đau ngực" thành "dau nguc". */
export function foldVietnamese(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D');
}

/** Câu hỏi có dấu hiệu khẩn cấp (tiếng Anh, tiếng Việt có hoặc không dấu). */
export function isEmergency(question: string): boolean {
  const text = question.normalize('NFC').toLowerCase();
  return englishPatterns.some((pattern) => pattern.test(text)) ||
    vietnamesePatterns.some((pattern) => pattern.test(text)) ||
    unaccentedPatterns.some((pattern) => pattern.test(foldVietnamese(text)));
}
