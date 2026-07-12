# Implementation Plan: Centralized Secure Secret Input

**Task:** `SYSM-78`
**Branch:** `SYSM-78-secure-secret-input`
**Implementation:** completed on the branch; awaiting PR validation
**Evidence scan:** `f4564e7b-b16c-4d36-bba8-509c879bc2a4`
**Scan revision:** `121b08bc6dfb312b9af6bc06f6914275b7f2c143`
**Scan manifest SHA-256:** `d05647b890ef00af195d3f706aac16bfea946bfab26d9dd2db68ddcc1526a966`

## Selected Design And Constraints

Implement the scan portfolio's typed-boundary option for the six process-argument
findings. A shared `SecretInput` abstraction will be the only supported path from a
CLI command to a credential-bearing service call.

The boundary must enforce these invariants:

- Secret bytes never enter supported process arguments, help examples, diagnostic
  output, environment variables, or a reusable password file.
- Interactive input comes from `/dev/tty` with echo disabled and terminal state
  restored on success, error, interruption, and suspension.
- Automation explicitly selects non-terminal stdin or an inherited descriptor.
- Reads are bounded to 64 KiB, reject empty input and NUL bytes, and remove only one
  trailing `LF` or `CRLF` record terminator.
- Errors identify the input channel and failure class but never include secret data.
- Only one secret may consume stdin in a single invocation; additional secrets must
  use a prompt or distinct inherited descriptors.

Use Darwin `readpassphrase` with `RPP_REQUIRE_TTY` for prompt mode. The macOS 27 SDK
documents that it reads from `/dev/tty`, disables echo by default, restores terminal
state on failure and handled signals, and fails when no controlling terminal exists.
For inherited descriptors, accept descriptor numbers `>= 3`, duplicate before
reading, and close only the duplicate.

This work removes cross-process and shell-history exposure. It does not promise
perfect in-process zeroization: current service protocols require Swift `String`,
which may copy storage. Temporary mutable buffers should still be cleared promptly.

## Source Revision And Drift Check

The completed scan is bound to revision
`121b08bc6dfb312b9af6bc06f6914275b7f2c143` and snapshot digest
`codex-security-snapshot/v1:sha256:2b4f6a8b168a16c3a6ee84a9e2f000472ecf725ac34a77de86a869e0f7abee41`.
This branch starts from `d5411c54ca5348d4ed1f34ae85bb94dff2e3d6c5`.

The two revisions are not in a direct ancestor relationship, so source drift is
formally present. A path-scoped diff is empty for all five affected command files,
`CLI.swift`, and the existing Keychain integration tests. The reviewed input
boundaries therefore remain materially identical. Re-run the drift check before
implementation if the branch is rebased or updated.

## Affected Components

| Component | Planned responsibility |
| --- | --- |
| `Sources/SysmCore/Utilities/SecretInput.swift` | Source enum, bounded readers, no-echo prompt, redacted errors, buffer cleanup |
| `Sources/sysm/CLI.swift` or a focused CLI helper | Convert parsed transport flags into one valid `SecretInput` request |
| `Sources/sysm/Commands/Slack/SlackAuth.swift` | Prompt, stdin, and FD token acquisition |
| `Sources/sysm/Commands/PDF/PDFDecrypt.swift` | Prompt, stdin, and FD decryption password acquisition |
| `Sources/sysm/Commands/PDF/PDFEncrypt.swift` | Independent owner/user secret sources with stdin-conflict rejection |
| `Sources/sysm/Commands/Keychain/KeychainSet.swift` | Prompt, stdin, and FD value acquisition |
| `Sources/sysm/Commands/Calendar/CalendarCaldavAuth.swift` | Prompt, stdin, and FD app-password acquisition |
| `Tests/SysmCoreTests` and `Tests/IntegrationTests` | Resolver, parsing, service handoff, and process-boundary regression coverage |
| DocC, guides, completions, release notes | Safe examples and explicit breaking-change guidance |

The downstream Slack, PDF, Keychain, and CalDAV service protocols remain unchanged
in this branch. The control belongs at the CLI-to-service boundary.

## Ordered Work Packages

1. **Land the shared boundary.** Add `SecretInputSource`, `SecretInputRequest`,
   `SecretInputReader`, and `SecretInputError`. Implement prompt, stdin, and inherited
   FD sources with bounded reads and redacted failures.
2. **Add a test seam.** Let command coordination receive a secret reader and the
   existing service protocol so tests can verify exact handoff without changing a
   user's real Slack or CalDAV Keychain entries.
3. **Migrate single-secret commands.** Move Slack, PDF decrypt, Keychain set, and
   CalDAV auth to the shared resolver.
4. **Migrate PDF encrypt.** Resolve required owner and optional user passwords
   independently; reject two stdin consumers and ambiguous source selections.
5. **Remove value-bearing options.** Delete supported `--token <value>`,
   `--password <value>`, `--owner-password <value>`, `--user-password <value>`,
   `--value <value>`, and `--app-password <value>` forms. Do not retain a hidden
   compatibility option: it would preserve the vulnerable argv path.
6. **Update user surfaces.** Regenerate help/completions and replace every unsafe
   README, DocC, guide, test, and release example.
7. **Re-run security proof.** Execute the six original PoCs plus focused unit and
   integration suites, then record a finding-by-finding closure receipt.

## Compatibility And Migration

The proposed command contract is:

| Command | Interactive | Automation |
| --- | --- | --- |
| `slack auth` | `--configure` prompts for token | `--token-stdin` or `--token-fd N` |
| `pdf decrypt` | password prompt by default | `--password-stdin` or `--password-fd N` |
| `pdf encrypt` | owner prompt by default; `--user-password-prompt` requests a second prompt | matching `--owner-password-stdin/fd` and `--user-password-stdin/fd` selectors |
| `keychain set` | value prompt by default | `--value-stdin` or `--value-fd N` |
| `calendar caldav-auth` | `--configure` prompts after `--apple-id` | `--app-password-stdin` or `--app-password-fd N` |

This is an intentional CLI break. Release notes must show safe before/after examples
without printing literal secrets. Unknown legacy options must fail without reflecting
the following sentinel value into stderr. We should not claim the six findings fixed
until value-bearing options are absent and process-table probes pass.

Environment-variable and password-file modes are out of scope for the first release:
environment values remain process metadata, while password files add persistence and
permission-management obligations. A future Keychain-reference input may be useful
but is not needed to close these findings.

## Tactical Protections During Migration

- Change all documentation and shell-completion descriptions in the same commit as
  each command migration.
- Never log source selection together with a value, byte count, prefix, or hash.
- Validate Slack token shape only after secure acquisition and keep validation
  messages generic.
- Preserve `--status` and `--remove` paths without reading any input.
- Make non-interactive default behavior fail closed with a concise instruction to
  select stdin or an inherited descriptor.
- Reject terminal stdin when a `--*-stdin` flag is selected; prompt mode owns TTY
  input and must not silently fall back.

## Tests And Security Validation

1. Unit-test every source: successful exact-byte delivery, empty input, `CRLF`, NUL,
   over-limit data, invalid or closed FD, interrupted prompt, and terminal restoration.
2. Table-test selector precedence and mutual exclusion for all five commands,
   including PDF's two-secret combinations.
3. Inject mock service protocols and prove the exact acquired secret reaches the
   intended service once while status/remove paths read nothing.
4. Update `KeychainIntegrationTests` to pipe the test value instead of passing
   `--value`; keep cleanup scoped to its UUID service name.
5. Use disposable PDFs to prove prompt/stdin/FD modes preserve encryption and
   decryption behavior.
6. Run help and error-output snapshots with sentinel secrets; no sentinel may appear
   in stdout or stderr.
7. Re-run each finding's process-table probe with the secure mode. Keep the child
   blocked before sending secret bytes, inspect argv, send the bytes, and verify the
   legitimate operation completes.
8. Run `swift test`, `swift build -c release`, and `git diff --check` before review.

Finding closure matrix:

| Finding | Required proof |
| --- | --- |
| Slack token argv exposure (`occ_3e04eeb21a20a0729eb28805`) | stdin/FD token absent from argv; prompt and status behavior preserved |
| PDF decrypt password argv exposure (`occ_e8135a1cc05279d788600f6b`) | secure input absent from argv; disposable PDF decrypts |
| PDF owner password argv exposure (`occ_9d8aa863902dcdfde52b5e71`) | owner secret absent from argv; permissions remain correct |
| PDF user password argv exposure (`occ_c1685d6604a85e4a8f1f583b`) | optional user secret absent from argv; omission still works |
| Keychain value argv exposure (`occ_c9c73b3214eaa25b84f04bd2`) | piped/FD value absent from argv; set/get round trip passes |
| CalDAV app-password argv exposure (`occ_34f2fc617c60ad8e50aa8470`) | mock handoff receives value; status/remove behavior preserved |

## Performance And Resource Benchmarks

The boundary adds one bounded read and no extra process or network hop. Measure
interactive prompt startup and stdin/FD acquisition over 1,000 disposable iterations;
the acceptance threshold is no statistically meaningful regression beyond normal CLI
startup variance. Confirm peak resident memory remains bounded when input exceeds the
64 KiB limit and that rejected input is not retained by long-lived helpers.

## Rollout And Rollback

Ship all five command migrations together so documentation has one coherent secret
input model. Call out the breaking syntax in the release notes and Homebrew release
notes. A pre-release build should be exercised from an interactive terminal and from
shell automation using pipes and inherited descriptors.

Rollback is a source revert plus documentation rollback. Do not restore secret-bearing
argv options as an emergency compatibility switch; if a command-specific regression
appears, disable that operation with a safe error while retaining the secure reader.

## Acceptance Criteria

- All six original findings fail to reproduce through every supported command path.
- No supported CLI option accepts a secret value as its next argv element.
- Interactive prompts require a controlling TTY, disable echo, and restore terminal
  state on all tested exits.
- Stdin and inherited-FD modes are explicit, bounded, mutually validated, and covered
  by legitimate-operation tests.
- Help, completions, docs, diagnostics, and release examples contain no literal-secret
  invocation pattern.
- Full tests and release build pass, with no changes to the two unrelated Photos and
  Notes P3 findings.

## Open Decisions

- Flag names are finalized in the command-contract table above.
- Keychain-item references are deferred; stdin and inherited descriptors cover this
  remediation without adding another lookup contract.
- This branch does not bump or publish a release. The next release must communicate
  the intentional syntax break and use the normal versioning workflow.
