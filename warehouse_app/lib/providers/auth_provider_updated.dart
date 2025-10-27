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
    _checkLoginStatus();
  }
  
  // Проверка статуса авторизации при запуске
  Future<void> _checkLoginStatus() async {
    print('Checking login status...');
    _status = AuthStatus.authenticating;
    notifyListeners();
    
    try {
      final isLoggedIn = await _storageService.isLoggedIn();
      print('Is logged in: $isLoggedIn');
      
      if (isLoggedIn) {
        // Токен действителен, просто загружаем пользователя
        print('Token is valid, loading user data');
        _user = await _storageService.getUser();
        _deviceId = await _storageService.getDeviceId();
        print('User loaded: ${_user?.name}, Device ID: $_deviceId');
        _status = AuthStatus.authenticated;
      } else {
        // Токен недействителен или отсутствует, нужен новый вход
        print('Token is invalid or missing, need new login');
        _status = AuthStatus.unauthenticated;
        // Очищаем данные сессии, чтобы избежать проблем с устаревшими данными
        await _storageService.clearAll();
      }
    } catch (e) {
      print('Error checking login status: ${e.toString()}');
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    
    print('Auth status set to: $_status');
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
  
  // Проверка PIN-кода (для входа с сохраненным токеном)
  Future<bool> checkPin(String pin) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final isValid = await _storageService.checkPin(pin);
      
      if (isValid) {
        _status = AuthStatus.authenticated;
        _user = await _storageService.getUser();
        _deviceId = await _storageService.getDeviceId();
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Невірний PIN-код';
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
