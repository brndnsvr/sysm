# sysm - Codex Instructions

Unified CLI for Apple ecosystem integration on macOS.

## Project Overview

Swift CLI tool using ArgumentParser for command routing. Two-layer architecture:
- `SysmCore` (library) - Services, protocols, models, utilities
- `sysm` (executable) - CLI commands

## Build & Test

```bash
swift build              # Debug build
swift build -c release   # Release build
swift test               # Run tests
```

**Platform:** macOS 26+ (swift-tools-version 6.2, Swift 5 language mode). Moving to Swift 6 language mode requires the strict concurrency migration across all actors and models.

## Code Patterns

### Services
- Framework-based (EventKit, Contacts, Photos): Use **actors**
- AppleScript/shell-based: Use **structs**
- All services have protocols in `/Sources/SysmCore/Protocols/`
- Registered in `ServiceContainer` with factory pattern

### Commands
- Use `AsyncParsableCommand` for actor-based services
- Use `ParsableCommand` for struct-based services
- Support `--json` flag via `OutputFormatter.printJSON()`

### Error Handling
- Domain-specific enums conforming to `LocalizedError`
- Named `{Service}Error` (e.g., `CalendarError`, `ContactsError`)

## Project Task Tracking

Tasks for this repo live in Linear (workspace `wzrd-ai`, team `WZ`, project
"sysm"). Repo-local markdown task trackers are retired — do not recreate them or mint new local task numbers.

**Workflow:**
- Read and update items in Linear (Linear UI or the `linear-task` skill)
- Create a Linear issue for non-trivial work (>15 min or worth tracking)
- Reference the Linear issue key in commits: `WZ-<n>: description`
- Branch naming: `wz-<n>-short-description`
- Legacy local task IDs survive only in historical git history — never assign new ones
- Plane is retired (2026-09-05). Old `WZRD-*` / `SYSM-*` keys in git history stay
  as-is; resolve one to its Linear key with `linear_task.py resolve <key>`
