# Claude-Discord Integration

This repository contains the Product Requirements Document and example implementation for integrating Claude Code with Discord.

## Files

- `claude-discord-integration-prd.md` - Complete Product Requirements Document
- `discord-notifier.sh` - Example bash script for sending Claude notifications to Discord
- `claude-settings-example.json` - Example Claude Code settings configuration

## Quick Start

1. **Configure Claude Code**: Copy the hooks configuration from `claude-settings-example.json` to your Claude Code settings

2. **Update the webhook URL**: Edit `discord-notifier.sh` and replace the WEBHOOK_URL with your own Discord webhook

3. **Install dependencies**: Ensure `jq` and `curl` are installed:
   ```bash
   sudo apt-get install jq curl  # Ubuntu/Debian
   brew install jq curl           # macOS
   ```

4. **Test the integration**: Claude notifications will now be sent to your Discord channel

## Implementation Notes

- The current implementation only handles outbound messages (Claude → Discord)
- For inbound messages (Discord → Claude), you'll need to implement a separate service as described in the PRD
- The webhook URL in the example should be replaced with your own for security

## Security

⚠️ **Important**: Never commit real webhook URLs to version control. The URL in this example is for demonstration purposes only.