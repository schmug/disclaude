require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuration
const config = {
    apiKey: process.env.API_KEY || 'change-me-in-production',
    sessionTimeoutMs: (parseInt(process.env.SESSION_TIMEOUT_MINUTES) || 30) * 60 * 1000,
    messageTtlMs: (parseInt(process.env.MESSAGE_TTL_SECONDS) || 300) * 1000,
    maxMessagesPerSession: parseInt(process.env.MAX_MESSAGES_PER_SESSION) || 100,
    nodeEnv: process.env.NODE_ENV || 'development'
};

// In-memory storage (replace with Redis for production)
const sessions = new Map();
const messageQueues = new Map();

// Middleware
app.use(helmet());
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*'
}));
app.use(express.json());

// Development logging
if (config.nodeEnv === 'development') {
    const morgan = require('morgan');
    app.use(morgan('dev'));
}

// Rate limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
});
app.use('/api/', limiter);

// Authentication middleware
function authenticate(req, res, next) {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token || token !== config.apiKey) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    
    next();
}

// Session management
class Session {
    constructor(id) {
        this.id = id;
        this.createdAt = Date.now();
        this.lastActivity = Date.now();
        this.messageCount = 0;
    }
    
    updateActivity() {
        this.lastActivity = Date.now();
    }
    
    isExpired() {
        return Date.now() - this.lastActivity > config.sessionTimeoutMs;
    }
}

// Message queue management
class MessageQueue {
    constructor(sessionId) {
        this.sessionId = sessionId;
        this.messages = [];
    }
    
    add(message) {
        const messageWithId = {
            ...message,
            id: Date.now().toString(),
            receivedAt: new Date().toISOString()
        };
        
        this.messages.push(messageWithId);
        
        // Limit queue size
        if (this.messages.length > config.maxMessagesPerSession) {
            this.messages.shift();
        }
        
        // Set TTL for the message
        setTimeout(() => {
            this.removeMessage(messageWithId.id);
        }, config.messageTtlMs);
        
        return messageWithId;
    }
    
    removeMessage(messageId) {
        this.messages = this.messages.filter(m => m.id !== messageId);
    }
    
    getMessages(since) {
        if (since) {
            return this.messages.filter(m => m.id > since);
        }
        return this.messages;
    }
    
    clear() {
        this.messages = [];
    }
}

// Clean up expired sessions
setInterval(() => {
    for (const [sessionId, session] of sessions.entries()) {
        if (session.isExpired()) {
            sessions.delete(sessionId);
            messageQueues.delete(sessionId);
            console.log(`Cleaned up expired session: ${sessionId}`);
        }
    }
}, 60000); // Check every minute

// Routes

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        uptime: process.uptime(),
        sessions: sessions.size,
        timestamp: new Date().toISOString()
    });
});

// Create or update session
app.post('/api/sessions/:sessionId', authenticate, (req, res) => {
    const { sessionId } = req.params;
    
    let session = sessions.get(sessionId);
    if (!session) {
        session = new Session(sessionId);
        sessions.set(sessionId, session);
        messageQueues.set(sessionId, new MessageQueue(sessionId));
        console.log(`Created new session: ${sessionId}`);
    } else {
        session.updateActivity();
    }
    
    res.json({
        sessionId: session.id,
        createdAt: new Date(session.createdAt).toISOString(),
        lastActivity: new Date(session.lastActivity).toISOString()
    });
});

// Post a reply from Discord
app.post('/api/replies', authenticate, (req, res) => {
    const { sessionId, message } = req.body;
    
    if (!sessionId || !message) {
        return res.status(400).json({ error: 'Missing sessionId or message' });
    }
    
    // Get or create session
    let session = sessions.get(sessionId);
    if (!session) {
        session = new Session(sessionId);
        sessions.set(sessionId, session);
        messageQueues.set(sessionId, new MessageQueue(sessionId));
    }
    session.updateActivity();
    
    // Add message to queue
    const queue = messageQueues.get(sessionId);
    const savedMessage = queue.add(message);
    
    console.log(`Received reply for session ${sessionId} from ${message.author.username}`);
    
    res.json({
        success: true,
        messageId: savedMessage.id,
        sessionId: sessionId
    });
});

// Get replies for a session (Claude polls this)
app.get('/api/replies/:sessionId', authenticate, (req, res) => {
    const { sessionId } = req.params;
    const { since } = req.query;
    
    const session = sessions.get(sessionId);
    if (!session) {
        return res.json({ messages: [] });
    }
    
    session.updateActivity();
    
    const queue = messageQueues.get(sessionId);
    const messages = queue ? queue.getMessages(since) : [];
    
    res.json({
        sessionId: sessionId,
        messages: messages,
        lastMessageId: messages.length > 0 ? messages[messages.length - 1].id : since
    });
});

// Clear messages for a session
app.delete('/api/replies/:sessionId', authenticate, (req, res) => {
    const { sessionId } = req.params;
    
    const queue = messageQueues.get(sessionId);
    if (queue) {
        queue.clear();
    }
    
    res.json({ success: true });
});

// Session heartbeat
app.post('/api/sessions/:sessionId/heartbeat', authenticate, (req, res) => {
    const { sessionId } = req.params;
    
    const session = sessions.get(sessionId);
    if (!session) {
        return res.status(404).json({ error: 'Session not found' });
    }
    
    session.updateActivity();
    res.json({ success: true });
});

// Error handling
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

// Start server
app.listen(PORT, () => {
    console.log(`Reply service running on port ${PORT}`);
    console.log(`Environment: ${config.nodeEnv}`);
    console.log(`Session timeout: ${config.sessionTimeoutMs / 1000}s`);
    console.log(`Message TTL: ${config.messageTtlMs / 1000}s`);
});