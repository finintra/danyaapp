import 'dart:convert';
import 'dart:io';

void main() async {
  // URL бекенду
  final url = 'http://192.168.31.252:3000/flf/api/v1/task/attach';
  
  // Токен авторизації (замініть на свій)
  final token = 'your_auth_token_here'; // Replace with a valid token
  
  // Дані для запиту
  final data = {
    'picking_barcode': 'OUT/00001',
  };
  
  // Заголовки запиту
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
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
    final jsonBody = json.encode(data);
    print('Request body: $jsonBody');
    request.add(utf8.encode(jsonBody));
    
    // Відправляємо запит і отримуємо відповідь
    final response = await request.close();
    
    // Читаємо відповідь
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status code: ${response.statusCode}');
    print('Response body: $responseBody');
    
    // Закриваємо клієнт
    client.close();
  } catch (e) {
    print('Error: $e');
  }
}
