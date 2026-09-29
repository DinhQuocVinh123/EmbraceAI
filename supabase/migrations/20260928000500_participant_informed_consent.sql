alter table public.participants
  add column if not exists consent_version text,
  add column if not exists consent_recorded_at timestamptz,
  add column if not exists consent_source text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'participants_consent_source_check'
      and conrelid = 'public.participants'::regclass
  ) then
    alter table public.participants
      add constraint participants_consent_source_check
      check (consent_source is null or consent_source in ('participant', 'staff'));
  end if;
end;
$$;

update public.participants
set consent_recorded_at = coalesce(consent_recorded_at, updated_at, now()),
    consent_source = coalesce(consent_source, 'staff')
where consent_status = 'accepted';

create or replace function public.record_participant_consent(
  p_consent_version text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  if nullif(trim(p_consent_version), '') is null then
    raise exception 'Consent version is required' using errcode = '22023';
  end if;

  update public.participants
  set consent_status = 'accepted',
      consent_version = trim(p_consent_version),
      consent_recorded_at = now(),
      consent_source = 'participant',
      updated_at = now()
  where auth_user_id = auth.uid()
    and status in ('invited', 'active')
    and expires_at > now()
  returning participant_code into v_code;

  if v_code is null then
    raise exception 'Active participant account required'
      using errcode = '42501';
  end if;

  insert into public.audit_logs (
    actor_user_id, action, participant_code, detail
  ) values (
    auth.uid(), 'participant.consent_accepted', v_code,
    jsonb_build_object(
      'consent_status', 'accepted',
      'consent_version', trim(p_consent_version),
      'consent_source', 'participant'
    )
  );
end;
$$;

create or replace function public.set_consent_status(
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
  set consent_status = new_status,
      consent_version = case
        when new_status = 'pending' then null
        else consent_version
      end,
      consent_recorded_at = case
        when new_status = 'pending' then null
        else now()
      end,
      consent_source = case
        when new_status = 'pending' then null
        else 'staff'
      end,
      updated_at = now()
  where participant_code = upper(target_code);
  if not found then
    raise exception 'Participant not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (
    actor_user_id, action, participant_code, detail
  ) values (
    auth.uid(), 'participant.consent_changed', upper(target_code),
    jsonb_build_object(
      'consent_status', new_status,
      'consent_source', 'staff'
    )
  );
end;
$$;

revoke all on function public.record_participant_consent(text) from public;
grant execute on function public.record_participant_consent(text)
  to authenticated;
