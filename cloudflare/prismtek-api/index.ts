import { AI } from '@cloudflare/ai';

// Define types for OpenAI-compatible chat completion
interface ChatCompletionRequest {
  model?: string;
  messages: Array<{ role: string; content: string }>;
  temperature?: number;
  max_tokens?: number;
  stream?: boolean;
  [key: string]: any;
}

interface ChatCompletionChoice {
  index: number;
  message: { role: string; content: string };
  finish_reason: string | null;
}

interface ChatCompletionUsage {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

interface ChatCompletionResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: ChatCompletionChoice[];
  usage: ChatCompletionUsage;
}

// Handle CORS preflight
function handleCors(request: Request): Response | null {
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '86400',
      },
    });
  }
  return null;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    // Handle CORS
    const corsResponse = handleCors(request);
    if (corsResponse) return corsResponse;

    const url = new URL(request.url);
    
    // Health check endpoint
    if (url.pathname === '/healthz') {
      return Response.json({ 
        ok: true, 
        service: 'prismtek-api',
        timestamp: new Date().toISOString(),
        env: {
          hasNvidiaKey: !!env.NVIDIA_API_KEY,
          hasGatewayAccount: !!env.AI_GATEWAY_ACCOUNT_ID,
          hasGatewayName: !!env.AI_GATEWAY_GATEWAY_NAME,
          gatewayAccount: env.AI_GATEWAY_ACCOUNT_ID ? '(set)' : '(not set)',
          gatewayName: env.AI_GATEWAY_GATEWAY_NAME ? '(set)' : '(not set)'
        }
      });
    }
    
    // OpenAI-compatible chat completions endpoint
    if (url.pathname === '/v1/chat/completions' && request.method === 'POST') {
      try {
        // Debug: Log what we have
        console.log('DEBUG: Checking env vars');
        console.log('DEBUG: NVIDIA_API_KEY present:', !!env.NVIDIA_API_KEY);
        console.log('DEBUG: AI_GATEWAY_ACCOUNT_ID present:', !!env.AI_GATEWAY_ACCOUNT_ID);
        console.log('DEBUG: AI_GATEWAY_GATEWAY_NAME present:', !!env.AI_GATEWAY_GATEWAY_NAME);
        
        // Check for required environment variables
        if (!env.NVIDIA_API_KEY) {
          return Response.json(
            { error: 'NVIDIA_API_KEY not configured' },
            { status: 500 }
          );
        }
        
        if (!env.AI_GATEWAY_ACCOUNT_ID || !env.AI_GATEWAY_GATEWAY_NAME) {
          return Response.json(
            { 
              error: 'AI Gateway not configured', 
              details: {
                AI_GATEWAY_ACCOUNT_ID: env.AI_GATEWAY_ACCOUNT_ID || '(missing)',
                AI_GATEWAY_GATEWAY_NAME: env.AI_GATEWAY_GATEWAY_NAME || '(missing)'
              }
            },
            { status: 500 }
          );
        }
        
        // Parse request body
        let requestData: ChatCompletionRequest;
        try {
          requestData = await request.json();
        } catch (e) {
          return Response.json(
            { error: 'Invalid JSON in request body' },
            { status: 400 }
          );
        }
        
        // Prepare the request to NVIDIA via AI Gateway
        const gatewayUrl = `https://gateway.ai.cloudflare.com/v1/${env.AI_GATEWAY_ACCOUNT_ID}/${env.AI_GATEWAY_GATEWAY_NAME}`;
        
        console.log('DEBUG: Forwarding to:', gatewayUrl);
        
        const nvidiaResponse = await fetch(`${gatewayUrl}/v1/chat/completions`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${env.NVIDIA_API_KEY}`,
          },
          body: JSON.stringify(requestData),
        });
        
        console.log('DEBUG: NVIDIA response status:', nvidiaResponse.status);
        
        if (!nvidiaResponse.ok) {
          const errorText = await nvidiaResponse.text();
          console.log('DEBUG: NVIDIA error:', errorText);
          return Response.json(
            { error: `NVIDIA API error: ${nvidiaResponse.status} - ${errorText}` },
            { status: nvidiaResponse.status }
          );
        }
        
        const responseData = await nvidiaResponse.json();
        
        // Return the response with CORS headers
        return Response.json(responseData, {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          },
        });
      } catch (error) {
        console.log('DEBUG: Exception:', error);
        return Response.json(
          { error: `Internal server error: ${error.message}` },
          { status: 500 }
        );
      }
    }
    
    // Original health check and echo endpoints for backward compatibility
    if (url.pathname === '/healthz') {
      return Response.json({ ok: true, service: 'prismtek-api' });
    }
    
    // Default response
    return Response.json({ 
      ok: true, 
      service: 'prismtek-api', 
      path: url.pathname,
      message: 'Use /v1/chat/completions for AI chat or /healthz for health check'
    });
  },
};
