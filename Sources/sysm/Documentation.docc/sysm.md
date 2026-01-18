# ``sysm``

Unified CLI for the Apple ecosystem on macOS.

## Overview

sysm provides a single command-line interface to interact with macOS system services including Calendar, Reminders, Notes, Contacts, Mail, Messages, Safari, Music, Photos, Finder tags, Spotlight, Shortcuts, Focus modes, and Weather.

### Key Features

- **Personal Information Management**: Calendar events, reminders, notes, and contacts
- **Communication**: Mail and iMessage integration
- **Media**: Music playback control and Photos library access
- **System Integration**: Finder tags, Spotlight search, Focus modes
- **Automation**: Multi-step workflows, scheduled tasks, and custom plugins
- **Weather**: Current conditions and forecasts via WeatherKit or Open-Meteo

### Quick Start

```bash
# Install
make install

# View today's calendar
sysm calendar today

# Check upcoming reminders
sysm reminders today

# Search contacts
sysm contacts search "John"

# Get weather
sysm weather current "San Francisco"
```

## Topics

### Services

- ``CalendarService``
- ``ReminderService``
- ``ContactsService``
- ``NotesService``
- ``MailService``
- ``MessagesService``
- ``SafariService``
- ``MusicService``
- ``PhotosService``
- ``TagsService``
- ``SpotlightService``
- ``ShortcutsService``
- ``FocusService``
- ``WeatherService``
- ``WeatherKitService``

### Automation

- ``WorkflowEngine``
- ``PluginManager``
- ``ScheduleCommand``

### Models

- ``CalendarEvent``
- ``Reminder``
- ``Contact``
- ``Note``
- ``CurrentWeather``
- ``Forecast``

### Utilities

- ``DateParser``
- ``DateFormatters``
- ``AppleScriptRunner``
- ``OutputFormatter``
