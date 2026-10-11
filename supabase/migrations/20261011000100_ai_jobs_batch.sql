-- Máy GPU trả lời nhiều câu cùng lúc (Ollama OLLAMA_NUM_PARALLEL), nên nhận
-- tối đa max_jobs việc trong một lần, cũ nhất trước. claim_ai_job (một việc)
-- vẫn giữ cho chương trình chạy nền bản cũ trong lúc chuyển đổi.
create function public.claim_ai_jobs(max_jobs integer)
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
    where j.id in (
      select q.id
      from public.ai_jobs q
      where q.status = 'queued' and q.created_at > now() - interval '90 seconds'
      order by q.created_at
      limit least(greatest(max_jobs, 1), 8)
      for update skip locked
    )
    returning j.id, j.request, j.created_at
  )
  select claimed.id, claimed.request from claimed order by claimed.created_at;
end;
$$;

revoke all on function public.claim_ai_jobs(integer) from public, anon, authenticated;
grant execute on function public.claim_ai_jobs(integer) to service_role;
