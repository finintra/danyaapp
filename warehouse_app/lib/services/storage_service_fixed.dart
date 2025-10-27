import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class StorageService {
  // Сохранение токена
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    
    // Устанавливаем время истечения токена (24 часа)
    final expiryTime = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
    await prefs.setInt(AppConstants.tokenExpiryKey, expiryTime);
  }
  
  // Получение токена
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    // Проверяем, не истек ли токен
    if (token != null) {
      final expiryTime = prefs.getInt(AppConstants.tokenExpiryKey);
      if (expiryTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > expiryTime) {
          // Токен истек, удаляем его
          await prefs.remove(AppConstants.tokenKey);
          await prefs.remove(AppConstants.tokenExpiryKey);
          return null;
        }
      }
    }
    
    return token;
  }
  
  // Проверка, авторизован ли пользователь
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
  
  // Сохранение ID устройства
  Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.deviceIdKey, deviceId);
  }
  
  // Получение ID устройства
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.deviceIdKey);
  }
  
  // Сохранение данных пользователя
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = user.toJson();
    await prefs.setString(AppConstants.userKey, json.encode(userJson));
  }
  
  // Получение данных пользователя
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    
    if (userJson != null) {
      final userData = json.decode(userJson) as Map<String, dynamic>;
      return User.fromJson(userData);
    }
    
    return null;
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
  
  // Не используем сохранение логина и пароля, только токен
  
  // Очистка данных сессии
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.tokenExpiryKey);
    await prefs.remove(AppConstants.deviceIdKey);
    await prefs.remove(AppConstants.pinKey);
  }
}
