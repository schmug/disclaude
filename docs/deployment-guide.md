# Disclaude Bidirectional Deployment Guide

This guide walks through deploying the bidirectional Discord-Claude integration using Cloudflare Workers.

## Prerequisites

- Node.js 18+ installed
- Cloudflare account (free tier is sufficient)
- Discord account with permissions to create bots
- Claude Code CLI installed and configured

## Step 1: Deploy Cloudflare Worker

### 1.1 Install Dependencies
```bash
cd cloudflare-worker
npm install
```

### 1.2 Login to Cloudflare
```bash
npx wrangler login
```

### 1.3 Create KV Namespace
```bash
# Create production namespace
npx wrangler kv:namespace create "SESSIONS"

# Create preview namespace
npx wrangler kv:namespace create "SESSIONS" --preview
```

Copy the generated IDs and update `wrangler.toml`:
```toml
[[kv_namespaces]]
binding = "SESSIONS"
id = "your-production-id"
preview_id = "your-preview-id"
```

### 1.4 Set Secrets
```bash
# Generate a secure token for Claude authentication
CLAUDE_TOKEN=$(openssl rand -hex 32)
echo "Save this token: $CLAUDE_TOKEN"

# Set the secret in Cloudflare
npx wrangler secret put CLAUDE_AUTH_TOKEN
# Paste the token when prompted

# Set Discord bot token (we'll get this in Step 2)
npx wrangler secret put DISCORD_BOT_TOKEN
```

### 1.5 Deploy Worker
```bash
npm run deploy
```

Note the deployed URL (e.g., `https://disclaude-bridge.your-subdomain.workers.dev`)

## Step 2: Create Discord Bot

### 2.1 Create Discord Application
1. Go to https://discord.com/developers/applications
2. Click "New Application"
3. Name it "Disclaude" (or your preference)
4. Navigate to the "Bot" section
5. Click "Add Bot"

### 2.2 Configure Bot Permissions
1. Under "Privileged Gateway Intents", enable:
   - MESSAGE CONTENT INTENT
2. Under "Bot Permissions", select:
   - Send Messages
   - Read Message History
   - Use Slash Commands

### 2.3 Copy Bot Token
1. Click "Reset Token" and copy the token
2. Save this token securely

### 2.4 Invite Bot to Server
1. Go to OAuth2 > URL Generator
2. Select scopes: `bot`, `applications.commands`
3. Select bot permissions from Step 2.2
4. Copy the generated URL and open it
5. Select your Discord server and authorize

## Step 3: Configure Discord Bot

### 3.1 Set Up Bot Environment
```bash
cd discord-bot
cp .env.example .env
```

Edit `.env`:
```env
DISCORD_BOT_TOKEN=your-bot-token-from-step-2
WORKER_URL=https://disclaude-bridge.your-subdomain.workers.dev
```

### 3.2 Install Dependencies
```bash
npm install
```

### 3.3 Register Slash Commands
Create `register-commands.js`:
```javascript
import { REST, Routes, SlashCommandBuilder } from 'discord.js';
import dotenv from 'dotenv';

dotenv.config();

const commands = [
  new SlashCommandBuilder()
    .setName('claude')
    .setDescription('Manage Claude sessions')
    .addSubcommand(subcommand =>
      subcommand
        .setName('start')
        .setDescription('Start a Claude session')
        .addStringOption(option =>
          option.setName('session')
            .setDescription('Session ID (optional)')
            .setRequired(false)))
    .addSubcommand(subcommand =>
      subcommand
        .setName('stop')
        .setDescription('Stop the Claude session')),
].map(command => command.toJSON());

const rest = new REST({ version: '10' }).setToken(process.env.DISCORD_BOT_TOKEN);

(async () => {
  try {
    console.log('Registering slash commands...');
    await rest.put(
      Routes.applicationCommands(YOUR_CLIENT_ID),
      { body: commands },
    );
    console.log('Commands registered!');
  } catch (error) {
    console.error(error);
  }
})();
```

Run: `node register-commands.js`

### 3.4 Start Bot
```bash
npm start
```

## Step 4: Configure Claude Integration

### 4.1 Update Environment
Add to your `.env` file in the disclaude root:
```env
# Bidirectional communication
WORKER_URL=https://disclaude-bridge.your-subdomain.workers.dev
CLAUDE_AUTH_TOKEN=your-generated-token-from-step-1
CLAUDE_SESSION_ID=claude-default
```

### 4.2 Update Claude Hook Configuration
Edit `.claude/settings.local.json`:
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "cd /home/schmug/disclaude && source .env && /home/schmug/disclaude/src/discord-notifier.sh"
          }
        ]
      }
    ],
    "PostMessage": [
      {
        "matcher": ".*discord.*",
        "hooks": [
          {
            "type": "command",
            "command": "/home/schmug/disclaude/src/claude-poller.sh --once"
          }
        ]
      }
    ]
  }
}
```

### 4.3 Test the Integration

1. In Discord, use `/claude start` in a channel
2. Send a test message
3. Run the poller manually to test:
   ```bash
   ./src/claude-poller.sh --once
   ```

## Step 5: Production Deployment

### 5.1 Use a Process Manager (PM2)
```bash
npm install -g pm2

# Start Discord bot
cd discord-bot
pm2 start index.js --name disclaude-bot

# Start Claude poller (optional - can be triggered by hooks)
cd ..
pm2 start src/claude-poller.sh --name disclaude-poller
```

### 5.2 Set Up Monitoring
- Monitor Cloudflare Worker analytics
- Set up Discord bot status monitoring
- Configure alerts for errors

### 5.3 Security Hardening
1. Rotate tokens regularly
2. Implement rate limiting in Worker
3. Add IP allowlisting if needed
4. Enable Cloudflare DDoS protection

## Troubleshooting

### Worker Not Receiving Messages
- Check Discord bot is online
- Verify WORKER_URL in bot .env
- Check Cloudflare Worker logs: `npx wrangler tail`

### Claude Not Receiving Messages
- Verify CLAUDE_AUTH_TOKEN matches
- Check KV namespace is properly bound
- Test poller manually with --once flag

### Session Mapping Issues
- Ensure `/claude start` was run in the channel
- Check KV storage for session mappings
- Verify session hasn't expired (24h TTL)

## Architecture Diagram

```
Discord User
    ↓
Discord Server
    ↓
Discord Bot (discord-bot/)
    ↓
Cloudflare Worker (cloudflare-worker/)
    ↓
KV Storage (Session State)
    ↓
Claude Poller (src/claude-poller.sh)
    ↓
Claude Code CLI
```

## Next Steps

1. Implement message filtering/routing
2. Add support for attachments
3. Create web dashboard for session management
4. Implement message history retrieval
5. Add support for multiple Claude instances