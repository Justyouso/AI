#!/bin/bash
# Auto-configure gateway-guardian in AGENTS.md
# This script adds mandatory protection rules to AGENTS.md

set -e

AGENTS_MD="$HOME/.openclaw/workspace/AGENTS.md"
MARKER_START="### 🛡️ Gateway Configuration Protection (CRITICAL)"
MARKER_END="**This is non-negotiable.** Gateway downtime = you can't communicate with your human."

echo "========================================="
echo "Gateway Guardian - Auto Configuration"
echo "========================================="
echo

# Check if AGENTS.md exists
if [[ ! -f "$AGENTS_MD" ]]; then
    echo "⚠️  AGENTS.md not found at $AGENTS_MD"
    echo "   Creating default AGENTS.md..."
    cat > "$AGENTS_MD" << 'EOF'
# AGENTS.md - Your Workspace

## Safety

- Don't exfiltrate private data. Ever.
- Don't run destructive commands without asking.
- When in doubt, ask.
EOF
    echo "✓ Created default AGENTS.md"
fi

# Check if already configured
if grep -q "$MARKER_START" "$AGENTS_MD" 2>/dev/null; then
    echo "⚠️  Gateway Guardian rules already exist in AGENTS.md"
    echo
    read -p "Reinstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Configuration cancelled"
        exit 0
    fi
    
    # Remove old configuration
    sed -i "/$MARKER_START/,/$MARKER_END/d" "$AGENTS_MD"
    echo "✓ Removed old configuration"
fi

# Find the Safety section
if ! grep -q "## Safety" "$AGENTS_MD"; then
    echo "⚠️  No '## Safety' section found in AGENTS.md"
    echo "   Adding Safety section..."
    cat >> "$AGENTS_MD" << 'EOF'

## Safety

- Don't exfiltrate private data. Ever.
- Don't run destructive commands without asking.
- When in doubt, ask.
EOF
fi

# Add gateway-guardian rules after Safety section
echo
echo "Adding gateway-guardian rules to AGENTS.md..."

# Create temporary file with new content
TEMP_FILE=$(mktemp)
awk -v marker="$MARKER_START" '
/## Safety/ {
    print
    getline
    print
    print ""
    print "### 🛡️ Gateway Configuration Protection (CRITICAL)"
    print ""
    print "**MANDATORY RULE: Never modify gateway config without protection!**"
    print ""
    print "When user requests ANY gateway configuration change:"
    print ""
    print "1. **MUST read** `~/.openclaw/skills/gateway-guardian/SKILL.md` first"
    print "2. **MUST use** `~/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh`"
    print "3. **NEVER use** `gateway` tool'\''s `config.apply` or `config.patch` directly"
    print ""
    print "**Why this matters:**"
    print "- Bad config can kill the gateway permanently"
    print "- Direct config changes have no rollback"
    print "- `safe_config_apply.sh` provides: backup → validate → apply → health check → auto-rollback"
    print ""
    print "**Workflow:**"
    print "```bash"
    print "# 1. Validate first"
    print "~/.openclaw/skills/gateway-guardian/scripts/validate_config.sh new-config.json"
    print ""
    print "# 2. Apply safely (with auto-rollback)"
    print "~/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh new-config.json"
    print "```"
    print ""
    print "**This is non-negotiable.** Gateway downtime = you can'\''t communicate with your human."
    print ""
    next
}
{ print }
' "$AGENTS_MD" > "$TEMP_FILE"

# Replace original file
mv "$TEMP_FILE" "$AGENTS_MD"

echo "✓ Gateway Guardian rules added to AGENTS.md"
echo

echo "========================================="
echo "✓ Configuration Complete"
echo "========================================="
echo
echo "What was configured:"
echo "  • Added mandatory protection rules to AGENTS.md"
echo "  • AI will now automatically use gateway-guardian for config changes"
echo
echo "To verify:"
echo "  cat ~/.openclaw/workspace/AGENTS.md | grep -A 20 'Gateway Configuration Protection'"
echo
echo "Next steps:"
echo "  1. Restart your OpenClaw session to load new rules"
echo "  2. Test by requesting a gateway config change"
echo
