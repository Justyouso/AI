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
# Clone the entire repo and copy the skill
cd /tmp
git clone https://github.com/Justyouso/AI.git
cp -r AI/skills/gateway-guardian ~/.openclaw/skills/

# Or download specific skill folder
cd ~/.openclaw/skills/
wget https://github.com/Justyouso/AI/archive/refs/heads/main.zip
unzip main.zip
mv AI-main/skills/gateway-guardian ./
rm -rf AI-main main.zip
```

### 2. Auto-Configure (Recommended)

```bash
~/.openclaw/skills/gateway-guardian/scripts/auto-configure.sh
```

This adds mandatory protection rules to your `AGENTS.md`, ensuring AI always uses safe config apply.

### 3. Done!

Your gateway is now protected. AI will automatically use safe scripts for all config changes.

## 📖 Usage

### For AI Agents

When a user requests gateway config changes, the AI will automatically:

1. Read `gateway-guardian/SKILL.md`
2. Validate the new config
3. Use `safe_config_apply.sh` instead of direct `gateway` tool
4. Create backup, apply, health check, and rollback if needed

**No manual intervention required!**

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
# List backups first
~/.openclaw/skills/gateway-guardian/scripts/list_backups.sh

# Restore specific backup
cp ~/.openclaw/backups/openclaw.json.20260310_120000 ~/.openclaw/openclaw.json
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
- Manual cleanup available via `list_backups.sh`

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

# 2. Apply safely (with auto-rollback)
~/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh new-config.json
\`\`\`

**This is non-negotiable.** Gateway downtime = you can't communicate with your human.
```

## 📋 Scripts Reference

| Script | Purpose |
|--------|---------|
| `safe_config_apply.sh` | Apply config with backup + validation + rollback |
| `validate_config.sh` | Validate config without applying |
| `list_backups.sh` | List available config backups |
| `auto-configure.sh` | Auto-add protection rules to AGENTS.md |
| `install.sh` | Install system-level shell wrapper (optional) |

## 🧪 Testing

Test the protection mechanism:

```bash
# Create a bad config (invalid port)
cat > /tmp/bad-config.json << 'EOF'
{
  "gateway": {
    "port": "not-a-number",
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "test"
    }
  }
}
EOF

# Try to apply (will fail validation)
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
- No support for partial config validation (full config only)

### Recovery

If gateway fails completely:

1. **Check backups:**
   ```bash
   ~/.openclaw/skills/gateway-guardian/scripts/list_backups.sh
   ```

2. **Restore manually:**
   ```bash
   cp ~/.openclaw/backups/openclaw.json.YYYYMMDD_HHMMSS ~/.openclaw/openclaw.json
   ```

3. **Run doctor:**
   ```bash
   openclaw doctor --non-interactive
   ```

4. **Restart:**
   ```bash
   openclaw gateway restart
   ```

## 📚 Advanced

### Custom Health Check Timeout

```bash
safe_config_apply.sh new-config.json --timeout 60
```

Default is 30 seconds. Increase if your gateway takes longer to start.

### System-Level Protection (Optional)

Install shell wrapper to intercept all `openclaw gateway config.*` commands:

```bash
~/.openclaw/skills/gateway-guardian/scripts/install.sh
source ~/.bashrc
```

This adds a shell alias that automatically uses safe apply for any gateway config command.

### Integration with Other Tools

Gateway Guardian works seamlessly with:
- OpenClaw CLI (`openclaw gateway restart`)
- AI agents (via AGENTS.md rules)
- Manual config edits (via safe scripts)
- Cron jobs (for scheduled config updates)

## 🤝 Contributing

Found a bug or have a suggestion?

1. Fork the repo
2. Create a feature branch
3. Submit a pull request

Or open an issue on GitHub!

## 📄 License

MIT License - Feel free to use and modify.

---

**Made with ❤️ for the OpenClaw community**

**Protect your gateway. Sleep better at night. 🛡️**
