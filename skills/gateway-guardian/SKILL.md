---
name: gateway-guardian
description: MANDATORY protection for OpenClaw gateway config changes. ALWAYS use this skill when user requests config.apply, config.patch, gateway restart with config changes, or any gateway configuration modification. This skill provides automatic backup, validation, and rollback to prevent gateway downtime from invalid configurations. DO NOT use the gateway tool directly for config changes - always use this skill's safe_config_apply.sh script instead.
license: MIT
acceptLicenseTerms: true
---

# Gateway Guardian

**CRITICAL: This skill MUST be used for ALL gateway config changes.**

Ensures OpenClaw gateway never gets killed by config errors through automatic backup, validation, and rollback mechanisms.

## When to Use (MANDATORY)

Use this skill for:
- Any `gateway config.apply` request
- Any `gateway config.patch` request  
- Any gateway configuration modification
- When user asks to "change gateway config"
- When user asks to "update openclaw config"

**DO NOT** use the `gateway` tool directly. Always use `safe_config_apply.sh` from this skill.

## Installation (Recommended)

**IMPORTANT: Run auto-configuration after installing this skill!**

```bash
~/.openclaw/skills/gateway-guardian/scripts/auto-configure.sh
```

This automatically adds mandatory protection rules to your `AGENTS.md`, ensuring AI always uses safe config apply.

**After auto-configuration:**
- AI will automatically read this skill when config changes are requested
- AI will use `safe_config_apply.sh` instead of direct `gateway` tool
- Your gateway is protected from config errors

**Without auto-configuration:**
- AI might skip this skill (less reliable)
- Direct `gateway` tool calls bypass protection
- Higher risk of gateway downtime

### Optional: System-Level Protection

For additional protection, install the shell wrapper:

```bash
scripts/install.sh
source ~/.bashrc
```

This adds a shell alias that automatically intercepts dangerous gateway commands.

## Core Workflow

When applying gateway config changes, always use the safe apply workflow:

1. **Validate** the new config first
2. **Backup** current config automatically
3. **Apply** new config
4. **Health check** gateway startup
5. **Rollback** automatically if health check fails

## Quick Start

### Safe Config Apply

Use this for all config changes:

```bash
scripts/safe_config_apply.sh /path/to/new-config.json
```

With custom health check timeout:

```bash
scripts/safe_config_apply.sh /path/to/new-config.json --timeout 60
```

### Validate Before Applying

Always validate first to catch errors early:

```bash
scripts/validate_config.sh /path/to/new-config.json
```

### List Available Backups

```bash
scripts/list_backups.sh
scripts/list_backups.sh --limit 20
```

## Integration with Gateway Tool

When using the `gateway` tool with `config.apply` or `config.patch` actions:

1. Write the new config to a temporary file
2. Run `validate_config.sh` on it
3. If validation passes, use `safe_config_apply.sh` instead of direct `gateway` tool
4. Report results to user

Example workflow:

```bash
# User requests config change
# 1. Generate new config
cat > /tmp/new-config.json << 'EOF'
{
  "gateway": {
    "port": 18789,
    "auth": {
      "mode": "token"
    }
  }
}
EOF

# 2. Validate
if scripts/validate_config.sh /tmp/new-config.json; then
  # 3. Safe apply
  scripts/safe_config_apply.sh /tmp/new-config.json
else
  echo "Config validation failed, aborting"
  exit 1
fi
```

## What Gets Validated

### Critical Checks

- JSON syntax validity
- Required field presence (`gateway.auth.mode`, `gateway.port`)
- Field type correctness (port as number, auth.mode as string)
- Auth mode values (`none`, `token`, or `both`)

### Warnings

- Empty or null auth tokens
- Possible duplicate keys
- Missing recommended fields

## Backup Management

- Backups stored in `~/.openclaw/backups/`
- Filename format: `openclaw.json.YYYYMMDD_HHMMSS`
- Automatic retention: last 10 backups kept
- Manual cleanup available via `list_backups.sh`

## Rollback Behavior

### Automatic Rollback Triggers

- Gateway fails to start within timeout (default 30s)
- `openclaw status` doesn't show "running"
- Gateway process crashes during startup

### Rollback Process

1. Restore previous config from backup
2. Restart gateway
3. Verify gateway is running
4. Report success/failure

### Manual Rollback

If automatic rollback fails:

```bash
# List backups
script_backups.sh

# Restore manually
cp ~/.openclaw/backups/openclaw.json.20260309_232000 ~/.openclaw/openclaw.json

# Restart
openclaw gateway restart
```

## Advanced Topics

For detailed information on rollback strategies, failure scenarios, and recovery procedures, see:

- **references/rollback-strategy.md** - Complete rollback documentation

## Limitations

- Health check only validates initial startup (not long-term stability)
- Cannot detect issues that manifest after startup
- Requires gateway to be restartable for rollback
- No support for partial config validation (full config only)

## Best Practices

1. Always validate before applying
2. Use safe apply for all config changes
3. Monitor logs after changes: `journalctl -u openclaw-gateway -f`
4. Keep recent backups available
5. Test config changes in isolated environment when possible

## Error Messages

- **"Invalid JSON syntax"** - Fix JSON formatting before applying
- **"Missing required field"** - Add missing fields (especially `gateway.auth.mode`)
- **"Gateway failed to start"** - Check logs, automatic rollback triggered
- **"Rollback failed"** - Manual intervention required, see backup list
