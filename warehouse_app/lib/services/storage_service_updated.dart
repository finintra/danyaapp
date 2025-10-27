import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class StorageService {
  final ApiService _apiService = ApiService();
  
  // Сохранение токена с датой истечения срока действия
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    
    // Сохраняем дату истечения срока действия токена (1 месяц)
    final DateTime now = DateTime.now();
    final DateTime expiryDate = now.add(const Duration(days: 30));
    await prefs.setString(AppConstants.tokenExpiryKey, expiryDate.toIso8601String());
    print('Token saved with expiry date: $expiryDate');
  }
  
  // Получение токена
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }
  
  // Сохранение данных пользователя
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, json.encode(user.toJson()));
    print('User data saved: ${user.name}');
  }
  
  // Получение данных пользователя
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    
    return null;
  }
  
  // Сохранение ID устройства
  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.deviceIdKey, deviceId);
    print('Device ID saved: $deviceId');
  }
  
  // Получение ID устройства
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.deviceIdKey);
  }
  
  // Проверка срока действия токена
  Future<bool> isTokenValid() async {
    print('Checking token validity');
    
    // Перевіряємо наявність токену
    final token = await getToken();
    if (token == null) {
      print('No token found');
      return false;
    }
    
    // Перевіряємо термін дії токену за датою
    final prefs = await SharedPreferences.getInstance();
    final expiryDateStr = prefs.getString(AppConstants.tokenExpiryKey);
    
    print('Token expiry date string: $expiryDateStr');
    
    if (expiryDateStr == null) {
      print('No expiry date found, token is invalid');
      return false;
    }
    
    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      final now = DateTime.now();
      final isValidByDate = now.isBefore(expiryDate);
      
      print('Current date: $now');
      print('Expiry date: $expiryDate');
      print('Is token valid by date: $isValidByDate');
      
      if (!isValidByDate) {
        print('Token expired by date');
        return false;
      }
      
      // Додатково перевіряємо валідність токену через API
      try {
        final isValidByApi = await _apiService.validateToken();
        print('Is token valid by API check: $isValidByApi');
        return isValidByApi;
      } catch (e) {
        print('Error validating token with API: $e');
        // Якщо не вдалося перевірити через API, довіряємо перевірці за датою
        return isValidByDate;
      }
    } catch (e) {
      print('Error parsing expiry date: ${e.toString()}');
      return false;
    }
  }
  
  // Проверка, авторизован ли пользователь и действителен ли токен
  Future<bool> isLoggedIn() async {
    print('Checking if user is logged in');
    final token = await getToken();
    print('Token exists: ${token != null}');
    
    if (token == null) {
      print('No token found, user is not logged in');
      return false;
    }
    
    // Проверяем срок действия токена
    final isValid = await isTokenValid();
    print('Token validity check result: $isValid');
    return isValid;
  }
  
  // Сохранение PIN-кода
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.pinKey, pin);
    print('PIN saved: $pin');
  }
  
  // Получение PIN-кода
  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(AppConstants.pinKey);
    print('PIN retrieved: $pin');
    return pin;
  }
  
  // Проверка PIN-кода
  Future<bool> checkPin(String enteredPin) async {
    print('\n\n=== PIN CHECK ===');
    final savedPin = await getPin();
    print('Checking PIN: entered=$enteredPin, saved=$savedPin');
    
    // Перевіряємо, чи збігається введений PIN-код зі збереженим
    final isValid = savedPin == enteredPin;
    print('PIN check result: $isValid');
    
    print('=== END OF PIN CHECK ===\n\n');
    return isValid;
  }
  
  // Очистка данных сессии
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.tokenExpiryKey);
    await prefs.remove(AppConstants.pinKey);
    // Не удаляем deviceId, чтобы сохранить его для следующего входа
    print('All auth data cleared');
  }
}
