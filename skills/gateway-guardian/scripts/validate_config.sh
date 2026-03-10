#!/bin/bash
# Validate OpenClaw config without applying
# Usage: validate_config.sh <config-path>

set -e

CONFIG_FILE="$1"

if [[ -z "$CONFIG_FILE" ]]; then
    echo "Error: No config file specified"
    echo "Usage: $0 <config-path>"
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "Validating config: $CONFIG_FILE"
echo

# Check 1: JSON syntax
echo "[1/4] Checking JSON syntax..."
if jq empty "$CONFIG_FILE" 2>/dev/null; then
    echo "✓ Valid JSON"
else
    echo "✗ Invalid JSON syntax"
    jq . "$CONFIG_FILE" 2>&1 | head -5
    exit 1
fi

# Check 2: Required fields
echo "[2/4] Checking required fields..."
ERRORS=0

# Critical fields
if ! jq -e '.gateway.auth.mode' "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "✗ Missing: gateway.auth.mode (required in 2026.3.7+)"
    ERRORS=$((ERRORS + 1))
fi

if ! jq -e '.gateway.port' "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "✗ Missing: gateway.port"
    ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -eq 0 ]]; then
    echo "✓ All required fields present"
fi

# Check 3: Field types
echo "[3/4] Checking field types..."
TYPE_ERRORS=0

# Port should be number
if jq -e '.gateway.port' "$CONFIG_FILE" >/dev/null 2>&1; then
    PORT_TYPE=$(jq -r '.gateway.port | type' "$CONFIG_FILE")
    if [[ "$PORT_TYPE" != "number" ]]; then
        echo "✗ gateway.port should be number, got: $PORT_TYPE"
        TYPE_ERRORS=$((TYPE_ERRORS + 1))
    fi
fi

# Auth mode should be string
if jq -e '.gateway.auth.mode' "$CONFIG_FILE" >/dev/null 2>&1; then
    AUTH_MODE=$(jq -r '.gateway.auth.mode' "$CONFIG_FILE")
    if [[ ! "$AUTH_MODE" =~ ^(none|token|both)$ ]]; then
        echo "✗ gateway.auth.mode should be 'none', 'token', or 'both', got: $AUTH_MODE"
        TYPE_ERRORS=$((TYPE_ERRORS + 1))
    fi
fi

if [[ $TYPE_ERRORS -eq 0 ]]; then
    echo "✓ Field types valid"
fi

ERRORS=$((ERRORS + TYPE_ERRORS))

# Check 4: Common issues
echo "[4/4] Checking for common issues..."
WARNINGS=0

# Check for duplicate keys (jq will catch this in syntax check, but let's be explicit)
KEYS=$(jq -r 'paths(scalars) | join(".")' "$CONFIG_FILE" | sort)
DUPLICATES=$(echo "$KEYS" | uniq -d)
if [[ -n "$DUPLICATES" ]]; then
    echo "⚠ Possible duplicate keys detected:"
    echo "$DUPLICATES"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for empty strings in critical fields
if jq -e '.gateway.auth.token' "$CONFIG_FILE" >/dev/null 2>&1; then
    TOKEN=$(jq -r '.gateway.auth.token' "$CONFIG_FILE")
    if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
        echo "⚠ gateway.auth.token is empty or null"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

if [[ $WARNINGS -eq 0 ]]; then
    echo "✓ No common issues found"
fi

# Summary
echo
echo "========================================="
if [[ $ERRORS -eq 0 ]]; then
    echo "✓ Config validation passed"
    if [[ $WARNINGS -gt 0 ]]; then
        echo "⚠ $WARNINGS warning(s) found"
    fi
    exit 0
else
    echo "✗ Config validation failed with $ERRORS error(s)"
    exit 1
fi
