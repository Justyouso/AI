#!/bin/bash
# Safe config apply with automatic rollback on failure
# Usage: safe_config_apply.sh <new-config-path> [--timeout SECONDS]

set -e

CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
BACKUP_DIR="$CONFIG_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/openclaw.json.$TIMESTAMP"
HEALTH_CHECK_TIMEOUT=30
ROLLBACK_MARKER="$CONFIG_DIR/.rollback_in_progress"

# Parse arguments
NEW_CONFIG="$1"
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout)
            HEALTH_CHECK_TIMEOUT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate input
if [[ -z "$NEW_CONFIG" ]]; then
    echo "Error: No config file specified"
    echo "Usage: $0 <new-config-path> [--timeout SECONDS]"
    exit 1
fi

if [[ ! -f "$NEW_CONFIG" ]]; then
    echo "Error: Config file not found: $NEW_CONFIG"
    exit 1
fi

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Step 1: Validate new config syntax
echo "[1/5] Validating new config syntax..."
if ! jq empty "$NEW_CONFIG" 2>/dev/null; then
    echo "Error: Invalid JSON syntax in new config"
    exit 1
fi

# Check required fields
echo "[2/5] Checking required fields..."
REQUIRED_FIELDS=("gateway.auth.mode" "gateway.port")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! jq -e ".$field" "$NEW_CONFIG" >/dev/null 2>&1; then
        echo "Warning: Missing recommended field: $field"
    fi
done

# Step 2: Backup current config
echo "[3/5] Backing up current config..."
if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "Backup saved: $BACKUP_FILE"
else
    echo "Warning: No existing config to backup"
fi

# Step 3: Apply new config
echo "[4/5] Applying new config..."
cp "$NEW_CONFIG" "$CONFIG_FILE"
touch "$ROLLBACK_MARKER"

# Step 4: Restart gateway
echo "[5/5] Restarting gateway..."
if command -v openclaw &>/dev/null; then
    openclaw gateway restart
else
    echo "Warning: openclaw command not found, skipping restart"
fi

# Step 5: Health check
echo "Waiting for gateway to start (timeout: ${HEALTH_CHECK_TIMEOUT}s)..."
ELAPSED=0
GATEWAY_HEALTHY=false

while [[ $ELAPSED -lt $HEALTH_CHECK_TIMEOUT ]]; do
    if openclaw status 2>/dev/null | grep -q "running"; then
        GATEWAY_HEALTHY=true
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if [[ "$GATEWAY_HEALTHY" == "true" ]]; then
    echo "✓ Gateway is healthy"
    rm -f "$ROLLBACK_MARKER"
    
    # Keep only last 10 backups
    ls -t "$BACKUP_DIR"/openclaw.json.* 2>/dev/null | tail -n +11 | xargs -r rm
    
    echo "✓ Config applied successfully"
    exit 0
else
    echo "✗ Gateway failed to start, rolling back..."
    
    if [[ -f "$BACKUP_FILE" ]]; then
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        echo "Rolled back to: $BACKUP_FILE"
        
        # Try restart first
        openclaw gateway restart
        sleep 3
        
        if openclaw status 2>/dev/null | grep -q "running"; then
            echo "✓ Rollback successful, gateway is running"
            rm -f "$ROLLBACK_MARKER"
            exit 0
        else
            echo "⚠ Gateway still not running after rollback"
            echo "Running 'openclaw doctor' to fix..."
            echo
            
            # Run doctor to fix issues
            if openclaw doctor --non-interactive; then
                echo
                echo "✓ Doctor completed, checking gateway status..."
                sleep 2
                
                if openclaw status 2>/dev/null | grep -q "running"; then
                    echo "✓ Gateway recovered after doctor"
                    rm -f "$ROLLBACK_MARKER"
                    exit 0
                else
                    echo "✗ Gateway still not running after doctor"
                    echo "Manual intervention required"
                    echo "Backup location: $BACKUP_FILE"
                    rm -f "$ROLLBACK_MARKER"
                    exit 1
                fi
            else
                echo "✗ Doctor failed, manual intervention required"
                echo "Backup location: $BACKUP_FILE"
                rm -f "$ROLLBACK_MARKER"
                exit 1
            fi
        fi
    else
        echo "✗ No backup available for rollback"
        echo "Running 'openclaw doctor' to attempt recovery..."
        
        if openclaw doctor --non-interactive; then
            echo "✓ Doctor completed"
        else
            echo "✗ Doctor failed"
        fi
        
        rm -f "$ROLLBACK_MARKER"
        exit 1
    fi
fi
