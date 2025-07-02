#!/bin/bash

# Claude Discord Message Poller
# This script polls the Cloudflare Worker for new Discord messages

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Configuration
WORKER_URL="${WORKER_URL:-http://localhost:8787}"
CLAUDE_SESSION_ID="${CLAUDE_SESSION_ID:-claude-default}"
CLAUDE_AUTH_TOKEN="${CLAUDE_AUTH_TOKEN}"
POLL_INTERVAL="${POLL_INTERVAL:-5}"  # seconds

# Validate required environment variables
if [ -z "$CLAUDE_AUTH_TOKEN" ]; then
    echo "Error: CLAUDE_AUTH_TOKEN is not set" >&2
    exit 1
fi

# Function to poll for messages
poll_messages() {
    local response
    response=$(curl -s -X GET \
        -H "Authorization: Bearer $CLAUDE_AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        "${WORKER_URL}/claude/poll/${CLAUDE_SESSION_ID}")
    
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Error: Failed to poll messages (curl exit code: $exit_code)" >&2
        return 1
    fi
    
    # Check if response is valid JSON
    if ! echo "$response" | jq -e . >/dev/null 2>&1; then
        echo "Error: Invalid JSON response from worker" >&2
        echo "Response: $response" >&2
        return 1
    fi
    
    # Extract messages
    local messages
    messages=$(echo "$response" | jq -r '.messages[]? | @json')
    
    if [ -n "$messages" ]; then
        echo "$messages" | while IFS= read -r message_json; do
            # Parse message fields
            local message=$(echo "$message_json" | jq -r '.')
            local content=$(echo "$message" | jq -r '.content')
            local author=$(echo "$message" | jq -r '.author')
            local message_id=$(echo "$message" | jq -r '.id')
            local timestamp=$(echo "$message" | jq -r '.timestamp')
            
            # Output formatted message for Claude to process
            cat <<EOF
{
  "type": "discord_message",
  "session_id": "$CLAUDE_SESSION_ID",
  "message": {
    "id": "$message_id",
    "content": "$content",
    "author": "$author",
    "timestamp": "$timestamp"
  }
}
EOF
            
            # Acknowledge message receipt
            acknowledge_message "$message_id"
        done
    fi
    
    # Check if there are more messages
    local has_more=$(echo "$response" | jq -r '.has_more // false')
    if [ "$has_more" = "true" ]; then
        # Immediately poll again if there are more messages
        poll_messages
    fi
}

# Function to acknowledge message
acknowledge_message() {
    local message_id="$1"
    
    curl -s -X POST \
        -H "Authorization: Bearer $CLAUDE_AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"sessionId\": \"$CLAUDE_SESSION_ID\", \"status\": \"received\"}" \
        "${WORKER_URL}/claude/ack/${message_id}" >/dev/null 2>&1
}

# Main polling loop
if [ "$1" = "--once" ]; then
    # Single poll mode for testing
    poll_messages
else
    # Continuous polling mode
    echo "Starting Discord message poller for session: $CLAUDE_SESSION_ID" >&2
    echo "Polling interval: ${POLL_INTERVAL}s" >&2
    
    while true; do
        poll_messages
        sleep "$POLL_INTERVAL"
    done
fi