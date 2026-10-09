-- Kệ tài liệu cho trợ lý Ask EmbraceAI (PoC). Chỉ Edge Function đọc và ghi
-- kệ bằng service role; người tham gia không đọc trực tiếp bảng nào ở đây.
create extension if not exists vector with schema extensions;

-- Bật trợ lý cho từng tài khoản; mặc định tắt cho mọi người tham gia.
alter table public.participants
  add column ai_enabled boolean not null default false;

create table public.ai_documents (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{0,79}$'),
  title text not null check (char_length(title) between 1 and 200),
  version text not null check (char_length(version) between 1 and 40),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Mỗi đoạn giữ cả nguyên văn (model đọc) lẫn vector gte-small 384 chiều
-- (dùng để tìm). Vector đã chuẩn hoá nên tích vô hướng là cosine similarity.
create table public.ai_chunks (
  id bigint generated always as identity primary key,
  document_id uuid not null
    references public.ai_documents(id) on delete cascade,
  chunk_key text not null check (chunk_key ~ '^[a-z0-9][a-z0-9-]{0,119}$'),
  heading text not null check (char_length(heading) between 1 and 200),
  content text not null check (char_length(content) between 1 and 4000),
  embedding extensions.vector(384) not null,
  created_at timestamptz not null default now(),
  unique (document_id, chunk_key)
);

create index ai_chunks_embedding_idx
  on public.ai_chunks using hnsw (embedding extensions.vector_ip_ops);

create table public.ai_interactions (
  id bigint generated always as identity primary key,
  participant_code text
    references public.participants(participant_code) on delete cascade,
  question text not null check (char_length(question) <= 1000),
  result_type text not null check (result_type in (
    'answer', 'medical_redirect', 'out_of_scope', 'not_found',
    'emergency', 'busy', 'error'
  )),
  answer text check (char_length(answer) <= 4000),
  sources text[] not null default '{}',
  top_similarity real,
  model text,
  latency_ms integer,
  created_at timestamptz not null default now()
);

create index ai_interactions_created_idx
  on public.ai_interactions(created_at desc);

alter table public.ai_documents enable row level security;
alter table public.ai_chunks enable row level security;
alter table public.ai_interactions enable row level security;

create policy "staff can read ai interactions"
on public.ai_interactions for select
to authenticated
using (public.is_active_staff());

revoke all on public.ai_documents, public.ai_chunks, public.ai_interactions
  from anon, authenticated;
grant select on public.ai_interactions to authenticated;

-- Các đoạn gần câu hỏi nhất, kèm độ gần; ngưỡng do Edge Function quyết định.
create function public.match_ai_chunks(
  query_embedding extensions.vector(384),
  match_count integer default 4
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
  select
    d.slug,
    d.title,
    c.chunk_key,
    c.heading,
    c.content,
    (-(c.embedding <#> query_embedding))::real
  from public.ai_chunks c
  join public.ai_documents d on d.id = c.document_id
  order by c.embedding <#> query_embedding
  limit least(greatest(match_count, 1), 10);
$$;

revoke all on function public.match_ai_chunks(extensions.vector, integer)
  from public, anon, authenticated;
