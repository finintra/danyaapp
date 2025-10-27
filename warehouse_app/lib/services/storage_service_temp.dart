import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class StorageService {
  // Сохранение токена с датой истечения срока действия
  Future<void> saveToken(String token) async {
    print('Saving token: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    
    // Сохраняем дату истечения срока действия токена (1 месяц)
    final DateTime now = DateTime.now();
    final DateTime expiryDate = now.add(const Duration(days: 30));
    final expiryDateStr = expiryDate.toIso8601String();
    await prefs.setString(AppConstants.tokenExpiryKey, expiryDateStr);
    print('Token saved with expiry date: $expiryDateStr');
    
    // Перевіряємо, чи збереглися дані
    final savedToken = prefs.getString(AppConstants.tokenKey);
    final savedExpiryDate = prefs.getString(AppConstants.tokenExpiryKey);
    print('Verification - Saved token: $savedToken');
    print('Verification - Saved expiry date: $savedExpiryDate');
  }
  
  // Получение токена
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    print('Retrieved token: ${token != null ? "Token exists" : "Token is null"}');
    return token;
  }
  
  // Сохранение данных пользователя
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(AppConstants.userKey, userJson);
    print('User data saved: ${user.name}, JSON: $userJson');
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
    final deviceId = prefs.getString(AppConstants.deviceIdKey);
    print('Device ID retrieved: $deviceId');
    return deviceId;
  }
  
  // Проверка срока действия токена
  Future<bool> isTokenValid() async {
    print('Checking token validity');
    
    // Перевіряємо наявність токену
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token == null) {
      print('No token found, token is invalid');
      return false;
    }
    
    final expiryDateStr = prefs.getString(AppConstants.tokenExpiryKey);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.pinKey, pin);
    print('PIN saved: $pin');
    
    // Перевіряємо, чи збереглися дані
    final savedPin = prefs.getString(AppConstants.pinKey);
    print('Verification - Saved PIN: $savedPin');
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
