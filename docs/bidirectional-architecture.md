# Bidirectional Discord-Claude Integration Architecture

## Overview
This document outlines the architecture for enabling bidirectional communication between Claude Code and Discord using Cloudflare Workers.

## Architecture Components

### 1. Cloudflare Worker
- **Purpose**: Acts as a bridge between Discord and Claude Code
- **Endpoints**:
  - `/discord/webhook` - Receives Discord interactions
  - `/claude/poll/{session_id}` - Claude polls for new messages
  - `/claude/ack/{message_id}` - Claude acknowledges message receipt

### 2. Cloudflare KV Storage
- **Purpose**: Store session state and message queues
- **Keys**:
  - `session:{session_id}` - Active Claude sessions
  - `queue:{session_id}` - Pending messages for Claude
  - `channel:{channel_id}` - Maps Discord channels to sessions

### 3. Discord Bot
- **Purpose**: Listen to messages and forward to Cloudflare Worker
- **Permissions Required**:
  - Read Messages
  - Send Messages
  - Read Message History
  - Use Slash Commands (optional)

## Data Flow

### Claude → Discord (Existing)
1. Claude triggers notification event
2. Hook executes `discord-notifier.sh`
3. Script sends webhook POST to Discord

### Discord → Claude (New)
1. User sends message in Discord channel
2. Discord bot receives message event
3. Bot forwards to Cloudflare Worker
4. Worker stores in session queue (KV)
5. Claude polls Worker endpoint
6. Worker returns queued messages
7. Claude processes and responds

## Message Format

### Discord to Claude
```json
{
  "session_id": "claude-abc123",
  "message": {
    "id": "discord-message-id",
    "content": "User message text",
    "author": {
      "id": "user-id",
      "username": "username"
    },
    "channel_id": "channel-id",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### Claude Poll Response
```json
{
  "messages": [
    {
      "id": "message-id",
      "content": "Message content",
      "author": "username",
      "timestamp": "2024-01-01T00:00:00Z"
    }
  ],
  "has_more": false
}
```

## Session Management

### Session Creation
1. Claude starts with session ID in environment
2. First notification includes session metadata
3. Worker creates session mapping

### Session Lifecycle
- Sessions expire after 24 hours of inactivity
- Claude can extend session with heartbeat
- Graceful cleanup on Claude exit

## Security Considerations

1. **Authentication**:
   - Bearer token for Claude → Worker
   - Discord bot token validation
   - Optional IP allowlisting

2. **Rate Limiting**:
   - Per-session message limits
   - Global rate limits on Worker

3. **Data Privacy**:
   - Messages stored temporarily (TTL: 1 hour)
   - No permanent message logging
   - Session data encrypted at rest

## Implementation Plan

### Phase 1: Worker Setup
- Create Cloudflare Worker project
- Implement basic endpoints
- Set up KV namespace

### Phase 2: Discord Bot
- Create Discord application
- Implement message forwarding
- Handle connection lifecycle

### Phase 3: Claude Integration
- Add polling logic to Claude hooks
- Implement message processing
- Create response flow

### Phase 4: Testing & Deployment
- End-to-end testing
- Performance optimization
- Production deployment

## Configuration

### Environment Variables
- `DISCORD_BOT_TOKEN` - Discord bot authentication
- `CLOUDFLARE_ACCOUNT_ID` - CF account
- `CLOUDFLARE_API_TOKEN` - CF API access
- `WORKER_URL` - Deployed worker endpoint
- `CLAUDE_AUTH_TOKEN` - Bearer token for Claude

### Cloudflare Settings
- Worker name: `disclaude-bridge`
- KV namespace: `disclaude_sessions`
- Custom domain (optional): `disclaude.example.com`