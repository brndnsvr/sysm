# 0004. Mail Mailbox Listing via AppleScript

**Status:** Accepted
**Date:** 2026-02-05

## Context

The mail service needs to enumerate mailboxes across all configured accounts to support operations like listing, moving messages, and displaying folder structure. Three approaches were evaluated:

1. **AppleScript** - `tell application "Mail"` with direct mailbox enumeration
2. **JXA (JavaScript for Automation)** - Same scripting bridge, different language
3. **Shell** - Using `mdls`, `sqlite3`, or other CLI tools against Mail's data store

Performance testing showed AppleScript mailbox listing completes in ~0.3s compared to ~2.2s for JXA (the next fastest alternative), making AppleScript approximately **7.4x faster** for this operation.

## Decision

**Keep AppleScript for mailbox enumeration** in `MailService.getMailboxes()`.

The performance advantage is significant enough to justify the trade-offs of AppleScript (string-based, no compile-time safety). Since the mail service already uses AppleScript for all other operations (see ADR-0002), this maintains consistency within the service while delivering the best performance.

The implementation iterates mailboxes per-account and collects name, unread count, message count, and full path in a single pass.

## Consequences

### Positive

1. **Fast enumeration** - ~0.3s for typical mailbox listings vs ~2.2s for JXA
2. **Consistent approach** - All mail operations use the same AppleScript infrastructure
3. **Single IPC call** - One `osascript` invocation collects all mailbox data

### Negative

1. **String parsing** - Results use delimiter-based serialization (`|||` and `###`)
2. **No type safety** - AppleScript property access has no compile-time checking
3. **Mail.app dependency** - Requires Mail to be running and Automation permission granted

## Related

- [ADR-0002](0002-applescript-vs-framework.md) - AppleScript vs Native Framework Selection
- `Sources/SysmCore/Services/MailService.swift` - `getMailboxes()` implementation
