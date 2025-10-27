import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // URL бекенду
  final url = 'http://192.168.31.252:3000/flf/api/v1/task/attach';
  
  // Токен авторизації (замініть на свій)
  final token = 'your_auth_token_here'; // Replace with a valid token
  
  // Заголовки запиту
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  
  // Дані для запиту
  final data = {
    'picking_barcode': 'OUT/00001',
  };
  
  try {
    // Конвертуємо дані в JSON
    final jsonBody = json.encode(data);
    print('Request URL: $url');
    print('Request headers: $headers');
    print('Request body: $jsonBody');
    
    // Відправляємо POST запит
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonBody,
    );
    
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    
  } catch (e) {
    print('Error: $e');
  }
}
