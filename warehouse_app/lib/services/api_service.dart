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
        print('Error: ${responseData['error']}, Message: ${responseData['message']}');
        return ApiResponse(
          success: false,
          error: responseData['error'],
          message: responseData['message'],
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
        
        // Перевіряємо, чи потрібно створити PIN
        final requiresPinSetup = data['requires_pin_setup'] ?? false;
        print('Login successful. Requires PIN setup: $requiresPinSetup');
        
        // Зберігаємо інформацію про те, чи потрібно створити PIN
        await _storageService.saveRequiresPinSetup(requiresPinSetup);
        
        // Повертаємо ApiResponse з requires_pin_setup
        return ApiResponse(
          success: true,
          data: {
            ...data,
            'requires_pin_setup': requiresPinSetup,
          },
        );
      } else {
        print('Login failed: ${apiResponse.error} - ${apiResponse.message}');
        return apiResponse;
      }
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
        
        // Для входу по бейджу також перевіряємо requires_pin_setup
        final requiresPinSetup = data['requires_pin_setup'] ?? false;
        await _storageService.saveRequiresPinSetup(requiresPinSetup);
        
        print('Badge login successful. Requires PIN setup: $requiresPinSetup');
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
  
  // Створення PIN коду
  Future<ApiResponse> createPin(String pin, String pinConfirm) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'NO_TOKEN',
          message: 'Токен не знайдено. Будь ласка, увійдіть знову.',
        );
      }

      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.createPinEndpoint),
        headers: await _getHeaders(),
        body: json.encode({
          'pin': pin,
          'pin_confirm': pinConfirm,
          'token': token,
        }),
      );

      final apiResponse = _handleResponse(response);

      if (apiResponse.success) {
        // Зберігаємо, що PIN вже налаштовано
        await _storageService.saveRequiresPinSetup(false);
        print('PIN created successfully');
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

  // Вхід по PIN коду
  Future<ApiResponse> loginWithPin(String pin) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'NO_TOKEN',
          message: 'Токен не знайдено. Будь ласка, увійдіть знову.',
        );
      }

      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.loginPinEndpoint),
        headers: await _getHeaders(),
        body: json.encode({
          'pin': pin,
          'token': token,
        }),
      );

      final apiResponse = _handleResponse(response);

      if (apiResponse.success) {
        print('PIN login successful, saving data');
        final data = apiResponse.data;
        await _storageService.saveToken(data['token']);
        await _storageService.saveDeviceId(data['device_id']);

        // Отримуємо користувача з даних відповіді та зберігаємо його
        final user = User.fromJson(data['user']);
        await _storageService.saveUser(user);

        print('PIN login data saved successfully');
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
      
      // Try to parse the response body to see if it's valid JSON
      try {
        final responseData = json.decode(response.body);
        print('Response data decoded successfully: $responseData');
        
        // Check if the response has the expected structure
        if (responseData['picking'] == null) {
          print('ERROR: Response is missing "picking" field');
        }
        if (responseData['line'] == null) {
          print('ERROR: Response is missing "line" field');
        }
        if (responseData['order_summary'] == null) {
          print('ERROR: Response is missing "order_summary" field');
        }
      } catch (e) {
        print('ERROR parsing response JSON: $e');
      }
      
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
}
