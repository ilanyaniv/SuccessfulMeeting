-- A2: goals collection. Run once in the Supabase SQL Editor on a database
-- created with the earlier supabase-schema.sql. Safe to run more than once.

alter table public.meetings
  add column if not exists goals_purpose            text,         -- inviter's answer: purpose of the meeting
  add column if not exists goals_expected_outcomes  text,         -- inviter's answer: answers, decisions, timetable expected
  add column if not exists goals_status             text not null default 'Pending'
                                                    check (goals_status in ('Pending', 'Submitted')),
  add column if not exists goals_requested_at       timestamptz;  -- when A2 emailed the goals form (empty = not sent yet)
