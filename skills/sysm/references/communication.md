# sysm Communication Reference — mail, messages, safari, outlook, slack

## mail

### mail inbox
`sysm mail inbox [--account <account>] [--limit <limit>] [--json]`
- `--limit` Default: 20

### mail unread
`sysm mail unread [--account <account>] [--limit <limit>] [--json]`
- `--limit` Default: 50

### mail read
`sysm mail read <id> [--max-content <chars>] [--json]`

### mail search
`sysm mail search [<query>] [--body <body>] [--after <YYYY-MM-DD>] [--before <YYYY-MM-DD>] [--account <account>] [--limit <limit>] [--json]`
- `<query>` Searches subject/sender
- `--body` Searches message body

### mail accounts
`sysm mail accounts [--json]`

### mail mailboxes
`sysm mail mailboxes [--account <account>] [--json]`

### mail send
`sysm mail send --to <to> --subject <subject> [--body <text>] [--html-body <html>] [--html-file <path>] [--cc <cc>] [--bcc <bcc>] [--account <account>] [--force]`
- `--to`, `--cc`, `--bcc` Take several addresses separated by commas or
  semicolons: `--to "a@example.com, b@example.com"`
- `--force` Skip confirmation

### mail reply
`sysm mail reply <message-id> --body <body> [--all] [--send]`
- `--all` Reply-all
- `--send` Send immediately (default: creates draft)

### mail forward
`sysm mail forward <message-id> --to <to> [--body <body>] [--send]`
- `--to` Takes several addresses separated by commas or semicolons

### mail draft create
`sysm mail draft create [--to <to>] [--subject <subject>] [--body <body>]`
- `--to` Takes several addresses separated by commas or semicolons
- Opens the draft in Mail; nothing is sent

### mail mark
`sysm mail mark <id> [--read] [--unread]`

### mail flag
`sysm mail flag <id> [--flag] [--unflag]`

### mail move
`sysm mail move <id> <mailbox> [--account <account>]`

### mail delete
`sysm mail delete <id> [--force]`

### mail attachments
`sysm mail attachments list <message-id> [--json]`
`sysm mail attachments download <message-id> [--output-dir <dir>] [--json]`

---

## messages

### messages send
`sysm messages send <recipient> <message>`
- `<recipient>` Phone number (+15551234567) or email (for iMessage)

### messages recent
`sysm messages recent [--limit <limit>] [--json]`
- `--limit` Default: 20

### messages read
`sysm messages read <conversation-id> [--limit <limit>] [--json]`
- `--limit` Default: 30

---

## safari

### safari rl
`sysm safari rl [<url>] [--title <title>] [--json]`
- Omit `<url>` to list reading list items
- Provide `<url>` to add to reading list

### safari bookmarks
`sysm safari bookmarks [--folder <folder>] [--json]`

### safari tabs
`sysm safari tabs [--json]`

---

## outlook
*Requires Microsoft Outlook installed.*

### outlook inbox
`sysm outlook inbox [--limit <limit>] [--json]`
- `--limit` Default: 20

### outlook unread
`sysm outlook unread [--limit <limit>] [--json]`

### outlook search
`sysm outlook search <query> [--limit <limit>] [--json]`

### outlook read
`sysm outlook read <id> [--json]`

### outlook send
`sysm outlook send --to <email>... [--cc <email>...] --subject <subject> --body <body> [--force]`
- `--to` and `--cc` are repeatable

### outlook calendar
`sysm outlook calendar [--days <days>] [--json]`
- `--days` Look-ahead days (default: 7)

### outlook tasks
`sysm outlook tasks [--priority <priority>] [--json]`
- `--priority` high, normal, low

---

## slack
*Requires Slack API token stored via `sysm slack auth`.*

### slack auth
`sysm slack auth [--token <token>] [--remove] [--status]`
- `--token` xoxb-... (bot) or xoxp-... (user)
- Run once to configure; token stored in Keychain

### slack send
`sysm slack send <channel> <message> [--json]`
- `<channel>` #general or general (# optional)

### slack status
`sysm slack status <text> [--emoji <emoji>]`
- Empty string clears status: `sysm slack status ""`
- `--emoji` e.g., :coffee:

### slack channels
`sysm slack channels [--limit <limit>] [--json]`
- `--limit` Default: 100
