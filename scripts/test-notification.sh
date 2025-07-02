#!/bin/bash
# Test script for Discord notifications

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

# Check webhook URL
if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
    echo "❌ Error: DISCORD_WEBHOOK_URL not set"
    echo "Please edit .env and add your Discord webhook URL"
    exit 1
fi

echo "🧪 Testing Discord notifications..."
echo ""

# Test different notification types
declare -A test_cases=(
    ["info"]="ℹ️ This is an info message from Claude"
    ["success"]="✅ Task completed successfully!"
    ["warning"]="⚡ Warning: This is a test warning"
    ["error"]="❌ Error: This is a test error"
)

for type in "${!test_cases[@]}"; do
    message="${test_cases[$type]}"
    echo "Sending $type notification..."
    
    payload=$(jq -n \
        --arg session "test-$(date +%s)" \
        --arg type "$type" \
        --arg message "$message" \
        '{
            session_id: $session,
            notification: {
                type: $type,
                message: $message
            }
        }')
    
    echo "$payload" | "$PROJECT_ROOT/src/discord-notifier.sh"
    
    # Small delay between messages
    sleep 1
done

echo ""
echo "✅ Test complete! Check your Discord channel for messages."