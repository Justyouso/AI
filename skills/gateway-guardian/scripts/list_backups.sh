#!/bin/bash
# List available config backups
# Usage: list_backups.sh [--limit N]

BACKUP_DIR="$HOME/.openclaw/backups"
LIMIT=10

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "No backups found (directory doesn't exist)"
    exit 0
fi

BACKUPS=$(ls -t "$BACKUP_DIR"/openclaw.json.* 2>/dev/null | head -n "$LIMIT")

if [[ -z "$BACKUPS" ]]; then
    echo "No backups found"
    exit 0
fi

echo "Available config backups (newest first):"
echo

COUNT=1
while IFS= read -r backup; do
    FILENAME=$(basename "$backup")
    TIMESTAMP=${FILENAME#openclaw.json.}
    SIZE=$(du -h "$backup" | cut -f1)
    
    # Parse timestamp
    YEAR=${TIMESTAMP:0:4}
    MONTH=${TIMESTAMP:4:2}
    DAY=${TIMESTAMP:6:2}
    HOUR=${TIMESTAMP:9:2}
    MINUTE=${TIMESTAMP:11:2}
    SECOND=${TIMESTAMP:13:2}
    
    DATE_STR="$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND"
    
    echo "[$COUNT] $DATE_STR ($SIZE)"
    echo "    $backup"
    echo
    
    COUNT=$((COUNT + 1))
done <<< "$BACKUPS"

echo "Total: $(echo "$BACKUPS" | wc -l) backup(s)"
echo
echo "To restore a backup:"
echo "  cp <backup-path> ~/.openclaw/openclaw.json"
echo "  openclaw gateway restart"
