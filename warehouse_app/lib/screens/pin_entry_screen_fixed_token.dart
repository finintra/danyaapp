import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../screens/invoice_scan_screen.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final StorageService _storageService = StorageService();
  String _pin = '';
  bool _isError = false;
  bool _isLoading = false;
  String? _userName;
  
  @override
  void initState() {
    super.initState();
    _loadUserName();
  }
  
  Future<void> _loadUserName() async {
    final user = await _storageService.getUser();
    if (mounted) {
      setState(() {
        _userName = user?.name;
      });
    }
  }
  
  // Проверка PIN-кода
  Future<void> _checkPin() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Checking PIN: $_pin');
      // Перевіряємо PIN-код з збереженим
      final isValid = await _storageService.checkPin(_pin);
      print('PIN check result: $isValid');
      
      if (isValid) {
        // Якщо PIN вірний, переходимо до головного екрану
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const InvoiceScanScreen()),
          );
        }
      } else {
        // Якщо PIN невірний, показуємо помилку
        if (mounted) {
          setState(() {
            _isError = true;
            _pin = '';
            _isLoading = false;
          });
          
          // Показуємо помилку на 2 секунди
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isError = false;
              });
            }
          });
        }
      }
    } catch (e) {
      print('Error checking PIN: ${e.toString()}');
      if (mounted) {
        setState(() {
          _isError = true;
          _pin = '';
          _isLoading = false;
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isError = false;
            });
          }
        });
      }
    }
  }
  
  // Выход из системы
  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _storageService.clearAll();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error during logout: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
      });
      
      // Если введены все 4 цифры, проверяем PIN
      if (_pin.length == 4) {
        _checkPin();
      }
    }
  }
  
  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Введіть PIN-код'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _logout,
            tooltip: 'Вийти',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 40),
                // Приветствие пользователя
                if (_userName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Вітаємо, $_userName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                // Инструкция
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Введіть PIN-код для входу',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                // Индикаторы PIN-кода
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _pin.length
                            ? _isError
                                ? Colors.red
                                : AppTheme.primaryColor
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                // Сообщение об ошибке
                if (_isError)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'Невірний PIN-код',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ),
                const Spacer(),
                // Цифровая клавиатура
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDigitButton('1'),
                          _buildDigitButton('2'),
                          _buildDigitButton('3'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDigitButton('4'),
                          _buildDigitButton('5'),
                          _buildDigitButton('6'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDigitButton('7'),
                          _buildDigitButton('8'),
                          _buildDigitButton('9'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Пустая кнопка для выравнивания
                          const SizedBox(width: 80, height: 80),
                          _buildDigitButton('0'),
                          // Кнопка удаления
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: IconButton(
                              icon: const Icon(Icons.backspace, size: 30),
                              onPressed: _removeDigit,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildDigitButton(String digit) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _addDigit(digit),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
