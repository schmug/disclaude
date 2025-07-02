export async function handleDiscordWebhook(request, env) {
  try {
    // Parse Discord webhook payload
    const payload = await request.json();
    
    // Verify Discord signature (if using interactions endpoint)
    // This is optional but recommended for security
    
    // Extract message data
    const { 
      channel_id,
      author,
      content,
      id: messageId,
      timestamp
    } = payload;

    // Skip bot messages to prevent loops
    if (author.bot) {
      return new Response('Bot message ignored', { status: 200 });
    }

    // Get or create session mapping for this channel
    const sessionKey = `channel:${channel_id}`;
    let sessionId = await env.SESSIONS.get(sessionKey);
    
    if (!sessionId) {
      // No active session for this channel
      return new Response(
        JSON.stringify({ 
          error: 'No active Claude session for this channel' 
        }),
        { 
          status: 404,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    // Store message in session queue
    const queueKey = `queue:${sessionId}`;
    const queue = JSON.parse(await env.SESSIONS.get(queueKey) || '[]');
    
    queue.push({
      id: messageId,
      content,
      author: author.username,
      authorId: author.id,
      channelId: channel_id,
      timestamp
    });

    // Store updated queue (with 1 hour TTL)
    await env.SESSIONS.put(queueKey, JSON.stringify(queue), {
      expirationTtl: 3600
    });

    return new Response(
      JSON.stringify({ 
        success: true,
        messageId,
        sessionId,
        queueLength: queue.length
      }),
      { 
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Discord webhook error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to process Discord webhook' }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}