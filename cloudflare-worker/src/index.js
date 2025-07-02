import { Router } from 'itty-router';
import { handleDiscordWebhook } from './handlers/discord';
import { handleClaudePoll, handleClaudeAck } from './handlers/claude';
import { authMiddleware } from './middleware/auth';
import { errorHandler } from './middleware/error';

// Create router instance
const router = Router();

// Health check endpoint
router.get('/', () => new Response('Disclaude Bridge Worker is running!'));

// Discord webhook endpoint
router.post('/discord/webhook', handleDiscordWebhook);

// Claude endpoints (protected by auth)
router.get('/claude/poll/:sessionId', authMiddleware, handleClaudePoll);
router.post('/claude/ack/:messageId', authMiddleware, handleClaudeAck);

// 404 for unmatched routes
router.all('*', () => new Response('Not Found', { status: 404 }));

// Export worker
export default {
  async fetch(request, env, ctx) {
    return router
      .handle(request, env, ctx)
      .catch((err) => errorHandler(err, request));
  },
};