require('dotenv').config();
const { Client, GatewayIntentBits, Partials } = require('discord.js');
const axios = require('axios');

// Configuration
const config = {
    botToken: process.env.DISCORD_BOT_TOKEN,
    channelIds: process.env.DISCORD_CHANNEL_IDS?.split(',').map(id => id.trim()) || [],
    replyServiceUrl: process.env.REPLY_SERVICE_URL || 'http://localhost:3000',
    replyServiceApiKey: process.env.REPLY_SERVICE_API_KEY,
    botUsername: process.env.BOT_USERNAME || 'Claude Assistant',
    sessionTrackingMethod: process.env.SESSION_TRACKING_METHOD || 'thread'
};

// Validate configuration
if (!config.botToken) {
    console.error('Error: DISCORD_BOT_TOKEN not set in environment variables');
    process.exit(1);
}

// Create Discord client
const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMessageReactions
    ],
    partials: [Partials.Message, Partials.Channel, Partials.Reaction]
});

// Session tracking
const sessions = new Map();

// Helper function to extract session ID from message
function getSessionId(message) {
    if (config.sessionTrackingMethod === 'thread' && message.thread) {
        return `thread-${message.thread.id}`;
    }
    
    // Try to extract from embed footer (for webhook messages)
    if (message.embeds.length > 0 && message.embeds[0].footer?.text) {
        const match = message.embeds[0].footer.text.match(/Session: ([a-zA-Z0-9-]+)/);
        if (match) return match[1];
    }
    
    // Fallback to channel-based session
    return `channel-${message.channel.id}`;
}

// Helper function to send reply to Claude
async function sendToClaude(sessionId, message, author) {
    try {
        const response = await axios.post(
            `${config.replyServiceUrl}/replies`,
            {
                sessionId,
                message: {
                    content: message.content,
                    author: {
                        id: author.id,
                        username: author.username,
                        discriminator: author.discriminator
                    },
                    timestamp: message.createdAt.toISOString(),
                    messageId: message.id,
                    channelId: message.channel.id
                }
            },
            {
                headers: {
                    'Authorization': `Bearer ${config.replyServiceApiKey}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log(`Reply sent to Claude for session ${sessionId}`);
        return response.data;
    } catch (error) {
        console.error('Error sending reply to Claude:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
        }
        throw error;
    }
}

// Discord event handlers
client.once('ready', () => {
    console.log(`Discord bot logged in as ${client.user.tag}`);
    console.log(`Monitoring channels: ${config.channelIds.join(', ')}`);
    
    // Set bot status
    client.user.setActivity('for Claude messages', { type: 'WATCHING' });
});

// Message handler
client.on('messageCreate', async (message) => {
    // Ignore messages from bots (including self)
    if (message.author.bot) return;
    
    // Check if message is in a monitored channel
    if (config.channelIds.length > 0 && !config.channelIds.includes(message.channel.id)) {
        // Check if it's in a thread of a monitored channel
        if (!message.channel.isThread() || !config.channelIds.includes(message.channel.parentId)) {
            return;
        }
    }
    
    // Look for Claude messages in the conversation context
    let isReplyToClaude = false;
    let sessionId = null;
    
    // Check if replying to a message
    if (message.reference) {
        try {
            const repliedTo = await message.channel.messages.fetch(message.reference.messageId);
            
            // Check if replied to Claude (webhook or bot message)
            if (repliedTo.author.username === config.botUsername || 
                (repliedTo.webhookId && repliedTo.author.username === 'Claude Assistant')) {
                isReplyToClaude = true;
                sessionId = getSessionId(repliedTo);
            }
        } catch (error) {
            console.error('Error fetching replied message:', error);
        }
    }
    
    // Check if in a thread created by Claude
    if (!isReplyToClaude && message.channel.isThread()) {
        const starterMessage = await message.channel.fetchStarterMessage().catch(() => null);
        if (starterMessage && 
            (starterMessage.author.username === config.botUsername ||
             starterMessage.author.username === 'Claude Assistant')) {
            isReplyToClaude = true;
            sessionId = getSessionId(message);
        }
    }
    
    // Send to Claude if this is a reply
    if (isReplyToClaude && sessionId) {
        try {
            // Add reaction to show processing
            await message.react('⏳');
            
            // Send to Claude
            await sendToClaude(sessionId, message, message.author);
            
            // Update reaction to show success
            await message.reactions.cache.get('⏳')?.remove();
            await message.react('✅');
            
        } catch (error) {
            // Update reaction to show error
            await message.reactions.cache.get('⏳')?.remove();
            await message.react('❌');
            
            // Send error message
            await message.reply('Sorry, I couldn\'t forward your message to Claude. Please try again later.');
        }
    }
});

// Error handling
client.on('error', (error) => {
    console.error('Discord client error:', error);
});

process.on('unhandledRejection', (error) => {
    console.error('Unhandled promise rejection:', error);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('Shutting down Discord bot...');
    client.destroy();
    process.exit(0);
});

// Login to Discord
client.login(config.botToken).catch(error => {
    console.error('Failed to login to Discord:', error);
    process.exit(1);
});