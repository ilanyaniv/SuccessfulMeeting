# A2: Meeting goals collection (Make + Lovable app)

After A1 records a meeting, A2 emails the inviter a link to the meeting's **Goals** page in the Successful Meetings web app, built with Lovable. The inviter fills in the purpose of the meeting, the expected outcomes and any action items already known. The app saves the answers straight into Supabase.

A2 has two parts:

| Part | Where it runs | What it does |
| --- | --- | --- |
| **Send goals link** | Make scenario, on a schedule (for example, every 15 minutes) | Finds meetings whose inviter has not been emailed yet and sends each inviter a link to the meeting's Goals page |
| **Goals page** | Lovable app | Shows the meeting details, saves the goals and action items in Supabase |

The meeting's page in the app (`/meetings/<MeetingID>`) is its **summary document**: it shows the goals before the meeting, and A3 will add the summary after it.

## Flow

**Make scenario: Send goals link**

1. **HTTP: Make a request**: gets meetings from Supabase where `goals_requested_at` is empty and `goals_status` is `Pending`.
2. **Iterator**: handles the meetings one at a time.
3. **Gmail: Send an email**: emails the inviter a link to `https://YOUR-APP.lovable.app/meetings/<MeetingID>/goals`.
4. **HTTP: Make a request**: sets `goals_requested_at`, so the same meeting is not emailed again, and saves the meeting's app link in `summary_document`.

**Lovable app: Goals page**

1. The inviter opens the link and signs in with their Google account.
2. The page shows the meeting's title, date, time and attendees.
3. The inviter fills in the purpose and expected outcomes, and adds action items (what, accountable person's email, due date).
4. On **Submit**, the app saves the goals in `meetings`, sets `goals_status` to `Submitted`, and adds each action item to `action_items` with status `Open`.

## Database changes

`A2-migration.sql` makes two changes. Run it once in the Supabase SQL Editor.

**1. Four new columns on `meetings`** (`supabase-schema.sql` already includes them for a fresh install):

| Column | Type | Set by |
| --- | --- | --- |
| goals_purpose | text | App |
| goals_expected_outcomes | text | App |
| goals_status | Pending or Submitted (default Pending) | App |
| goals_requested_at | timestamptz (empty until the email is sent) | Make |

**2. Access rules for people signed in to the app.** Make keeps using the secret key and is not affected. A signed-in user is matched by their account's email:

| Who | Can see | Can change |
| --- | --- | --- |
| Inviter | Their own meetings and those meetings' action items | Goals fields of their own meetings; add action items to their own meetings; status of those action items |
| Attendee | Meetings they are invited to | Nothing |
| Accountable person | Their own action items | Status of their own action items (Open or Done) |

The app can change only `goals_purpose`, `goals_expected_outcomes` and `goals_status` on a meeting, and only `status` on an action item. Titles, times, attendees and the rest stay with the automations.

I tested these rules on a local PostgreSQL copy with a stand-in for Supabase sign-in: an inviter saved goals on their own meeting and added an action item, a second user could not change that meeting, the accountable person marked the item Done, and editing a title or adding an item to someone else's meeting was refused.

## Building the Goals page in Lovable

1. In Lovable, create a project and connect it to your Supabase project (**Supabase** button in the editor). Lovable then uses your project's public key and the access rules above. Never paste the secret key into Lovable.
2. In Supabase, open **Authentication > Providers** and turn on **Google**. Add your Lovable app's address to **Authentication > URL Configuration > Redirect URLs**.
3. Give Lovable this prompt:

> Build a web app called Successful Meetings on the connected Supabase project. Users sign in with Google through Supabase Auth.
>
> Tables already exist: `meetings` (meeting_id, title, scheduled_date, start_time, end_time, duration_minutes, inviter, attendees, summary_document, goals_purpose, goals_expected_outcomes, goals_status) and `action_items` (action_item_id, meeting_id, name, accountable, due_date, status). Do not create or change tables or policies.
>
> Pages:
> 1. **Sign in** with Google.
> 2. **My meetings** (`/`): meetings where `inviter` equals the signed-in user's email, newest first, showing title, date, time and goals status.
> 3. **Meeting page** (`/meetings/:id`): title, date, start and end time, duration, attendees, the goals, and the meeting's action items.
> 4. **Goals page** (`/meetings/:id/goals`): shows the meeting details read-only, then a form with "What is the purpose of the meeting?" (required), "What should come out of it? (answers, decisions, timetable)" (required), and a list of action items where each row has "What needs to be done", "Accountable person's email" and "Due date" (date picker), with buttons to add and remove rows. On Submit, update the meeting's `goals_purpose`, `goals_expected_outcomes` and set `goals_status` to `Submitted`, insert each action item into `action_items` with status `Open`, then go to the meeting page. If goals were already submitted, show them and let the inviter edit and resubmit; do not insert action items that are already there.
> 5. **My action items** (`/my-actions`): open action items where `accountable` equals the signed-in user's email, sorted by due date, with a "Mark as Done" button that sets `status` to `Done`.
>
> If a signed-in user opens a meeting they are not allowed to see, show "This meeting isn't available to you".

4. Publish the app and note its address (for example, `https://successful-meetings.lovable.app`).

## Make setup

1. Import `A2-send-goals-link.blueprint.json` into a new Make scenario.
2. In both HTTP modules, replace `YOUR-PROJECT-REF` and the key, the same way as in A1.
3. In the **Gmail** module, connect the Google account that sends the emails.
4. **Skip meetings that fail.** The Gmail module has an **Ignore** error handler. If an email fails for one meeting (for example, a 403 error), Make skips that meeting and goes on to the next one. If you imported an older version of the blueprint, add it by hand: right-click the Gmail module, choose **Add error handler**, then choose **Ignore**.
5. Replace `YOUR-APP.lovable.app` with your app's address in two places: the link in the Gmail email body, and `summary_document` in the last HTTP module.
6. **Test:** create a test meeting in Google Calendar and let A1 record it. Run the scenario once and check that the email arrives. Open the link, sign in, fill in the goals with one action item and submit. Then check in Supabase that:
   - the meeting's row has the goals, `goals_status` = Submitted and the app link in `summary_document`;
   - the action item is in `action_items` with status Open.
7. Turn the scenario on.

## Known limits

- **Sign-in email must match.** The inviter must sign in with the same Google account that organized the meeting in Google Calendar, or the app will not show the meeting.
- **Attendees are matched by text.** The attendee rule checks whether the user's email appears in the attendees list, so an address that contains another one (for example, `ann@x.com` inside `joann@x.com`) could see that meeting.
- **A skipped meeting is tried again on the next run.** The Ignore handler stops that meeting before the last HTTP module, so `goals_requested_at` stays empty. The next run tries the email again. Fix the cause (usually the sender's Gmail connection) or the meeting will keep showing up in the scenario's history as a warning.
- **Every meeting recorded by A1 gets the email,** including meetings created after they already took place.
- **Gmail module:** I wrote the blueprint without access to Make. If the Gmail module shows as unknown after import, add **Gmail > Send an email** by hand with the recipient, subject and body described above.
