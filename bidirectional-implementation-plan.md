# Bi-Directional Claude-Discord Messaging Implementation Plan

## Overview

This document outlines the implementation plan for adding bi-directional messaging capabilities to the Claude-Discord integration, allowing users to respond to Claude's messages and have those responses routed back to the active Claude session.

## Architecture

### Components

1. **Discord Bot** (New)
   - Listens for messages in configured channels
   - Tracks Claude's messages and subsequent replies
   - Forwards replies to the Reply Service
   - Manages conversation threading

2. **Reply Service** (New)
   - HTTP API server that receives replies from Discord bot
   - Maintains session state and message queues
   - Provides endpoint for Claude to poll for new messages
   - Handles session lifecycle management

3. **Claude Hook Extension** (New)
   - Additional hook for checking incoming messages
   - Periodic polling mechanism
   - Message processing and context injection

4. **Existing Webhook Notifier** (Unchanged)
   - Continues to handle simple one-way notifications
   - Remains available for basic setups

### Data Flow

```
Claude → Notification Hook → Discord (via webhook or bot)
                                ↓
User types reply in Discord ←──┘
        ↓
Discord Bot detects reply
        ↓
Bot sends to Reply Service
        ↓
Reply Service queues message
        ↓
Claude polls Reply Service
        ↓
Claude receives and processes reply
```

## Implementation Phases

### Phase 1: Discord Bot Foundation
- Create bot application in Discord Developer Portal
- Implement basic bot structure with discord.js or discord.py
- Add message listening and filtering capabilities
- Implement reply detection logic

### Phase 2: Reply Service
- Create HTTP API server (Express.js or FastAPI)
- Implement session management with Redis or in-memory store
- Create endpoints:
  - `POST /replies` - Receive replies from Discord bot
  - `GET /replies/:sessionId` - Claude polls for messages
  - `POST /sessions/:sessionId/heartbeat` - Keep sessions alive
- Add message queue with TTL

### Phase 3: Claude Integration
- Create new hook script for polling replies
- Implement polling mechanism with backoff
- Add reply processing logic
- Handle session context management

### Phase 4: Enhanced Features
- Thread management in Discord
- Message persistence
- Typing indicators
- Rich message formatting
- File attachment support

## Technical Decisions

### Language/Framework Options

**Discord Bot:**
- **Option 1: Node.js with discord.js** (Recommended)
  - Pros: Excellent Discord API support, large community
  - Cons: Requires Node.js runtime
  
- **Option 2: Python with discord.py**
  - Pros: Simple syntax, good for prototyping
  - Cons: discord.py is in maintenance mode

**Reply Service:**
- **Option 1: Node.js with Express** (Recommended)
  - Pros: Same language as bot, simple deployment
  - Cons: Single-threaded by default
  
- **Option 2: Python with FastAPI**
  - Pros: Modern async support, automatic API docs
  - Cons: Different language from bot

### Session Management
- Use Redis for production deployments
- In-memory store for development/simple setups
- Session timeout: 30 minutes of inactivity
- Message queue with 5-minute TTL

### Security Considerations
- Authenticate Discord bot with Reply Service
- Use API keys for Reply Service endpoints
- Sanitize all user input
- Rate limiting on all endpoints
- No storage of sensitive message content

## Configuration

### Environment Variables
```bash
# Discord Bot
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_CHANNEL_IDS=channel1,channel2
REPLY_SERVICE_URL=http://localhost:3000
REPLY_SERVICE_API_KEY=your-api-key

# Reply Service
PORT=3000
API_KEY=your-api-key
SESSION_TIMEOUT_MINUTES=30
MESSAGE_TTL_SECONDS=300
REDIS_URL=redis://localhost:6379  # Optional
```

### Claude Settings Addition
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
          "command": "REPLY_SERVICE_URL=$REPLY_SERVICE_URL /path/to/check-replies.sh"
        }]
      }
    ]
  }
}
```

## Deployment Options

### Local Development
1. Run Discord bot locally
2. Run Reply Service on localhost
3. Use ngrok for Discord bot if needed

### Production
1. **Discord Bot**: Deploy to VPS, Heroku, or AWS EC2
2. **Reply Service**: Deploy to same infrastructure
3. **Redis**: Use managed Redis service
4. **Monitoring**: Add logging and health checks

## Migration Path

1. Existing webhook users can continue using one-way messaging
2. Bot features are opt-in via configuration
3. Gradual rollout with feature flags
4. Documentation for both simple and advanced setups

## Success Metrics

- Message delivery reliability > 99%
- Reply latency < 2 seconds
- Session persistence across Claude restarts
- Zero message loss during normal operation
- Clear error messages for configuration issues

## Next Steps

1. Set up Discord application and bot account
2. Implement basic Discord bot with message listening
3. Create Reply Service API scaffold
4. Test end-to-end message flow
5. Add production-ready features