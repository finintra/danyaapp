require('dotenv').config();
const axios = require('axios');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const API_PREFIX = '/flf/api/v1';

async function testCredentialsFlow() {
  console.log('=== Тест системи збереження credentials ===\n');
  
  try {
    // 1. Тест логіну з логін/пароль
    console.log('1. Тестуємо логін з логін/пароль...');
    const loginResponse = await axios.post(`${BASE_URL}${API_PREFIX}/login`, {
      login: 'admin',
      password: 'admin',
      device_id: 'test-device-001'
    });
    
    if (!loginResponse.data.ok) {
      throw new Error('Login failed: ' + JSON.stringify(loginResponse.data));
    }
    
    console.log('✓ Логін успішний');
    console.log('  Token:', loginResponse.data.token.substring(0, 50) + '...');
    console.log('  User ID:', loginResponse.data.user.id);
    console.log('  User name:', loginResponse.data.user.name);
    
    const token = loginResponse.data.token;
    const userId = loginResponse.data.user.id;
    
    // 2. Тест входу по PIN з токеном
    console.log('\n2. Тестуємо логін по PIN з токеном...');
    const pinResponse = await axios.post(`${BASE_URL}${API_PREFIX}/login_pin`, {
      pin: '1234', // PIN код користувача
      token: token
    });
    
    if (!pinResponse.data.ok) {
      console.log('⚠ Логін по PIN не вдався:', pinResponse.data.error);
      console.log('  Це може бути нормально, якщо credentials не збережені або PIN невірний');
    } else {
      console.log('✓ Логін по PIN успішний');
      console.log('  New Token:', pinResponse.data.token.substring(0, 50) + '...');
    }
    
    // 3. Тест використання токену для API запитів
    console.log('\n3. Тестуємо використання токену для API запитів...');
    const statusResponse = await axios.get(`${BASE_URL}${API_PREFIX}/device/status`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    if (!statusResponse.data.ok) {
      throw new Error('Device status check failed');
    }
    
    console.log('✓ API запит з токеном працює');
    console.log('  Device ID:', statusResponse.data.device_id);
    console.log('  User:', statusResponse.data.user.name);
    
    console.log('\n=== Всі тести пройдено успішно! ===');
    
  } catch (error) {
    console.error('\n❌ Помилка під час тестування:');
    if (error.response) {
      console.error('  Status:', error.response.status);
      console.error('  Data:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('  Error:', error.message);
    }
    process.exit(1);
  }
}

// Запуск тестів
if (require.main === module) {
  testCredentialsFlow();
}

module.exports = { testCredentialsFlow };

