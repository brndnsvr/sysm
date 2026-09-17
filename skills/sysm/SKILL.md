---
name: sysm
description: Use sysm — a locally installed macOS CLI tool — to interact with Apple ecosystem services from the terminal. ALWAYS use this skill when the user wants to work with Calendar, Reminders, Notes, Contacts, Mail, Messages, Safari, Music, Photos, Finder, Spotlight, Tags, Focus, Weather, Clipboard, System info, Notifications, Screen Capture, Bluetooth, Network, Speech, Images, PDFs, Audio, AV recording, Vision, NLP, Keychain, Virtual Machines, Shortcuts, App Store, Podcasts, Books, Time Machine, Slack, Outlook, or any other macOS/Apple service. Trigger even if the user doesn't mention "sysm" — if they ask to "check my calendar", "send a message to X", "OCR this PDF", "set volume to 50", or any task that maps to a macOS service, use this skill. Proactively reach for sysm rather than reimplementing what it already does.
effort: high
---

# sysm — macOS Apple Ecosystem CLI

`sysm` is installed at `/opt/homebrew/bin/sysm` (v1.26.4.0). It wraps Apple frameworks, AppleScript, and system APIs into a unified CLI.

## How to Use This Skill

1. Identify which domain the user's request falls into (table below)
2. Read the corresponding reference file for exact command syntax and options
3. Construct and run the command via the Bash tool
4. If a command needs an ID (e.g., event ID, message ID), use `--json` on a list/search command first to find it

## Domain → Reference File

| Domain | Commands | Reference |
|--------|----------|-----------|
| PIM | calendar, reminders, contacts, notes | `references/pim.md` |
| Communication | mail, messages, safari, outlook, slack | `references/communication.md` |
| Media | music, photos, podcasts, books, audio, av | `references/media.md` |
| Files & Data | finder, tags, spotlight, disk, pdf, image, vision, language, keychain | `references/files.md` |
| System | system, network, bluetooth, capture, notify, speak, timemachine, weather, geo, focus, appstore | `references/system.md` |
| Automation | shortcuts, workflow, schedule, plugin, exec, ai | `references/automation.md` |
| Virtual Machines | vm | `references/vm.md` |
| Meta | update, completions | `references/meta.md` |

## Key Patterns

### Running commands
Use the Bash tool. Most commands are safe to run directly. Destructive commands (`delete`, `trash`, `send`) that have a `--force` flag will prompt for confirmation unless `--force` is passed — only add `--force` if the user has confirmed intent.

### Machine-readable output
Nearly every command supports `--json`. Use it when:
- You need to find an ID to pass to a subsequent command
- The user wants to pipe output into something else
- You need to extract a specific field

```bash
# Find an event ID, then show details
sysm calendar today --json | jq '.[] | {id, title}'
sysm calendar show <event-id>
```

### Selecting by name, and ambiguity
Commands that act on an item by title refuse to guess when several match. `sysm reminders complete "Pay rent"` reports every incomplete reminder with that title and its list, and you re-run with `--id`. `calendar delete` and `calendar edit` take `--id` the same way, and name the occurrence they will act on before a recurring event changes.

### Piping stdin
Some commands read from stdin when no argument is given:
```bash
echo "Buy milk" | sysm clipboard copy
cat notes.txt | sysm notes create "My Note" --stdin
```

### IDs
Many commands require an ID obtained from a prior list/search:
- Calendar events: `sysm calendar today --json` → `.id`
- Reminders: `sysm reminders list --json` → `.id`
- Mail messages: `sysm mail inbox --json` → `.id`
- Photos assets: `sysm photos recent --json` → `.id`
- Contacts: `sysm contacts search "name" --json` → `.identifier`

## Permissions

If a command fails with a permissions error, the user needs to grant access in **System Settings → Privacy & Security**:

| Permission needed | Commands |
|------------------|----------|
| Calendars | calendar, reminders |
| Contacts | contacts |
| Full Disk Access | mail, safari |
| Photos | photos |
| Automation | notes, music, messages, shortcuts |
| Microphone | av record |
| Screen Recording | capture |
| Location | network wifi (SSID), weather with WeatherKit |

## Weather Backend Note

`sysm weather` defaults to WeatherKit (requires signed binary). If WeatherKit fails, add `--backend open-meteo` — it works without signing and is free. Open-Meteo carries no alert feed, so `weather alerts --backend open-meteo` reports that alerts need WeatherKit rather than answering "no alerts".

## Common Multi-Step Workflows

### Find and act on a specific item
```bash
# Find the reminder, then complete exactly the one you meant
sysm reminders search "groceries" --json
sysm reminders complete --id <reminder-id>
```

### Capture and process
```bash
# Screenshot then OCR
sysm capture screen --output /tmp/shot.png
sysm image ocr /tmp/shot.png
```

### Record and transcribe
```bash
sysm av record mic --output output.m4a --duration 30
sysm av transcribe output.m4a --timestamps
```

### VM with shared directory
```bash
sysm vm create dev --os linux --cpus 4 --memory 4096 --disk 20
sysm vm share add dev --path ~/projects --tag hostfs
sysm vm start dev --iso ~/Downloads/ubuntu.iso
```
