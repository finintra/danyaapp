import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class StorageService {
  // Сохранение токена с датой истечения срока действия
  Future<void> saveToken(String token) async {
    print('Saving token: $token');
    final prefs = await SharedPreferences.getInstance();
    
    // Зберігаємо токен
    await prefs.setString('auth_token', token);
    
    // Сохраняем дату истечения срока действия токена (1 месяц)
    final DateTime now = DateTime.now();
    final DateTime expiryDate = now.add(const Duration(days: 30));
    final expiryDateStr = expiryDate.toIso8601String();
    await prefs.setString('token_expiry', expiryDateStr);
    
    // Також зберігаємо прапорець, що користувач авторизований
    await prefs.setBool('is_logged_in', true);
    
    print('Token saved with expiry date: $expiryDateStr');
  }
  
  // Получение токена
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Retrieved token: ${token != null ? "Token exists" : "Token is null"}');
    return token;
  }
  
  // Сохранение данных пользователя
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString('user_data', userJson);
    print('User data saved: ${user.name}');
    
    // Якщо у користувача є PIN-код, зберігаємо його
    if (user.pin != null && user.pin!.isNotEmpty) {
      await savePin(user.pin!);
    }
    
    // Якщо у користувача є мова, зберігаємо її
    if (user.lang != null && user.lang!.isNotEmpty) {
      await saveLanguage(user.lang!);
    }
  }
  
  // Получение данных пользователя
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    
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
    await prefs.setString('device_id', deviceId);
    print('Device ID saved: $deviceId');
  }
  
  // Получение ID устройства
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id');
    print('Device ID retrieved: $deviceId');
    return deviceId;
  }
  
  // Проверка срока действия токена
  Future<bool> isTokenValid() async {
    print('Checking token validity');
    final prefs = await SharedPreferences.getInstance();
    
    // Перевіряємо наявність токену
    final token = prefs.getString('auth_token');
    if (token == null) {
      print('No token found, token is invalid');
      return false;
    }
    
    // Перевіряємо наявність дати закінчення терміну дії
    final expiryDateStr = prefs.getString('token_expiry');
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
    final prefs = await SharedPreferences.getInstance();
    
    // Перевіряємо прапорець авторизації
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!isLoggedIn) {
      print('User is not logged in according to flag');
      return false;
    }
    
    // Перевіряємо наявність токену
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
    await prefs.setString('user_pin', pin);
    print('PIN saved: $pin');
  }
  
  // Получение PIN-кода
  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');
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
  
  // Збереження мови користувача
  Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_lang', lang);
    print('Language saved: $lang');
  }
  
  // Отримання мови користувача
  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('user_lang');
    print('Language retrieved: $lang');
    return lang;
  }
  
  // Очистка данных сессии
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('token_expiry');
    await prefs.remove('user_pin');
    await prefs.remove('is_logged_in');
    // Не видаляємо deviceId та user_lang, щоб зберегти їх для наступного входу
    print('All auth data cleared');
  }
}
