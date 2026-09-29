insert into public.participant_journal_entries (
  participant_code,
  client_entry_id,
  note,
  tags,
  mood_after,
  occurred_at,
  client_updated_at
)
select
  participant_code,
  client_entry_id,
  'Guided relaxation session completed.',
  array['Session']::text[],
  mood_after,
  occurred_at,
  client_updated_at
from public.sessions
on conflict (participant_code, client_entry_id) do nothing;
