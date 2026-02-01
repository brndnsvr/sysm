# Project Tasks

> **Next ID:** T-005

## Inbox

Quick captures, triage to other lanes regularly.

## Inflight

Active work. Limit to ~3 tasks for focus.

## Next

Ready to start or blocked.

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

### T-002: Decouple nested types from service protocols

> **Created:** 2025-01-31
> **Updated:** 2025-01-31
> **Labels:** refactor

Moved nested types to standalone models in `/Models/` for proper protocol abstraction:

**PhotosServiceProtocol:**
- [x] `PhotosService.PhotoAlbum` → `PhotoAlbum` in `Models/PhotoAlbum.swift`
- [x] `PhotosService.PhotoAsset` → `PhotoAsset` in `Models/PhotoAsset.swift`
- [x] `PhotosService.AssetMetadata` → `AssetMetadata` in `Models/PhotoAsset.swift`

**WorkflowEngineProtocol:**
- [x] `WorkflowEngine.Workflow` → `Workflow` in `Models/Workflow.swift`
- [x] `WorkflowEngine.Step` → `WorkflowStep` in `Models/Workflow.swift`
- [x] `WorkflowEngine.WorkflowResult` → `WorkflowResult` in `Models/Workflow.swift`
- [x] `WorkflowEngine.ValidationResult` → `WorkflowValidationResult` in `Models/Workflow.swift`

Protocols now reference standalone types. Services updated to use external models.

---

### T-001: Register utility services in ServiceContainer

> **Created:** 2025-01-31
> **Updated:** 2025-01-31
> **Labels:** refactor, infra

Registered 7 utility services in ServiceContainer with protocols for dependency injection and testability:

- [x] `ScriptRunner` → `ScriptRunnerProtocol`
- [x] `AppleScriptRunner` → `AppleScriptRunnerProtocol` (static methods converted to instance, deprecated wrappers added)
- [x] `LaunchdService` → `LaunchdServiceProtocol`
- [x] `CacheService` → `CacheServiceProtocol` (`@unchecked Sendable` for class)
- [x] `MarkdownExporter` → `MarkdownExporterProtocol` (API refactored: outputDir moved to method params)
- [x] `TriggerService` → `TriggerServiceProtocol` (`@unchecked Sendable` for class)
- [x] `DateParser` → `DateParserProtocol` (static methods converted to instance, deprecated wrappers added)

**Protocols created:** `Sources/SysmCore/Protocols/{ScriptRunner,AppleScriptRunner,Launchd,Cache,MarkdownExporter,Trigger,DateParser}Protocol.swift`

**ServiceContainer updated:** Factory, cache, accessor, and reset for each service.

**Commands updated:** All call sites now use `Services.xxx()` pattern.
