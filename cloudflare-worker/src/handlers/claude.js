export async function handleClaudePoll(request, env, ctx) {
  const { sessionId } = ctx.params;
  
  try {
    // Get messages from queue
    const queueKey = `queue:${sessionId}`;
    const queueData = await env.SESSIONS.get(queueKey);
    
    if (!queueData) {
      return new Response(
        JSON.stringify({ messages: [], has_more: false }),
        { 
          status: 200,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    const queue = JSON.parse(queueData);
    
    // Return up to 10 messages at a time
    const messages = queue.slice(0, 10);
    const remaining = queue.slice(10);
    
    // Update queue with remaining messages
    if (remaining.length > 0) {
      await env.SESSIONS.put(queueKey, JSON.stringify(remaining), {
        expirationTtl: 3600
      });
    } else {
      // Clear empty queue
      await env.SESSIONS.delete(queueKey);
    }

    // Update session last activity
    const sessionKey = `session:${sessionId}`;
    const session = JSON.parse(await env.SESSIONS.get(sessionKey) || '{}');
    session.lastActivity = new Date().toISOString();
    await env.SESSIONS.put(sessionKey, JSON.stringify(session), {
      expirationTtl: 86400 // 24 hours
    });

    return new Response(
      JSON.stringify({
        messages,
        has_more: remaining.length > 0,
        session_id: sessionId
      }),
      { 
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Claude poll error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to poll messages' }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

export async function handleClaudeAck(request, env, ctx) {
  const { messageId } = ctx.params;
  
  try {
    const body = await request.json();
    const { sessionId, status } = body;

    // Log acknowledgment (could be used for delivery tracking)
    console.log(`Message ${messageId} acknowledged by session ${sessionId} with status: ${status}`);

    // Optional: Store ack status for tracking
    const ackKey = `ack:${messageId}`;
    await env.SESSIONS.put(ackKey, JSON.stringify({
      sessionId,
      status,
      timestamp: new Date().toISOString()
    }), {
      expirationTtl: 3600 // 1 hour
    });

    return new Response(
      JSON.stringify({ success: true }),
      { 
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Claude ack error:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to acknowledge message' }),
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}