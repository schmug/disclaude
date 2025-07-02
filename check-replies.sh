#!/bin/bash

# Claude Reply Checker Hook
# This script polls the reply service for new Discord messages

# Load environment variables from .env file
if [ -f ".env" ]; then
    source .env
fi

# Configuration
REPLY_SERVICE_URL="${REPLY_SERVICE_URL:-http://localhost:3000}"
REPLY_SERVICE_API_KEY="${REPLY_SERVICE_API_KEY}"
LAST_MESSAGE_FILE="/tmp/claude-discord-last-message-${SESSION_ID:-unknown}"

# Check if API key is set
if [ -z "$REPLY_SERVICE_API_KEY" ]; then
    echo '{"success": false, "message": "REPLY_SERVICE_API_KEY not set"}'
    exit 0  # Non-blocking error
fi

# Read hook input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)

# Read last message ID if exists
LAST_MESSAGE_ID=""
if [ -f "$LAST_MESSAGE_FILE" ]; then
    LAST_MESSAGE_ID=$(cat "$LAST_MESSAGE_FILE")
fi

# Build query parameter
QUERY=""
if [ -n "$LAST_MESSAGE_ID" ]; then
    QUERY="?since=$LAST_MESSAGE_ID"
fi

# Poll for new messages
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $REPLY_SERVICE_API_KEY" \
    -H "Content-Type: application/json" \
    "$REPLY_SERVICE_URL/api/replies/${SESSION_ID}${QUERY}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" != "200" ]; then
    echo '{"success": false, "message": "Failed to fetch replies"}'
    exit 0  # Non-blocking error
fi

# Extract messages
MESSAGES=$(echo "$BODY" | jq -r '.messages // []' 2>/dev/null)
MESSAGE_COUNT=$(echo "$MESSAGES" | jq 'length' 2>/dev/null)

if [ "$MESSAGE_COUNT" -gt 0 ]; then
    # Save last message ID
    LAST_ID=$(echo "$BODY" | jq -r '.lastMessageId // ""' 2>/dev/null)
    if [ -n "$LAST_ID" ]; then
        echo "$LAST_ID" > "$LAST_MESSAGE_FILE"
    fi
    
    # Format messages for output
    FORMATTED_MESSAGES=$(echo "$MESSAGES" | jq -r '.[] | "[\(.author.username)]: \(.content)"' 2>/dev/null)
    
    # Return messages as notification
    echo "{\"success\": true, \"hasMessages\": true, \"messages\": $(echo "$MESSAGES" | jq -c .), \"formatted\": $(echo "$FORMATTED_MESSAGES" | jq -Rs .)}"
else
    echo '{"success": true, "hasMessages": false}'
fi