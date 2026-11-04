# Successful Meetings

Successful Meetings helps organizations hold fewer, better meetings. Every meeting gets a clear goal, gets a written summary afterwards, and produces tracked action items. Management gets the data to see which meetings are worth their cost.

## The problem

- **Meetings without a clear goal:** when nobody states what a meeting should achieve, there is no way to tell whether it succeeded.
- **Too many hours lost:** people are invited to meetings they don't need to attend. A single 30-minute meeting with 4 attendees at $40 per hour costs $80, and the cost multiplies across an organization.

## How it works

1. A new meeting is created in **Google Calendar**. If it has at least the minimum number of attendees set in the settings table, it is recorded in the **Supabase** database.
2. The inviter gets an email with a link to the meeting's **Goals** page in the web app, built with **Lovable**. There they state the meeting's purpose and expected outcomes and can add action items.
3. Meetings are not recorded or transcribed. After the meeting ends, the inviter gets a link to the **Summary** page and fills in what was discussed and decided, plus action items, each with an accountable person and a due date.
4. Until the summary is submitted, the inviter gets a **daily reminder**.
5. Each person with open action items gets a **daily email** with a link to the **My action items** page, where they can mark items as Done.
6. Managers can pull **reports** on demand: meetings held in a date range, working hours spent in meetings, overdue action items and meetings whose summary is still pending.

The automations run in **Make**. Everyone signs in to the app with their Google account.

## Documentation

The full PRD in Hebrew is [Successful-Meetings-PRD-he.docx](Successful-Meetings-PRD-he.docx), in the main directory.

The English PRD pages are in the [`PRD`](PRD) folder:

- [Page 1: The Problem](PRD/successful-meetings-page1.md)
- [Page 2: Solution and Architecture](PRD/successful-meetings-page2.md)
- [Page 3: Development Plan and Success Metrics](PRD/successful-meetings-page3.md)

## License

Licensed under the [Apache License 2.0](LICENSE).
