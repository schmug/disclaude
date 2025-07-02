# Product Requirements Document: Claude-Discord Messaging Integration

## 1. Introduction

This system enables bi-directional communication between Claude Code and Discord, allowing Claude to send messages to a Discord channel via webhook and receive replies back through a custom hook mechanism. This integration facilitates real-time collaboration and notification capabilities between Claude's AI-powered coding assistant and Discord communication channels.

## 2. Product Overview

The system consists of two primary components:
- **Outbound Messaging**: Claude sends messages to Discord using a webhook URL when triggered by notification events
- **Inbound Messaging**: A Discord bot or webhook listener captures replies and routes them back to Claude through a custom endpoint

The integration leverages Claude Code's hook system to intercept notification events and transform them into Discord messages, while a separate service monitors Discord for replies and feeds them back to Claude's active session.

## 3. Functional Requirements

### Core Features:
- **Message Sending**
  - Intercept Claude Code notification events
  - Format messages for Discord webhook compatibility
  - Send messages to specified Discord channel
  - Handle message formatting (markdown, code blocks, embeds)

- **Reply Receiving**
  - Monitor Discord channel for replies
  - Filter replies based on context (thread, mentions, reactions)
  - Route replies back to Claude's active session
  - Maintain conversation context

- **Session Management**
  - Track active Claude sessions
  - Associate Discord threads with Claude sessions
  - Handle session timeouts and cleanup

- **Error Handling**
  - Retry failed webhook requests
  - Log communication failures
  - Provide fallback notification methods

## 4. Technical Requirements

### Discord Integration:
- **Webhook URL**: `https://discord.com/api/webhooks/1389593574823297265/_vH5vyOwwidXgh5tnhUpiqBue6sWLWCisXmvTyVj7xScECIkKRnleOt_zndX5Zq_3bXU`
- **Message Format**: JSON payload with content, embeds, and optional username/avatar
- **Rate Limits**: Respect Discord's rate limiting (5 requests per 2 seconds)

### Claude Hook Configuration:
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "discord-notifier.sh"
          }
        ]
      }
    ]
  }
}
```

### Data Formats:
- **Hook Input** (from Claude):
  ```json
  {
    "session_id": "string",
    "transcript_path": "string",
    "notification": {
      "type": "string",
      "message": "string"
    }
  }
  ```

- **Discord Webhook Payload**:
  ```json
  {
    "content": "string",
    "username": "Claude",
    "embeds": [{
      "title": "string",
      "description": "string",
      "color": "number"
    }]
  }
  ```

### Reply Service Requirements:
- HTTP endpoint for receiving Discord replies
- WebSocket or polling mechanism for Discord monitoring
- Session state storage (Redis/in-memory)
- Authentication mechanism for secure communication

## 5. User Stories

1. **As Claude**, I want to send status updates to Discord so that team members can monitor my progress on coding tasks.

2. **As a Discord user**, I want to reply to Claude's messages so that I can provide guidance or answer questions during task execution.

3. **As a developer**, I want Claude to notify me in Discord when encountering errors so that I can intervene quickly.

4. **As Claude**, I want to receive confirmation when my Discord messages are delivered so that I know communication was successful.

5. **As a team lead**, I want to see Claude's task completion notifications in Discord so that I can track project progress.

## 6. Acceptance Criteria

### Message Sending:
- ✓ All Claude notifications trigger Discord webhook within 2 seconds
- ✓ Messages preserve formatting (code blocks, lists, links)
- ✓ Failed webhook requests retry up to 3 times
- ✓ Session ID included in Discord message metadata
- ✓ Messages truncated if exceeding Discord's 2000 character limit

### Reply Receiving:
- ✓ Replies from Discord received within 5 seconds
- ✓ Only replies in same thread/channel are processed
- ✓ Reply content accessible to Claude's current session
- ✓ Support for text, code blocks, and attachments
- ✓ Graceful handling of session disconnection

### System Reliability:
- ✓ 99% uptime for message delivery
- ✓ Comprehensive error logging
- ✓ No message loss during network interruptions
- ✓ Clean session cleanup after 30 minutes of inactivity

## 7. Limitations and Constraints

### Technical Limitations:
- Discord webhook cannot receive replies directly (requires separate bot/service)
- Maximum message size limited to 2000 characters (Discord API limit)
- Rate limiting enforces maximum 5 messages per 2 seconds
- Claude hooks execute with user permissions (security consideration)

### Operational Constraints:
- Requires persistent service for reply monitoring
- Discord bot token needed for advanced features (reactions, thread management)
- No built-in message persistence (requires external storage)
- Limited to text-based communication (no voice/video)

### Security Considerations:
- Webhook URL must be kept secure
- No sensitive data should be sent through Discord
- Authentication required for reply endpoint
- Session IDs should be anonymized in public channels