# Gateway Guardian - Rollback Strategy

## Overview

This document explains the rollback mechanisms and recovery strategies when config changes fail.

## Automatic Rollback

The `safe_config_apply.sh` script implements automatic rollback with these steps:

1. **Backup** - Current config saved to `~/.openclaw/backups/openclaw.json.YYYYMMDD_HHMMSS`
2. **Apply** - New config copied to `~/.openclaw/openclaw.json`
3. **Restart** - Gateway restarted with new config
4. **Health Check** - Wait up to 30s (configurable) for gateway to become healthy
5. **Rollback** - If health check fails, restore backup and restart

## Rollback Marker

During config application, a marker file is created:

```
~/.openclaw/.rollback_in_progress
```

This marker:
- Indicates a config change is in progress
- Removed after successful health check
- Removed after rollback completes
- Can be used by monitoring tools to detect stuck rollbacks

## Manual Rollback

If automatic rollback fails, manually restore from backup:

```bash
# List available backups
~/.openclaw/skills/gateway-guardian/scripts/list_backups.sh

# Restore specific backup
cp ~/.openclaw/backups/openclaw.json.20260309_232000 ~/.openclaw/openclaw.json

# Restart gateway
openclaw gateway restart

# Verify
openclaw status
```

## Backup Retention

- Backups are kept in `~/.openclaw/backups/`
- Automatic cleanup keeps last 10 backups
- Manual cleanup: `rm ~/.openclaw/backups/openclaw.json.YYYYMMDD_HHMMSS`

## Health Check Logic

Gateway is considered healthy when:
- `openclaw status` returns successfully
- Output contains "running"
- Check completes within timeout (default 30s)

## Common Failure Scenarios

### Scenario 1: Invalid JSON Syntax

**Detection:** Pre-flight validation catches this before applying

**Recovery:** Config is never applied, no rollback needed

### Scenario 2: Missing Required Fields

**Detection:** Pre-flight validation warns about this

**Recovery:** Config is applied but gateway may fail to start, automatic rollback triggers

### Scenario 3: Gateway Crashes on Startup

**Detection:** Health check timeout

**Recovery:** Automatic rollback to previous config

### Scenario 4: Gateway Starts but Becomes Unhealthy

**Detection:** Not caught by automatic rollback (only cks initial startup)

**Recovery:** Manual rollback required

## Best Practices

1. **Always validate first:**
   ```bash
   ~/.openclaw/skills/gateway-guardian/scripts/validate_config.sh new-config.json
   ```

2. **Use safe apply for all changes:**
   ```bash
   ~/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh new-config.json
   ```

3. **Test in isolated environment first** if possible

4. **Keep backup directory clean** but retain recent backups

5. **Monitor logs** after config changes:
   ```bash
   journalctl -u openclaw-gateway -f
   ```

## Limitations

- Health check only validates initial startup, not long-term stability
- Cannot detect configuration issues that manifest later
- Rollback requires gateway to be restartable (if gateway is completely broken, manual intervention needed)
- No support for partial config updates (always full config replacement)

## Future Improvements

- Add config diff before applying
- Support for config validation against schema
- Longer-term health monitoring (5-10 minutes)
- Integration with monitoring/alerting systems
- Support for staged rollouts (canary deployments)
