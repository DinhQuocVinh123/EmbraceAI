// Kệ tài liệu dùng chung cho ingest và ask: cắt đoạn, lập vector, tìm gần.
import { pipeline } from '@huggingface/transformers';

// Đúng model embedding mà Supabase Edge Functions dùng (384 chiều), nên
// kết quả tìm ở đây giữ nguyên khi chuyển kệ lên Supabase.
const MODEL = 'Supabase/gte-small';
const MAX_WORDS = 160;

let extractor;

export async function embed(text) {
  extractor ??= await pipeline('feature-extraction', MODEL);
  const output = await extractor(text, { pooling: 'mean', normalize: true });
  return Array.from(output.data);
}

// Vector đã chuẩn hoá nên tích vô hướng chính là cosine similarity.
export function similarity(a, b) {
  let sum = 0;
  for (let i = 0; i < a.length; i++) sum += a[i] * b[i];
  return sum;
}

const words = (text) => text.split(/\s+/).filter(Boolean).length;

/**
 * Cắt Markdown theo mục `##`, rồi gom đoạn văn và từng dòng danh sách thành
 * các đoạn không quá MAX_WORDS từ. Mỗi đoạn mang tiêu đề mục ở đầu để vẫn
 * hiểu được khi đứng một mình.
 */
export function chunkMarkdown(markdown, source) {
  const chunks = [];
  for (const section of markdown.split(/^## /m).filter((s) => s.trim())) {
    const [headingLine, ...rest] = section.split('\n');
    const heading = headingLine.trim();
    const units = rest
      .join('\n')
      .split(/\n\s*\n|\n(?=- |\d+\. )/)
      .map((u) => u.trim())
      .filter(Boolean);
    let current = [];
    const flush = () => {
      if (!current.length) return;
      const part = chunks.filter((c) => c.heading === heading).length + 1;
      chunks.push({
        id: `${source}#${slug(heading)}-${part}`,
        source,
        heading,
        text: `${heading}\n\n${current.join('\n')}`,
      });
      current = [];
    };
    for (const unit of units) {
      if (current.length && words([...current, unit].join(' ')) > MAX_WORDS) flush();
      current.push(unit);
    }
    flush();
  }
  return chunks;
}

const slug = (text) =>
  text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
