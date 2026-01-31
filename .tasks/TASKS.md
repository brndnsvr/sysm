# Project Tasks

> **Next ID:** T-005

## Inbox

Quick captures, triage to other lanes regularly.

## Inflight

Active work. Limit to ~3 tasks for focus.

## Next

Ready to start or blocked.

### T-001: Register utility services in ServiceContainer

> **Created:** 2025-01-31
> **Labels:** refactor, infra

Several utility services exist but aren't registered in ServiceContainer, reducing testability:

- [ ] `CacheService`
- [ ] `DateParser`
- [ ] `LaunchdService`
- [ ] `TriggerService`
- [ ] `ScriptRunner`
- [ ] `AppleScriptRunner`
- [ ] `MarkdownExporter`

Either create protocols and register for testability, or document as internal utilities not intended for DI.

**Files:** `Sources/SysmCore/Services/ServiceContainer.swift`, each utility service file

---

### T-002: Decouple nested types from service protocols

> **Created:** 2025-01-31
> **Labels:** refactor

Protocol return types are coupled to concrete implementations via nested types:

**PhotosServiceProtocol:**
- [ ] Move `PhotosService.PhotoAlbum` to `/Models/`
- [ ] Move `PhotosService.PhotoAsset` to `/Models/`

**WorkflowEngineProtocol:**
- [ ] Move `WorkflowEngine.Workflow` to `/Models/`
- [ ] Move `WorkflowEngine.Step` to `/Models/`

Update protocols to reference standalone types.

---

### T-003: Evaluate WeatherKitService concurrency model

> **Created:** 2025-01-31
> **Labels:** refactor

WeatherKitService uses `@MainActor` on a struct, inconsistent with other framework-based services that use actors.

- [ ] Review current implementation
- [ ] Evaluate refactoring to actor pattern like CalendarService, ContactsService
- [ ] Document decision if keeping current approach

**File:** `Sources/SysmCore/Services/WeatherKitService.swift`

## Backlog

Prioritized future work (top = highest priority).

### T-004: Add Architecture Decision Records (ADRs)

> **Created:** 2025-01-31
> **Labels:** docs

Document key architectural decisions:

- [ ] Actor vs Struct services - why framework-based use actors, AppleScript-based use structs
- [ ] AppleScript vs Framework - decision criteria for each approach
- [ ] ServiceContainer pattern - factory-based DI with lazy caching

Create `/docs/adr/` directory with markdown files following ADR format.

## Done

Completed tasks. Archive monthly or when this section gets long.
