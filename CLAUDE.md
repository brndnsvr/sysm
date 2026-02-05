# sysm - Claude Code Instructions

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

This project uses a markdown-based task system in `.task-tracking/TASKS.md`.

**Quick Reference:**
- All tasks: `.task-tracking/TASKS.md`
- Task IDs: T-001, T-002, etc. (never renumber)
- Next ID: Top of TASKS.md

**Workflow:**
- Check Inflight section before starting work
- Create tasks for non-trivial work (>15 min or worth tracking)
- Move tasks between sections as work progresses
- Add log entries for decisions, blockers, or progress worth noting
- Update the Updated date when modifying a task
- Reference task IDs in commits: `T-XXX: description`
- Branch naming: `t-XXX-short-description`

**Labels:** bug, feature, refactor, docs, infra, automation

**Triage Inbox regularly** - move items to proper lanes or delete.
