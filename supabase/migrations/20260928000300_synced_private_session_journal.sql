create table public.participant_journal_entries (
  participant_code text not null,
  client_entry_id uuid not null,
  note text not null default '' check (char_length(note) <= 10000),
  tags text[] not null default array['Session']::text[],
  mood_after smallint check (mood_after between 1 and 5),
  occurred_at timestamptz not null,
  client_updated_at timestamptz not null,
  created_at timestamptz not null default now(),
  primary key (participant_code, client_entry_id),
  foreign key (participant_code, client_entry_id)
    references public.sessions(participant_code, client_entry_id)
    on delete cascade
);

create index participant_journal_occurred_idx
  on public.participant_journal_entries(participant_code, occurred_at desc);

alter table public.participant_journal_entries enable row level security;

create policy "participants can read their private journal"
on public.participant_journal_entries for select
to authenticated
using (
  exists (
    select 1
    from public.participants
    where participant_code = participant_journal_entries.participant_code
      and auth_user_id = auth.uid()
      and status = 'active'
      and expires_at > now()
  )
);

revoke all on public.participant_journal_entries from anon, authenticated;
grant select on public.participant_journal_entries to authenticated;

create function public.sync_session_journal(
  p_local_entry_id bigint,
  p_client_entry_id uuid,
  p_occurred_at timestamptz,
  p_client_updated_at timestamptz,
  p_mood_after smallint,
  p_note text,
  p_tags text[]
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_note text := coalesce(p_note, '');
  v_tags text[] := coalesce(p_tags, array['Session']::text[]);
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
  if char_length(v_note) > 10000 then
    raise exception 'Journal note is too long'
      using errcode = '22023';
  end if;
  if cardinality(v_tags) > 12 or exists (
    select 1 from unnest(v_tags) as tag
    where char_length(tag) > 50
  ) then
    raise exception 'Journal tags are invalid'
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
    btrim(v_note) <> ''
  )
  on conflict (participant_code, client_entry_id) do update
  set local_entry_id = excluded.local_entry_id,
      occurred_at = excluded.occurred_at,
      client_updated_at = excluded.client_updated_at,
      mood_after = excluded.mood_after,
      reflection_provided = excluded.reflection_provided;

  insert into public.participant_journal_entries (
    participant_code,
    client_entry_id,
    note,
    tags,
    mood_after,
    occurred_at,
    client_updated_at
  ) values (
    v_code,
    p_client_entry_id,
    v_note,
    v_tags,
    p_mood_after,
    p_occurred_at,
    p_client_updated_at
  )
  on conflict (participant_code, client_entry_id) do update
  set note = excluded.note,
      tags = excluded.tags,
      mood_after = excluded.mood_after,
      occurred_at = excluded.occurred_at,
      client_updated_at = excluded.client_updated_at;

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

revoke all on function public.sync_session_journal(
  bigint, uuid, timestamptz, timestamptz, smallint, text, text[]
) from public;

grant execute on function public.sync_session_journal(
  bigint, uuid, timestamptz, timestamptz, smallint, text, text[]
) to authenticated;
