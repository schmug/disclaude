# Claude-Discord Integration

This repository contains the Product Requirements Document and example implementation for integrating Claude Code with Discord.

## Files

- `claude-discord-integration-prd.md` - Complete Product Requirements Document
- `discord-notifier.sh` - Example bash script for sending Claude notifications to Discord
- `claude-settings-example.json` - Example Claude Code settings configuration

## Quick Start

1. **Set up Discord webhook**:
   - Copy `.env.example` to `.env`: `cp .env.example .env`
   - Edit `.env` and replace with your actual Discord webhook URL
   - **Never commit the `.env` file to version control!**

2. **Configure Claude Code**: Copy the hooks configuration from `claude-settings-example.json` to your Claude Code settings

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

## Implementation Notes

- The current implementation only handles outbound messages (Claude → Discord)
- For inbound messages (Discord → Claude), you'll need to implement a separate service as described in the PRD
- The webhook URL in the example should be replaced with your own for security

## Security

⚠️ **Important Security Guidelines**:
- **Never commit real webhook URLs to version control**
- Store webhook URLs in environment variables or `.env` files
- Add `.env` to your `.gitignore` file
- Rotate webhook URLs immediately if accidentally exposed
- Use `.env.example` as a template without real credentials