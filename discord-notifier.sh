#!/bin/bash

# Discord Notifier Hook for Claude Code
# This script receives notification events from Claude and sends them to Discord

# Discord webhook URL
WEBHOOK_URL="https://discord.com/api/webhooks/1389593574823297265/_vH5vyOwwidXgh5tnhUpiqBue6sWLWCisXmvTyVj7xScECIkKRnleOt_zndX5Zq_3bXU"

# Read JSON input from stdin
INPUT=$(cat)

# Extract notification details using jq (ensure jq is installed)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification.type // "info"' 2>/dev/null)
MESSAGE=$(echo "$INPUT" | jq -r '.notification.message // "No message provided"' 2>/dev/null)

# Truncate message if too long (Discord limit is 2000 chars)
if [ ${#MESSAGE} -gt 1900 ]; then
    MESSAGE="${MESSAGE:0:1897}..."
fi

# Escape message for JSON
ESCAPED_MESSAGE=$(echo "$MESSAGE" | jq -Rs .)

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

# Create Discord webhook payload
PAYLOAD=$(cat <<EOF
{
    "username": "Claude Assistant",
    "embeds": [{
        "title": "$TITLE",
        "description": $ESCAPED_MESSAGE,
        "color": $COLOR,
        "footer": {
            "text": "Session: ${SESSION_ID:0:8}"
        },
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
    }]
}
EOF
)

# Send to Discord with retries
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        "$WEBHOOK_URL")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "204" ]; then
        # Success - return success to Claude
        echo '{"success": true, "message": "Notification sent to Discord"}'
        exit 0
    elif [ "$HTTP_CODE" = "429" ]; then
        # Rate limited - wait and retry
        sleep 2
        RETRY_COUNT=$((RETRY_COUNT + 1))
    else
        # Other error
        echo '{"success": false, "message": "Failed to send to Discord: HTTP '"$HTTP_CODE"'"}'
        exit 1
    fi
done

# Max retries exceeded
echo '{"success": false, "message": "Max retries exceeded"}'
exit 1