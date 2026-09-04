# Kit — household life admin

Calendar, inbox, meals, groceries, appointments, and what's on this week
for a Brisbane couple with no kids. Alias **Kit**. Fork of
`lifestyle/family-assistant`: school off, product price-watch left to
Scout.

Needs **Google Calendar + Gmail in OneCLI** or it is only a notes file.
Connect at http://127.0.0.1:10254 (Apps → Gmail / Google Calendar). Same
Google account for both.

## Stamp it

```bash
ncl groups create --template lifestyle/family-assistant --name Kit --timezone Australia/Brisbane
ncl groups config update --id <group-id> --assistant-name Kit --provider opencode
ncl groups restart --id <group-id>
```

Wire the orchestrator destination as `kit`.

Scheduled tasks stamp **paused**. On first chat, Kit confirms times then
resumes:

- Daily morning brief (default 07:00)
- Weekly week-ahead (default Sunday 18:00)
- Weekly memory tidy (recommend on)

Grocery-day meal planning is created only when they name a shop day.
Product watches stay on Scout — do not resume a price-watch task here.
