# Claude-Discord Integration

This repository contains the Product Requirements Document and example implementation for integrating Claude Code with Discord.

## Files

- `claude-discord-integration-prd.md` - Complete Product Requirements Document
- `discord-notifier.sh` - Example bash script for sending Claude notifications to Discord
- `claude-settings-example.json` - Example Claude Code settings configuration

## Understanding Claude Code Hooks

Claude Code hooks are user-defined shell commands that execute at specific points during Claude's operation. This integration uses the `Notification` hook to send messages to Discord.

### Available Hook Events

- **PreToolUse**: Runs before tool calls (can block execution)
- **PostToolUse**: Runs after tool completion
- **Notification**: Triggers when Claude sends notifications (used by this integration)
- **Stop**: Executes when Claude finishes responding

### Hook Configuration

Hooks are configured in Claude Code settings files (e.g., `~/.claude/settings.json`). Each hook receives JSON data via stdin and can return JSON to control Claude's behavior.

⚠️ **Security Note**: Hooks execute with your full user permissions. Only use trusted scripts.

## Quick Start

1. **Set up Discord webhook**:
   - Copy `.env.example` to `.env`: `cp .env.example .env`
   - Edit `.env` and replace with your actual Discord webhook URL
   - **Never commit the `.env` file to version control!**

2. **Configure Claude Code**: 
   - Copy the hooks configuration from `claude-settings-example.json` to your Claude Code settings
   - Or add to your existing `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "Notification": [
         {
           "matcher": ".*",
           "hooks": [{
             "type": "command",
             "command": "DISCORD_WEBHOOK_URL=$DISCORD_WEBHOOK_URL /path/to/discord-notifier.sh"
           }]
         }
       ]
     }
   }
   ```

3. **Install dependencies**: Ensure `jq` and `curl` are installed:
   ```bash
   sudo apt-get install jq curl  # Ubuntu/Debian
   brew install jq curl           # macOS
   ```

4. **Test the integration**: 
   ```bash
   # Set the environment variable (or add to .env)
   export DISCORD_WEBHOOK_URL="your-webhook-url-here"
   
   # Test the notifier
   echo '{"session_id": "test", "notification": {"type": "info", "message": "Test message"}}' | ./discord-notifier.sh
   ```

## How It Works

1. Claude Code generates a notification event
2. The Notification hook is triggered with JSON data containing:
   - `session_id`: Unique identifier for the Claude session
   - `notification.type`: Type of notification (info, success, warning, error)
   - `notification.message`: The notification content
3. The `discord-notifier.sh` script processes this data and sends a formatted message to Discord
4. Discord displays the message as an embedded card with color coding based on notification type

## Implementation Notes

- The current implementation only handles outbound messages (Claude → Discord)
- For inbound messages (Discord → Claude), you'll need to implement a separate service as described in the PRD
- Hook scripts have a 60-second execution timeout
- Failed hooks won't prevent Claude from continuing operation

## Security

⚠️ **Important Security Guidelines**:
- **Never commit real webhook URLs to version control**
- Store webhook URLs in environment variables or `.env` files
- Add `.env` to your `.gitignore` file
- Rotate webhook URLs immediately if accidentally exposed
- Use `.env.example` as a template without real credentials

## Resources

- [Claude Code Hooks Documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Discord Webhook Guide](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)