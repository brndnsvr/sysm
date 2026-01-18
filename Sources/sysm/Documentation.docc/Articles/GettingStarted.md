# Getting Started with sysm

Learn how to install sysm and use its core features.

## Overview

sysm is a unified command-line interface for interacting with macOS system services. This guide walks you through installation, permissions setup, and basic usage.

## Installation

### Building from Source

```bash
git clone https://github.com/brndnsvr/sysm.git
cd sysm
make install
```

This installs the binary to `~/bin/sysm`.

### With Code Signing (WeatherKit Support)

For full functionality including Apple WeatherKit:

```bash
make install-notarized
```

Requirements:
- Apple Developer Program membership
- Developer ID Application certificate
- App ID with WeatherKit capability

## Permissions

sysm requires macOS permissions for each service it accesses. Grant these in **System Settings > Privacy & Security**:

| Permission | Commands |
|------------|----------|
| Calendar | `calendar`, `reminders` |
| Contacts | `contacts` |
| Full Disk Access | `mail`, `safari` |
| Photos | `photos` |
| Automation | `notes`, `music`, `messages`, `shortcuts` |

## Basic Usage

### Calendar

```bash
# View today's events
sysm calendar today

# View this week
sysm calendar week

# Add an event
sysm calendar add "Team Meeting" --start "tomorrow 10am" --calendar "Work"
```

### Reminders

```bash
# View today's reminders
sysm reminders today

# Add a reminder
sysm reminders add "Buy groceries" --list "Shopping" --due "tomorrow"

# Complete a reminder
sysm reminders complete "Buy groceries"
```

### Contacts

```bash
# Search contacts
sysm contacts search "John Smith"

# View upcoming birthdays
sysm contacts birthdays
```

### Weather

```bash
# Current conditions
sysm weather current "New York"

# 7-day forecast
sysm weather forecast "London"

# Use Open-Meteo (no signing required)
sysm weather current "Paris" --backend open-meteo
```

## Output Formats

Most commands support JSON output for scripting:

```bash
sysm calendar today --json
sysm contacts search "Smith" --json | jq '.[] | .email'
```

## Automation

### Workflows

Create multi-step automations with YAML:

```bash
# Create a workflow
sysm workflow new morning-routine

# Run a workflow
sysm workflow run morning-routine --verbose

# Validate syntax
sysm workflow validate morning-routine
```

### Scheduling

Schedule recurring tasks:

```bash
# Daily at 8am
sysm schedule add morning --cron "0 8 * * *" --cmd "sysm workflow run morning.yaml"

# Every hour
sysm schedule add sync --every 3600 --cmd "sysm reminders sync"
```

## Next Steps

- Explore the command reference: `sysm --help`
- Read about <doc:Security>
- Check the [ROADMAP](https://github.com/brndnsvr/sysm/blob/main/ROADMAP.md) for detailed feature documentation
