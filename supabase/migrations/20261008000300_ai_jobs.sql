-- Hàng chờ câu hỏi cho model tự host. Máy GPU không nhận kết nối từ ngoài:
-- ask-embrace đặt việc vào đây, chương trình trên máy GPU tự gọi ai-worker để
-- lấy việc và gửi kết quả về. Mỗi việc chứa câu hỏi kèm các đoạn tài liệu,
-- nên ask-embrace xoá nó ngay khi xong; việc bị bỏ dở tự xoá sau 10 phút.
create table public.ai_jobs (
  id uuid primary key default gen_random_uuid(),
  request jsonb not null,
  status text not null default 'queued'
    check (status in ('queued', 'working', 'done', 'failed')),
  result text check (char_length(result) <= 20000),
  error text check (char_length(error) <= 1000),
  created_at timestamptz not null default now(),
  claimed_at timestamptz,
  finished_at timestamptz
);

create index ai_jobs_queue_idx on public.ai_jobs(created_at)
  where status = 'queued';

-- Lần cuối máy GPU hỏi việc; ask-embrace dựa vào đây để báo bận ngay khi máy
-- đang tắt, thay vì bắt người dùng chờ hết giờ.
create table public.ai_worker_status (
  id smallint primary key default 1 check (id = 1),
  last_seen timestamptz not null
);

alter table public.ai_jobs enable row level security;
alter table public.ai_worker_status enable row level security;

revoke all on public.ai_jobs, public.ai_worker_status from anon, authenticated;

-- Nhận việc cũ nhất đang chờ (bỏ qua việc người hỏi đã thôi chờ), đồng thời
-- dọn các việc bị bỏ dở.
create function public.claim_ai_job()
returns table (id uuid, request jsonb)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  delete from public.ai_jobs where created_at < now() - interval '10 minutes';

  return query
  with claimed as (
    update public.ai_jobs j
    set status = 'working', claimed_at = now()
    where j.id = (
      select q.id
      from public.ai_jobs q
      where q.status = 'queued' and q.created_at > now() - interval '90 seconds'
      order by q.created_at
      limit 1
      for update skip locked
    )
    returning j.id, j.request
  )
  select claimed.id, claimed.request from claimed;
end;
$$;

revoke all on function public.claim_ai_job() from public, anon, authenticated;
grant execute on function public.claim_ai_job() to service_role;
