#!/bin/bash

# Discord Notifier Hook for Claude Code (Secure Version)
# This script receives notification events from Claude and sends them to Discord
# with proper input validation and escaping

set -euo pipefail

# Load environment variables from .env file
if [ -f ".env" ]; then
    # Use a subshell to prevent variable expansion attacks
    source .env
fi

WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"

# Check if webhook URL is set
if [ -z "$WEBHOOK_URL" ]; then
    echo '{"success": false, "message": "DISCORD_WEBHOOK_URL environment variable not set"}'
    exit 1
fi

# Validate webhook URL format
if ! [[ "$WEBHOOK_URL" =~ ^https://discord\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+$ ]]; then
    echo '{"success": false, "message": "Invalid Discord webhook URL format"}'
    exit 1
fi

# Read JSON input from stdin
INPUT=$(cat)

# Validate JSON input
if ! echo "$INPUT" | jq empty 2>/dev/null; then
    echo '{"success": false, "message": "Invalid JSON input"}'
    exit 1
fi

# Extract fields with strict validation
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null | head -1)
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification.type // "info"' 2>/dev/null | head -1)
MESSAGE=$(echo "$INPUT" | jq -r '.notification.message // "No message provided"' 2>/dev/null | head -1)

# Sanitize session ID - only allow alphanumeric, dash, and underscore
SESSION_ID=$(echo "$SESSION_ID" | tr -cd '[:alnum:]-_' | head -c 50)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"

# Sanitize notification type - only allow known types
case "$NOTIFICATION_TYPE" in
    error|success|warning|info)
        # Valid type
        ;;
    *)
        NOTIFICATION_TYPE="info"
        ;;
esac

# Truncate message if too long (Discord limit is 2000 chars)
if [ ${#MESSAGE} -gt 1900 ]; then
    MESSAGE="${MESSAGE:0:1897}..."
fi

# Properly escape message for JSON using jq
# The -R flag reads raw text, -s slurps it into a single string
# This handles all special characters including quotes, newlines, backslashes
ESCAPED_MESSAGE=$(echo -n "$MESSAGE" | jq -Rs .)

# Create Discord embed based on notification type
case "$NOTIFICATION_TYPE" in
    "error")
        COLOR=15158332  # Red
        TITLE="⚠️ Error"
        ;;
    "success")
        COLOR=3066993   # Green
        TITLE="✅ Success"
        ;;
    "warning")
        COLOR=15105570  # Orange
        TITLE="⚡ Warning"
        ;;
    *)
        COLOR=3447003   # Blue
        TITLE="ℹ️ Info"
        ;;
esac

# Create timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

# Build JSON payload using jq to ensure proper escaping
PAYLOAD=$(jq -n \
  --arg username "Claude Assistant" \
  --arg title "$TITLE" \
  --argjson description "$ESCAPED_MESSAGE" \
  --argjson color "$COLOR" \
  --arg session "${SESSION_ID:0:8}" \
  --arg timestamp "$TIMESTAMP" \
  '{
    username: $username,
    embeds: [{
      title: $title,
      description: $description,
      color: $color,
      footer: {
        text: ("Session: " + $session)
      },
      timestamp: $timestamp
    }]
  }')

# Validate generated payload
if ! echo "$PAYLOAD" | jq empty 2>/dev/null; then
    echo '{"success": false, "message": "Failed to generate valid JSON payload"}'
    exit 1
fi

# Send to Discord with retries
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Use timeout to prevent hanging
    RESPONSE=$(timeout 30 curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "User-Agent: Claude-Discord-Notifier/1.0" \
        --data-raw "$PAYLOAD" \
        "$WEBHOOK_URL" 2>/dev/null) || {
        echo '{"success": false, "message": "Network error or timeout"}'
        exit 1
    }
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    case "$HTTP_CODE" in
        204)
            # Success
            echo '{"success": true, "message": "Notification sent to Discord"}'
            exit 0
            ;;
        429)
            # Rate limited - wait and retry
            sleep 2
            RETRY_COUNT=$((RETRY_COUNT + 1))
            ;;
        400)
            # Bad request - don't retry
            echo '{"success": false, "message": "Discord rejected the request (bad format)"}'
            exit 1
            ;;
        401|403|404)
            # Auth/permission errors - don't retry
            echo '{"success": false, "message": "Discord webhook authentication failed"}'
            exit 1
            ;;
        *)
            # Other errors - retry
            RETRY_COUNT=$((RETRY_COUNT + 1))
            ;;
    esac
done

# Max retries exceeded
echo '{"success": false, "message": "Max retries exceeded"}'
exit 1