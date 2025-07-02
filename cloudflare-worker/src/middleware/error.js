export function errorHandler(error, request) {
  console.error('Worker error:', error.message, {
    url: request.url,
    method: request.method,
    stack: error.stack
  });

  return new Response(
    JSON.stringify({
      error: 'Internal server error',
      message: error.message
    }),
    {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    }
  );
}