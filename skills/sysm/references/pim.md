# sysm PIM Reference — calendar, reminders, contacts, notes

## calendar

### calendar calendars
`sysm calendar calendars [--details] [--json]`
- `--details` Show detailed calendar information

### calendar today
`sysm calendar today [--json] [--show-calendar]`
- `--show-calendar` Show calendar name for each event

### calendar week
`sysm calendar week [--json] [--show-calendar]`

### calendar list
`sysm calendar list <date> [--end-date <end-date>] [--calendar <calendar>] [--json] [--show-calendar]`
- `<date>` Natural language or ISO: 'tomorrow', 'next monday', '2025-01-15'
- `--end-date` End date for range query

### calendar search
`sysm calendar search <query> [--days <days>] [--json] [--show-calendar]`
- `--days` Days ahead to search (default: 30)

### calendar show
`sysm calendar show <event-id> [--json]`
- Get event-id from `sysm calendar today --json`

### calendar add
`sysm calendar add <title> --start <start> [--end <end>] [--calendar <calendar>] [--location <location>] [--latitude <lat>] [--longitude <lon>] [--radius <radius>] [--attendee <email>] [--notes <notes>] [--url <url>] [--all-day] [--repeats <freq>] [--repeat-interval <n>] [--repeat-until <date>] [--repeat-count <n>] [--remind <minutes>] [--show-as <status>] [--json]`
- `--start` Required. Natural language: 'tomorrow 2pm', 'next monday 10:00'
- `--end` Defaults to 1 hour after start
- `--repeats` daily, weekly, monthly, yearly
- `--remind` Minutes before event (can repeat: --remind 15 --remind 60)
- `--show-as` busy, free, tentative, unavailable

### calendar edit
`sysm calendar edit [<title>] [--id <id>] [--new-title <title>] [--start <start>] [--end <end>] [--future]`
- Finds the event by title, or exactly by `--id` from `--json` output
- `--future` For a recurring event, change this occurrence and all later ones
- Without `--future`, a recurring event changes only the occurrence named in the prompt

### calendar delete
`sysm calendar delete [<title>] [--id <id>] [--future] [--force]`
- `--id` Delete exactly this event, instead of matching a title
- `--future` For a recurring event, delete this occurrence and all later ones
- The confirmation names the occurrence it will delete, so check it before answering

### calendar validate
`sysm calendar validate [--json]`
- Reports events whose dates fall outside 2000–2100 and cannot reach it: a lone
  out-of-range date, a series beginning after the range, or one whose rule ran
  out before it
- A series that still recurs today is not reported, so contact birthdays
  carried in ordinary calendars stay out of the results

### calendar attendees
`sysm calendar attendees <event-id> [--json]`

### calendar rename
`sysm calendar rename <name> --new-name <new-name>`

### calendar set-color
`sysm calendar set-color <name> --color <color>`
- `--color` Hex: #FF5733 or FF5733

### calendar conflicts
`sysm calendar conflicts --start <start> [--end <end>] [--calendar <calendar>] [--json]`

### calendar import
`sysm calendar import <file> --calendar <calendar> [--dry-run]`
- `<file>` Path to .ics file
- Events the calendar already holds are skipped, and the summary reports how
  many, so re-importing a file does not double the calendar
- A repeating event arrives as one series with its repeat rule
- Times carrying a `TZID` are read in that zone; a floating time is read in the
  Mac's zone
- `EXDATE` and per-occurrence overrides are not read, so an occurrence deleted
  from a series comes back

### calendar export
`sysm calendar export <calendar> [--start <start>] [--end <end>] [--output <output>]`
- Defaults: 1 year ago → 1 year ahead, stdout
- A repeating event is written once with its `RRULE`; an occurrence edited on
  its own is written as a `RECURRENCE-ID` exception

---

## reminders

### reminders lists
`sysm reminders lists [--json]`

### reminders list
`sysm reminders list [<list-name>] [--all] [--details] [--json]`
- `--all` Include completed reminders
- `--details` Show notes, URL, recurrence

### reminders search
`sysm reminders search <query> [--list <list>] [--all] [--priority <priority>] [--overdue] [--has-alarms] [--recurring] [--tag <tag>] [--details] [--json]`
- `--priority` high, medium, low, none
- `--tag` Hashtag format, e.g., work

### reminders today
`sysm reminders today [--json]`

### reminders add
`sysm reminders add <task> [--list <list>] [--start <start>] [--due <due>] [--priority <priority>] [--notes <notes>] [--url <url>] [--repeats <freq>] [--repeat-interval <n>] [--repeat-days-of-month <days>] [--repeat-months <months>] [--repeat-positions <positions>] [--repeat-until <date>] [--repeat-count <n>] [--alarm <minutes>] [--location <name>] [--location-latitude <lat>] [--location-longitude <lon>] [--location-radius <m>] [--location-trigger <enter|leave>] [--tags <tags>] [--quiet] [--json]`
- `--list` Default: Reminders
- `--priority` 1=high, 5=medium, 9=low, 0=none
- `--start` / `--due` Natural language: 'tomorrow 9am', 'next monday', 'YYYY-MM-DD'
- A due date given without a time creates an all-day reminder; add a time to
  get a timed one
- `--repeats` daily, weekly, monthly, yearly
- `--alarm` Minutes before the due date; repeat the option for several alarms
- `--location` Location-based alarm; pair with `--location-trigger enter|leave`
- `--tags` Space-separated, e.g. `--tags "work urgent"`

### reminders edit
`sysm reminders edit <id> [--title <title>] [--start <start>] [--due <due>] [--priority <priority>] [--notes <notes>] [--alarm <minutes>] [--json]`
- `--alarm` Replaces all existing alarms (repeatable)

### reminders move
`sysm reminders move <id> --to <list> [--json]`

### reminders delete
`sysm reminders delete <id> [--force]`

### reminders complete
`sysm reminders complete [<name>] [--id <id>]`
- `<name>` Exact title of an incomplete reminder
- `--id` Complete exactly this reminder, from `sysm reminders list --json`
- When several incomplete reminders share the title, the command completes
  none of them and lists each candidate with its ID and list; re-run with
  `--id`

### reminders add-tags / remove-tags
`sysm reminders add-tags <id> <tags>... [--json]`
`sysm reminders remove-tags <id> <tags>... [--json]`

### reminders list-tags
`sysm reminders list-tags [--list <list>] [--all] [--json]`

### reminders create-list / delete-list
`sysm reminders create-list <name>`
`sysm reminders delete-list <name> [--force]`

### reminders validate
`sysm reminders validate [--json]`

### reminders track / untrack / tracked / done / dismiss / new / sync
```bash
sysm reminders track <name> [--project <project>]   # Link to project tracking
sysm reminders untrack <name>
sysm reminders tracked [--json]
sysm reminders done <name>
sysm reminders dismiss <name>
sysm reminders new [--json]                          # Create via interactive prompt
sysm reminders sync                                  # Force iCloud sync
```

---

## contacts

### contacts search
`sysm contacts search [<query>] [--company <company>] [--job-title <job-title>] [--email <email>] [--json]`
- All filters are optional and combinable

### contacts show
`sysm contacts show <identifier> [--json]`

### contacts add
`sysm contacts add [--first-name <name>] [--last-name <name>] [--organization <org>] [--job-title <title>] [--email <email>]... [--phone <phone>]... [--notes <notes>] [--url <url>] [--birthday <date>] [--json]`
- `--birthday` YYYY-MM-DD or MM-DD

### contacts edit
`sysm contacts edit <identifier> [--first-name] [--last-name] [--organization] [--job-title] [--email]... [--phone]... [--notes] [--json]`
- `--email` / `--phone` Replace existing values

### contacts delete
`sysm contacts delete <identifier> [--force]`

### contacts email / phone
`sysm contacts email <query> [--json]`   # Quick lookup of email
`sysm contacts phone <query> [--json]`   # Quick lookup of phone

### contacts birthdays
`sysm contacts birthdays [--days <days>] [--json]`
- `--days` Look-ahead days (default: 30)

### contacts groups list
`sysm contacts groups list [--json]`

### contacts photo
`sysm contacts photo set <identifier> --image <path>`
`sysm contacts photo get <identifier> --output <path>`
`sysm contacts photo remove <identifier>`

### contacts duplicates / merge
`sysm contacts duplicates [--similarity <0.0-1.0>] [--json]`  # default: 0.8
`sysm contacts merge <primary-id> <duplicate-id> [--json]`    # keeps primary, deletes duplicate

---

## notes

### notes list
`sysm notes list [--folder <folder>] [--json]`
- Default folder: Notes

### notes count
`sysm notes count [--folder <folder>] [--json]`

### notes show
`sysm notes show <note-id> [--raw] [--json]`
- `--raw` Show raw HTML instead of plain text

### notes search
`sysm notes search <query> [--folder <folder>] [--body] [--show-content] [--json]`
- `--body` Search in note body, not just title

### notes folders
`sysm notes folders [--json]`

### notes create
`sysm notes create <title> [--body <body>] [--folder <folder>] [--stdin] [--html] [--from-markdown <file>]`
- `--stdin` Read body from stdin: `echo "content" | sysm notes create "Title" --stdin`
- `--html` Treat the body as HTML rather than plain text
- `--from-markdown` Read structured Notes Markdown from a file, or `-` for stdin
- Without `--folder`, the note lands in the default account's default folder

### notes edit
`sysm notes edit <id> [--title <title>] [--body <body>] [--stdin]`

### notes append
`sysm notes append <note-id> <content>`

### notes delete
`sysm notes delete <id> [--force]`

### notes move
`sysm notes move <note-id> <to-folder>`

### notes duplicate
`sysm notes duplicate <note-id> [--name <name>] [--json]`

### notes create-folder / delete-folder
`sysm notes create-folder <name>`
`sysm notes delete-folder <name> [--force]`

### notes import
`sysm notes import [--folder <folder>] [--output <output>] [--exclude <pattern>]... [--delete] [--dry-run] [--json]`
- Exports Notes to markdown files
- `--output` Default: ~/_inbox
- `--delete` Remove from Notes after export
- `--dry-run` Preview without importing

### notes check
`sysm notes check [--folder <folder>] [--output <output>] [--json]`
- Checks for new/changed notes for tracking
