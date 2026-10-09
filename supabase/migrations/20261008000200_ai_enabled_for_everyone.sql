-- Ask EmbraceAI is on for every participant, including accounts created later.
-- ask-embrace still refuses inactive or expired participants. To hide the chat
-- for one person, set their ai_enabled back to false.
alter table public.participants
  alter column ai_enabled set default true;

update public.participants
set ai_enabled = true
where not ai_enabled;
