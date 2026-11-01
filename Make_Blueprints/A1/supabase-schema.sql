-- Successful Meetings: database schema for Supabase (PostgreSQL)
-- Run once in the Supabase SQL Editor.

create table if not exists public.meetings (
  meeting_id        bigint generated always as identity primary key,
  calendar_event_id text not null unique,          -- Google Calendar event ID, used to find the meeting later
  title             text,
  scheduled_date    date,
  start_time        timestamptz,
  end_time          timestamptz,
  duration_minutes  integer generated always as
                      ((extract(epoch from (end_time - start_time)) / 60)::integer) stored,
  inviter           text,                            -- organizer's email
  attendees         text,                            -- attendee emails, comma-separated
  summary_document  text,                            -- filled by A2
  transcript_path   text,                            -- filled by A3
  score             integer check (score between 1 and 100),  -- filled by A4
  created_at        timestamptz not null default now()
);

create table if not exists public.action_items (
  action_item_id    bigint generated always as identity primary key,
  meeting_id        bigint not null references public.meetings (meeting_id) on delete cascade,
  name              text not null,
  accountable       text not null,                   -- email of the accountable person
  due_date          date,
  status            text not null default 'Open' check (status in ('Open', 'Done')),
  created_at        timestamptz not null default now()
);

-- Settings: a single row of values the automations read.
create table if not exists public.settings (
  id                smallint primary key default 1 check (id = 1),  -- only one row allowed
  min_attendees     integer not null default 2 check (min_attendees >= 1)  -- A1 records a meeting only if it has at least this many attendees
);
insert into public.settings (id, min_attendees) values (1, 2) on conflict (id) do nothing;

-- Row Level Security on, with no public policies: only the service role key
-- (used by Make) can read and write these tables.
alter table public.meetings     enable row level security;
alter table public.action_items enable row level security;
alter table public.settings     enable row level security;
