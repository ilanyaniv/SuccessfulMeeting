# A2: Meeting goals collection (Make scenarios)

After A1 records a meeting, A2 emails the inviter a Google Form asking for the goal of the meeting. When the inviter submits it, A2 saves the answers in Supabase, creates the meeting's summary document in Google Docs, and adds any action items the inviter listed.

A2 is two scenarios:

| Scenario | Trigger | What it does |
| --- | --- | --- |
| **A2a: Send goals form** | Schedule (for example, every 15 minutes) | Finds meetings that have not been sent the form yet and emails each inviter a pre-filled link to the form |
| **A2b: Receive goals** | A new response in the form's Google Sheet | Saves the goals, creates the summary document and adds the action items |

## Flow

**A2a: Send goals form**

1. **HTTP: Make a request**: gets meetings from Supabase where `goals_requested_at` is empty and `goals_status` is `Pending`.
2. **Iterator**: handles the meetings one at a time.
3. **Gmail: Send an email**: emails the inviter a link to the form, with the MeetingID, title and date already filled in.
4. **HTTP: Make a request**: sets `goals_requested_at` so the same meeting is not emailed again.

**A2b: Receive goals**

1. **Google Sheets: Watch Rows**: picks up each new form response.
2. **Google Docs: Create a Document**: creates the meeting's summary document with the title, date, goals and action items. It has an empty "Meeting summary" section that A3 will fill in after the meeting.
3. **HTTP: Make a request**: saves the purpose and expected outcomes in the `meetings` table, sets `goals_status` to `Submitted`, and saves the document's link in `summary_document`.
4. **HTTP: Make a request** (up to 5 times): adds each filled-in action item to the `action_items` table with status `Open`.

## Database changes

`A2-migration.sql` adds four columns to `meetings`. `supabase-schema.sql` already includes them for a fresh install.

| Column | Type | Set by |
| --- | --- | --- |
| goals_purpose | text | A2b |
| goals_expected_outcomes | text | A2b |
| goals_status | Pending or Submitted (default Pending) | A2b |
| goals_requested_at | timestamptz (empty until the email is sent) | A2a |

## The Google Form

Create a form named **Meeting goals** with these questions, **in this order**. The order matters: A2b reads the answers by their column position in the response sheet.

| # | Question | Type | Required | Sheet column |
| --- | --- | --- | --- | --- |
| | (Timestamp, added by Google) | | | A |
| 1 | MeetingID | Short answer, number | Yes | B |
| 2 | Meeting title | Short answer | No | C |
| 3 | Meeting date | Short answer | No | D |
| 4 | What is the purpose of the meeting? | Paragraph | Yes | E |
| 5 | What should come out of it? (answers, decisions, timetable) | Paragraph | Yes | F |
| 6 | Action item 1: what needs to be done | Short answer | No | G |
| 7 | Action item 1: accountable person's email | Short answer, email | No | H |
| 8 | Action item 1: due date (YYYY-MM-DD) | Short answer, regular expression `^\d{4}-\d{2}-\d{2}$` | No | I |
| 9 to 11 | Action item 2: same three questions | | No | J to L |
| 12 to 14 | Action item 3: same three questions | | No | M to O |
| 15 to 17 | Action item 4: same three questions | | No | P to R |
| 18 to 20 | Action item 5: same three questions | | No | S to U |

Form settings:

- **Collect email addresses: off.** If it is on, Google adds an extra column B and every answer shifts by one column.
- In the **Responses** tab, click **Link to Sheets** and create a new spreadsheet. Its tab is named **Form Responses 1**.

The due date uses a short answer with a pattern instead of a date question, because a date question is saved in the sheet's local date format, which Supabase may not accept.

### Get the pre-filled link

1. In the form, open the **...** menu and choose **Get pre-filled link**.
2. Type `111` in MeetingID, `TITLE` in Meeting title and `DATE` in Meeting date, then click **Get link** and copy it.
3. The link looks like `https://docs.google.com/forms/d/e/1FAIpQ.../viewform?usp=pp_url&entry.123456=111&entry.234567=TITLE&entry.345678=DATE`. Note the three `entry.` numbers and the form ID (the part after `/forms/d/e/`).

## Setup

1. **Database:** in the Supabase SQL Editor, run `A2-migration.sql`.
2. **Form:** create the form and its response sheet as described above, and get the pre-filled link.
3. **A2a:** in Make, import `A2a-send-goals-form.blueprint.json`, then:
   - In both HTTP modules, replace `YOUR-PROJECT-REF` and the key, the same way as in A1.
   - In the **Gmail** module, connect the Google account that sends the emails. In the email body, edit the form link: replace `YOUR_FORM_ID` with your form ID, and `ENTRY_MEETING_ID`, `ENTRY_TITLE` and `ENTRY_DATE` with the three entry numbers.
4. **A2b:** import `A2b-receive-goals.blueprint.json`, then:
   - In **Google Sheets: Watch Rows**, connect your Google account and select the response spreadsheet and the **Form Responses 1** tab. When asked where to start, choose **From now on**.
   - In **Google Docs: Create a Document**, connect your Google account and choose the folder for the summary documents.
   - In all six HTTP modules, replace `YOUR-PROJECT-REF` and the key.
5. **Test:** create a test meeting in Google Calendar and let A1 record it. Run A2a once and check that the email arrives with MeetingID filled in. Submit the form with one action item, run A2b once, and check that:
   - the meeting's row in `meetings` has the goals, `goals_status` = Submitted and a link in `summary_document`;
   - the action item is in `action_items` with status Open;
   - the summary document opens from the link.
6. Turn both scenarios on.

## Known limits

- **Action items must be filled in order.** A2b stops at the first empty action item, so if item 2 is empty, items 3 to 5 are skipped.
- **Line breaks** in the purpose and expected outcomes are saved as " / ", and double quotes as single quotes, to keep the request to Supabase valid.
- **An inviter can edit the MeetingID** in the form. If it is changed to a number that does not exist, the goals are not saved.
- **If the inviter submits the form twice,** the second answers replace the first in `meetings`, a second summary document is created, and the action items are added again.
- **Every meeting recorded by A1 gets the email,** including meetings created after they already took place.
- **Module names:** I wrote these blueprints without access to Make. If the Gmail, Google Docs or Google Sheets module shows as unknown after import, add it by hand from the Make menu with the settings described above. The Google Docs module's document ID is mapped as `2.id`; if your module names that output differently, update the `summary_document` value in the HTTP module after it.
