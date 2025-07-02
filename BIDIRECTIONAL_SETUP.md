# Bi-Directional Claude-Discord Messaging Setup

This guide explains how to set up the full bi-directional messaging system that allows Discord users to respond to Claude's messages.

## Architecture Overview

```
┌─────────────┐     ┌──────────────┐     ┌───────────────┐
│   Claude    │────▶│   Discord    │────▶│     User      │
│             │     │  (webhook)   │     │               │
└─────────────┘     └──────────────┘     └───────────────┘
       ▲                                           │
       │            ┌──────────────┐               │
       │            │ Discord Bot  │◀──────────────┘
       │            └──────────────┘
       │                    │
       │            ┌──────────────┐
       └────────────│Reply Service │
                    └──────────────┘
```

## Components

1. **Discord Webhook** (existing): One-way notifications from Claude to Discord
2. **Discord Bot** (new): Listens for user replies in Discord
3. **Reply Service** (new): HTTP API that queues messages for Claude
4. **Reply Checker Hook** (new): Claude polls for new messages

## Quick Start

### 1. Start the Reply Service

```bash
cd reply-service
npm install
cp .env.example .env
# Edit .env with your configuration
npm start
```

The Reply Service will run on `http://localhost:3000` by default.

### 2. Set up the Discord Bot

```bash
cd discord-bot
npm install
cp .env.example .env
# Edit .env with your Discord bot token and configuration
npm start
```

See `discord-bot/README.md` for detailed Discord bot setup instructions.

### 3. Configure Claude Hooks

Add to your Claude settings (`~/.claude/settings.json`):

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
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [{
          "type": "command",
          "command": "REPLY_SERVICE_URL=$REPLY_SERVICE_URL REPLY_SERVICE_API_KEY=$REPLY_SERVICE_API_KEY /path/to/check-replies.sh"
        }]
      }
    ]
  }
}
```

### 4. Environment Variables

Create a `.env` file in the root directory with all required variables:

```bash
# Discord Webhook (for notifications)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_TOKEN

# Discord Bot
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_CHANNEL_IDS=channel-id-1,channel-id-2

# Reply Service
REPLY_SERVICE_URL=http://localhost:3000
REPLY_SERVICE_API_KEY=your-secure-api-key
```

## Usage

1. **Claude sends a notification** → Appears in Discord via webhook
2. **User replies in Discord** → Bot detects and sends to Reply Service
3. **Claude checks for replies** → PostToolUse hook polls Reply Service
4. **Claude receives messages** → Can process and respond accordingly

## Session Management

The system tracks conversations using:
- Discord thread IDs (preferred)
- Embed footer session IDs (fallback)
- Channel-based sessions (last resort)

Sessions expire after 30 minutes of inactivity by default.

## Security Considerations

- Use strong API keys for the Reply Service
- Run services behind a firewall in production
- Consider using HTTPS for the Reply Service
- Rotate Discord bot tokens regularly
- Never commit credentials to version control

## Deployment Options

### Local Development
- Run all services on localhost
- Use the provided `.env.example` files

### Production
- Deploy Reply Service to a VPS or cloud platform
- Run Discord bot on a stable server
- Use a process manager (PM2, systemd, etc.)
- Set up monitoring and logging
- Use Redis for Reply Service persistence

## Troubleshooting

### Bot not detecting replies
- Check bot permissions in Discord
- Verify channel IDs in configuration
- Ensure MESSAGE CONTENT INTENT is enabled

### Claude not receiving messages
- Check Reply Service is running
- Verify API key configuration
- Check hook execution logs
- Ensure proper session tracking

### Session issues
- Messages expire after 5 minutes by default
- Sessions timeout after 30 minutes
- Check Reply Service logs for details

## Advanced Configuration

### Custom Session Tracking
Edit `BOT_USERNAME` and `SESSION_TRACKING_METHOD` in Discord bot `.env`

### Message Persistence
Set `REDIS_URL` in Reply Service `.env` for persistent storage

### Rate Limiting
Adjust `RATE_LIMIT_*` variables in Reply Service `.env`