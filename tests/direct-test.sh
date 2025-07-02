#!/bin/bash

# Direct security test without mocking

set -e

# Test dangerous inputs directly
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/123456789/test-webhook"

echo "Testing command injection with \$(whoami):"
echo '{"session_id": "test", "notification": {"type": "info", "message": "User $(whoami) was here"}}' | ./discord-notifier-secure.sh

echo -e "\nTesting JSON injection:"
echo '{"session_id": "test", "notification": {"type": "info", "message": "Test\", \"malicious\": \"value"}}' | ./discord-notifier-secure.sh

echo -e "\nTesting single quotes:"
echo '{"session_id": "test", "notification": {"type": "info", "message": "It'"'"'s working!"}}' | ./discord-notifier-secure.sh

echo -e "\nTesting backticks:"
echo '{"session_id": "test", "notification": {"type": "info", "message": "Result: `id`"}}' | ./discord-notifier-secure.sh

echo -e "\nTesting newlines:"
echo '{"session_id": "test", "notification": {"type": "info", "message": "Line1\nLine2\nLine3"}}' | ./discord-notifier-secure.sh

echo -e "\nTesting session ID with special chars:"
echo '{"session_id": "test-$(whoami)-`id`-;rm", "notification": {"type": "info", "message": "Test"}}' | ./discord-notifier-secure.sh

echo -e "\nTesting environment variables:"
echo '{"session_id": "test", "notification": {"type": "info", "message": "$HOME and $USER should not expand"}}' | ./discord-notifier-secure.sh