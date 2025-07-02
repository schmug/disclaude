#!/bin/bash

# Compare security between original and secure versions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL="$SCRIPT_DIR/../discord-notifier.sh"
SECURE="$SCRIPT_DIR/../discord-notifier-secure.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Mock Discord webhook
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/123456789/abc-xyz_123"

# Test cases with potentially dangerous inputs
declare -A test_cases=(
    ["simple"]='{"session_id": "test123", "notification": {"type": "info", "message": "Hello Discord"}}'
    ["single_quote"]='{"session_id": "test", "notification": {"type": "info", "message": "It'"'"'s working"}}'
    ["double_quote"]='{"session_id": "test", "notification": {"type": "info", "message": "She said \"Hello\""}}'
    ["command_sub"]='{"session_id": "test", "notification": {"type": "info", "message": "User $(whoami) logged in"}}'
    ["backticks"]='{"session_id": "test", "notification": {"type": "info", "message": "Output: `date`"}}'
    ["semicolon"]='{"session_id": "test", "notification": {"type": "info", "message": "Step 1; rm -rf /"}}'
    ["newlines"]='{"session_id": "test", "notification": {"type": "info", "message": "Line1\nLine2\nLine3"}}'
    ["json_inject"]='{"session_id": "test", "notification": {"type": "info", "message": "Test\", \"evil\": \"payload"}}'
    ["unicode"]='{"session_id": "test", "notification": {"type": "info", "message": "🚀 Unicode → test ← 完了"}}'
    ["backslash"]='{"session_id": "test", "notification": {"type": "info", "message": "Path: C:\\Users\\Test"}}'
    ["env_var"]='{"session_id": "test", "notification": {"type": "info", "message": "Home is $HOME and user is $USER"}}'
    ["session_inject"]='{"session_id": "test-$(id)", "notification": {"type": "info", "message": "Test"}}'
    ["type_inject"]='{"session_id": "test", "notification": {"type": "error$(ls)", "message": "Test"}}'
    ["null_byte"]='{"session_id": "test", "notification": {"type": "info", "message": "Before\x00After"}}'
    ["very_long"]='{"session_id": "test", "notification": {"type": "info", "message": "'"$(printf 'A%.0s' {1..2500})"'"}}'
)

# Mock curl that shows the payload
cat > "$SCRIPT_DIR/curl" << 'MOCK_CURL'
#!/bin/bash
for arg in "$@"; do
    if [ "$prev" = "--data-raw" ] || [ "$prev" = "-d" ]; then
        echo "PAYLOAD_START"
        echo "$arg"
        echo "PAYLOAD_END"
    fi
    prev="$arg"
done
echo -e "\n204"
MOCK_CURL
chmod +x "$SCRIPT_DIR/curl"

export PATH="$SCRIPT_DIR:$PATH"

echo -e "${BLUE}=== Security Comparison Test ===${NC}"
echo -e "Comparing original vs secure implementation\n"

# Function to test a script
test_script() {
    local script_name="$1"
    local script_path="$2"
    local test_name="$3"
    local input="$4"
    
    echo -e "\n${YELLOW}Testing $script_name with: $test_name${NC}"
    
    # Run test and capture output
    local output
    output=$(echo "$input" | timeout 5 bash "$script_path" 2>&1 || echo "TIMEOUT/ERROR")
    
    # Check for dangerous patterns in output
    local issues=()
    
    if [[ "$output" == *"PAYLOAD_START"* ]]; then
        local payload=$(echo "$output" | sed -n '/PAYLOAD_START/,/PAYLOAD_END/p' | sed '1d;$d')
        
        # Check for command injection indicators
        if [[ "$payload" == *'$('* ]] || [[ "$payload" == *'`'* ]]; then
            issues+=("Command substitution characters present")
        fi
        
        # Check for unescaped quotes that could break JSON
        if echo "$payload" | jq empty 2>/dev/null; then
            echo -e "${GREEN}✓ Valid JSON generated${NC}"
        else
            issues+=("Invalid JSON - potential injection")
            echo -e "${RED}✗ Invalid JSON generated${NC}"
        fi
        
        # Check if dangerous strings are properly escaped
        if [[ "$test_name" == *"inject"* ]] && [[ "$payload" == *"evil"* ]]; then
            issues+=("Injection payload not properly escaped")
        fi
    else
        issues+=("Failed to generate payload")
    fi
    
    if [ ${#issues[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ No security issues detected${NC}"
    else
        echo -e "${RED}✗ Issues found:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  ${RED}- $issue${NC}"
        done
    fi
    
    # Show trimmed output for debugging
    if [[ ${#output} -gt 200 ]]; then
        echo -e "${BLUE}Output preview:${NC} ${output:0:200}..."
    else
        echo -e "${BLUE}Output:${NC} $output"
    fi
}

# Test each case with both versions
for test_name in "${!test_cases[@]}"; do
    input="${test_cases[$test_name]}"
    
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}Test Case: $test_name${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    test_script "ORIGINAL" "$ORIGINAL" "$test_name" "$input"
    test_script "SECURE" "$SECURE" "$test_name" "$input"
done

# Cleanup
rm -f "$SCRIPT_DIR/curl"

echo -e "\n${BLUE}=== Summary ===${NC}"
echo -e "The secure version should handle all edge cases without security issues."
echo -e "Key improvements:"
echo -e "- Proper JSON escaping using jq"
echo -e "- Input validation and sanitization"
echo -e "- Session ID character filtering"
echo -e "- Webhook URL validation"
echo -e "- Timeout protection"