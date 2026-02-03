# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) for the sysm project. ADRs document significant architectural decisions, their context, and their consequences.

## What are ADRs?

Architecture Decision Records capture important architectural decisions made during the project's evolution. Each record explains:

- **What** decision was made
- **Why** it was made (context and motivation)
- **How** it affects the codebase (consequences)
- **When** it was decided (status and date)

ADRs help new contributors understand the project's design philosophy and provide historical context for future refactoring decisions.

## ADR Format

Each ADR follows this standard structure:

```markdown
# [Number]. [Title]

**Status:** [Accepted | Superseded | Deprecated]
**Date:** YYYY-MM-DD

## Context

What is the issue we're trying to solve? What factors are driving this decision?

## Decision

What did we decide to do and how does it work?

## Consequences

What are the positive and negative outcomes of this decision?
```

## Records

| Number | Title | Status | Date |
|--------|-------|--------|------|
| [0001](0001-actor-vs-struct.md) | Actor vs Struct for Service Concurrency | Accepted | 2025-02-02 |
| [0002](0002-applescript-vs-framework.md) | AppleScript vs Native Framework Selection | Accepted | 2025-02-02 |
| [0003](0003-service-container-di.md) | ServiceContainer Dependency Injection Pattern | Accepted | 2025-02-02 |

## Creating New ADRs

When making a significant architectural decision:

1. **Number it sequentially** - Use the next available number (0004, 0005, etc.)
2. **Use a descriptive title** - Focus on the decision, not the problem
3. **Include all sections** - Context, Decision, Consequences are required
4. **Reference code** - Link to specific files and line numbers when relevant
5. **Update the index** - Add your ADR to the table above
6. **Mark the status** - Start with "Accepted", update later if superseded

## Guidelines

- Write for future maintainers who weren't involved in the original decision
- Be specific about trade-offs and alternatives considered
- Include code examples where they clarify the decision
- Reference related tasks, commits, or issues for traceability
- Keep ADRs immutable - if a decision changes, create a new ADR and mark the old one as superseded
