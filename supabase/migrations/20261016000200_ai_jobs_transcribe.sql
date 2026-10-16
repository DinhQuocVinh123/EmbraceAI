-- Hàng chờ ai_jobs giờ có hai loại việc: 'chat' (Ask EmbraceAI, gửi cho Ollama)
-- và 'transcribe' (nói thay vì gõ, gửi cho Whisper trên cùng máy GPU). Việc
-- transcribe chứa đoạn ghi âm WAV (base64, tối đa 30 giây); như việc chat, nó bị
-- xoá ngay khi xong và tự xoá sau 10 phút nếu bị bỏ dở.
alter table public.ai_jobs
  add column kind text not null default 'chat'
    check (kind in ('chat', 'transcribe'));

-- Chương trình chạy nền bản cũ (chưa biết Whisper) gọi hai hàm dưới: từ nay chúng
-- chỉ trao việc chat, để bản cũ không bao giờ đưa đoạn ghi âm cho Ollama.
create or replace function public.claim_ai_job()
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
      where q.status = 'queued' and q.kind = 'chat'
        and q.created_at > now() - interval '90 seconds'
      order by q.created_at
      limit 1
      for update skip locked
    )
    returning j.id, j.request
  )
  select claimed.id, claimed.request from claimed;
end;
$$;

create or replace function public.claim_ai_jobs(max_jobs integer)
returns table (id uuid, request jsonb)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  return query
  select claimed.id, claimed.request
  from public.claim_ai_jobs(max_jobs, array['chat']) claimed;
end;
$$;

-- Bản mới: máy GPU nói nó làm được những loại việc nào (kinds). Giữ nguyên các
-- quy tắc của bản trước: dọn việc quá 10 phút, trả lại hàng chờ việc nhận quá
-- 40 giây chưa xong, bỏ qua việc chờ quá 90 giây, nhiều nhất 8 việc một lần.
create function public.claim_ai_jobs(max_jobs integer, kinds text[])
returns table (id uuid, request jsonb, kind text)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  delete from public.ai_jobs where created_at < now() - interval '10 minutes';

  update public.ai_jobs
  set status = 'queued', claimed_at = null
  where status = 'working' and claimed_at < now() - interval '40 seconds';

  return query
  with picked as materialized (
    select q.id
    from public.ai_jobs q
    where q.status = 'queued' and q.kind = any(kinds)
      and q.created_at > now() - interval '90 seconds'
    order by q.created_at
    limit least(greatest(max_jobs, 1), 8)
    for update skip locked
  ),
  claimed as (
    update public.ai_jobs j
    set status = 'working', claimed_at = now()
    from picked
    where j.id = picked.id
    returning j.id, j.request, j.kind, j.created_at
  )
  select claimed.id, claimed.request, claimed.kind
  from claimed
  order by claimed.created_at;
end;
$$;

revoke all on function public.claim_ai_jobs(integer, text[]) from public, anon, authenticated;
grant execute on function public.claim_ai_jobs(integer, text[]) to service_role;
