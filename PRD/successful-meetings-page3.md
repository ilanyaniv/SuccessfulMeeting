# Successful Meetings: Product Requirements Document

## Page 3: Development Plan and Success Metrics

The first release is built in 6 weeks, then measured against a baseline taken before launch to show whether meetings became shorter, more focused and more productive.

### Development plan (6 weeks)

| Week | Focus | Deliverables | Done when |
| --- | --- | --- | --- |
| 1 | Foundations | Database with the Meetings and Action Items tables. Google Calendar connection. A1: every new meeting is recorded in the database. | A test meeting created in Google Calendar appears in the Meetings table with start time, end time and duration. |
| 2 | Goals collection | A2: Google Form sent to the inviter with the meeting details, purpose, expected outcomes and extra action items. Summary file created per meeting. | The inviter's answers appear in the meeting's summary file, and added action items appear in the Action Items table. |
| 3 | Recording and transcript | A3: recording and transcript captured from Zoom and Google Meet, path saved in the Meetings table. | A finished test meeting has a working transcript path in the database. |
| 4 | Meeting analysis | A4: transcript compared with the goals; summary, 1 to 100 score (goal achievement and attendee participation) and action items with due dates written to the database. | Scores on 10 test meetings match a manual review by the team. |
| 5 | Action items and reports | A6: daily email to each accountable person with a "mark as Done" link. A5: the three management reports. | Clicking the link changes the status to Done, and all three reports return correct numbers on test data. |
| 6 | Pilot and launch | End-to-end testing, bug fixing, and a pilot with one group of real users inside our company. Baseline metrics collected. | The full flow runs on real meetings for one week without manual help. |

**Before week 1:** collect the baseline. Export 4 weeks of Google Calendar data to measure the number of meetings, their duration and attendee counts before the product is used.

### Success metrics

Each metric is compared with the baseline (where one exists) and tracked weekly after launch.

| Metric | What it shows | How it is measured | Source |
| --- | --- | --- | --- |
| Meetings with a stated goal | Problem 1: meetings have a clear target | Share of meetings whose Google Form was completed before the meeting | Meetings table, summary file |
| Average meeting score | Problem 1: meetings achieve their goal | Average 1 to 100 score per week | Meetings table |
| Attendee participation | Problem 2: only needed people are invited | Share of attendees who spoke during the meeting | A4 transcript analysis |
| Average attendees per meeting | Problem 2: smaller meetings | Number of attendees per meeting, compared with the baseline | Meetings table |
| Working hours in meetings | Problem 2: time saved | Sum of duration x attendees per week, compared with the baseline | Report 2 |
| Cost of meetings | Value in money | Working hours in meetings x average hourly cost ($40) | Report 2 |
| Number of meetings | Fewer unnecessary meetings | Meetings per week, compared with the baseline | Report 1 |
| Action items completed on time | Meetings lead to results | Share of action items marked Done by their due date | Action Items table |
| Overdue action items | Follow-through gaps | Open action items past their due date | Report 3 |
| Adoption | People actually use the product | Share of new meetings that go through the full flow (form, recording, analysis) | Meetings table |

### What "good value" looks like

The targets below are proposals for discussion, to be confirmed after the baseline is collected:

- At least **80%** of meetings have a stated goal.
- Average meeting score of **70 or higher**.
- **15% fewer** working hours in meetings than the baseline.
- At least **70%** of action items completed on time.
