alter table public.sessions
  add column client_entry_id uuid;

update public.sessions
set client_entry_id = extensions.gen_random_uuid()
where client_entry_id is null;

alter table public.sessions
  alter column client_entry_id set not null;

alter table public.sessions
  drop constraint sessions_participant_code_local_entry_id_key;

alter table public.sessions
  add constraint sessions_participant_client_entry_key
  unique (participant_code, client_entry_id);

drop function public.record_session(
  bigint, timestamptz, timestamptz, smallint, boolean
);

create function public.record_session(
  p_local_entry_id bigint,
  p_client_entry_id uuid,
  p_occurred_at timestamptz,
  p_client_updated_at timestamptz,
  p_mood_after smallint,
  p_reflection_provided boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  select participant_code into v_code
  from public.participants
  where auth_user_id = auth.uid()
    and status = 'active'
    and expires_at > now();

  if v_code is null then
    raise exception 'Active participant account required'
      using errcode = '42501';
  end if;
  if p_mood_after is not null and p_mood_after not between 1 and 5 then
    raise exception 'Mood score must be between 1 and 5'
      using errcode = '22023';
  end if;

  insert into public.sessions (
    participant_code,
    local_entry_id,
    client_entry_id,
    occurred_at,
    client_updated_at,
    mood_after,
    reflection_provided
  ) values (
    v_code,
    p_local_entry_id,
    p_client_entry_id,
    p_occurred_at,
    p_client_updated_at,
    p_mood_after,
    p_reflection_provided
  )
  on conflict (participant_code, client_entry_id) do update
  set local_entry_id = excluded.local_entry_id,
      occurred_at = excluded.occurred_at,
      client_updated_at = excluded.client_updated_at,
      mood_after = excluded.mood_after,
      reflection_provided = excluded.reflection_provided;

  update public.participants
  set session_count = (
        select count(*)::integer
        from public.sessions
        where participant_code = v_code
      ),
      last_activity_at = greatest(
        coalesce(last_activity_at, p_occurred_at),
        p_occurred_at
      ),
      updated_at = now()
  where participant_code = v_code;
end;
$$;

revoke all on function public.record_session(
  bigint, uuid, timestamptz, timestamptz, smallint, boolean
) from public;

grant execute on function public.record_session(
  bigint, uuid, timestamptz, timestamptz, smallint, boolean
) to authenticated;
