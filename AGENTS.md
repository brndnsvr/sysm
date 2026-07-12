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

**Platform:** macOS 13+ (swift-tools-version 5.9). Upgrading to macOS 15+ / swift-tools-version 6.0 requires Swift 6 strict concurrency migration across all actors and models.

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

Tasks for this repo live in Plane on `plane-goa` (workspace `wzrd`, project
"bss sysm"). Repo-local markdown task trackers are retired — do not recreate them or mint new local task numbers.

**Workflow:**
- Read and update items in Plane (Plane UI or the `wzrd-plane-bridge` skill)
- Create a Plane item for non-trivial work (>15 min or worth tracking)
- Reference the Plane task ID in commits: `<PLANE-ID>: description`
- Branch naming: `<plane-id>-short-description`
- Legacy local task IDs survive only in historical git history — never assign new ones
