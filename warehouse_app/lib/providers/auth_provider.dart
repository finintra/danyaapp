import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _deviceId;
  String? _errorMessage;
  
  AuthStatus get status => _status;
  User? get user => _user;
  String? get deviceId => _deviceId;
  String? get errorMessage => _errorMessage;
  
  AuthProvider() {
    _initializeAuth();
  }
  
  // Ініціалізація провайдера
  Future<void> _initializeAuth() async {
    await _checkLoginStatus();
  }
  
  // Проверка статуса авторизации при запуске
  Future<void> _checkLoginStatus() async {
    print('AuthProvider: Checking login status...');
    _status = AuthStatus.authenticating;
    notifyListeners();
    
    try {
      final isLoggedIn = await _storageService.isLoggedIn();
      print('AuthProvider: Is logged in: $isLoggedIn');
      
      if (isLoggedIn) {
        // Токен действителен, просто загружаем пользователя
        print('AuthProvider: Token is valid, loading user data');
        _user = await _storageService.getUser();
        _deviceId = await _storageService.getDeviceId();
        print('AuthProvider: User loaded: ${_user?.name}, Device ID: $_deviceId');
        _status = AuthStatus.authenticated;
      } else {
        // Токен недействителен или отсутствует, нужен новый вход
        print('AuthProvider: Token is invalid or missing, need new login');
        _status = AuthStatus.unauthenticated;
        // Очищаем данные сессии, чтобы избежать проблем с устаревшими данными
        await _storageService.clearAll();
      }
    } catch (e) {
      print('AuthProvider: Error checking login status: ${e.toString()}');
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    
    print('AuthProvider: Auth status set to: $_status');
    notifyListeners();
  }
  
  // Вход по логину и паролю
  Future<bool> login(String login, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final deviceId = await _storageService.getDeviceId();
      final response = await _apiService.login(login, password, deviceId);
      
      if (response.success) {
        _user = await _storageService.getUser();
        _deviceId = await _storageService.getDeviceId();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = response.message ?? response.error ?? 'Неизвестная ошибка';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Вход по бейджу и PIN-коду
  Future<bool> loginWithBadge(String badgeBarcode, String pin) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final deviceId = await _storageService.getDeviceId();
      final response = await _apiService.loginWithBadge(badgeBarcode, pin, deviceId);
      
      if (response.success) {
        _user = await _storageService.getUser();
        _deviceId = await _storageService.getDeviceId();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = response.message ?? response.error ?? 'Неизвестная ошибка';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Створення PIN коду
  Future<bool> createPin(String pin, String pinConfirm) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.createPin(pin, pinConfirm);
      
      if (response.success) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = response.message ?? response.error ?? 'Помилка створення PIN-коду';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Перевірка PIN-кода (використовує loginWithPin з бекенду)
  Future<bool> checkPin(String pin) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Використовуємо loginWithPin для перевірки PIN з бекенду
      final response = await _apiService.loginWithPin(pin);
      
      if (response.success) {
        _user = await _storageService.getUser();
        _deviceId = await _storageService.getDeviceId();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = response.message ?? response.error ?? 'Невірний PIN-код';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Отримання прапорця про необхідність створення PIN
  Future<bool> requiresPinSetup() async {
    return await _storageService.getRequiresPinSetup();
  }
  
  // Проверка валидности токена
  Future<bool> checkTokenValidity() async {
    try {
      return await _storageService.isLoggedIn();
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }
  
  // Выход из системы
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Игнорируем ошибки при выходе
    } finally {
      await _storageService.clearAll();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
}
