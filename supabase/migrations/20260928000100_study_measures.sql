alter table public.participants
  add column demographics_status text not null default 'not_started'
    check (demographics_status in ('not_started', 'draft', 'submitted')),
  add column final_assessment_status text not null default 'not_due'
    check (final_assessment_status in ('not_due', 'due', 'in_progress', 'submitted')),
  add column final_assessment_opened_at timestamptz,
  add column final_assessment_opened_by uuid references auth.users(id) on delete set null;

create table public.participant_demographics (
  participant_code text primary key
    references public.participants(participant_code) on delete cascade,
  form_version text not null,
  status text not null default 'draft'
    check (status in ('draft', 'submitted')),
  age_years smallint check (age_years between 0 and 120),
  gender text check (
    gender in ('female', 'male', 'prefer_not_to_say')
  ),
  ethnic_background text check (
    ethnic_background in (
      'asian', 'indigenous', 'latin_american', 'middle_eastern', 'white',
      'mixed_multiple', 'other', 'prefer_not_to_say'
    )
  ),
  ethnic_other text check (char_length(ethnic_other) <= 200),
  country_of_birth text check (char_length(country_of_birth) <= 120),
  relationship_status text check (
    relationship_status in ('single', 'partnered', 'prefer_not_to_say')
  ),
  cardiovascular_diagnosis text
    check (char_length(cardiovascular_diagnosis) <= 500),
  comorbidities text check (char_length(comorbidities) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  submitted_at timestamptz
);

create table public.program_assessments (
  id uuid primary key default extensions.gen_random_uuid(),
  participant_code text not null
    references public.participants(participant_code) on delete cascade,
  timepoint text not null check (timepoint in ('baseline', 'final')),
  form_version text not null,
  status text not null default 'draft'
    check (status in ('draft', 'submitted')),
  gad_1 smallint check (gad_1 between 0 and 3),
  gad_2 smallint check (gad_2 between 0 and 3),
  gad_3 smallint check (gad_3 between 0 and 3),
  gad_4 smallint check (gad_4 between 0 and 3),
  gad_5 smallint check (gad_5 between 0 and 3),
  gad_6 smallint check (gad_6 between 0 and 3),
  gad_7 smallint check (gad_7 between 0 and 3),
  emotional_wellbeing smallint check (emotional_wellbeing between 1 and 5),
  prem_1 smallint check (prem_1 between 1 and 5),
  prem_2 smallint check (prem_2 between 1 and 5),
  prem_3 smallint check (prem_3 between 1 and 5),
  prem_4 smallint check (prem_4 between 1 and 5),
  prem_5 smallint check (prem_5 between 1 and 5),
  prem_6 smallint check (prem_6 between 1 and 5),
  prem_7 smallint check (prem_7 between 1 and 5),
  prem_8 smallint check (prem_8 between 1 and 5),
  open_1 text check (char_length(open_1) <= 2000),
  open_2 text check (char_length(open_2) <= 2000),
  open_3 text check (char_length(open_3) <= 2000),
  open_4 text check (char_length(open_4) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  submitted_at timestamptz,
  unique (participant_code, timepoint)
);

create index program_assessments_participant_idx
  on public.program_assessments(participant_code, timepoint);

alter table public.participant_demographics enable row level security;
alter table public.program_assessments enable row level security;

create policy "staff or owner can read demographics"
on public.participant_demographics for select
to authenticated
using (
  public.is_active_staff()
  or exists (
    select 1 from public.participants
    where participant_code = participant_demographics.participant_code
      and auth_user_id = auth.uid()
  )
);

create policy "staff or owner can read assessments"
on public.program_assessments for select
to authenticated
using (
  public.is_active_staff()
  or exists (
    select 1 from public.participants
    where participant_code = program_assessments.participant_code
      and auth_user_id = auth.uid()
  )
);

create function public.save_participant_demographics(
  p_form_version text,
  p_answers jsonb,
  p_submit boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_age smallint := nullif(p_answers ->> 'age_years', '')::smallint;
  v_gender text := nullif(p_answers ->> 'gender', '');
  v_ethnicity text := nullif(p_answers ->> 'ethnic_background', '');
  v_ethnic_other text := nullif(btrim(p_answers ->> 'ethnic_other'), '');
  v_country text := nullif(btrim(p_answers ->> 'country_of_birth'), '');
  v_relationship text := nullif(p_answers ->> 'relationship_status', '');
  v_diagnosis text := nullif(btrim(p_answers ->> 'cardiovascular_diagnosis'), '');
  v_comorbidities text := nullif(btrim(p_answers ->> 'comorbidities'), '');
begin
  select participant_code into v_code
  from public.participants
  where auth_user_id = auth.uid()
    and status = 'active'
    and expires_at > now();

  if v_code is null then
    raise exception 'Active participant account required' using errcode = '42501';
  end if;
  if p_submit and (
    v_age is null or v_gender is null or v_ethnicity is null
    or v_country is null or v_relationship is null or v_diagnosis is null
    or (v_ethnicity = 'other' and v_ethnic_other is null)
  ) then
    raise exception 'Complete all required demographic questions before submitting'
      using errcode = '22023';
  end if;

  insert into public.participant_demographics (
    participant_code, form_version, status, age_years, gender,
    ethnic_background, ethnic_other, country_of_birth, relationship_status,
    cardiovascular_diagnosis, comorbidities, updated_at, submitted_at
  ) values (
    v_code, p_form_version, case when p_submit then 'submitted' else 'draft' end,
    v_age, v_gender, v_ethnicity, v_ethnic_other, v_country, v_relationship,
    v_diagnosis, v_comorbidities, now(), case when p_submit then now() end
  )
  on conflict (participant_code) do update set
    form_version = excluded.form_version,
    status = excluded.status,
    age_years = excluded.age_years,
    gender = excluded.gender,
    ethnic_background = excluded.ethnic_background,
    ethnic_other = excluded.ethnic_other,
    country_of_birth = excluded.country_of_birth,
    relationship_status = excluded.relationship_status,
    cardiovascular_diagnosis = excluded.cardiovascular_diagnosis,
    comorbidities = excluded.comorbidities,
    updated_at = now(),
    submitted_at = case
      when p_submit then coalesce(participant_demographics.submitted_at, now())
      else participant_demographics.submitted_at
    end;

  update public.participants
  set demographics_status = case when p_submit then 'submitted' else 'draft' end,
      updated_at = now()
  where participant_code = v_code;
end;
$$;

create function public.save_program_assessment(
  p_timepoint text,
  p_form_version text,
  p_answers jsonb,
  p_submit boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_final_status text;
begin
  if p_timepoint not in ('baseline', 'final') then
    raise exception 'Invalid assessment timepoint' using errcode = '22023';
  end if;

  select participant_code, final_assessment_status
  into v_code, v_final_status
  from public.participants
  where auth_user_id = auth.uid()
    and status = 'active'
    and expires_at > now();

  if v_code is null then
    raise exception 'Active participant account required' using errcode = '42501';
  end if;
  if p_timepoint = 'final' and v_final_status not in ('due', 'in_progress') then
    raise exception 'Final assessment is not open' using errcode = '42501';
  end if;

  insert into public.program_assessments (
    participant_code, timepoint, form_version, status,
    gad_1, gad_2, gad_3, gad_4, gad_5, gad_6, gad_7,
    emotional_wellbeing,
    prem_1, prem_2, prem_3, prem_4, prem_5, prem_6, prem_7, prem_8,
    open_1, open_2, open_3, open_4, updated_at, submitted_at
  ) values (
    v_code, p_timepoint, p_form_version,
    case when p_submit then 'submitted' else 'draft' end,
    nullif(p_answers ->> 'gad_1', '')::smallint,
    nullif(p_answers ->> 'gad_2', '')::smallint,
    nullif(p_answers ->> 'gad_3', '')::smallint,
    nullif(p_answers ->> 'gad_4', '')::smallint,
    nullif(p_answers ->> 'gad_5', '')::smallint,
    nullif(p_answers ->> 'gad_6', '')::smallint,
    nullif(p_answers ->> 'gad_7', '')::smallint,
    nullif(p_answers ->> 'emotional_wellbeing', '')::smallint,
    nullif(p_answers ->> 'prem_1', '')::smallint,
    nullif(p_answers ->> 'prem_2', '')::smallint,
    nullif(p_answers ->> 'prem_3', '')::smallint,
    nullif(p_answers ->> 'prem_4', '')::smallint,
    nullif(p_answers ->> 'prem_5', '')::smallint,
    nullif(p_answers ->> 'prem_6', '')::smallint,
    nullif(p_answers ->> 'prem_7', '')::smallint,
    nullif(p_answers ->> 'prem_8', '')::smallint,
    nullif(btrim(p_answers ->> 'open_1'), ''),
    nullif(btrim(p_answers ->> 'open_2'), ''),
    nullif(btrim(p_answers ->> 'open_3'), ''),
    nullif(btrim(p_answers ->> 'open_4'), ''),
    now(), case when p_submit then now() end
  )
  on conflict (participant_code, timepoint) do update set
    form_version = excluded.form_version,
    status = excluded.status,
    gad_1 = excluded.gad_1,
    gad_2 = excluded.gad_2,
    gad_3 = excluded.gad_3,
    gad_4 = excluded.gad_4,
    gad_5 = excluded.gad_5,
    gad_6 = excluded.gad_6,
    gad_7 = excluded.gad_7,
    emotional_wellbeing = excluded.emotional_wellbeing,
    prem_1 = excluded.prem_1,
    prem_2 = excluded.prem_2,
    prem_3 = excluded.prem_3,
    prem_4 = excluded.prem_4,
    prem_5 = excluded.prem_5,
    prem_6 = excluded.prem_6,
    prem_7 = excluded.prem_7,
    prem_8 = excluded.prem_8,
    open_1 = excluded.open_1,
    open_2 = excluded.open_2,
    open_3 = excluded.open_3,
    open_4 = excluded.open_4,
    updated_at = now(),
    submitted_at = case
      when p_submit then coalesce(program_assessments.submitted_at, now())
      else program_assessments.submitted_at
    end;

  if p_timepoint = 'final' then
    update public.participants
    set final_assessment_status = case
          when p_submit then 'submitted' else 'in_progress'
        end,
        updated_at = now()
    where participant_code = v_code;
  end if;
end;
$$;

create function public.open_final_assessment(target_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_manage_participants() then
    raise exception 'Not authorised' using errcode = '42501';
  end if;

  update public.participants
  set final_assessment_status = 'due',
      final_assessment_opened_at = now(),
      final_assessment_opened_by = auth.uid(),
      updated_at = now()
  where participant_code = upper(target_code)
    and final_assessment_status in ('not_due', 'due', 'in_progress');

  if not found then
    raise exception 'Participant not found or assessment already submitted'
      using errcode = 'P0002';
  end if;

  insert into public.audit_logs (
    actor_user_id, action, participant_code, detail
  ) values (
    auth.uid(), 'participant.final_assessment_opened', upper(target_code),
    jsonb_build_object('form_version', '2026-04-16-v1')
  );
end;
$$;

revoke all on public.participant_demographics from anon, authenticated;
revoke all on public.program_assessments from anon, authenticated;
grant select on public.participant_demographics, public.program_assessments
  to authenticated;

revoke all on function public.save_participant_demographics(text, jsonb, boolean)
  from public;
revoke all on function public.save_program_assessment(text, text, jsonb, boolean)
  from public;
revoke all on function public.open_final_assessment(text) from public;

grant execute on function public.save_participant_demographics(text, jsonb, boolean)
  to authenticated;
grant execute on function public.save_program_assessment(text, text, jsonb, boolean)
  to authenticated;
grant execute on function public.open_final_assessment(text) to authenticated;

alter publication supabase_realtime add table public.participant_demographics;
alter publication supabase_realtime add table public.program_assessments;
