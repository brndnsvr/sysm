# sysm Meta Reference — update, completions

## update
*Self-update sysm to the latest version.*

### update
`sysm update [--check] [--json]`
- `--check` Check for updates without installing
- `--json` Output as JSON (useful for scripting version checks)

---

## completions
*Manage shell completions for sysm.*

### completions install
`sysm completions install`
- Install shell completions for the current shell (zsh/bash/fish)

### completions uninstall
`sysm completions uninstall`
- Remove installed shell completions

### completions show
`sysm completions show`
- Print completion script to stdout (for manual installation)

### completions status
`sysm completions status`
- Show whether completions are installed for the current shell
