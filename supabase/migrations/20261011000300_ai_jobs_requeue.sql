-- Một việc đã được nhận nhưng câu trả lời của ai-worker không tới được máy GPU
-- (kết nối đứt giữa chừng) sẽ kẹt ở "working" mãi. Việc nhận quá 40 giây mà
-- chưa xong được trả lại hàng chờ: bình thường một câu xong trong vài giây,
-- nên câu đó vẫn còn thời gian được trả lời trước khi người hỏi thôi chờ.
create or replace function public.claim_ai_jobs(max_jobs integer)
returns table (id uuid, request jsonb)
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
    where q.status = 'queued' and q.created_at > now() - interval '90 seconds'
    order by q.created_at
    limit least(greatest(max_jobs, 1), 8)
    for update skip locked
  ),
  claimed as (
    update public.ai_jobs j
    set status = 'working', claimed_at = now()
    from picked
    where j.id = picked.id
    returning j.id, j.request, j.created_at
  )
  select claimed.id, claimed.request from claimed order by claimed.created_at;
end;
$$;
