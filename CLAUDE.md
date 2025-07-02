# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude-Discord integration project that enables Claude Code to send notifications to Discord channels via webhooks. The system uses Claude Code's hook mechanism to intercept notification events and forward them to Discord.

## Key Components

### Project Structure
```
disclaude/
├── src/
│   └── discord-notifier.sh      # Main notification script
├── examples/
│   ├── .env.example            # Environment template
│   └── claude-settings-example.json  # Claude hook configuration
├── scripts/
│   ├── install.sh              # Installation helper
│   └── test-notification.sh    # Testing utility
├── docs/
│   └── PRD.md                  # Product requirements
└── tests/                      # Test suites (if present)
```

### Architecture

The integration follows an event-driven pattern:
1. Claude Code triggers notification events
2. Hook system pipes JSON event data to `discord-notifier.sh`
3. Script extracts notification details and formats Discord embed
4. Message sent to Discord webhook with retry logic

### Dependencies

System utilities required:
- `jq` - JSON processing
- `curl` - HTTP requests to Discord API

Install with:
```bash
# Ubuntu/Debian
sudo apt-get install jq curl

# macOS
brew install jq curl
```

## Important Implementation Details

### Discord Webhook Format
The script sends Discord embeds with:
- Color coding based on notification type (error=red, success=green, warning=orange)
- Timestamp and session ID in footer
- 2000 character message limit (Discord API constraint)

### Error Handling
- 3 retry attempts for failed requests
- Special handling for rate limiting (HTTP 429)
- JSON response returned to Claude indicating success/failure

### Security Requirements
- The Discord webhook URL must be provided via the `DISCORD_WEBHOOK_URL` environment variable
- Never hardcode webhook URLs in scripts
- Use `.env` files for local development (already in .gitignore)
- The script will fail with an error if the environment variable is not set

## Future Development

The PRD documents plans for bi-directional communication (receiving Discord replies), which would require implementing a separate service with:
- Discord bot or webhook listener
- Session state management
- HTTP endpoint for Claude to receive replies