# Structured Apple Notes

`sysm notes create` can turn a narrow Markdown dialect into Notes-native paragraph styles and checklists.

```bash
sysm notes create "Trent's School Supplies" \
  --folder "Kids Stuff" \
  --from-markdown supplies.md
```

Use `-` to read Markdown from standard input:

```bash
generate-content | sysm notes create "Shopping List" \
  --folder "Kids Stuff" \
  --from-markdown -
```

`--from-markdown` cannot be combined with `--body` or `--stdin`. Existing `--body` and `--stdin` behavior is
unchanged.

## Supported Markdown

| Markdown | Apple Notes format |
|---|---|
| `# Title` | Title |
| `## Heading` | Heading |
| `### Subheading` | Subheading |
| Plain paragraph | Body |
| `- [ ] Item` | Native unchecked checklist item |
| `- [x] Item` | Native checked checklist item |

Wrapped lines in one plain paragraph are joined with a space. Blank lines end paragraphs. Inline Markdown, nested
lists, links, tables, and attachments are intentionally treated as literal body text or left unsupported.

The positional CLI title remains the note name shown in the Notes list. A Markdown `#` line is content formatted
with Notes' Title paragraph style; it does not replace the positional title.

## Implementation and safety model

The existing Notes path is:

- `Sources/sysm/Commands/Notes/NotesCreate.swift` for CLI input.
- `Sources/SysmCore/Services/NotesService.swift` for Notes AppleScript CRUD.
- `Sources/SysmCore/Services/NotesMarkdown.swift` for deterministic parsing and HTML escaping.
- `Sources/SysmCore/Services/NotesAccessibilityFormatter.swift` for native Notes formatting.

Notes' macOS scripting dictionary exposes an HTML `body` property and exact note IDs, but it does not expose
native checklist state. Structured creation therefore uses a bounded hybrid path:

1. Parse Markdown and preflight Accessibility before creating anything.
2. Require an explicitly named folder to resolve to exactly one Notes folder, then create plain, escaped bootstrap
   content there through Notes AppleScript.
3. Capture the new note's exact ID, set Notes' selection to that ID, and show it in a separate window.
4. Locate exactly one editable Accessibility text area containing every parsed block in order.
5. Before every format action, recheck the selected note ID, frontmost Notes process, focused editor, and selected
   text range.
6. Invoke Notes' own Title, Heading, Subheading, Body, Checklist, and mark/unmark menu commands.
7. Read the exact ID, folder, plaintext, and HTML body back. Verify the content and native list structure.

If targeting, focus, selection, formatting, or read-back verification fails, the command stops instead of trying a
different window or note. A failure after creation reports the partial note ID so it can be inspected safely; sysm
does not delete or retry against another note.

Duplicate folder names across Notes accounts are rejected for structured creation because a folder name alone cannot
identify the intended destination safely. Rename one duplicate or omit `--folder` to use Notes' default folder.

Structured `notes edit` is intentionally not provided. Reformatting an existing personal note cannot currently be
made transactional if Accessibility fails midway. Plain `notes edit --body` and `notes edit --stdin` remain
available.

## Compatibility and permissions

- macOS Automation permission is required for Notes AppleScript.
- Accessibility permission is required for the `sysm` executable that applies Notes-native formatting.
- Title/Heading/Subheading styles and native checklists require an iCloud or On My Mac Notes account. Notes accounts
  from other providers may disable the commands; sysm fails closed when a required menu item is unavailable.
- Keyboard shortcuts can vary by language and input source. sysm resolves the active Notes menu items by their
  Command-Shift equivalents and does not emit unverified global keystrokes.
- A user's “Automatically sort checked items” Notes setting can reorder checked items. sysm marks checked items from
  bottom to top so remaining selections stay stable.

Notes HTML read-back serializes a native checklist as list items but does not reliably expose checked versus
unchecked state. Automated verification confirms the exact note/folder, all text, and checklist list structure.
A manual canary is still required to certify tappable checkdots, checked state, and heading appearance on a given
macOS/Notes release.

## Automated coverage

- Parser tests cover all supported blocks, line endings, literal unsupported Markdown, and invalid empty content.
- Renderer tests cover HTML escaping and marker removal from bootstrap content.
- Service tests cover preflight-before-create, exact ID handoff, requested folder, and partial-note error reporting.
- CLI tests cover help, incompatible input flags, and `--from-markdown -` without touching Notes.
