# A1: Meeting registration (Make scenario)

When a new meeting is created in Google Calendar, A1 adds an item for it to the **Meetings** board in monday.com.

## Flow

1. **Google Calendar: Watch Events** (trigger): picks up newly created events in the calendar.
2. **Filter: Only meetings with attendees**: skips personal calendar blocks that have no invitees.
3. **monday.com: Create an Item**: adds the meeting to the Meetings board.

## Meetings board in monday.com

Create a board named **Meetings** with these columns. The item name holds the meeting title.

| Column | monday column type | Value from Google Calendar | Filled by |
| --- | --- | --- | --- |
| Item name (Meeting title) | Name | Event title | A1 |
| MeetingID | Text | Event ID: unique and automatic; A2 to A4 use it to find the meeting | A1 |
| Scheduled date | Date | Start date | A1 |
| Start time | Text | Start, `YYYY-MM-DD HH:mm` | A1 |
| End time | Text | End, `YYYY-MM-DD HH:mm` | A1 |
| Duration (minutes) | Numbers | End minus start | A1 |
| Inviter | Email | Organizer's email | A1 |
| Attendees | Long text | Attendee emails, comma-separated | A1 |
| Summary document | Link | Empty | A2 |
| Transcript path | Link | Empty | A3 |
| Score | Numbers | Empty | A4 |

Attendees are stored as emails, not as monday People, because many attendees may not be monday users.

## Setup

1. In monday.com, create the **Meetings** board with the columns above.
2. In Make, create a new scenario, open the **...** menu at the bottom, choose **Import Blueprint**, and select `A1-meeting-registration.blueprint.json`.
3. Open the **Google Calendar** module: connect your Google account and choose the calendar to watch.
4. Open the **monday.com** module: connect your monday account, then select the **Meetings** board and a group. Make now lists the board's columns. Map each one as in the table above; the formulas are already in the blueprint and can be copied from it if a field comes up empty.
5. Click **Run once**, then create a test meeting with at least one attendee in Google Calendar. A new item should appear on the board.
6. Set the schedule (for example, every 15 minutes) and turn the scenario on.

## Known limits

- **All-day events** have no start or end time, so those columns and the duration stay empty.
- **Recurring meetings** are recorded once, when the series is created, not once per occurrence.
- **Edits** made to a meeting after it is created (new time, new attendees) are not updated on the board.
