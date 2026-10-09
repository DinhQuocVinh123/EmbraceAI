// Kệ tài liệu trong một Postgres chạy ngay trên máy (PGlite + pgvector), nạp
// đúng file migration tìm kết hợp của Supabase. Nhờ vậy bộ thử nghiệm xếp hạng
// các đoạn y hệt match_ai_chunks_hybrid trên database thật.
import { readFile } from 'node:fs/promises';

import { PGlite } from '@electric-sql/pglite';
import { vector } from '@electric-sql/pglite/vector';

const HYBRID_MIGRATION = '../../supabase/migrations/20261009000100_ai_hybrid_search.sql';

export async function openShelf(shelf) {
  const db = new PGlite({ extensions: { vector } });
  // Chỉ dựng những gì migration cần: hai bảng kệ (cùng cột như trên Supabase)
  // và các role mà Supabase có sẵn.
  await db.exec(`
    create role anon; create role authenticated;
    create schema extensions;
    create extension vector with schema extensions;
    create table public.ai_documents (
      id uuid primary key default gen_random_uuid(),
      slug text not null unique,
      title text not null
    );
    create table public.ai_chunks (
      id bigint generated always as identity primary key,
      document_id uuid not null references public.ai_documents(id),
      chunk_key text not null,
      heading text not null,
      content text not null,
      embedding extensions.vector(384) not null
    );
  `);
  await db.exec(await readFile(HYBRID_MIGRATION, 'utf8'));

  for (const source of new Set(shelf.map((c) => c.source))) {
    await db.query('insert into ai_documents (slug, title) values ($1, $1)', [source]);
  }
  for (const chunk of shelf) {
    await db.query(
      `insert into ai_chunks (document_id, chunk_key, heading, content, embedding)
       select id, $2, $3, $4, $5 from ai_documents where slug = $1`,
      [chunk.source, chunk.id.split('#')[1], chunk.heading, chunk.text, JSON.stringify(chunk.embedding)],
    );
  }

  return {
    async search(question, embedding, count) {
      const { rows } = await db.query(
        'select * from match_ai_chunks_hybrid($1, $2, $3)',
        [question, JSON.stringify(embedding), count],
      );
      return rows.map((r) => ({
        id: `${r.document_slug}#${r.chunk_key}`,
        text: r.content,
        score: r.similarity,
      }));
    },
  };
}
