export async function authMiddleware(request, env) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(
      JSON.stringify({ error: 'Missing or invalid authorization header' }),
      { 
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }

  const token = authHeader.substring(7);
  
  // Verify token against stored secret
  if (token !== env.CLAUDE_AUTH_TOKEN) {
    return new Response(
      JSON.stringify({ error: 'Invalid authentication token' }),
      { 
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }

  // Auth successful, continue to handler
  return null;
}