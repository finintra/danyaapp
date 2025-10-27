const express = require('express');
const bodyParser = require('body-parser');
const app = express();

// Middleware
app.use(bodyParser.json());

// Test route
app.post('/test', (req, res) => {
  console.log('Request body:', req.body);
  console.log('Request headers:', req.headers);
  
  res.json({
    success: true,
    receivedData: req.body
  });
});

// Start server
const PORT = 3002;
app.listen(PORT, () => {
  console.log(`Test server running on port ${PORT}`);
});

// Make a test request from the mobile app
const http = require('http');

// Function to simulate a request from the mobile app
function simulateAppRequest() {
  const data = JSON.stringify({
    picking_barcode: 'OUT/00001'
  });
  
  const options = {
    hostname: 'localhost',
    port: 3002,
    path: '/test',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data)
    }
  };
  
  const req = http.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);
    console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
    
    let responseData = '';
    res.on('data', (chunk) => {
      responseData += chunk;
    });
    
    res.on('end', () => {
      console.log('Response body:', responseData);
    });
  });
  
  req.on('error', (e) => {
    console.error(`Problem with request: ${e.message}`);
  });
  
  // Write data to request body
  req.write(data);
  req.end();
}

// Wait for server to start then make the request
setTimeout(simulateAppRequest, 1000);
