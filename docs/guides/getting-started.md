# Getting Started with sysm

Welcome to sysm! This guide will help you get up and running quickly.

## Table of Contents

- [What is sysm?](#what-is-sysm)
- [Installation](#installation)
- [First Steps](#first-steps)
- [Basic Usage](#basic-usage)
- [Common Workflows](#common-workflows)
- [Next Steps](#next-steps)

## What is sysm?

sysm is a unified CLI for the Apple ecosystem on macOS. It lets you:

- Manage Calendar events and Reminders from the terminal
- Search Contacts and check upcoming birthdays
- Read Mail, send messages, and manage drafts
- Access Notes, create and organize content
- Send iMessages and SMS
- Control Safari (bookmarks, reading list, tabs)
- Manage Photos albums and search your library
- Control Music playback
- Tag files with Finder tags
- Search with Spotlight
- Run Shortcuts
- Check Weather
- And much more!

**Why use sysm?**
- **Terminal productivity**: Stay in your terminal workflow
- **Automation**: Script and automate Apple services
- **Consistency**: Unified interface across all services
- **JSON output**: Easy integration with other tools
- **Fast**: Efficient native and AppleScript-based operations

## Installation

### Quick Install (Homebrew)

Coming soon!

```bash
brew tap brndnsvr/tap
brew install sysm
```

### From Source

```bash
# Clone the repository
git clone https://github.com/brndnsvr/sysm.git
cd sysm

# Build and install to ~/bin
make install

# Add ~/bin to PATH if not already (add to ~/.zshrc or ~/.bashrc)
export PATH="$HOME/bin:$PATH"

# Verify installation
sysm --version
```

**Install location options:**
```bash
# Install to ~/bin (default, no sudo)
make install

# Install to /usr/local/bin (requires sudo)
make install PREFIX=/usr/local/bin

# Install with code signing (for WeatherKit)
make install-notarized
```

### Requirements

- **macOS 13.0+** (macOS 15+ recommended)
- **Xcode 15+** or Swift 5.9+ toolchain
- **Apple Developer Account** (only for WeatherKit features)

## First Steps

### 1. Verify Installation

```bash
sysm --version
sysm --help
```

### 2. Grant Permissions

sysm needs permissions to access macOS services. You'll be prompted on first use, or grant manually:

**System Settings** → **Privacy & Security** → Enable for Terminal:
- **Calendars** - for calendar commands
- **Reminders** - for reminder commands
- **Contacts** - for contact commands
- **Photos** - for photo commands
- **Automation** - for Mail, Notes, Messages, etc.

**Quick permission setup:**
```bash
# These will prompt for permissions
sysm calendar today
sysm reminders today
sysm contacts search "test"
sysm photos albums
```

### 3. Try Basic Commands

```bash
# Calendar - see today's events
sysm calendar today

# Reminders - see what's due
sysm reminders today

# Contacts - search
sysm contacts search "John"

# Mail - check inbox
sysm mail inbox --limit 5

# Notes - list notes
sysm notes list

# Photos - list albums
sysm photos albums
```

## Basic Usage

### Command Structure

```bash
sysm <service> <subcommand> [arguments] [options]
```

**Examples:**
```bash
sysm calendar today
sysm calendar add "Meeting" --start "tomorrow 2pm"
sysm reminders add "Task" --list "Work"
sysm contacts search "Alice"
sysm mail inbox --limit 10
```

### Getting Help

```bash
# Top-level help
sysm --help

# Service-level help
sysm calendar --help

# Command-level help
sysm calendar add --help
```

### JSON Output

Most commands support `--json` for machine-readable output:

```bash
# Human-readable (default)
sysm calendar today

# JSON output
sysm calendar today --json

# Use with jq
sysm calendar today --json | jq '.[] | .title'
```

### Common Options

- `--json` - Output as JSON
- `--help` - Show help
- `--version` - Show version

## Common Workflows

### Calendar Management

```bash
# View events
sysm calendar today
sysm calendar week
sysm calendar list --calendar "Work"

# Add events
sysm calendar add "Team Meeting" --start "tomorrow 10am" --duration 60
sysm calendar add "Lunch" --start "today 12pm" --end "today 1pm" --location "Cafe"

# All-day events
sysm calendar add "Holiday" --start "2024-07-04" --all-day

# Recurring events
sysm calendar add "Standup" --start "tomorrow 9am" --duration 15 --recurrence "FREQ=DAILY;COUNT=5"

# Search events
sysm calendar search "meeting" --days 7

# Delete events
sysm calendar delete "Meeting"

# Edit events
sysm calendar edit "Meeting" --new-title "Team Sync"

# Export to iCalendar
sysm calendar export --calendar "Work" --start "2024-01-01" --end "2024-12-31" > work.ics
```

### Reminders & Tasks

```bash
# View reminders
sysm reminders today
sysm reminders list --list "Work"
sysm reminders list --all  # Include completed

# Add reminders
sysm reminders add "Buy groceries" --list "Personal"
sysm reminders add "Submit report" --list "Work" --due "Friday 5pm" --priority high

# Complete reminders
sysm reminders complete "Buy groceries"
sysm reminders done "Submit report"  # Alias

# Edit reminders
sysm reminders edit <id> --title "New title" --due "tomorrow"

# Delete reminders
sysm reminders delete <id>

# Manage lists
sysm reminders lists
sysm reminders create-list "Project X"
sysm reminders delete-list "Old List"
```

### Contact Management

```bash
# Search contacts
sysm contacts search "John"
sysm contacts search-email "example.com"
sysm contacts search-phone "555"

# Upcoming birthdays
sysm contacts birthdays --days 30

# View contact details
sysm contacts get <id>

# Create contact
sysm contacts create --given "Jane" --family "Doe" --email "jane@example.com"

# Update contact
sysm contacts update <id> --phone "+15551234567"

# Delete contact
sysm contacts delete <id>
```

### Mail Management

```bash
# View mail
sysm mail accounts
sysm mail inbox --limit 20
sysm mail inbox --account "Work" --limit 10
sysm mail unread --limit 5

# Search mail
sysm mail search "project update" --limit 10
sysm mail search --body "budget" --after "2024-01-01"

# Message operations
sysm mail mark <id> --read
sysm mail flag <id>
sysm mail delete <id>
sysm mail move <id> --to "Archive"

# Send mail
sysm mail send --to "alice@example.com" --subject "Hello" --body "Message"

# Reply and forward
sysm mail reply <id> --body "Thanks!" --send
sysm mail forward <id> --to "bob@example.com" --body "FYI"

# Drafts
sysm mail draft --to "alice@example.com" --subject "Draft"
sysm mail drafts
```

### Notes & Organization

```bash
# List notes
sysm notes list
sysm notes list --folder "Work"

# Create notes
sysm notes create "Meeting Notes" --folder "Work"
sysm notes create "Ideas" --body "Initial thoughts..." --folder "Personal"

# View and edit notes
sysm notes show <id>
sysm notes update <id> --title "New Title" --body "Updated content"
sysm notes append <id> --content "Additional notes"

# Search notes
sysm notes search "project" --folder "Work"
sysm notes search "budget" --search-body

# Organize
sysm notes move <id> --to-folder "Archive"
sysm notes duplicate <id> --new-name "Copy of Note"

# Manage folders
sysm notes folders
sysm notes create-folder "Project X"
sysm notes delete-folder "Old Folder"
```

### Photos & Media

```bash
# Albums
sysm photos albums
sysm photos album-photos <album-id> --limit 10

# Recent photos/videos
sysm photos recent --limit 20
sysm photos videos --limit 10

# Search
sysm photos search-date --from "2024-01-01" --to "2024-01-31"
sysm photos search-person "Alice"

# Export
sysm photos export <photo-id> --output ~/Downloads/photo.jpg

# Favorites
sysm photos favorite <photo-id>
```

## Next Steps

### Learn More

- **Architecture**: Read `docs/guides/architecture.md` to understand how sysm works
- **Troubleshooting**: See `docs/guides/troubleshooting.md` for common issues
- **Contributing**: See `CONTRIBUTING.md` to contribute code

### Automation Examples

**Daily standup report:**
```bash
#!/bin/bash
echo "Today's Schedule:"
sysm calendar today

echo -e "\nTasks Due Today:"
sysm reminders today

echo -e "\nUpcoming Birthdays:"
sysm contacts birthdays --days 7
```

**Backup calendar:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
sysm calendar export --start "2024-01-01" --end "2024-12-31" > "calendar-backup-$DATE.ics"
```

**Unread mail summary:**
```bash
#!/bin/bash
sysm mail unread --json | jq -r '.[] | "\(.subject) - \(.sender)"'
```

### Shell Completion

```bash
# Generate completions
sysm --generate-completion-script zsh > _sysm

# Install (Homebrew zsh)
sudo cp _sysm /opt/homebrew/share/zsh/site-functions/

# Install (system zsh)
sudo cp _sysm /usr/local/share/zsh/site-functions/

# Reload shell
exec zsh
```

### Integration with Other Tools

**With fzf (fuzzy finder):**
```bash
# Select and view an event
sysm calendar today --json | jq -r '.[] | .title' | fzf | xargs sysm calendar show

# Select and complete a reminder
sysm reminders today --json | jq -r '.[] | .title' | fzf | xargs sysm reminders complete
```

**With jq (JSON processor):**
```bash
# Extract specific fields
sysm contacts search "John" --json | jq -r '.[] | "\(.firstName) \(.lastName): \(.email[0])"'

# Filter and format
sysm calendar week --json | jq '.[] | select(.isAllDay == false) | .title'
```

### Join the Community

- **GitHub**: [github.com/brndnsvr/sysm](https://github.com/brndnsvr/sysm)
- **Issues**: Report bugs and request features
- **Discussions**: Ask questions and share ideas
- **Contributing**: Help improve sysm

## Tips & Tricks

1. **Use aliases** for common commands:
   ```bash
   alias today='sysm calendar today && sysm reminders today'
   alias inbox='sysm mail inbox --limit 10'
   ```

2. **Create scripts** for workflows (see automation examples above)

3. **Use JSON + jq** for advanced filtering and formatting

4. **Set up shell completion** for faster command entry

5. **Check `--help`** for each command to discover all options

Enjoy using sysm! 🚀
