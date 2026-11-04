# A1: Meeting registration (Make scenario)

When a new meeting is created in Google Calendar, A1 adds a row for it to the **meetings** table in Supabase.

The Successful Meetings web app, built with Lovable, reads the same table. Inviters see their meetings there and fill in each meeting's goals and summary (see A2-setup.md).

## Flow

1. **Google Calendar: Watch Events** (trigger): picks up newly created events in the calendar.
2. **HTTP: Make a request** (HTTP app version 4): reads `min_attendees` from the `settings` table in Supabase.
3. **Filter: Enough attendees**: lets the meeting through only if its number of attendees is equal to or greater than `min_attendees`. Meetings with fewer attendees are not recorded.
4. **HTTP: Make a request** (HTTP app version 4): sends the meeting to Supabase's REST API, which inserts it into the `meetings` table. If the same calendar event arrives twice, the second one is ignored.

## Database

`supabase-schema.sql` creates both tables from the PRD:

**meetings**

| Column | Type | Filled by |
| --- | --- | --- |
| meeting_id | bigint, generated automatically | Database |
| calendar_event_id | text, unique | A1 (Google Calendar event ID, used by A2 to A4 to find the meeting) |
| title | text | A1 |
| scheduled_date | date | A1 |
| start_time, end_time | timestamptz | A1 |
| duration_minutes | integer, calculated from start and end | Database |
| inviter | text (organizer's email) | A1 |
| attendees | text (emails, comma-separated) | A1 |
| summary_document | text (link to the meeting's page in the app) | A2 |
| transcript_path | text | A3 |
| score | integer, 1 to 100 | A4 |

**settings**: one row of values the automations read.

| Column | Type | Default | Used by |
| --- | --- | --- | --- |
| min_attendees | integer, 1 or more | 2 | A1: a meeting is recorded only if it has at least this many attendees |

To change the minimum, edit the value in **Table Editor > settings**, or run `update public.settings set min_attendees = 3;` in the SQL Editor. The table holds a single row, so there is only one value to change.

**action_items**: action_item_id, meeting_id (links to meetings), name, accountable, due_date, status (Open or Done, default Open).

## Setup

1. In Supabase, open **SQL Editor**, paste the contents of `supabase-schema.sql`, and click **Run**.
2. In Supabase, open **Project Settings > API** and copy the **Project URL** and the **service_role** key.
3. In Make, create a new scenario, open the **...** menu at the bottom, choose **Import Blueprint**, and select `A1-meeting-registration.blueprint.json`.
4. Open the **Google Calendar** module: connect your Google account and choose the calendar to watch.
5. Open **both HTTP modules** (the settings read and the meeting insert) and make the same two changes in each:
   - In the URL, replace `YOUR-PROJECT-REF` with your project's reference (the part of the Project URL before `.supabase.co`).
   - In the `apikey` header, replace `YOUR_SUPABASE_SERVICE_ROLE_KEY` with your secret key. If the key starts with `sb_secret_`, delete the `Authorization` header. If it is a legacy service_role key (starts with `eyJ`), put it in the `Authorization` header too, after `Bearer `.
6. Click **Run once**, then create a test meeting with at least `min_attendees` attendees in Google Calendar. A new row should appear in **Table Editor > meetings**.
7. Set the schedule (for example, every 15 minutes) and turn the scenario on.

## Security

The service_role key bypasses all access rules in Supabase. Keep it only inside Make, never in the PRD, the GitHub repo or a shared document. The tables have Row Level Security turned on with no public policies, so nobody can read them with the public (anon) key.

## Known limits

- **Attendee count** is the number of people on the Google Calendar invite. Google usually lists the organizer as an attendee too, so a meeting with you and one guest counts as 2.

- **All-day events** are saved with midnight as their start and end times, so their duration counts as a full day (1,440 minutes).
- **Events with no start time** are skipped by the filter, so they never reach Supabase.
- **Recurring meetings** are recorded once, when the series is created, not once per occurrence.
- **Edits** made to a meeting after it is created (new time, new attendees) are not updated in the table.
- **Titles** with double quotes are saved with single quotes instead, and backslashes become forward slashes, so the request stays valid JSON.
