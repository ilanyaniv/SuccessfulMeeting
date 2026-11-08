# Meeting exclusion and the Admin page

Some meetings should stay out of Successful Meetings entirely: a private 1:1, an HR talk, a board meeting. Each meeting now has an **excluded** flag (true or false, default false). An excluded meeting:

- gets **no emails** from any automation (A2 goals link today; A3 to A5 must use the same filter, see below);
- **collects no data**: inviters and attendees cannot see it or its action items in the app, cannot fill in goals and cannot add action items;
- is **left out of reports**.

Admins manage the flag, and see who gets emailed for each meeting, on a new **Admin** page in the Lovable app.

## What changed

| File | Change |
| --- | --- |
| `exclusion-migration.sql` (new) | Adds `excluded`, `excluded_reason`, `excluded_at` to `meetings`; adds an `admins` table; hides excluded meetings from inviters and attendees; lets admins read every meeting and change the flag |
| `A1-meeting-registration.blueprint.json` | A meeting whose calendar title or description contains `#exclude` is recorded with `excluded = true`, so it is never emailed |
| `A2-send-goals-link.blueprint.json` | Both Supabase requests add `excluded=is.false`, so excluded meetings are never emailed or updated |

### Why `#exclude` in A1

A2 runs every 15 minutes, so a new meeting could get its goals email before you have time to exclude it in the Admin page. Writing `#exclude` anywhere in the event's title or description excludes it from the moment it is recorded. You can still turn the flag on or off later in the Admin page.

## Database

New columns on `meetings`:

| Column | Type | Set by |
| --- | --- | --- |
| excluded | boolean, default false | A1 (`#exclude`) or an admin |
| excluded_reason | text, optional | Admin |
| excluded_at | timestamptz | Set automatically when an admin excludes the meeting |

New table `admins` (`email`, lowercase). Anyone listed here can open the Admin page.

Admins change meetings only through two database functions, so an inviter can never switch the flag on their own meeting:

| Function | What it does |
| --- | --- |
| `admin_set_excluded(meeting_id, excluded, reason)` | Turns exclusion on or off |
| `admin_resend_goals_email(meeting_id)` | Clears `goals_requested_at` so A2 emails the inviter again on its next run (only for meetings that are not excluded and whose goals are still Pending) |

Admins can also read and change `min_attendees` in `settings`.

I tested the rules on a local PostgreSQL copy with a stand-in for Supabase sign-in: an excluded meeting and its action items were hidden from the inviter and the attendee, the inviter could not save goals on it or change the flag, A2's query skipped it, an admin saw all meetings, toggled the flag with a reason and changed `min_attendees`, and a non-admin calling the admin functions was refused.

## Setup

1. In Supabase **SQL Editor**, run `exclusion-migration.sql`.
2. Add yourself as admin (change the address, use lowercase):
   ```sql
   insert into public.admins (email) values ('you@example.com') on conflict do nothing;
   ```
3. In Make, re-import `A1-meeting-registration.blueprint.json` and `A2-send-goals-link.blueprint.json` (or edit by hand: add `&excluded=is.false` to the end of both URLs in A2, and add the `excluded` line to A1's JSON body). Re-enter the Supabase key, project ref and app address as before.
4. Paste the Lovable prompt below into your Successful Meetings project.
5. **Test:** create a calendar meeting with `#exclude` in the title and check that its row has `excluded = true` and no email arrives. Then exclude an ordinary meeting from the Admin page and check that the inviter no longer sees it in the app.

## Rule for the next automations (A3 to A5 and reports)

Every Make request that reads `meetings` must add `excluded=is.false` to its URL, and every report must filter `where not excluded`. Action item reminders (A5) should read action items through `meetings` with the same filter, for example:
`/rest/v1/action_items?select=*,meetings!inner(excluded)&meetings.excluded=is.false&status=eq.Open`

## Lovable prompt: Admin page

> Add an admin area to the Successful Meetings app. Do not create or change tables, policies or functions; they already exist in Supabase.
>
> **Who is an admin:** call the Supabase function `is_admin()` (rpc, no arguments, returns true or false) after sign-in. Show an "Admin" link in the header only when it returns true. If a non-admin opens an admin page, show "This page is for admins only".
>
> **Admin > Meetings** (`/admin/meetings`): a table of all rows in `meetings` (admins can read every row), newest `start_time` first, 25 per page. Columns: title, date and start time, inviter, number of attendees (count of comma-separated emails in `attendees`, full list in a tooltip), goals status, "Goals email" (if `goals_requested_at` is set show "Sent" and the date, otherwise "Not sent yet"; if the meeting is excluded show "Blocked"), and an "Excluded" switch.
> - Filters at the top: search by title or inviter, date range, and a selector "All / Active / Excluded" (default All). Show counts of active and excluded meetings.
> - Excluded rows are shown greyed out with an "Excluded" badge and the reason.
> - Turning the switch **on** opens a small dialog: "Exclude this meeting from Successful Meetings? No emails will be sent and inviters and attendees will not see it." with an optional "Reason" text field and a confirm button. On confirm call rpc `admin_set_excluded` with `{ p_meeting_id, p_excluded: true, p_reason }`.
> - Turning the switch **off** calls rpc `admin_set_excluded` with `{ p_meeting_id, p_excluded: false }` after a simple confirm.
> - A row menu has "Resend goals email", shown only when the meeting is not excluded and `goals_status` is "Pending". It calls rpc `admin_resend_goals_email` with `{ p_meeting_id }` and shows the toast "The goals email will be sent again within 15 minutes".
> - Clicking a row opens a side panel with all meeting details: times, duration, inviter, the full attendee list, goals (purpose and expected outcomes), the `summary_document` link, and the meeting's action items (read-only).
> - After any change, refresh the row and show a success or error toast.
>
> **Admin > Settings** (`/admin/settings`): shows `min_attendees` from the single row in `settings` (id = 1) with a number input (1 or more) and a Save button that updates it. Explain under the field: "A meeting is recorded only if it has at least this many attendees." Also show a read-only list of admins from the `admins` table and the hint: "Add or remove admins in Supabase."
>
> Also: in the existing non-admin pages, nothing changes; excluded meetings are already hidden from them by the database.
