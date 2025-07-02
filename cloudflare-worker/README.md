# Disclaude Bridge - Cloudflare Worker

This Cloudflare Worker enables bidirectional communication between Claude Code and Discord.

## Setup

### 1. Install Dependencies
```bash
cd cloudflare-worker
npm install
```

### 2. Create KV Namespace
```bash
# Create production namespace
wrangler kv:namespace create "SESSIONS"

# Create preview namespace for development
wrangler kv:namespace create "SESSIONS" --preview
```

Copy the IDs from the output and update `wrangler.toml`.

### 3. Configure Secrets
```bash
# Set authentication tokens
wrangler secret put DISCORD_BOT_TOKEN
wrangler secret put CLAUDE_AUTH_TOKEN
```

### 4. Development
```bash
npm run dev
```

### 5. Deploy
```bash
npm run deploy
```

## API Endpoints

### POST /discord/webhook
Receives messages from Discord bot and queues them for Claude.

### GET /claude/poll/:sessionId
Claude polls this endpoint to retrieve queued messages.

### POST /claude/ack/:messageId
Claude acknowledges message receipt.

## Environment Variables

See `.env.example` for required configuration.