import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class StorageService {
  // Сохранение токена с датой истечения срока действия
  Future<void> saveToken(String token) async {
    print('DEBUG: Saving token: $token');
    final prefs = await SharedPreferences.getInstance();
    
    // Очищаємо старі дані перед збереженням нових
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.tokenExpiryKey);
    
    // Зберігаємо токен
    final tokenSaved = await prefs.setString(AppConstants.tokenKey, token);
    print('DEBUG: Token saved successfully: $tokenSaved');
    
    // Сохраняем дату истечения срока действия токена (1 месяц)
    final DateTime now = DateTime.now();
    final DateTime expiryDate = now.add(const Duration(days: 30));
    final expiryDateStr = expiryDate.toIso8601String();
    final expirySaved = await prefs.setString(AppConstants.tokenExpiryKey, expiryDateStr);
    print('DEBUG: Token expiry date saved successfully: $expirySaved');
    print('DEBUG: Token saved with expiry date: $expiryDateStr');
    
    // Перевіряємо, чи збереглися дані
    final savedToken = prefs.getString(AppConstants.tokenKey);
    final savedExpiryDate = prefs.getString(AppConstants.tokenExpiryKey);
    print('DEBUG: Verification - Saved token: $savedToken');
    print('DEBUG: Verification - Saved expiry date: $savedExpiryDate');
    
    // Виводимо всі ключі та значення в SharedPreferences
    print('DEBUG: All SharedPreferences keys:');
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      print('DEBUG: Key: $key, Value: ${prefs.get(key)}');
    }
  }
  
  // Получение токена
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    print('DEBUG: Retrieved token: ${token != null ? "Token exists" : "Token is null"}');
    
    // Виводимо всі ключі та значення в SharedPreferences
    print('DEBUG: All SharedPreferences keys when getting token:');
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      print('DEBUG: Key: $key, Value: ${prefs.get(key)}');
    }
    
    return token;
  }
  
  // Сохранение данных пользователя
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(AppConstants.userKey, userJson);
    print('DEBUG: User data saved: ${user.name}, JSON: $userJson');
  }
  
  // Получение данных пользователя
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    
    if (userJson != null) {
      try {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        final user = User.fromJson(userData);
        print('DEBUG: User data retrieved: ${user.name}');
        return user;
      } catch (e) {
        print('DEBUG: Error parsing user data: $e');
        return null;
      }
    }
    
    print('DEBUG: No user data found');
    return null;
  }
  
  // Сохранение ID устройства
  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.deviceIdKey, deviceId);
    print('DEBUG: Device ID saved: $deviceId');
  }
  
  // Получение ID устройства
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString(AppConstants.deviceIdKey);
    print('DEBUG: Device ID retrieved: $deviceId');
    return deviceId;
  }
  
  // Проверка срока действия токена
  Future<bool> isTokenValid() async {
    print('DEBUG: Checking token validity');
    
    // Перевіряємо наявність токену
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token == null) {
      print('DEBUG: No token found, token is invalid');
      return false;
    }
    
    final expiryDateStr = prefs.getString(AppConstants.tokenExpiryKey);
    print('DEBUG: Token expiry date string: $expiryDateStr');
    
    if (expiryDateStr == null) {
      print('DEBUG: No expiry date found, token is invalid');
      return false;
    }
    
    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      final now = DateTime.now();
      final isValid = now.isBefore(expiryDate);
      
      print('DEBUG: Current date: $now');
      print('DEBUG: Expiry date: $expiryDate');
      print('DEBUG: Is token valid by date: $isValid');
      
      return isValid;
    } catch (e) {
      print('DEBUG: Error parsing expiry date: ${e.toString()}');
      return false;
    }
  }
  
  // Проверка, авторизован ли пользователь и действителен ли токен
  Future<bool> isLoggedIn() async {
    print('DEBUG: Checking if user is logged in');
    final token = await getToken();
    print('DEBUG: Token exists: ${token != null}');
    
    if (token == null) {
      print('DEBUG: No token found, user is not logged in');
      return false;
    }
    
    // Проверяем срок действия токена
    final isValid = await isTokenValid();
    print('DEBUG: Token validity check result: $isValid');
    return isValid;
  }
  
  // Сохранение PIN-кода
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.pinKey, pin);
    print('DEBUG: PIN saved: $pin');
    
    // Перевіряємо, чи збереглися дані
    final savedPin = prefs.getString(AppConstants.pinKey);
    print('DEBUG: Verification - Saved PIN: $savedPin');
  }
  
  // Получение PIN-кода
  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(AppConstants.pinKey);
    print('DEBUG: PIN retrieved: $pin');
    return pin;
  }
  
  // Проверка PIN-кода
  Future<bool> checkPin(String enteredPin) async {
    print('\n\nDEBUG: === PIN CHECK ===');
    final savedPin = await getPin();
    print('DEBUG: Checking PIN: entered=$enteredPin, saved=$savedPin');
    
    // Перевіряємо, чи збігається введений PIN-код зі збереженим
    final isValid = savedPin == enteredPin;
    print('DEBUG: PIN check result: $isValid');
    
    print('DEBUG: === END OF PIN CHECK ===\n\n');
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
    print('DEBUG: All auth data cleared');
  }
}
