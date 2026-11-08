-- Meeting exclusion flag and admin access.
-- Run once in the Supabase SQL Editor, after supabase-schema.sql and A2-migration.sql.
-- Safe to run more than once.

-- 1. The flag. An excluded meeting gets no emails, collects no data and is hidden
--    from inviters and attendees in the app. Only admins can see or change it.
alter table public.meetings
  add column if not exists excluded         boolean not null default false,
  add column if not exists excluded_reason  text,          -- optional note shown in the admin page
  add column if not exists excluded_at      timestamptz;   -- set automatically when excluded turns on

create index if not exists meetings_excluded_idx on public.meetings (excluded);

-- 2. Admins: people allowed to manage every meeting in the app.
create table if not exists public.admins (
  email      text primary key check (email = lower(email)),
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;

-- Add yourself (change the address), then add more admins the same way:
-- insert into public.admins (email) values ('you@example.com') on conflict do nothing;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.admins
                 where email = lower(auth.jwt() ->> 'email'));
$$;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "admins read admins" on public.admins;
create policy "admins read admins" on public.admins
  for select to authenticated using (public.is_admin());
grant select on public.admins to authenticated;

-- 3. Inviters and attendees no longer see or change excluded meetings,
--    or the action items of excluded meetings.
drop policy if exists "inviter reads own meetings"   on public.meetings;
drop policy if exists "attendee reads meetings"      on public.meetings;
drop policy if exists "inviter updates own meetings" on public.meetings;
drop policy if exists "read related action items"    on public.action_items;
drop policy if exists "inviter adds action items"    on public.action_items;
drop policy if exists "update related action items"  on public.action_items;

create policy "inviter reads own meetings" on public.meetings
  for select to authenticated
  using (not excluded and lower(inviter) = lower(auth.jwt() ->> 'email'));

create policy "attendee reads meetings" on public.meetings
  for select to authenticated
  using (not excluded
         and position(lower(auth.jwt() ->> 'email') in lower(coalesce(attendees, ''))) > 0);

create policy "inviter updates own meetings" on public.meetings
  for update to authenticated
  using (not excluded and lower(inviter) = lower(auth.jwt() ->> 'email'))
  with check (not excluded and lower(inviter) = lower(auth.jwt() ->> 'email'));

create policy "read related action items" on public.action_items
  for select to authenticated
  using (exists (select 1 from public.meetings m
                 where m.meeting_id = action_items.meeting_id
                   and not m.excluded
                   and (lower(m.inviter) = lower(auth.jwt() ->> 'email')
                        or lower(action_items.accountable) = lower(auth.jwt() ->> 'email'))));

create policy "inviter adds action items" on public.action_items
  for insert to authenticated
  with check (exists (select 1 from public.meetings m
                      where m.meeting_id = action_items.meeting_id
                        and not m.excluded
                        and lower(m.inviter) = lower(auth.jwt() ->> 'email')));

create policy "update related action items" on public.action_items
  for update to authenticated
  using (exists (select 1 from public.meetings m
                 where m.meeting_id = action_items.meeting_id
                   and not m.excluded
                   and (lower(m.inviter) = lower(auth.jwt() ->> 'email')
                        or lower(action_items.accountable) = lower(auth.jwt() ->> 'email'))));

-- 4. Admins read everything; they change meetings only through the functions below,
--    so inviters can never switch the flag themselves.
drop policy if exists "admins read all meetings"     on public.meetings;
drop policy if exists "admins read all action items" on public.action_items;
drop policy if exists "admins read settings"         on public.settings;
drop policy if exists "admins update settings"       on public.settings;

create policy "admins read all meetings" on public.meetings
  for select to authenticated using (public.is_admin());
create policy "admins read all action items" on public.action_items
  for select to authenticated using (public.is_admin());
create policy "admins read settings" on public.settings
  for select to authenticated using (public.is_admin());
create policy "admins update settings" on public.settings
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

grant select on public.settings to authenticated;
grant update (min_attendees) on public.settings to authenticated;

-- Turn exclusion on or off for one meeting.
create or replace function public.admin_set_excluded(p_meeting_id bigint, p_excluded boolean, p_reason text default null)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can change exclusion' using errcode = '42501';
  end if;
  update public.meetings
     set excluded        = p_excluded,
         excluded_reason = case when p_excluded then p_reason else null end,
         excluded_at     = case when p_excluded then now() else null end
   where meeting_id = p_meeting_id;
end;
$$;

-- Send the goals email again: clears goals_requested_at so A2 picks the meeting up on its next run.
create or replace function public.admin_resend_goals_email(p_meeting_id bigint)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can resend emails' using errcode = '42501';
  end if;
  update public.meetings
     set goals_requested_at = null
   where meeting_id = p_meeting_id and not excluded and goals_status = 'Pending';
end;
$$;

revoke execute on function public.admin_set_excluded(bigint, boolean, text) from public, anon;
revoke execute on function public.admin_resend_goals_email(bigint)        from public, anon;
grant  execute on function public.admin_set_excluded(bigint, boolean, text) to authenticated;
grant  execute on function public.admin_resend_goals_email(bigint)        to authenticated;
