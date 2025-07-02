# Claude-Discord Bot Setup

This Discord bot enables bi-directional messaging between Claude and Discord.

## Prerequisites

- Node.js 16.11.0 or higher
- A Discord bot token
- The Reply Service running

## Discord Bot Setup

1. **Create a Discord Application**:
   - Go to https://discord.com/developers/applications
   - Click "New Application" and give it a name
   - Go to the "Bot" section
   - Click "Add Bot"
   - Copy the bot token

2. **Configure Bot Permissions**:
   - In the "Bot" section, enable these Privileged Gateway Intents:
     - MESSAGE CONTENT INTENT
   - In the "OAuth2" → "URL Generator" section:
     - Select "bot" scope
     - Select these permissions:
       - Read Messages/View Channels
       - Send Messages
       - Send Messages in Threads
       - Create Public Threads
       - Read Message History
       - Add Reactions

3. **Invite Bot to Server**:
   - Copy the generated URL from step 2
   - Open it in your browser and select your server

## Installation

1. **Install dependencies**:
   ```bash
   cd discord-bot
   npm install
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Set up your `.env` file**:
   ```
   DISCORD_BOT_TOKEN=your-bot-token
   DISCORD_CHANNEL_IDS=channel-id-1,channel-id-2
   REPLY_SERVICE_URL=http://localhost:3000
   REPLY_SERVICE_API_KEY=your-api-key
   ```

4. **Run the bot**:
   ```bash
   npm start
   # Or for development with auto-reload:
   npm run dev
   ```

## How It Works

1. The bot monitors specified Discord channels
2. When users reply to Claude's messages, the bot detects it
3. Replies are sent to the Reply Service
4. Claude polls the Reply Service and receives the messages

## Features

- **Thread Support**: Automatically tracks conversations in threads
- **Reply Detection**: Recognizes direct replies to Claude messages
- **Visual Feedback**: Shows ⏳ while processing, ✅ on success, ❌ on error
- **Session Tracking**: Maintains conversation context across messages

## Troubleshooting

- **Bot not responding**: Check if the bot has permissions in the channel
- **Authentication errors**: Verify your API key matches the Reply Service
- **Missing messages**: Ensure MESSAGE CONTENT INTENT is enabled