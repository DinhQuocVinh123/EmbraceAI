create extension if not exists pgcrypto with schema extensions;

create table public.staff_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin', 'coordinator', 'researcher')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.participants (
  id uuid primary key default extensions.gen_random_uuid(),
  participant_code text not null unique
    check (participant_code ~ '^EA[A-Z0-9]{8}$'),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  study_id text not null check (char_length(study_id) between 1 and 80),
  group_name text not null default 'Unassigned'
    check (char_length(group_name) between 1 and 80),
  status text not null default 'invited'
    check (status in ('invited', 'active', 'suspended', 'completed')),
  consent_status text not null default 'pending'
    check (consent_status in ('pending', 'accepted', 'withdrawn')),
  session_count integer not null default 0 check (session_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  activated_at timestamptz,
  last_activity_at timestamptz,
  expires_at timestamptz not null
);

create table public.sessions (
  id uuid primary key default extensions.gen_random_uuid(),
  participant_code text not null
    references public.participants(participant_code) on delete cascade,
  local_entry_id bigint not null,
  occurred_at timestamptz not null,
  client_updated_at timestamptz not null,
  mood_after smallint check (mood_after between 1 and 5),
  reflection_provided boolean not null default false,
  source text not null default 'guided-session'
    check (source = 'guided-session'),
  created_at timestamptz not null default now(),
  unique (participant_code, local_entry_id)
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  participant_code text,
  detail jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

create index participants_auth_user_idx
  on public.participants(auth_user_id);
create index sessions_participant_occurred_idx
  on public.sessions(participant_code, occurred_at desc);
create index audit_logs_occurred_idx
  on public.audit_logs(occurred_at desc);

alter table public.staff_profiles enable row level security;
alter table public.participants enable row level security;
alter table public.sessions enable row level security;
alter table public.audit_logs enable row level security;

create function public.is_active_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.staff_profiles
    where user_id = auth.uid() and active
  );
$$;

create function public.can_manage_participants()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.staff_profiles
    where user_id = auth.uid()
      and active
      and role in ('admin', 'coordinator')
  );
$$;

create policy "staff can read own profile"
on public.staff_profiles for select
to authenticated
using (user_id = auth.uid() or public.is_active_staff());

create policy "staff or owner can read participants"
on public.participants for select
to authenticated
using (public.is_active_staff() or auth_user_id = auth.uid());

create policy "staff or owner can read sessions"
on public.sessions for select
to authenticated
using (
  public.is_active_staff()
  or exists (
    select 1
    from public.participants
    where participant_code = sessions.participant_code
      and auth_user_id = auth.uid()
      and status = 'active'
      and expires_at > now()
  )
);

create policy "staff can read audit logs"
on public.audit_logs for select
to authenticated
using (public.is_active_staff());

create function public.activate_participant()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.participants
  set status = 'active',
      activated_at = coalesce(activated_at, now()),
      updated_at = now()
  where auth_user_id = auth.uid()
    and status in ('invited', 'active')
    and expires_at > now();

  if not found then
    raise exception 'Participant account is expired or inactive'
      using errcode = 'P0001';
  end if;
end;
$$;

create function public.set_participant_status(
  target_code text,
  new_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_manage_participants() then
    raise exception 'Not authorised' using errcode = '42501';
  end if;
  if new_status not in ('invited', 'active', 'suspended', 'completed') then
    raise exception 'Invalid participant status' using errcode = '22023';
  end if;

  update public.participants
  set status = new_status, updated_at = now()
  where participant_code = upper(target_code);
  if not found then
    raise exception 'Participant not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (
    actor_user_id, action, participant_code, detail
  ) values (
    auth.uid(), 'participant.status_changed', upper(target_code),
    jsonb_build_object('status', new_status)
  );
end;
$$;

create function public.set_consent_status(
  target_code text,
  new_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_manage_participants() then
    raise exception 'Not authorised' using errcode = '42501';
  end if;
  if new_status not in ('pending', 'accepted', 'withdrawn') then
    raise exception 'Invalid consent status' using errcode = '22023';
  end if;

  update public.participants
  set consent_status = new_status, updated_at = now()
  where participant_code = upper(target_code);
  if not found then
    raise exception 'Participant not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (
    actor_user_id, action, participant_code, detail
  ) values (
    auth.uid(), 'participant.consent_changed', upper(target_code),
    jsonb_build_object('consent_status', new_status)
  );
end;
$$;

create function public.record_session(
  p_local_entry_id bigint,
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
  v_inserted_id uuid;
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
    occurred_at,
    client_updated_at,
    mood_after,
    reflection_provided
  ) values (
    v_code,
    p_local_entry_id,
    p_occurred_at,
    p_client_updated_at,
    p_mood_after,
    p_reflection_provided
  )
  on conflict (participant_code, local_entry_id) do nothing
  returning id into v_inserted_id;

  if v_inserted_id is null then
    update public.sessions
    set occurred_at = p_occurred_at,
        client_updated_at = p_client_updated_at,
        mood_after = p_mood_after,
        reflection_provided = p_reflection_provided
    where participant_code = v_code
      and local_entry_id = p_local_entry_id;
  else
    update public.participants
    set session_count = session_count + 1,
        last_activity_at = greatest(
          coalesce(last_activity_at, p_occurred_at),
          p_occurred_at
        ),
        updated_at = now()
    where participant_code = v_code;
  end if;
end;
$$;

revoke all on public.staff_profiles from anon;
revoke all on public.participants from anon;
revoke all on public.sessions from anon;
revoke all on public.audit_logs from anon, authenticated;
grant select on public.staff_profiles, public.participants, public.sessions
  to authenticated;
grant select on public.audit_logs to authenticated;

revoke all on function public.is_active_staff() from public;
revoke all on function public.can_manage_participants() from public;
revoke all on function public.activate_participant() from public;
revoke all on function public.set_participant_status(text, text) from public;
revoke all on function public.set_consent_status(text, text) from public;
revoke all on function public.record_session(
  bigint, timestamptz, timestamptz, smallint, boolean
) from public;

grant execute on function public.is_active_staff() to authenticated;
grant execute on function public.can_manage_participants() to authenticated;
grant execute on function public.activate_participant() to authenticated;
grant execute on function public.set_participant_status(text, text)
  to authenticated;
grant execute on function public.set_consent_status(text, text)
  to authenticated;
grant execute on function public.record_session(
  bigint, timestamptz, timestamptz, smallint, boolean
) to authenticated;

alter publication supabase_realtime add table public.participants;
alter publication supabase_realtime add table public.sessions;
