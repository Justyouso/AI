#!/bin/bash
# OpenClaw Gateway Guardian - System-level interceptor
# This wrapper intercepts dangerous gateway commands and adds safety checks

REAL_OPENCLAW="/home/blithe/.npm-global/bin/openclaw"
GUARDIAN_SCRIPT="$HOME/.openclaw/skills/gateway-guardian/scripts/safe_config_apply.sh"
VALIDATE_SCRIPT="$HOME/.openclaw/skills/gateway-guardian/scripts/validate_config.sh"

# Check if this is a gateway config command
if [[ "$1" == "gateway" ]]; then
    case "$2" in
        config.apply|config.patch)
            echo "⚠️  Gateway Guardian: Intercepting config change"
            echo "   Using safe apply with automatic rollback protection"
            echo
            
            # Extract config file path from arguments
            CONFIG_FILE=""
            for arg in "$@"; do
                if [[ -f "$arg" ]]; then
                    CONFIG_FILE="$arg"
                    break
                fi
            done
            
            if [[ -z "$CONFIG_FILE" ]]; then
                echo "Error: No config file found in arguments"
                echo "Usage: openclaw gateway config.apply <config-file>"
                exit 1
            fi
            
            # Validate first
            if ! "$VALIDATE_SCRIPT" "$CONFIG_FILE"; then
                echo
                echo "❌ Config validation failed"
                echo "   Fix errors before applying"
                exit 1
            fi
            
            echo
            echo "✓ Validation passed, applying with safety checks..."
            echo
            
            # Use safe apply
            exec "$GUARDIAN_SCRIPT" "$CONFIG_FILE"
            ;;
        
        restart)
            # Check if there's a rollback marker (config change in progress)
            if [[ -f "$HOME/.openclaw/.rollback_in_progress" ]]; then
                echo "⚠️  Gateway Guardian: Rollback in progress"
                echo "   Allowing restart for recovery"
            fi
            
            # Normal restart, pass through
            exec "$REAL_OPENCLAW" "$@"
            ;;
        
        *)
            # Other gateway commands, pass through
            exec "$REAL_OPENCLAW" "$@"
            ;;
    esac
else
    # Not a gateway command, pass through
    exec "$REAL_OPENCLAW" "$@"
fi
