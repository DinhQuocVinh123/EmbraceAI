-- Sửa claim_ai_jobs: chọn việc trong "where id in (... limit n for update skip
-- locked)" có thể bị Postgres chạy lại nhiều lần, mỗi lần bỏ qua việc vừa khoá
-- và lấy thêm việc mới, nên một lần gọi đã nhận cả 30 việc thay vì tối đa 8.
-- CTE materialized chỉ chạy đúng một lần, nên giới hạn được giữ.
create or replace function public.claim_ai_jobs(max_jobs integer)
returns table (id uuid, request jsonb)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  delete from public.ai_jobs where created_at < now() - interval '10 minutes';

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
