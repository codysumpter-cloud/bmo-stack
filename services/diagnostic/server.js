/**
 * Simple HTTP server for diagnostic consultations
 * Exposes Pump Specialist agent to FLOWCOMMANDER Flutter app
 */

const http = require('http');
const url = require('url');
const DiagnosticConsultationService = require('./consultation-service');

// Initialize service
const diagnosticService = new DiagnosticConsultationService();

const server = http.createServer(async (req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  
  // Health check endpoint
  if (path === '/api/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', service: 'diagnostic-consultation' }));
    return;
  }
  
  // Diagnostic consultation endpoint
  if (path === '/api/diagnose' && req.method === 'POST') {
    let body = '';
    
    // Collect request body
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', async () => {
      try {
        const context = JSON.parse(body);
        
        // Validate required fields
        if (!context.symptom) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Missing required field: symptom' }));
          return;
        }
        
        // Get consultation from pump specialist
        const enhancement = await diagnosticService.consult(context);
        
        // Return enhancement
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(enhancement));
      } catch (error) {
        console.error('Error processing diagnostic consultation:', error);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
          error: 'Internal server error', 
          message: error.message 
        }));
      }
    });
    
    return;
  }
  
  // Not found
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Endpoint not found' }));
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`Diagnostic consultation server running on port ${PORT}`);
});

module.exports = server;