-- Optional short note / description on important dates (shown on Us cards).
alter table public.important_dates
  add column if not exists note text;

alter table public.important_dates
  drop constraint if exists important_dates_note_len;

alter table public.important_dates
  add constraint important_dates_note_len
  check (note is null or char_length(note) <= 80);
