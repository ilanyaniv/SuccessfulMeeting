-- A2: goals collection in the Lovable app. Run once in the Supabase SQL Editor
-- on a database created with the earlier supabase-schema.sql. Safe to run more than once.

-- 1. Goal columns on meetings
alter table public.meetings
  add column if not exists goals_purpose            text,         -- inviter's answer: purpose of the meeting
  add column if not exists goals_expected_outcomes  text,         -- inviter's answer: answers, decisions, timetable expected
  add column if not exists goals_status             text not null default 'Pending'
                                                    check (goals_status in ('Pending', 'Submitted')),
  add column if not exists goals_requested_at       timestamptz;  -- when A2 emailed the link (empty = not sent yet)

-- 2. Access rules for people signed in to the Lovable app.
--    Make keeps using the secret key, which is not affected by these rules.
--    A signed-in user is matched by the email of their account.

drop policy if exists "inviter reads own meetings"        on public.meetings;
drop policy if exists "attendee reads meetings"            on public.meetings;
drop policy if exists "inviter updates own meetings"      on public.meetings;
drop policy if exists "read related action items"        on public.action_items;
drop policy if exists "inviter adds action items"        on public.action_items;
drop policy if exists "update related action items"      on public.action_items;

create policy "inviter reads own meetings" on public.meetings
  for select to authenticated
  using (lower(inviter) = lower(auth.jwt() ->> 'email'));

create policy "attendee reads meetings" on public.meetings
  for select to authenticated
  using (position(lower(auth.jwt() ->> 'email') in lower(coalesce(attendees, ''))) > 0);

create policy "inviter updates own meetings" on public.meetings
  for update to authenticated
  using (lower(inviter) = lower(auth.jwt() ->> 'email'))
  with check (lower(inviter) = lower(auth.jwt() ->> 'email'));

create policy "read related action items" on public.action_items
  for select to authenticated
  using (
    lower(accountable) = lower(auth.jwt() ->> 'email')
    or exists (select 1 from public.meetings m
               where m.meeting_id = action_items.meeting_id
                 and lower(m.inviter) = lower(auth.jwt() ->> 'email')));

create policy "inviter adds action items" on public.action_items
  for insert to authenticated
  with check (exists (select 1 from public.meetings m
                      where m.meeting_id = action_items.meeting_id
                        and lower(m.inviter) = lower(auth.jwt() ->> 'email')));

create policy "update related action items" on public.action_items
  for update to authenticated
  using (
    lower(accountable) = lower(auth.jwt() ->> 'email')
    or exists (select 1 from public.meetings m
               where m.meeting_id = action_items.meeting_id
                 and lower(m.inviter) = lower(auth.jwt() ->> 'email')));

-- 3. The app may change only these columns; everything else stays with the automations.
revoke update on public.meetings from authenticated;
grant  select on public.meetings to authenticated;
grant  update (goals_purpose, goals_expected_outcomes, goals_status) on public.meetings to authenticated;
grant  select, insert on public.action_items to authenticated;
revoke update on public.action_items from authenticated;
grant  update (status) on public.action_items to authenticated;
