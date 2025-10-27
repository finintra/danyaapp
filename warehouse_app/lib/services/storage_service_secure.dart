import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Сохранение токена с датой истечения срока действия
  Future<void> saveToken(String token) async {
    print('Saving token to secure storage');
    
    // Зберігаємо токен у захищеному сховищі
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
    
    // Сохраняем дату истечения срока действия токена (1 месяц)
    final DateTime now = DateTime.now();
    final DateTime expiryDate = now.add(const Duration(days: 30));
    final expiryDateStr = expiryDate.toIso8601String();
    await _secureStorage.write(key: AppConstants.tokenExpiryKey, value: expiryDateStr);
    
    print('Token and expiry date saved to secure storage');
    
    // Перевіряємо, чи збереглися дані
    final savedToken = await _secureStorage.read(key: AppConstants.tokenKey);
    final savedExpiryDate = await _secureStorage.read(key: AppConstants.tokenExpiryKey);
    print('Verification - Saved token: $savedToken');
    print('Verification - Saved expiry date: $savedExpiryDate');
  }
  
  // Получение токена
  Future<String?> getToken() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    print('Retrieved token from secure storage: ${token != null ? "Token exists" : "Token is null"}');
    return token;
  }
  
  // Сохранение данных пользователя
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(AppConstants.userKey, userJson);
    print('User data saved: ${user.name}');
  }
  
  // Получение данных пользователя
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    
    if (userJson != null) {
      try {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        final user = User.fromJson(userData);
        print('User data retrieved: ${user.name}');
        return user;
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    
    print('No user data found');
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
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    
    if (token == null) {
      print('No token found, token is invalid');
      return false;
    }
    
    final expiryDateStr = await _secureStorage.read(key: AppConstants.tokenExpiryKey);
    print('Token expiry date string: $expiryDateStr');
    
    if (expiryDateStr == null) {
      print('No expiry date found, token is invalid');
      return false;
    }
    
    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      final now = DateTime.now();
      final isValid = now.isBefore(expiryDate);
      
      print('Current date: $now');
      print('Expiry date: $expiryDate');
      print('Is token valid by date: $isValid');
      
      return isValid;
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
    await _secureStorage.write(key: AppConstants.pinKey, value: pin);
    print('PIN saved to secure storage: $pin');
  }
  
  // Получение PIN-кода
  Future<String?> getPin() async {
    final pin = await _secureStorage.read(key: AppConstants.pinKey);
    print('PIN retrieved from secure storage: $pin');
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
    await prefs.remove(AppConstants.userKey);
    
    // Очищаємо захищене сховище
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.tokenExpiryKey);
    await _secureStorage.delete(key: AppConstants.pinKey);
    
    // Не удаляем deviceId, чтобы сохранить его для следующего входа
    print('All auth data cleared');
  }
}
