import { Client, GatewayIntentBits, Events } from 'discord.js';
import fetch from 'node-fetch';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Configuration
const config = {
  discordToken: process.env.DISCORD_BOT_TOKEN,
  workerUrl: process.env.WORKER_URL || 'http://localhost:8787',
  claudeSessions: new Map(), // Map channel IDs to Claude session IDs
};

// Create Discord client
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
});

// Ready event
client.once(Events.ClientReady, (readyClient) => {
  console.log(`Discord bot logged in as ${readyClient.user.tag}`);
});

// Message event
client.on(Events.MessageCreate, async (message) => {
  // Ignore bot messages
  if (message.author.bot) return;

  // Check if this channel has an active Claude session
  const sessionId = config.claudeSessions.get(message.channel.id);
  
  // For now, we'll forward all non-bot messages
  // In production, you might want to check for a specific prefix or mention
  
  try {
    // Forward message to Cloudflare Worker
    const response = await fetch(`${config.workerUrl}/discord/webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        channel_id: message.channel.id,
        author: {
          id: message.author.id,
          username: message.author.username,
          bot: message.author.bot,
        },
        content: message.content,
        id: message.id,
        timestamp: message.createdAt.toISOString(),
      }),
    });

    const result = await response.json();
    
    if (\!response.ok) {
      console.error('Worker error:', result);
      
      // If no session exists, notify the user
      if (response.status === 404) {
        await message.reply('No active Claude session in this channel. Start one with `/claude start`');
      }
    } else {
      console.log(`Message forwarded: ${message.id} -> Session: ${result.sessionId}`);
    }
  } catch (error) {
    console.error('Failed to forward message:', error);
  }
});

// Slash command handler for session management
client.on(Events.InteractionCreate, async (interaction) => {
  if (\!interaction.isChatInputCommand()) return;

  const { commandName } = interaction;

  if (commandName === 'claude') {
    const subcommand = interaction.options.getSubcommand();
    
    if (subcommand === 'start') {
      const sessionId = interaction.options.getString('session') || generateSessionId();
      
      // Register session mapping
      config.claudeSessions.set(interaction.channel.id, sessionId);
      
      // TODO: Register with Worker
      await interaction.reply(`Claude session started: ${sessionId}`);
      
    } else if (subcommand === 'stop') {
      config.claudeSessions.delete(interaction.channel.id);
      await interaction.reply('Claude session stopped');
    }
  }
});

// Helper to generate session IDs
function generateSessionId() {
  return `claude-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

// Error handling
client.on('error', (error) => {
  console.error('Discord client error:', error);
});

// Login
client.login(config.discordToken);
ENDOFFILE < /dev/null
