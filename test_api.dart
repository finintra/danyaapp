import 'dart:convert';
import 'dart:io';

void main() async {
  // URL бекенду
  final url = 'http://192.168.31.252:3000/flf/api/v1/login';
  
  // Дані для авторизації
  final data = {
    'login': 'admin',
    'password': 'admin',
    'device_id': 'test_device'
  };
  
  // Заголовки запиту
  final headers = {
    'Content-Type': 'application/json',
  };
  
  try {
    // Створюємо HTTP клієнт
    final client = HttpClient();
    
    // Створюємо запит
    final request = await client.postUrl(Uri.parse(url));
    
    // Додаємо заголовки
    headers.forEach((key, value) {
      request.headers.add(key, value);
    });
    
    // Додаємо тіло запиту
    request.add(utf8.encode(json.encode(data)));
    
    // Відправляємо запит і отримуємо відповідь
    final response = await request.close();
    
    // Читаємо відповідь
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status code: ${response.statusCode}');
    print('Response body: $responseBody');
    
    // Парсимо відповідь
    final responseJson = json.decode(responseBody);
    
    // Аналізуємо структуру відповіді
    print('\n=== DETAILED RESPONSE ANALYSIS ===');
    
    if (responseJson['user'] != null) {
      print('\nUser object:');
      responseJson['user'].forEach((key, value) {
        print('  $key: $value');
      });
      
      // Перевіряємо наявність об'єкта employee
      if (responseJson['user']['employee'] != null) {
        print('\nEmployee object:');
        responseJson['user']['employee'].forEach((key, value) {
          print('  $key: $value');
        });
        
        // Шукаємо поле pin
        if (responseJson['user']['employee']['pin'] != null) {
          print('\n!!! PIN CODE FOUND: ${responseJson['user']['employee']['pin']} !!!');
        } else {
          print('\nPIN field not found in employee object');
        }
      } else {
        print('\nNo employee object found in user');
      }
    }
    
    print('=== END OF ANALYSIS ===');
    
    // Закриваємо клієнт
    client.close();
  } catch (e) {
    print('Error: $e');
  }
}
