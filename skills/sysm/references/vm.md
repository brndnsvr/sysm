# sysm VM Reference — Virtual Machine management

*Uses Apple Virtualization framework (macOS 13+). VMs stored in ~/.sysm/vms/<name>/*

## VM States
- **running** — VM process is active (PID file present and process alive)
- **saved** — VM state saved to disk (`saved_state.vzvmsave` present), can be restored
- **stopped** — Not running, no saved state

---

## vm ls
`sysm vm ls [<filter>] [--json]`
- `<filter>` up (running only) or down (stopped only); omit for all

## vm create
`sysm vm create <name> --os <os> [--cpus <n>] [--memory <mb>] [--disk <gb>] [--ipsw <path>] [--json]`
- `--os` linux or macos
- `--cpus` Default: 2
- `--memory` MB (default: 4096)
- `--disk` GB (default: 64)
- `--ipsw` macOS only: path to IPSW restore image

## vm start
`sysm vm start <name> [--iso <path>]`
- `--iso` Linux only: path to ISO installer image (first boot only)
- Runs in **foreground** — serial console for Linux, headless for macOS
- If saved state exists, automatically restores from it

## vm stop
`sysm vm stop <name> [--json]`
- Sends SIGINT to the running VM process

## vm info
`sysm vm info <name> [--json]`
- Config, state, disk size, shared dirs, Rosetta status

## vm delete
`sysm vm delete <name> [--force] [--json]`
- Removes entire VM bundle directory
- `--force` Skip confirmation

## vm resize
`sysm vm resize <name> --disk <gb> [--json]`
- Grow-only — cannot shrink a disk
- VM must be stopped

---

## vm share — Directory sharing (VirtioFS)
*Shares host directories into the guest over virtio-fs.*

### vm share add
`sysm vm share add <name> --path <host-path> --tag <tag> [--read-only] [--json]`
- `--path` Host directory to share
- `--tag` Mount tag — used in guest: `mount -t virtiofs <tag> /mnt/host`
- `--read-only` Guest gets read-only access

### vm share remove
`sysm vm share remove <name> --tag <tag> [--json]`

### vm share ls
`sysm vm share ls <name> [--json]`

**Guest-side mount (Linux):**
```bash
mount -t virtiofs hostfs /mnt/host
# or in /etc/fstab:
# hostfs  /mnt/host  virtiofs  defaults  0  0
```

---

## vm rosetta enable
`sysm vm rosetta enable <name> [--json]`
- **Apple Silicon only** (arm64)
- **Linux VMs only** — not supported for macOS guests
- Enables Rosetta 2 directory share so Linux can run x86_64 binaries
- After enabling, mount in guest:
  ```bash
  mount -t virtiofs rosetta /proc/sys/fs/binfmt_misc
  # Register Rosetta:
  /proc/sys/fs/binfmt_misc/register <<< ':rosetta:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:/media/rosetta/rosetta:CF'
  ```

---

## vm save / restore
*Requires macOS 14+. Saves full VM state to disk for instant resume.*

### vm save
`sysm vm save <name> [--json]`
- VM must be running
- Sends SIGUSR1 to the running VM process → saves state → VM exits
- State stored at: `~/.sysm/vms/<name>/saved_state.vzvmsave`

### vm restore
`sysm vm restore <name>`
- Validates saved state exists, then calls `vm start`
- `vm start` automatically detects and restores from saved state

---

## Common Workflows

### Create and boot a Linux VM
```bash
# Create VM bundle
sysm vm create dev --os linux --cpus 4 --memory 4096 --disk 20

# Add host directory share
sysm vm share add dev --path ~/projects --tag hostfs

# Enable Rosetta (Apple Silicon only)
sysm vm rosetta enable dev

# First boot with installer ISO
sysm vm start dev --iso ~/Downloads/ubuntu-24.04-live-server-arm64.iso

# Subsequent boots (no ISO needed)
sysm vm start dev
```

### Save and restore VM state
```bash
# From another terminal while VM is running:
sysm vm save dev      # VM saves state and exits

# Later, restore:
sysm vm start dev     # Automatically detects saved_state.vzvmsave and restores
# or explicitly:
sysm vm restore dev
```

### Grow disk
```bash
sysm vm stop dev                    # Must stop first
sysm vm resize dev --disk 40        # Grow from 20GB → 40GB
# Then inside guest, resize the filesystem:
# sudo resize2fs /dev/vda
```

### List and inspect
```bash
sysm vm ls                          # All VMs
sysm vm ls up                       # Running only
sysm vm info dev --json             # Full config as JSON
sysm vm share ls dev                # Shared directories
```
