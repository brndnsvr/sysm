# Configuration

Configure sysm behavior through environment variables.

## Overview

sysm supports configuration through environment variables for customizing paths and behavior without modifying the binary.

## Environment Variables

### SYSM_TRIGGER_PATH

Override the default trigger file path used by the reminder tracking system.

**Default**: `~/dayai/_dayai/TRIGGER.md`

```bash
# Set custom trigger path
export SYSM_TRIGGER_PATH="/path/to/custom/TRIGGER.md"

# Or use inline
SYSM_TRIGGER_PATH="/tmp/trigger.md" sysm reminders sync
```

## Weather Backends

The weather command supports multiple backends configured via the `--backend` flag:

| Backend | Description | Requirements |
|---------|-------------|--------------|
| `weatherkit` | Apple WeatherKit (default) | Code signing with WeatherKit entitlement |
| `open-meteo` | Open-Meteo free API | None |

```bash
# Use WeatherKit (default)
sysm weather current "Paris"

# Use Open-Meteo
sysm weather current "Paris" --backend open-meteo
```

## Paths

sysm uses the following default paths:

| Purpose | Path |
|---------|------|
| Workflows | `~/.sysm/workflows/` |
| Plugins | `~/.sysm/plugins/` |
| Schedules | `~/.sysm/schedules/` |
| Cache | `~/.sysm/cache/` |

## See Also

- <doc:GettingStarted>
- <doc:Security>
