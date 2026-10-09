-- Tìm kết hợp cho Ask EmbraceAI: theo nghĩa (vector gte-small) và theo đúng
-- từ (full-text tiếng Anh), gộp hai bảng xếp hạng bằng Reciprocal Rank Fusion.
-- Chỉ tìm theo nghĩa thì gte-small chấm các đoạn quá sát nhau: "How do I turn
-- on captions?" không kéo được đoạn có "Show captions" vào top 4.
alter table public.ai_chunks
  add column fts tsvector
  generated always as (to_tsvector('english', heading || ' ' || content)) stored;

create index ai_chunks_fts_idx on public.ai_chunks using gin (fts);

-- similarity vẫn là độ gần theo nghĩa, để ghi nhật ký và làm ngưỡng sàn.
create function public.match_ai_chunks_hybrid(
  query_text text,
  query_embedding extensions.vector(384),
  match_count integer default 6
)
returns table (
  document_slug text,
  document_title text,
  chunk_key text,
  heading text,
  content text,
  similarity real
)
language sql
stable
set search_path = public, extensions
as $$
  with question as (
    -- Các từ khoá (đã đưa về gốc) nối bằng OR: câu hỏi tự nhiên hiếm khi
    -- chứa đủ mọi từ của một đoạn.
    select string_agg(quote_literal(lexeme), ' | ')::tsquery as keywords
    from unnest(to_tsvector('english', query_text))
  ),
  by_meaning as (
    select c.id, row_number() over (order by c.embedding <#> query_embedding) as rank
    from public.ai_chunks c
    order by c.embedding <#> query_embedding
    limit 20
  ),
  by_words as (
    select c.id, row_number() over (order by ts_rank_cd(c.fts, q.keywords) desc) as rank
    from public.ai_chunks c, question q
    where c.fts @@ q.keywords
    order by ts_rank_cd(c.fts, q.keywords) desc
    limit 20
  )
  select
    d.slug,
    d.title,
    c.chunk_key,
    c.heading,
    c.content,
    (-(c.embedding <#> query_embedding))::real
  from by_meaning m
  full outer join by_words w on w.id = m.id
  join public.ai_chunks c on c.id = coalesce(m.id, w.id)
  join public.ai_documents d on d.id = c.document_id
  order by
    coalesce(1.0 / (50 + m.rank), 0) + coalesce(1.0 / (50 + w.rank), 0) desc
  limit least(greatest(match_count, 1), 10);
$$;

revoke all on function public.match_ai_chunks_hybrid(text, extensions.vector, integer)
  from public, anon, authenticated;
