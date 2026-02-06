# Project Tasks

> **Next ID:** T-009

## Inbox

Quick captures, triage to other lanes regularly.

## Inflight

Active work. Limit to ~3 tasks for focus.

### T-008: Fix --account Filter and Add accountName to MailMessage

> **Created:** 2026-02-05
> **Updated:** 2026-02-05
> **Labels:** bug, feature

Fix two blockers preventing per-account email processing:

- [x] Fix `--account` AppleScript syntax: `inbox of (first account whose name is ...)` → `mailbox "INBOX" of account "..."`
- [x] Add `accountName` field to `MailMessage` model
- [x] Update 3 AppleScript scripts (inbox, unread, search) to fetch `name of account of mailbox of msg`
- [x] Update 3 parsers for new field

**Files Modified:**
- `Sources/SysmCore/Services/MailService.swift` - Fixed 3 inboxSource constructions, added accountName to model/scripts/parsers

---

### T-007: Fix Mail Service Known Limitations

> **Created:** 2026-02-05
> **Updated:** 2026-02-05
> **Labels:** feature, docs

Fix 3 known limitations in the mail service:

- [x] Add `messageId` (RFC 822 Message-ID) to MailMessage and MailMessageDetail models
- [x] Update 4 AppleScript scripts to fetch `message id of msg`
- [x] Update 4 Swift parsers for new field positions
- [x] Add Message-ID display in MailRead text output
- [x] Add `maxContentLength` param to getMessage() protocol + implementation
- [x] Add `--max-content` flag to MailRead CLI
- [x] Create ADR-0004 for mailbox AppleScript performance documentation
- [x] Update ADR README index

**Files Modified:**
- `Sources/SysmCore/Services/MailService.swift` - Models, 4 scripts, 4 parsers, truncation, doc comment
- `Sources/SysmCore/Protocols/MailServiceProtocol.swift` - New param + protocol extension
- `Sources/sysm/Commands/Mail/MailRead.swift` - Message-ID display, --max-content flag
- `docs/adr/0004-mail-mailbox-applescript-performance.md` - New ADR
- `docs/adr/README.md` - Index update

## Next

Ready to start or blocked.

## Backlog

Prioritized future work (top = highest priority).

### T-006: Fix DateParser "next [weekday]" Bug

> **Created:** 2025-02-04
> **Updated:** 2025-02-04
> **Labels:** bug, parser

DateParser incorrectly calculates "next [weekday]" dates, off by one day.

**Issue:**
- Input: "next friday" (when today is Tuesday Feb 4)
- Expected: Friday, Feb 7
- Actual: Thursday, Feb 6

**Impact:**
- Affects calendar event creation with relative weekday dates
- Unit tests passed but didn't catch this edge case
- Other date formats work correctly (ISO, slash dates, "tomorrow", "today")

**Location:**
- `Sources/SysmCore/Services/DateParser.swift` around line 182 (weekday calculation logic)

**Testing:**
- Reproduced via: `sysm calendar add "Test" --start "next friday 10am"`
- Need additional test cases for relative weekday parsing

## Done

Completed tasks. Archive monthly or when this section gets long.

### T-005: Eliminate Dead Code (Test-Driven)

> **Created:** 2025-02-02
> **Updated:** 2025-02-04
> **Labels:** refactor, cleanup, test

Systematic dead code elimination with comprehensive test coverage:

- [x] Write tests for AppleScriptRunner replacement methods
- [x] Write tests for DateParser replacement methods
- [x] Write tests for TriggerService
- [x] Write tests for MarkdownExporter
- [x] Remove deprecated static methods (AppleScriptRunner: 3, DateParser: 4)
- [x] Evaluate and potentially remove TriggerService (single-use feature)
- [x] Evaluate and potentially remove MarkdownExporter (minimal usage)
- [x] Verify all removals don't break builds or tests
- [x] Validate test suite on Xcode-enabled machine
- [x] Real-world functional testing of refactored services

**Outcome:**
- ✅ Removed 7 deprecated static wrapper methods
- ✅ Zero usages confirmed via code review agents
- ✅ Build verified successful
- ✅ Created comprehensive test suites (4 files, 73 tests)
- ✅ All tests passing (validated 2025-02-04 on Xcode machine)
- ✅ Real-world validation completed (2025-02-04 on dev machine)
- ℹ️ TriggerService and MarkdownExporter retained per user decision

**Real-World Testing Results:**
- **DateParser**: Tested via `sysm calendar add` with natural language dates
  - ✅ "tomorrow 2pm" → Correct (Feb 5, 2026)
  - ⚠️  "next friday" → Bug found (off by 1 day) - tracked in T-006
  - ✅ "2/15 3pm" → Correct (Feb 15, 2026)
- **TriggerService**: Tested via `sysm reminders sync`
  - ✅ Successfully executed, proper empty state handling
- **MarkdownExporter**: Tested via `sysm notes import --dry-run`
  - ✅ Dry-run mode works correctly, proper JSON output
- **AppleScriptRunner**: Implicitly validated (used by all commands)

**Files Modified:**
- `Sources/SysmCore/Services/AppleScriptRunner.swift` - Removed 3 deprecated static methods
- `Sources/SysmCore/Services/DateParser.swift` - Removed 4 deprecated static methods
- `Package.swift` - Added SysmCoreTests target
- `Tests/SysmCoreTests/Services/AppleScriptRunnerTests.swift` - 17 tests
- `Tests/SysmCoreTests/Services/DateParserTests.swift` - 28 tests
- `Tests/SysmCoreTests/Services/TriggerServiceTests.swift` - 11 tests
- `Tests/SysmCoreTests/Services/MarkdownExporterTests.swift` - 17 tests

---

### T-004: Add Architecture Decision Records (ADRs)

> **Created:** 2025-01-31
> **Updated:** 2025-02-02
> **Labels:** docs

Created ADRs documenting three key architectural patterns:

- [x] Actor vs Struct services - framework-based use actors, AppleScript-based use structs
- [x] AppleScript vs Framework - decision criteria for each approach
- [x] ServiceContainer pattern - factory-based DI with lazy caching

**Files Created:**
- `/docs/adr/README.md` - ADR index and guidelines
- `/docs/adr/0001-actor-vs-struct.md` - Actor vs struct concurrency decision
- `/docs/adr/0002-applescript-vs-framework.md` - Framework selection criteria
- `/docs/adr/0003-service-container-di.md` - ServiceContainer DI pattern

---

### T-003: Evaluate WeatherKitService concurrency model

> **Created:** 2025-01-31
> **Updated:** 2025-02-01
> **Labels:** refactor

Converted WeatherKitService from struct to actor for consistency with other framework-based services.

**Analysis:**
- WeatherKitService held a `CLGeocoder` instance with internal mutable state
- Used `@preconcurrency import CoreLocation` to suppress Sendable warnings (hiding a real concern)
- CalendarService and ContactsService both use actors for similar framework-based services

**Resolution:**
- [x] Converted `struct WeatherKitService` → `actor WeatherKitService`
- [x] Removed `@preconcurrency` import workaround
- [x] Added documentation explaining the actor choice

WeatherService (Open-Meteo) kept as struct since it's truly stateless (only uses URLSession.shared).

---

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
