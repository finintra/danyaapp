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
      
      // Детальний аналіз відповіді
      try {
        final responseJson = json.decode(response.body);
        print('\n\n=== DETAILED RESPONSE ANALYSIS ===');
        print('Full response structure: $responseJson');
        
        if (responseJson['user'] != null) {
          print('\nUser object structure:');
          responseJson['user'].forEach((key, value) {
            print('  $key: $value');
          });
          
          // Перевіряємо наявність об'єкта employee
          if (responseJson['user']['employee'] != null) {
            print('\nEmployee object found in user:');
            responseJson['user']['employee'].forEach((key, value) {
              print('  $key: $value');
            });
            
            // Спеціально шукаємо поле pin
            if (responseJson['user']['employee']['pin'] != null) {
              print('\nFOUND PIN IN EMPLOYEE: ${responseJson['user']['employee']['pin']}');
            } else {
              print('\nPIN field not found in employee object');
            }
          } else {
            print('\nNo employee object found in user');
          }
        }
        print('=== END OF ANALYSIS ===\n\n');
      } catch (e) {
        print('Error analyzing response: $e');
      }
      
      final apiResponse = _handleResponse(response);
      
      if (apiResponse.success) {
        print('Login successful, saving data');
        final data = apiResponse.data;
        
        // Детальне логування структури відповіді
        print('Full API response data: $data');
        
        if (data['user'] != null) {
          print('User data structure: ${data['user']}');
          // Перевіряємо всі поля користувача
          data['user'].forEach((key, value) {
            print('User field: $key = $value');
          });
        }
        
        await _storageService.saveToken(data['token']);
        await _storageService.saveDeviceId(data['device_id']);
        
        // Отримуємо користувача з даних відповіді та зберігаємо його
        // Це також збереже PIN-код з моделі hr.employee
        final user = User.fromJson(data['user']);
        await _storageService.saveUser(user);
        
        // Перевіряємо, чи отримано PIN-код
        if (user.pin != null && user.pin!.isNotEmpty) {
          print('Saving PIN from hr.employee: ${user.pin}');
          await _storageService.savePin(user.pin!);
          print('PIN code saved successfully: ${user.pin}');
        } else {
          print('WARNING: No PIN code found in hr.employee');
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
        // Це також збереже PIN-код з моделі hr.employee
        final user = User.fromJson(data['user']);
        await _storageService.saveUser(user);
        
        // Перевіряємо, чи отримано PIN-код
        if (user.pin != null && user.pin!.isNotEmpty) {
          print('Saving PIN from hr.employee: ${user.pin}');
          await _storageService.savePin(user.pin!);
          print('PIN code saved successfully: ${user.pin}');
        } else {
          print('WARNING: No PIN code found in hr.employee');
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
  
  // Прикрепление к накладной по штрих-коду
  Future<ApiResponse> attachToPicking(String pickingBarcode) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.taskAttachEndpoint),
        headers: await _getHeaders(withAuth: true),
        body: json.encode({
          'picking_barcode': pickingBarcode,
        }),
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
  
  // Получение деталей накладной по ID
  Future<ApiResponse> getPickingDetails(int pickingId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.taskDetailsEndpoint}/$pickingId'),
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
  
  // Сканирование товара
  Future<ApiResponse> scanItem(int pickingId, String barcode) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.scanItemEndpoint),
        headers: await _getHeaders(withAuth: true),
        body: json.encode({
          'picking_id': pickingId,
          'barcode': barcode,
        }),
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
  
  // Отмена сборки и сброс прогресса
  Future<ApiResponse> cancelPicking(int pickingId) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.baseUrl + AppConstants.cancelLocalEndpoint),
        headers: await _getHeaders(withAuth: true),
        body: json.encode({
          'picking_id': pickingId,
        }),
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
}
