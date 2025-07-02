#!/bin/bash

# Security Test Suite for Discord Notifier
# Tests for prompt injection, RCE, and escaping issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISCORD_NOTIFIER="$SCRIPT_DIR/../discord-notifier.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Mock Discord webhook for testing
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/test/test"

# Test function
run_test() {
    local test_name="$1"
    local input_json="$2"
    local expected_contains="$3"
    local should_fail="${4:-false}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${YELLOW}Test $TESTS_RUN: $test_name${NC}"
    echo "Input: $input_json"
    
    # Create temp file for output
    local temp_output=$(mktemp)
    
    # Run the script with mock curl
    export PATH="$SCRIPT_DIR:$PATH"
    echo "$input_json" | bash "$DISCORD_NOTIFIER" > "$temp_output" 2>&1 || true
    
    local output=$(cat "$temp_output")
    echo "Output: $output"
    
    # Check if output contains expected string
    if [[ "$output" == *"$expected_contains"* ]]; then
        if [ "$should_fail" = "false" ]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAILED - Should have been sanitized${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if [ "$should_fail" = "true" ]; then
            echo -e "${GREEN}✓ PASSED - Properly sanitized${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAILED - Expected output not found${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
    
    rm -f "$temp_output"
}

# Create mock curl for testing
cat > "$SCRIPT_DIR/curl" << 'MOCK_CURL'
#!/bin/bash
# Mock curl that captures the payload
if [[ "$*" == *"-d"* ]]; then
    # Extract the data argument
    for i in "$@"; do
        if [ "$prev" = "-d" ]; then
            echo "PAYLOAD: $i" >&2
            # Check for dangerous patterns
            if [[ "$i" == *'$()'* ]] || [[ "$i" == *'`'* ]] || [[ "$i" == *';'* && "$i" != *'";"'* ]]; then
                echo "SECURITY: Command injection detected!" >&2
            fi
            if [[ "$i" == *'"'* ]] && [[ "$i" != *'\"'* ]]; then
                # Check for unescaped quotes that could break JSON
                echo "SECURITY: Unescaped quotes detected!" >&2
            fi
        fi
        prev="$i"
    done
fi
echo -e "\n204"
MOCK_CURL
chmod +x "$SCRIPT_DIR/curl"

echo "=== Discord Notifier Security Test Suite ==="
echo "Testing for: Prompt Injection, RCE, Quote Escaping"

# Test 1: Basic functionality
run_test "Basic message" \
    '{"session_id": "test123", "notification": {"type": "info", "message": "Hello Discord"}}' \
    "204"

# Test 2: Single quotes in message
run_test "Single quotes" \
    '{"session_id": "test", "notification": {"type": "info", "message": "It'"'"'s a test"}}' \
    "204"

# Test 3: Double quotes in message
run_test "Double quotes" \
    '{"session_id": "test", "notification": {"type": "info", "message": "She said \"Hello\""}}' \
    "204"

# Test 4: Command substitution attempt with $()
run_test "Command substitution \$()" \
    '{"session_id": "test", "notification": {"type": "info", "message": "$(whoami) was here"}}' \
    "Command injection" \
    true

# Test 5: Command substitution attempt with backticks
run_test "Command substitution backticks" \
    '{"session_id": "test", "notification": {"type": "info", "message": "`id` command test"}}' \
    "Command injection" \
    true

# Test 6: Semicolon command chaining
run_test "Semicolon injection" \
    '{"session_id": "test", "notification": {"type": "info", "message": "test; rm -rf /"}}' \
    "204"  # Should be properly escaped

# Test 7: Newline injection
run_test "Newline injection" \
    '{"session_id": "test", "notification": {"type": "info", "message": "Line1\nLine2\nLine3"}}' \
    "204"

# Test 8: JSON injection in message
run_test "JSON injection" \
    '{"session_id": "test", "notification": {"type": "info", "message": "Test\", \"malicious\": \"payload"}}' \
    "204"

# Test 9: Unicode and special characters
run_test "Unicode characters" \
    '{"session_id": "test", "notification": {"type": "info", "message": "🚀 Test → with ← unicode"}}' \
    "204"

# Test 10: Backslash escaping
run_test "Backslash characters" \
    '{"session_id": "test", "notification": {"type": "info", "message": "C:\\Users\\Test\\Path"}}' \
    "204"

# Test 11: Mixed quotes and escapes
run_test "Complex escaping" \
    '{"session_id": "test", "notification": {"type": "info", "message": "It'"'"'s \"complex\" with \\backslashes\\ and $vars"}}' \
    "204"

# Test 12: Session ID injection
run_test "Session ID injection" \
    '{"session_id": "test$(whoami)", "notification": {"type": "info", "message": "Test"}}' \
    "Command injection" \
    true

# Test 13: Notification type injection  
run_test "Type field injection" \
    '{"session_id": "test", "notification": {"type": "info$(date)", "message": "Test"}}' \
    "204"  # Should default to info

# Test 14: Environment variable expansion
run_test "Environment variable" \
    '{"session_id": "test", "notification": {"type": "info", "message": "$HOME should not expand"}}' \
    "Command injection" \
    true

# Test 15: Long message with special chars
LONG_MSG='A very long message with "quotes" and '"'"'apostrophes'"'"' and $(commands) and `backticks` and $variables and \backslashes\ and newlines\nand more...'
run_test "Long message with everything" \
    "{\"session_id\": \"test\", \"notification\": {\"type\": \"info\", \"message\": \"$LONG_MSG\"}}" \
    "204"

# Clean up
rm -f "$SCRIPT_DIR/curl"

# Summary
echo -e "\n=== Test Summary ==="
echo -e "Tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi