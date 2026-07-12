# Secure Secret Input

`sysm` never accepts Slack tokens, PDF passwords, Keychain values, or CalDAV
app-specific passwords as command-line values. Literal secrets in command arguments
can be exposed through shell history, process inspection, and execution telemetry.

## Interactive Use

Interactive commands read from `/dev/tty` with echo disabled:

```bash
sysm slack auth --configure
sysm calendar caldav-auth --apple-id you@icloud.com --configure
sysm pdf encrypt input.pdf --output encrypted.pdf
sysm pdf decrypt encrypted.pdf --output decrypted.pdf
sysm keychain set service account
```

Add `--user-password-prompt` to `pdf encrypt` when the encrypted PDF should also
require a separate password to open it.

## Automation With Standard Input

Select a command-specific `--*-stdin` flag and pipe the value from a protected
producer. `sysm` refuses stdin when it is a terminal, so this mode cannot silently
echo an interactively typed secret.

```bash
security find-generic-password -w -s sysm-slack-token |
  sysm slack auth --token-stdin

security find-generic-password -w -s source-secret |
  sysm keychain set destination-service destination-account --value-stdin
```

Only one secret may consume stdin in a command. PDF encryption with both owner and
user passwords should use separate inherited descriptors.

## Automation With Inherited Descriptors

Descriptor values are non-secret numbers, so they may safely appear in argv. Each
descriptor must be `3` or greater, non-terminal, and dedicated to one secret.

In zsh, values can come directly from Keychain without appearing in the `sysm`
command line:

```bash
sysm pdf encrypt input.pdf \
  --owner-password-fd 3 \
  --user-password-fd 4 \
  --output encrypted.pdf \
  3< <(security find-generic-password -w -s pdf-owner-password) \
  4< <(security find-generic-password -w -s pdf-user-password)
```

Secret input is limited to 64 KiB, must be valid UTF-8, and cannot be empty or
contain NUL bytes. The reader removes one trailing `LF` or `CRLF` produced by common
line-oriented secret tools. Environment-variable and password-file inputs are not
supported because they introduce separate metadata or persistence risks.
