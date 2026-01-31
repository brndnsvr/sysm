# Task Tracking System

Lightweight markdown-based project tracking for sysm.

## Quick Start

All tasks live in `TASKS.md`. Open it, find your lane, get to work.

## Task IDs

- Format: `T-XXX` (T-001, T-002, etc.)
- **Never renumber existing IDs** - they may be referenced in commits, branches, or notes
- Next available ID is at the top of `TASKS.md`

## Lanes

| Lane | Purpose | Limit |
|------|---------|-------|
| **Inbox** | Quick captures, unsorted ideas | Triage regularly |
| **Inflight** | Active work in progress | ~3 tasks max |
| **Next** | Ready to start, or blocked | No limit |
| **Backlog** | Prioritized future work (top = highest) | No limit |
| **Done** | Completed tasks | Archive monthly |

## Task Format

### Full Task
```markdown
### T-XXX: Title

> **Created:** YYYY-MM-DD | **Updated:** YYYY-MM-DD
> **Labels:** infra, automation, bug, feature, refactor, docs

Description here.

- [ ] Subtask one
- [x] Subtask two (completed)

#### Log
- YYYY-MM-DD: Note about progress, decisions, blockers
```

### Minimal Task
```markdown
### T-XXX: Title

> **Created:** YYYY-MM-DD

One-liner description.
```

### Blocked Task
```markdown
### T-XXX: Title

> **Created:** YYYY-MM-DD | **Updated:** YYYY-MM-DD
> **Blocked-by:** T-YYY or "waiting on vendor response"

Description.
```

## Labels

| Label | Use For |
|-------|---------|
| `bug` | Defects, unexpected behavior |
| `feature` | New functionality |
| `refactor` | Code improvements, no behavior change |
| `docs` | Documentation updates |
| `infra` | Build, CI/CD, tooling |
| `automation` | Scripts, workflows, automation |

## Conventions

### When to Create Tasks
- Work expected to take >15 minutes
- Anything worth tracking or referencing later
- Multi-step work that might be interrupted

### When NOT to Create Tasks
- Quick fixes (<15 min, obvious scope)
- Trivial changes you'll complete immediately

### Git Integration
- Reference task IDs in commits: `T-001: Add service registration`
- Branch naming: `t-001-service-registration`

### Maintenance
- **Triage Inbox** regularly - move to proper lanes or delete
- **Update dates** when modifying tasks
- **Add log entries** for decisions, blockers, context worth preserving
- **Archive Done** monthly to `archive/YYYY-MM.md`

## Archive

Completed tasks are archived monthly to `archive/YYYY-MM.md`.

To archive:
1. Cut the Done section contents
2. Create/append to `archive/YYYY-MM.md`
3. Add archive header if new file:
   ```markdown
   # Archived Tasks - YYYY-MM

   Tasks completed in Month YYYY.
   ```
