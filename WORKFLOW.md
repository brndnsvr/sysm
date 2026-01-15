# Workflow

Order of operations for features, fixes, and improvements.

---

## 1. Capture

- [ ] Add item to TODO file or create new one
- [ ] Tag with priority (Critical/High/Medium/Low)
- [ ] Note affected files

---

## 2. Understand

- [ ] Read related source files
- [ ] Trace code paths
- [ ] Check for existing patterns to follow
- [ ] Identify test coverage gaps

---

## 3. Plan

- [ ] Write plan in `.claude/plans/`
- [ ] List files to modify
- [ ] List files to create
- [ ] Define verification steps

---

## 4. Implement

- [ ] Create/modify files per plan
- [ ] Follow existing code style
- [ ] Add/update tests
- [ ] Run `swift build`

---

## 5. Verify

- [ ] Run `swift test`
- [ ] Manual test affected commands
- [ ] Check edge cases
- [ ] Confirm no regressions

---

## 6. Review

- [ ] Self-review diff
- [ ] Check for:
  - [ ] Input validation
  - [ ] Error handling
  - [ ] Code duplication
  - [ ] Magic numbers/strings

---

## 7. Commit

- [ ] Stage changes
- [ ] Write clear commit message
- [ ] Run `git status` to verify

---

## 8. Update

- [ ] Mark TODO item complete
- [ ] Update progress table
- [ ] Note any follow-up items discovered

---

## Quick Reference

```bash
# Build
swift build

# Test
swift test

# Install
cp .build/release/sysm ~/bin/

# Run specific command
sysm <command> <subcommand> [options]
```
