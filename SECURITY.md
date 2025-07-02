# Security Guidelines for Claude-Discord Integration

This document outlines the security measures implemented in the Claude-Discord integration to prevent common vulnerabilities.

## Security Improvements

### 1. Input Validation

- **JSON Validation**: All input is validated as proper JSON before processing
- **URL Validation**: Discord webhook URLs must match the expected format
- **Session ID Sanitization**: Only alphanumeric characters, dashes, and underscores allowed
- **Type Validation**: Notification types restricted to known values (info, success, warning, error)

### 2. Injection Prevention

#### Command Injection Protection
- No shell expansion of user input
- Proper quoting and escaping using `jq`
- No use of `eval` or similar dangerous constructs
- Environment variables don't expand in user messages

#### JSON Injection Protection
- All strings properly escaped using `jq -Rs`
- Special characters handled correctly:
  - Double quotes: `"`
  - Single quotes: `'`
  - Backslashes: `\`
  - Newlines: `\n`
  - Unicode characters

### 3. Implementation Details

#### Secure String Handling
```bash
# Bad - vulnerable to injection
PAYLOAD="{\"message\": \"$MESSAGE\"}"

# Good - properly escaped
ESCAPED_MESSAGE=$(echo -n "$MESSAGE" | jq -Rs .)
PAYLOAD=$(jq -n --argjson description "$ESCAPED_MESSAGE" '{description: $description}')
```

#### Session ID Sanitization
```bash
# Remove any characters that could be used for injection
SESSION_ID=$(echo "$SESSION_ID" | tr -cd '[:alnum:]-_' | head -c 50)
```

#### Safe Variable Usage
- Use of `set -euo pipefail` for strict error handling
- Proper quoting of all variables: `"$VAR"` not `$VAR`
- Default values to prevent undefined behavior: `"${VAR:-default}"`

### 4. Network Security

- **Timeout Protection**: 30-second timeout on curl requests
- **HTTPS Only**: Webhook URLs must use HTTPS
- **Rate Limit Handling**: Proper retry logic with backoff
- **Error Differentiation**: Different handling for auth vs temporary errors

### 5. Testing Security

Run the security test suite to verify protection:
```bash
./tests/security-test.sh
```

Test cases include:
- Command substitution attempts: `$(whoami)` and `` `id` ``
- Environment variable expansion: `$HOME`, `$USER`
- JSON injection: `"malicious": "payload"`
- Special characters: quotes, newlines, backslashes
- Unicode and emoji handling
- Very long messages (truncation)
- Null bytes and control characters

### 6. Best Practices for Users

1. **Environment Variables**
   - Never hardcode sensitive data
   - Use `.env` files (already in `.gitignore`)
   - Rotate webhook URLs if exposed

2. **Hook Configuration**
   - Only use hooks from trusted sources
   - Review hook scripts before installation
   - Use minimal permissions

3. **Monitoring**
   - Check Discord audit logs regularly
   - Monitor for unexpected messages
   - Set up webhook rate limits in Discord

### 7. Limitations

Even with these protections:
- Hooks run with user permissions
- Malicious hook configurations could still cause issues
- Discord webhook URLs should be treated as secrets

### 8. Reporting Security Issues

If you discover a security vulnerability:
1. Do not open a public issue
2. Contact the maintainers privately
3. Provide details and proof of concept
4. Allow time for a fix before disclosure

## Security Checklist

When modifying the scripts, ensure:
- [ ] All user input is validated
- [ ] No shell expansion of user data
- [ ] Proper JSON escaping using `jq`
- [ ] Session IDs are sanitized
- [ ] Error messages don't leak sensitive info
- [ ] Timeouts are in place
- [ ] Tests pass including security tests