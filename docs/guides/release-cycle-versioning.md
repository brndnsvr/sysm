# Release-Cycle Versioning

sysm versions use four numeric fields:

```text
GENERATION.YY.QUARTER.REVISION
```

- `GENERATION` identifies the current product and UI generation.
- `YY` is the two-digit release year.
- `QUARTER` is `1` through `4`.
- `REVISION` begins at `0` for the quarterly base release and increments for every later release in that cycle.

For example, `1.26.3.0` is the base Q3 2026 release for generation 1. A subsequent fix in the same cycle is `1.26.3.1`; revision numbers remain monotonic and may grow beyond a single digit. The next quarterly base is `1.26.4.0`.

This is a calendar-based release-cycle policy, not Semantic Versioning. Breaking changes and migration requirements must be called out explicitly in release notes instead of being inferred from a major-version increment.

## Commands

Start a quarterly base release by supplying the full version:

```bash
./scripts/bump-version.sh 1.26.3.0
```

Increment the revision within the current cycle:

```bash
./scripts/bump-version.sh revision
```

The version validator rejects missing fields, invalid quarters, leading-zero revisions, and generation `0`.
