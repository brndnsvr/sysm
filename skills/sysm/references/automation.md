# sysm Automation Reference — shortcuts, workflow, schedule, plugin, exec, ai

## shortcuts
*Runs Apple Shortcuts via `shortcuts` CLI.*

### shortcuts list
`sysm shortcuts list [--json]`

### shortcuts run
`sysm shortcuts run <name> [--input <text>] [--quiet]`
- `--input` Text to pass as input to the shortcut
- `--quiet` Suppress output

---

## workflow
*Multi-step automation via YAML workflow files stored in ~/.sysm/workflows/.*

### workflow run
`sysm workflow run <file> [--dry-run] [--verbose] [--json] [--workdir <dir>]`
- `--dry-run` Preview steps without executing
- `--workdir` Override workflow's working directory

### workflow validate
`sysm workflow validate <file> [--json] [--errors-only]`

### workflow list
`sysm workflow list [--dir <dir>] [--json] [--verbose]`
- `--dir` Default: ~/.sysm/workflows/

### workflow new
`sysm workflow new <name> [--dir <dir>] [--description <desc>] [--force] [--stdout]`
- `--stdout` Print YAML template to stdout instead of creating file

---

## schedule
*Cron-like scheduling backed by macOS launchd.*

### schedule add
`sysm schedule add <name> --cmd <command> [--cron <M H D Mo W>] [--every <seconds>] [--workdir <dir>] [--run-at-load] [--force] [--json]`
- `--cron` Standard cron format: '0 9 * * 1-5' (weekdays at 9am)
- `--every` Run every N seconds (alternative to cron)
- `--run-at-load` Also run immediately on creation

### schedule list
`sysm schedule list [--json] [--verbose]`

### schedule show
`sysm schedule show <name> [--json]`

### schedule enable / disable
`sysm schedule enable <name>`
`sysm schedule disable <name>`

### schedule run
`sysm schedule run <name>`
- Run a scheduled job immediately on demand

### schedule remove
`sysm schedule remove <name> [--force]`

### schedule logs
`sysm schedule logs <name> [--lines <n>] [--stderr] [--all] [--json]`
- `--lines` Default: 50
- `--stderr` Show stderr instead of stdout
- `--all` Show both

---

## plugin
*Extend sysm with custom shell/script commands.*

### plugin list
`sysm plugin list [--json] [--verbose]`

### plugin create
`sysm plugin create <name> [--description <desc>] [--force]`
- Creates a plugin scaffold in ~/.sysm/plugins/

### plugin install
`sysm plugin install <path> [--force] [--json]`
- `<path>` Path to plugin directory

### plugin remove
`sysm plugin remove <name>`

### plugin run
`sysm plugin run <plugin> <command> [<args>...] [--timeout <seconds>] [--json]`
- `--timeout` Default: 300

### plugin info
`sysm plugin info <name> [--json]`

---

## exec
*Run scripts inline or from files — bash, zsh, Python, AppleScript, or Swift.*

### exec run
`sysm exec run [<script-file>] [--code <code>] [--args <args>...] [--shell <shell>] [--python] [--applescript] [--swift] [--timeout <seconds>] [--stream] [--json] [--quiet]`
- `<script-file>` Path to script file (optional if using --code)
- `--code` Inline code: `sysm exec run --code "echo hello" --shell bash`
- `--python` Run as Python
- `--applescript` Run as AppleScript
- `--swift` Run as Swift script
- `--stream` Stream output in real-time
- `--timeout` Default: 300
- `--quiet` Suppress output, show only exit code

**Examples:**
```bash
# Inline bash
sysm exec run --code 'date +%Y-%m-%d' --shell bash

# Inline AppleScript
sysm exec run --applescript --code 'tell app "Finder" to get name of front window'

# Run a script file
sysm exec run ~/scripts/backup.py --python

# Pass arguments
sysm exec run ~/scripts/process.sh --args arg1 arg2
```

---

## ai
*On-device AI using Apple Intelligence (requires macOS 15.1+, Apple Silicon).*

### ai prompt
`sysm ai prompt <text> [--system <system-prompt>] [--json]`
- `--system` System prompt for context

### ai summarize
`sysm ai summarize <file> [--output <path>] [--chunk-size <chars>] [--json]`
- `--chunk-size` For large files (default: 4000 chars per chunk)
- `--output` Save to file

### ai extract-actions
`sysm ai extract-actions <file> [--output <path>] [--chunk-size <chars>] [--json]`
- Extracts action items from meeting notes, emails, etc.

### ai analyze
`sysm ai analyze <file> [--prompt <what-to-look-for>] [--output <path>] [--json]`
- `--prompt` Default: "Provide a detailed analysis of this text"

**Note:** All `ai` commands use on-device Apple Intelligence — no network calls, fully private.
