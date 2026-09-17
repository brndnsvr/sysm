# sysm Media Reference — music, photos, podcasts, books, audio, av

## music
*Controls Music.app via AppleScript.*

### music play / pause / next / prev
```bash
sysm music play
sysm music pause
sysm music next
sysm music prev
```

### music status
`sysm music status [--json]`
- Reports "stopped" without starting Music when the app is not running

### music volume
`sysm music volume <level>`
- `<level>` 0–100

### music shuffle
`sysm music shuffle [<state>]`
- `<state>` on / off (omit to show current)

### music repeat
`sysm music repeat [<mode>]`
- `<mode>` off / one / all (omit to show current)

### music playlists
`sysm music playlists [--json]`

### music play-playlist
`sysm music play-playlist <name>`

### music play-track
`sysm music play-track <query>`
- Searches and plays first match

### music play-next
`sysm music play-next <query>`
- Queues next (plays after current track)

### music search
`sysm music search <query> [--limit <limit>] [--json]`
- `--limit` Default: 20

---

## photos
*Requires Photos permission in System Settings.*

### photos albums list
`sysm photos albums list [--json]`

### photos list
`sysm photos list <album-id> [--limit <limit>] [--json]`
- `--limit` Default: 50
- Get album-id from `albums list --json`

### photos recent
`sysm photos recent [--limit <limit>] [--videos] [--json]`
- `--limit` Default: 20
- `--videos` Show videos instead of photos

### photos videos
`sysm photos videos [--album <album-id>] [--limit <limit>] [--json]`

### photos search
`sysm photos search --from <YYYY-MM-DD> --to <YYYY-MM-DD> [--limit <limit>] [--json]`
- Both `--from` and `--to` are required

### photos export
`sysm photos export <asset-id> [--output <path>] [--video]`
- `--video` Export as video (for video assets)
- Handles slow-motion and edited videos: the edited rendition is written when
  there is one, otherwise the original
- Replaces an existing file at the destination rather than failing

### photos metadata
`sysm photos metadata <asset-id> [--json]`

### photos edit
`sysm photos edit <asset-id> [--title <title>] [--description <description>]`

### photos people
`sysm photos people [<person-name>] [--json]`
- Omit name to list all people

### photos favorite / hidden
`sysm photos favorite <asset-id>... [--unfavorite]`
`sysm photos hidden <asset-id>... [--unhide]`

---

## podcasts
*Controls Podcasts.app via AppleScript.*

### podcasts shows
`sysm podcasts shows [--json]`

### podcasts episodes
`sysm podcasts episodes <show> [--json]`

### podcasts now-playing
`sysm podcasts now-playing [--json]`

### podcasts play / pause
`sysm podcasts play [<episode>]`   # Resumes if no episode given
`sysm podcasts pause`

---

## books
*Controls Books.app via AppleScript.*

### books list
`sysm books list [--json]`

### books collections
`sysm books collections [--json]`

---

## audio
*System-level audio control via CoreAudio.*

### audio volume (get)
`sysm audio volume [--json]`

### audio volume set
`sysm audio volume set <level> [--json]`
- `<level>` 0–100

### audio mute / unmute
`sysm audio mute [--json]`
`sysm audio unmute [--json]`

### audio devices
`sysm audio devices [--json]`
- Lists all input and output devices with their IDs

### audio input / output (get or set)
`sysm audio input [<device-name>] [--json]`
`sysm audio output [<device-name>] [--json]`
- Omit device name to show current default
- Provide device name to set as default

---

## av
*Audio/video recording and transcription via AVFoundation + Speech framework.*

### av devices
`sysm av devices [--json]`
- Lists available audio/video input devices

### av formats
`sysm av formats [--json]`
- Lists supported recording formats

### av record
`sysm av record [<shortcut>] [--output <path>] [--format <fmt>] [--duration <seconds>] [--device <device-id>] [--json]`
- `<shortcut>` teams / mic / all (convenient device presets)
- `--format` m4a, wav, aiff, caf (default: m4a)
- `--duration` Seconds to record; omit for interactive mode (press Enter to stop)
- `--device` Device ID from `av devices --json`

**Interactive mode** (no --duration):
```bash
sysm av record mic --output output.m4a
# Recording... Press Enter to stop, 'p' to pause/resume
```

### av transcribe
`sysm av transcribe <file> [--language <lang>] [--output <path>] [--timestamps] [--chunk-duration <seconds>] [--json]`
- `--language` e.g., en-US, ja-JP, es-ES (default: system language)
- `--timestamps` Include per-segment timestamps
- `--chunk-duration` Split long audio into chunks (default: 55s) — use for recordings >1 min
- `--output` Save transcription to file

**Common workflow:**
```bash
sysm av record mic --output meeting.m4a --duration 3600
sysm av transcribe meeting.m4a --timestamps --output meeting.txt
```
