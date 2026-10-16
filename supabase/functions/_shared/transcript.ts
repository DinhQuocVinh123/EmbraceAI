// Dọn chữ Whisper trả về trước khi đưa vào ô nhập của người dùng.
//
// Whisper được huấn luyện nhiều trên video mạng, nên với đoạn gần như im lặng nó
// hay "nghe" ra câu chào cuối video ("Hãy subscribe cho kênh...", "Thanks for
// watching"). App đã bỏ đoạn quá nhỏ tiếng; đây là lớp chặn thứ hai.

const hallucinations = [
  /subscribe/i,
  /đăng ký kênh/i,
  /ghiền mì gõ/i,
  /cảm ơn các bạn đã (theo dõi|xem)/i,
  /thanks? (you )?for watching/i,
  /^\[?(music|âm nhạc|blank_audio|silence)\]?$/i,
];

export function cleanTranscript(raw: string): string {
  const lines = raw
    .split('\n')
    .map((line) => line.replace(/\[[^\]]*\]|\([^)]*\)/g, '').replace(/\s+/g, ' ').trim())
    .filter((line) => line && !hallucinations.some((pattern) => pattern.test(line)));
  return lines.join(' ').trim();
}
