const axios = require('axios');

async function testApi() {
  try {
    // First, login to get token
    console.log('Logging in...');
    const loginResponse = await axios.post('http://localhost:3000/flf/api/v1/login', {
      login: 'admin',
      password: 'admin',
      device_id: 'test-device'
    });
    
    if (!loginResponse.data.ok || !loginResponse.data.token) {
      throw new Error('Login failed: ' + JSON.stringify(loginResponse.data));
    }
    
    console.log('Login successful, got token');
    const token = loginResponse.data.token;
    
    // Test getting picking details by ID
    console.log('\nTesting GET /flf/api/v1/task/7 (WH/OUT/00007)...');
    const detailsResponse = await axios.get('http://localhost:3000/flf/api/v1/task/7', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    console.log('Response:', JSON.stringify(detailsResponse.data, null, 2));
    
    // Test attaching to picking by barcode
    console.log('\nTesting POST /flf/api/v1/task/attach with WH/OUT/00008...');
    const attachResponse = await axios.post('http://localhost:3000/flf/api/v1/task/attach', {
      picking_barcode: 'WH/OUT/00008'
    }, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    console.log('Response:', JSON.stringify(attachResponse.data, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
      console.error('Response status:', error.response.status);
    }
  }
}

testApi();
