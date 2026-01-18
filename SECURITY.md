# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

To report a security vulnerability, please open an issue on GitHub or contact the maintainer directly.

## Security Model

sysm is a CLI tool that integrates with macOS system services and executes user-defined automation. Understanding the security model is critical for safe usage.

### Permissions

sysm requests permissions for various macOS services:

| Service | Permission | Data Access |
|---------|------------|-------------|
| Calendar | Calendar access | Read/write events |
| Reminders | Reminders access | Read/write reminders |
| Contacts | Contacts access | Read contacts |
| Photos | Photos library | Read/export photos |
| Mail | Automation (Mail.app) | Read messages, create drafts |
| Messages | Automation (Messages.app) | Read/send messages |
| Music | Automation (Music.app) | Playback control |
| Safari | Full Disk Access | Read bookmarks/reading list |
| Notes | Automation (Notes.app) | Read notes |

### Workflow Security

**IMPORTANT**: The `sysm workflow` command executes arbitrary shell commands from YAML files.

#### Risks

1. **Arbitrary Code Execution**: Workflows execute shell commands with your user privileges
2. **File System Access**: Workflows can read, write, or delete any files you have access to
3. **Network Access**: Workflows can make network requests
4. **Credential Exposure**: Workflow environment variables may contain sensitive data

#### Safe Usage Guidelines

1. **Review Before Running**: Always inspect workflow YAML files before execution
   ```bash
   cat ~/.sysm/workflows/my-workflow.yaml
   sysm workflow validate my-workflow
   ```

2. **Trust Sources**: Only run workflows from trusted sources

3. **Use Dry Run**: Test workflows with `--dry-run` first
   ```bash
   sysm workflow run my-workflow --dry-run
   ```

4. **Protect Workflow Directory**: Secure `~/.sysm/workflows/` permissions
   ```bash
   chmod 700 ~/.sysm/workflows
   ```

5. **No Secrets in YAML**: Never store credentials directly in workflow files. Use environment variables instead.

### Plugin Security

The `sysm plugin` system has similar security considerations:

1. **Arbitrary Execution**: Plugins are shell scripts that run with your privileges
2. **Review Code**: Inspect plugin scripts before installation
3. **Secure Directory**: Protect `~/.sysm/plugins/` with restrictive permissions
   ```bash
   chmod 700 ~/.sysm/plugins
   ```

### AppleScript Security

Several services use AppleScript via `osascript`. User input is escaped to prevent injection attacks, but:

1. AppleScript execution requires Automation permissions
2. Scripts run with your user privileges
3. Malicious input could potentially exploit escaping bugs

### Data Handling

- sysm does not transmit data to external servers (except `weather` command using Open-Meteo or WeatherKit APIs)
- No telemetry or analytics
- All data stays on your local machine
- Cache files stored in `~/.sysm/` are not encrypted

### Best Practices

1. **Keep Updated**: Use the latest version for security fixes
2. **Minimal Permissions**: Only grant permissions to services you use
3. **Review Automations**: Regularly audit workflows and plugins
4. **Backup Data**: sysm can modify calendar events and reminders

## Code Signing

For maximum security, use the signed and notarized build:

```bash
make install-notarized
```

This ensures:
- Binary is verified by Apple
- Gatekeeper allows execution
- Runtime hardening is enabled
