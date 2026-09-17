# sysm System Reference — system, network, bluetooth, capture, notify, speak, timemachine, weather, geo, focus, appstore

## system

### system info
`sysm system info [--json]`
- CPU, RAM, OS version, hardware model

### system battery
`sysm system battery [--json]`
- Charge level, charging state, cycle count

### system uptime
`sysm system uptime [--json]`

### system memory
`sysm system memory [--json]`
- Physical and virtual memory usage

### system disk
`sysm system disk [--path <path>] [--json]`
- `--path` Mount point to check (default: /)

---

## network

### network status
`sysm network status [--json]`
- Overall connectivity, default interface

### network wifi
`sysm network wifi [--json]`
- Current WiFi SSID, BSSID, signal strength
- Without Location permission macOS withholds the SSID and BSSID; the command
  still reports the rest, with no SSID, rather than failing

### network scan
`sysm network scan [--json]`
- Scan for available WiFi networks

### network interfaces
`sysm network interfaces [--json]`
- All network interfaces with IP/MAC addresses

### network dns
`sysm network dns [--json]`
- Current DNS servers

### network ping
`sysm network ping <host> [--count <n>] [--json]`
- `--count` Packets (default: 4)

---

## bluetooth

### bluetooth status
`sysm bluetooth status [--json]`

### bluetooth devices
`sysm bluetooth devices [--json]`
- Lists paired/connected Bluetooth devices

---

## capture
*Requires Screen Recording permission in System Settings.*

### capture screen
`sysm capture screen [--output <path>] [--display <n>]`
- `--output` Default: ~/Desktop/screenshot.png
- `--display` Display number for multi-monitor setups

### capture window
`sysm capture window [--output <path>]`
- Prompts to click a window

### capture area
`sysm capture area [--output <path>] [--rect <x,y,w,h>]`
- Omit `--rect` for interactive selection

---

## notify

### notify send
`sysm notify send <title> <body> [--subtitle <subtitle>] [--sound]`

### notify schedule
`sysm notify schedule <title> <body> --at <datetime> [--subtitle <subtitle>] [--sound]`
- `--at` Natural language: 'tomorrow 3pm', '2024-12-25 09:00'

### notify list
`sysm notify list [--json]`
- Lists pending scheduled notifications

### notify remove
`sysm notify remove [<identifier>] [--all]`
- `--all` Remove all pending notifications

---

## speak
*Text-to-speech via NSSpeechSynthesizer/AVSpeechSynthesizer.*

### speak text
`sysm speak text <text> [--voice <voice>] [--rate <wpm>]`
- `--rate` Words per minute (default ~175)

### speak voices
`sysm speak voices [--json] [--language <lang>]`
- `--language` e.g., en_US, fr_FR

### speak save
`sysm speak save <text> --output <path> [--voice <voice>] [--rate <wpm>]`
- `--output` Must be .aiff

---

## timemachine

### timemachine status
`sysm timemachine status [--json]`

### timemachine backups
`sysm timemachine backups [--json]`
- Lists available backup snapshots

### timemachine start
`sysm timemachine start`
- Triggers an immediate backup

---

## weather
*Defaults to WeatherKit (requires code-signed binary). Use `--backend open-meteo` if WeatherKit fails — it's free and works without signing.*

### weather current
`sysm weather current <location> [--backend <backend>] [--json]`
- `<location>` City name or 'lat,lon'
- `--backend` weatherkit (default) or open-meteo

### weather forecast
`sysm weather forecast <location> [--days <n>] [--backend <backend>] [--json]`
- `--days` 1–16 (default: 7)

### weather hourly
`sysm weather hourly <location> [--hours <n>] [--backend <backend>] [--json]`
- `--hours` 1–168 (default: 24)

### weather detailed
`sysm weather detailed <location> [--backend <backend>]`
- Full conditions: wind, humidity, UV, visibility, etc.

### weather alerts
`sysm weather alerts <location> [--backend <backend>]`
- Alerts need WeatherKit. With `--backend open-meteo` the command reports that
  alerts are unavailable rather than answering "no active alerts"

---

## geo
*Geocoding via MapKit/CoreLocation.*

### geo lookup
`sysm geo lookup <address> [--json]`
- Forward geocoding: address → lat/lon

### geo reverse
`sysm geo reverse <latitude> <longitude> [--json]`
- Reverse geocoding: lat/lon → address

### geo distance
`sysm geo distance <from> <to> [--json]`
- `<from>` / `<to>` 'lat,lon' format e.g., '40.7128,-74.0060'
- Returns great-circle distance

---

## focus
*Focus modes and Do Not Disturb.*

### focus status
`sysm focus status [--json]`
- Names the active Focus mode, or reports that none is on

### focus list
`sysm focus list [--json]`
- Lists the Focus modes configured on this Mac

### focus activate
`sysm focus activate <name>`
- `<name>` A configured mode, e.g. Work, Personal, Sleep

### focus off
`sysm focus off`
- Turns off whichever mode is active

### focus dnd
`sysm focus dnd <state>`
- `<state>` on or off

---

## appstore
*Mac App Store management. Requires `mas` (`brew install mas`).*

### appstore list
`sysm appstore list [--json]`
- Installed App Store apps with their IDs and versions

### appstore outdated
`sysm appstore outdated [--json]`
- Apps with an update available

### appstore search
`sysm appstore search <query> [--json]`

### appstore update
`sysm appstore update [<app-id>]`
- Updates every outdated app when the ID is omitted
