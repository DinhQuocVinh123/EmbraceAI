-- Thẻ "chuẩn bị câu hỏi cho buổi khám" (biên bản họp, mục 2).
--
-- appointment_questions: tối đa 3 câu hỏi mỗi người tham gia muốn mang tới buổi
-- khám, xếp theo thứ tự họ muốn hỏi trước (position 0, 1, 2). Chỉ chính người
-- tham gia đọc và sửa được; nhân viên không có quyền đọc (theo quyết định của
-- nhóm ngày 16/10/2026).
create table public.appointment_questions (
  id uuid primary key default gen_random_uuid(),
  participant_code text not null
    references public.participants(participant_code) on delete cascade,
  -- Lời người tham gia tự kể, để họ xem lại; có thể rỗng.
  concern text not null default '' check (char_length(concern) <= 1000),
  topics text[] not null default '{}'
    check (topics <@ array['why', 'monitor', 'next_time', 'other']),
  question text not null check (char_length(question) between 1 and 600),
  position smallint not null default 0 check (position between 0 and 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index appointment_questions_participant_idx
  on public.appointment_questions(participant_code, position);

alter table public.appointment_questions enable row level security;

create function public.owns_participant_code(code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.participants
    where participant_code = code
      and auth_user_id = auth.uid()
      and status = 'active'
      and expires_at > now()
  );
$$;

revoke all on function public.owns_participant_code(text) from public, anon;
grant execute on function public.owns_participant_code(text) to authenticated;

create policy "participants manage their appointment questions"
on public.appointment_questions for all
to authenticated
using (public.owns_participant_code(participant_code))
with check (public.owns_participant_code(participant_code));

revoke all on public.appointment_questions from anon, authenticated;
grant select, insert, update, delete on public.appointment_questions to authenticated;

-- Không quá 3 câu mỗi người: app đã chặn, đây là lớp chặn ở database.
create function public.limit_appointment_questions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (
    select count(*) from public.appointment_questions
    where participant_code = new.participant_code
  ) >= 3 then
    raise exception 'At most 3 appointment questions'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger appointment_questions_limit
before insert on public.appointment_questions
for each row execute function public.limit_appointment_questions();

-- Nhật ký AI dùng chung cho Ask EmbraceAI và thẻ chuẩn bị câu hỏi: feature cho
-- biết dòng nào của tính năng nào. Với thẻ chuẩn bị câu hỏi, question là lời
-- người tham gia kể, answer là đoạn câu hỏi model viết lại (result_type
-- 'rephrased'), question_english là bản tiếng Anh của đoạn đó khi app tiếng Việt.
-- Nhân viên đọc được nhật ký này như với Ask (theo quyết định của nhóm).
alter table public.ai_interactions
  add column feature text not null default 'ask'
    check (feature in ('ask', 'appointment_prep'));

-- Bỏ luật cũ về result_type theo nội dung, không theo tên đoán trước.
do $$
declare
  old_check text;
begin
  for old_check in
    select conname from pg_constraint
    where conrelid = 'public.ai_interactions'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%result_type%'
  loop
    execute format('alter table public.ai_interactions drop constraint %I', old_check);
  end loop;
end;
$$;

alter table public.ai_interactions
  add constraint ai_interactions_result_type_check check (result_type in (
    'answer', 'medical_redirect', 'out_of_scope', 'not_found',
    'emergency', 'busy', 'error', 'rephrased'
  ));
