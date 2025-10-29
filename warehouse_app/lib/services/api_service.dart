import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });
}

class ApiService {
  final StorageService _storageService = StorageService();
  
  // Получение заголовков для запросов
  Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (withAuth) {
      final token = await _storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Обработка ответа от API
  ApiResponse _handleResponse(http.Response response) {
    print('Processing response with status code: ${response.statusCode}');
    
    try {
      final responseData = json.decode(response.body);
      print('Response data decoded: $responseData');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Response successful');
        return ApiResponse(
          success: true,
          data: responseData,
        );
      } else {
        print('Response failed with status ${response.statusCode}');
        
        // Отримуємо повідомлення про помилку
        final error = responseData['error'];
        final message = responseData['message'];
        print('Error: $error, Message: $message');
        
        // Перевіряємо на помилки авторизації
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('Authorization error detected (status code: ${response.statusCode})');
          return ApiResponse(
            success: false,
            error: 'TOKEN_INVALID',
            message: 'Not authorized or token failed',
          );
        }
        
        // Перевіряємо на помилки авторизації в повідомленні
        if (error != null && error.toString().toLowerCase().contains('auth')) {
          print('Authorization error detected in error message');
          return ApiResponse(
            success: false,
            error: 'TOKEN_INVALID',
            message: 'Not authorized or token failed',
          );
        }
        
        if (message != null && message.toString().toLowerCase().contains('auth')) {
          print('Authorization error detected in message');
          return ApiResponse(
            success: false,
            error: 'TOKEN_INVALID',
            message: 'Not authorized or token failed',
          );
        }
        
        // Звичайна помилка
        return ApiResponse(
          success: false,
          error: error,
          message: message,
        );
      }
    } catch (e) {
      print('Error parsing response: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'PARSE_ERROR',
        message: 'Failed to parse server response: ${e.toString()}',
      );
    }
  }
  
  // Перевірка валідності токену через API
  Future<bool> validateToken() async {
    try {
      print('Validating token via API...');
      final response = await http.get(
        Uri.parse(AppConstants.baseUrl + AppConstants.deviceStatusEndpoint),
        headers: await _getHeaders(withAuth: true),
      );
      
      print('Token validation response status: ${response.statusCode}');
      
      // Якщо статус 200-299, токен валідний
      final isValid = response.statusCode >= 200 && response.statusCode < 300;
      print('Token is valid via API: $isValid');
      return isValid;
    } catch (e) {
      print('Error validating token via API: ${e.toString()}');
      return false;
    }
  }
  
  // Вход по логину и паролю
  Future<ApiResponse> login(String login, String password, String? deviceId) async {
    try {
      print('Attempting login with: $login, deviceId: $deviceId');
      print('URL: ${AppConstants.baseUrl + AppConstants.loginEndpoint}');
      
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.loginEndpoint),
        headers: await _getHeaders(),
        body: json.encode({
          'login': login,
          'password': password,
          'device_id': deviceId,
        }),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final apiResponse = _handleResponse(response);
      
      if (apiResponse.success) {
        print('Login successful, saving data');
        final data = apiResponse.data;
        
        await _storageService.saveToken(data['token']);
        await _storageService.saveDeviceId(data['device_id']);
        
        // Отримуємо користувача з даних відповіді та зберігаємо його
        final user = User.fromJson(data['user']);
        await _storageService.saveUser(user);
        
        // Перевіряємо, чи отримано PIN-код
        if (user.pin != null && user.pin!.isNotEmpty) {
          print('Saving PIN from hr.employee: ${user.pin}');
          await _storageService.savePin(user.pin!);
          print('PIN code saved successfully: ${user.pin}');
        } else {
          print('ERROR: No PIN code found in hr.employee');
          // Якщо PIN-код не отримано, повертаємо помилку
          return ApiResponse(
            success: false,
            error: 'NO_PIN_CODE',
            message: 'Не вдалося отримати PIN-код. Зверніться до адміністратора.',
          );
        }
        print('Data and PIN saved successfully');
      } else {
        print('Login failed: ${apiResponse.error} - ${apiResponse.message}');
      }
      
      return apiResponse;
    } catch (e) {
      print('Exception during login: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Вход по бейджу и PIN-коду
  Future<ApiResponse> loginWithBadge(String badgeBarcode, String pin, String? deviceId) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.loginBadgeEndpoint),
        headers: await _getHeaders(),
        body: json.encode({
          'badge_barcode': badgeBarcode,
          'pin': pin,
          'device_id': deviceId,
        }),
      );
      
      final apiResponse = _handleResponse(response);
      
      if (apiResponse.success) {
        print('Badge login successful, saving data');
        final data = apiResponse.data;
        await _storageService.saveToken(data['token']);
        await _storageService.saveDeviceId(data['device_id']);
        
        // Отримуємо користувача з даних відповіді та зберігаємо його
        final user = User.fromJson(data['user']);
        await _storageService.saveUser(user);
        
        // Перевіряємо, чи отримано PIN-код
        if (user.pin != null && user.pin!.isNotEmpty) {
          print('Saving PIN from hr.employee: ${user.pin}');
          await _storageService.savePin(user.pin!);
          print('PIN code saved successfully: ${user.pin}');
        } else {
          print('ERROR: No PIN code found in hr.employee');
          // Якщо PIN-код не отримано, повертаємо помилку
          return ApiResponse(
            success: false,
            error: 'NO_PIN_CODE',
            message: 'Не вдалося отримати PIN-код. Зверніться до адміністратора.',
          );
        }
        print('Data and PIN saved successfully');
      } else {
        print('Badge login failed: ${apiResponse.error} - ${apiResponse.message}');
      }
      
      return apiResponse;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Получение статуса устройства
  Future<ApiResponse> getDeviceStatus() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.baseUrl + AppConstants.deviceStatusEndpoint),
        headers: await _getHeaders(withAuth: true),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Выход из системы
  Future<ApiResponse> logout() async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.logoutEndpoint),
        headers: await _getHeaders(withAuth: true),
      );
      
      final apiResponse = _handleResponse(response);
      
      if (apiResponse.success) {
        await _storageService.clearAll();
      }
      
      return apiResponse;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Прикрепление к накладной
  Future<ApiResponse> attachToPicking(String invoice) async {
    try {
      print('Attaching to picking: $invoice');
      final headers = await _getHeaders(withAuth: true);
      final payload = json.encode({
        'picking_barcode': invoice,
      });
      print('Request URL: ${AppConstants.baseUrl + AppConstants.taskAttachEndpoint}');
      print('Request headers: $headers');
      print('Request payload: $payload');
      
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.taskAttachEndpoint),
        headers: headers,
        body: payload,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      // Обробляємо відповідь вручну
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          // Декодуємо JSON
          final responseData = json.decode(response.body);
          print('Response data decoded successfully: $responseData');
          
          // Перевіряємо структуру відповіді
          if (responseData is Map<String, dynamic>) {
            // Попередня обробка даних
            Map<String, dynamic> processedData = {};
            
            // Обробка picking
            if (responseData['picking'] != null) {
              Map<String, dynamic> pickingData = {};
              if (responseData['picking'] is Map) {
                (responseData['picking'] as Map).forEach((key, value) {
                  // Перетворюємо булеві значення на рядки
                  if (value is bool) {
                    pickingData[key.toString()] = value.toString();
                    print('Converted boolean to string in picking[$key]: $value -> ${value.toString()}');
                  } else {
                    pickingData[key.toString()] = value;
                  }
                });
              }
              processedData['picking'] = pickingData;
            } else {
              print('ERROR: Response is missing "picking" field');
              processedData['picking'] = {};
            }
            
            // Обробка line
            if (responseData['line'] != null) {
              Map<String, dynamic> lineData = {};
              if (responseData['line'] is Map) {
                (responseData['line'] as Map).forEach((key, value) {
                  // Перетворюємо булеві значення на рядки
                  if (value is bool) {
                    lineData[key.toString()] = value.toString();
                    print('Converted boolean to string in line[$key]: $value -> ${value.toString()}');
                  } else {
                    lineData[key.toString()] = value;
                  }
                });
              }
              processedData['line'] = lineData;
            } else {
              print('ERROR: Response is missing "line" field');
              processedData['line'] = {};
            }
            
            // Обробка order_summary
            if (responseData['order_summary'] != null) {
              Map<String, dynamic> summaryData = {};
              if (responseData['order_summary'] is Map) {
                (responseData['order_summary'] as Map).forEach((key, value) {
                  // Перетворюємо булеві значення на рядки
                  if (value is bool) {
                    summaryData[key.toString()] = value ? '1' : '0';
                    print('Converted boolean to string in order_summary[$key]: $value -> ${value ? '1' : '0'}');
                  } else {
                    summaryData[key.toString()] = value;
                  }
                });
              }
              processedData['order_summary'] = summaryData;
            } else {
              print('ERROR: Response is missing "order_summary" field');
              processedData['order_summary'] = {};
            }
            
            // Повертаємо оброблені дані
            print('Processed data: $processedData');
            return ApiResponse(
              success: true,
              data: processedData,
            );
          }
        } catch (e) {
          print('ERROR processing response data: $e');
        }
      }
      
      // Якщо не вдалося обробити відповідь вручну, використовуємо стандартний обробник
      return _handleResponse(response);
    } catch (e) {
      print('Exception during attachToPicking: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Сканирование товара
  Future<ApiResponse> scanItem(int pickingId, String barcode, int expectedProductId) async {
    try {
      print('Scanning item: $barcode for picking: $pickingId, expected product ID: $expectedProductId');
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.scanItemEndpoint),
        headers: await _getHeaders(withAuth: true),
        body: json.encode({
          'picking_id': pickingId,
          'barcode': barcode,
          'expected_product_id': expectedProductId,
        }),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('Exception during scanItem: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Получение деталей накладной
  Future<ApiResponse> getPickingDetails(int pickingId) async {
    try {
      print('Getting picking details for: $pickingId');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.taskDetailsEndpoint}/$pickingId'),
        headers: await _getHeaders(withAuth: true),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('Exception during getPickingDetails: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Отмена сборки накладной
  Future<ApiResponse> cancelPicking(int pickingId) async {
    try {
      print('Cancelling picking: $pickingId');
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.cancelLocalEndpoint),
        headers: await _getHeaders(withAuth: true),
        body: json.encode({
          'picking_id': pickingId,
        }),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('Exception during cancelPicking: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Підтвердження замовлення
  Future<ApiResponse> validatePicking(int pickingId) async {
    try {
      print('Validating picking: $pickingId');
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.validateEndpoint),
        headers: await _getHeaders(withAuth: true),
        body: json.encode({
          'picking_id': pickingId,
          'payload': [] // Порожній масив, оскільки всі дані вже відправлені при скануванні
        }),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('Exception during validatePicking: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
  
  // Підтвердження замовлення та перехід до наступної накладної
  Future<ApiResponse> confirmOrder(int pickingId) async {
    try {
      print('Confirming order: $pickingId');
      
      // Спочатку валідуємо замовлення
      final validateResponse = await validatePicking(pickingId);
      
      if (!validateResponse.success) {
        print('Order validation failed: ${validateResponse.error}');
        return validateResponse;
      }
      
      // Додатково викликаємо API для завершення замовлення
      try {
        // Це може бути додатковий запит для завершення замовлення
        final response = await http.post(
          Uri.parse(AppConstants.baseUrl + '/flf/api/v1/order/complete'),
          headers: await _getHeaders(withAuth: true),
          body: json.encode({
            'picking_id': pickingId,
          }),
        );
        
        print('Complete order response status: ${response.statusCode}');
        print('Complete order response body: ${response.body}');
      } catch (e) {
        // Ігноруємо помилки додаткового запиту
        print('Error in additional complete order request: $e');
      }
      
      // Після успішної валідації повертаємо успішний результат
      print('Order confirmed successfully');
      return ApiResponse(
        success: true,
        data: {'message': 'Замовлення успішно підтверджено'},
      );
    } catch (e) {
      print('Exception during confirmOrder: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'CONNECTION_ERROR',
        message: e.toString(),
      );
    }
  }
}
