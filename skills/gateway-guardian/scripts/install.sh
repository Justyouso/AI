#!/bin/bash
# Install Gateway Guardian system-level protection

set -e

WRAPPER_SCRIPT="$HOME/.openclaw/skills/gateway-guardian/scripts/openclaw-wrapper.sh"
BASHRC="$HOME/.bashrc"

echo "========================================="
echo "Gateway Guardian - System Installation"
echo "========================================="
echo

# Check if wrapper exists
if [[ ! -f "$WRAPPER_SCRIPT" ]]; then
    echo "Error: Wrapper script not found at $WRAPPER_SCRIPT"
    exit 1
fi

# Check if already installed
if grep -q "gateway-guardian" "$BASHRC" 2>/dev/null; then
    echo "⚠️  Gateway Guardian already installed in ~/.bashrc"
    echo
    read -p "Reinstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    
    # Remove old installation
    sed -i '/# Gateway Guardian - Start/,/# Gateway Guardian - End/d' "$BASHRC"
    echo "✓ Removed old installation"
fi

# Add alias to .bashrc
echo
echo "Adding alias to ~/.bashrc..."
cat >> "$BASHRC" << 'EOF'

# Gateway Guardian - Start
# Intercepts dangerous gateway config commands for safety
alias openclaw='~/.openclaw/skills/gateway-guardian/scripts/openclaw-wrapper.sh'
# Gateway Guardian - End
EOF

echo "✓ Alias added to ~/.bashrc"
echo

echo "========================================="
echo "✓ Installation Complete"
echo "========================================="
echo
echo "The wrapper will:"
echo "  • Intercept 'openclaw gateway config.apply'"
echo "  • Intercept 'openclaw gateway config.patch'"
echo "  • Validate config before applying"
echo "  • Use safe apply with automatic rollback"
echo "  • Pass through all other commands normally"
echo
echo "To activate in current shell:"
echo "  source ~/.bashrc"
echo
echo "Or start a new shell session."
echo
echo "To test:"
echo "  openclaw status  # Should work normally"
echo
echo "To uninstall:"
echo "  Remove the 'Gateway Guardian' section from ~/.bashrc"
echo
