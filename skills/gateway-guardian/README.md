# Gateway Guardian

**Protect your OpenClaw gateway from config errors with automatic backup, validation, and rollback.**

## 🎯 What It Does

Gateway Guardian ensures your OpenClaw gateway never gets killed by configuration errors. It provides:

- ✅ **Automatic backup** before every config change
- ✅ **Config validation** (syntax, required fields, types)
- ✅ **Health checks** after applying changes
- ✅ **Automatic rollback** if gateway fails to start
- ✅ **Auto-recovery** with `openclaw doctor` if rollback fails
- ✅ **AI enforcement** - AI automatically uses safe scripts

## 🚀 Quick Start

### 1. Install the Skill

```bash
# Download from ClawHub
clawhub install gateway-guardian

# Or manually
unzip gateway-guardian.skill -d ~/.openclaw/skills/
```

### 2. Auto-Configure (Recommended)

```bash
~/.openclaw/skills/gateway-guardian/scripts/auto-configure.sh
```

This adds mandatory protection rules to your `AGENTS.md`, ensuring AI always uses safe config apply.

### 3. Restart OpenClaw

```bash
openclaw gateway restart
```

## 📖 Usage

### For AI Agents

When a user requests gateway config changes, the AI will automatically:

1. Read `gateway-guardian/SKILL.md`
2. Validate the new config
3. Use `safe_config_apply.sh` instead of direct `gateway` tool

### For Manual Use

**Validate config before applying:**

```bash
~/.openclaw/skills/gateway-guardian/scripts/validate_config.sh new-config.json
```

**Apply config safely:**

```bash
~/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh new-config.json
```

**List available backups:**

```bash
~/.openclaw/skills/gateway-guardian/scripts/list_backups.sh
```

**Restore from backup:**

```bash
cp ~/.openclaw/backups/openclaw.json.YYYYMMDD_HHMMSS ~/.openclaw/openclaw.json
openclaw gateway restart
```

## 🛡️ How It Works

### Safe Apply Workflow

```
User requests config change
    ↓
Backup current config
    ↓
Validate new config (syntax, fields, types)
    ↓
Apply new config
    ↓
Restart gateway
    ↓
Health check (30s timeout)
    ↓
Success ✓  or  Failure → Rollback → Doctor
```

### What Gets Validated

- **JSON syntax** - Catches malformed JSON
- **Required fields** - `gateway.auth.mode`, `gateway.port`
- **Field types** - Port as number, auth mode as string
- **Auth mode values** - Must be `none`, `token`, or `both`
- **Common issues** - Empty tokens, duplicate keys

### Backup Management

- Backups stored in `~/.openclaw/backups/`
- Filename format: `openclaw.json.YYYYMMDD_HHMMSS`
- Automatic retention: keeps last 10 backups
- Manual cleanup available

## 🔧 Configuration

### Auto-Configuration (Recommended)

Run `auto-configure.sh` to add mandatory rules to `AGENTS.md`:

```bash
~/.openclaw/skills/gateway-guardian/scripts/auto-configure.sh
```

This ensures AI **always** uses gateway-guardian for config changes.

### Manual Configuration

If you prefer manual setup, add this to your `AGENTS.md` under the `## Safety` section:

```markdown
### 🛡️ Gateway Configuration Protection (CRITICAL)

**MANDATORY RULE: Never modify gateway config without protection!**

When user requests ANY gateway configuration change:

1. **MUST read** `~/.openclaw/skills/gateway-guardian/SKILL.md` first
2. **MUST use** `~/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh`
3. **NEVER use** `gateway` tool's `config.apply` or `config.patch` directly

**Workflow:**
\`\`\`bash
# 1. Validate first
~/.openclaw/skills/gateway-guardian/scripts/validate_config.sh new-config.json

# 2. Apply safely
~/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh new-config.json
\`\`\`
```

## 📋 Scripts Reference

| Script | Purpose |
|--------|---------|
| `safe_config_apply.sh` | Apply config with backup + validation + rollback |
| `validate_config.sh` | Validate config without applying |
| `list_backups.sh` | List available config backups |
| `auto-configure.sh` | Auto-add rules to AGENTS.md |
| `install.sh` | Install system-level shell wrapper (optional) |

## 🧪 Testing

Test the protection mechanism:

```bash
# Create a bad config (port 80 requires root)
cat > /tmp/bad-config.json << 'EOF'
{
  "gateway": {
    "port": 80,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "test"
    }
  }
}
EOF

# Try to apply (will fail and rollback)
~/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh /tmp/bad-config.json

# Verify gateway is still running
openclaw status
```

## ⚠️ Important Notes

### Why Auto-Configuration Matters

Without auto-configuration, AI agents might:
- Use `gateway config.apply` directly (no protection)
- Skip validation steps
- Not create backups
- Leave you with a broken gateway

**Auto-configuration ensures AI always uses safe scripts.**

### Limitations

- Health check only validates initial startup (not long-term stability)
- Cannot detect issues that manifest after startup
- Requires gateway to be restartable for rollback
- No support for partial config validation

### Recovery

If gateway fails completely:

1. Check backups: `~/.openclaw/skills/gateway-guardian/scripts/list_backups.sh`
2. Restore manually: `cp ~/.openclaw/backups/openclaw.json.YYYYMMDD_HHMMSS ~/.openclaw/openclaw.json`
3. Run doctor: `openclaw doctor --non-interactive`
4. Restart: `openclaw gateway restart`

## 📚 Advanced

### Custom Health Check Timeout

```bash
safe_config_apply.sh new-config.json --timeout 60
```

### System-Level Protection (Optional)

Install shell wrapper to intercept all `openclaw gateway config.*` commands:

```bash
~/.openclaw/skills/gateway-guardian/scripts/install.sh
source ~/.bashrc
```

This adds a shell alias that automatically uses safe apply.

## 🤝 Contributing

Found a bug or have a suggestion? Open an issue on ClawHub!

## 📄 License

MIT License - Feel free to use and modify.

---

**Made with ❤️ for the OpenClaw community**
