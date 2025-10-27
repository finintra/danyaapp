const axios = require('axios');

async function testAttachToPicking() {
  try {
    // Replace with a valid token
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwibmFtZSI6Ik1pdGNoZWxsIEFkbWluIiwiZGV2aWNlSWQiOiJkZWE3N2VjZS0wOWY1LTRlMGYtYTk1MC00NGI1ZWNhZDFhNDIiLCJpYXQiOjE3NjE1MDAzNjMsImV4cCI6MTc2MTUyOTE2M30.Zi0RAX3trfuSqloKqDwgoxztrsLSJxa7P8F3B_HIrR4';
    
    console.log('Testing attachToPicking endpoint...');
    
    // Test 1: With correct parameter name
    console.log('\nTest 1: With correct parameter name (picking_barcode)');
    const response1 = await axios.post(
      'http://localhost:3000/flf/api/v1/task/attach',
      { picking_barcode: 'OUT/00001' },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      }
    );
    
    console.log('Response status:', response1.status);
    console.log('Response data:', response1.data);
    
  } catch (error) {
    console.error('Error occurred:');
    console.error('Status:', error.response?.status);
    console.error('Data:', error.response?.data);
    console.error('Headers:', error.response?.headers);
    console.error('Full error:', error.message);
  }
}

testAttachToPicking();
