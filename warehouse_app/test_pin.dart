import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Константа для ключа PIN-коду в SharedPreferences
  const String pinKey = 'user_pin';
  
  // Очищаємо збережений PIN-код
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(pinKey);
  
  // Зберігаємо PIN-код 5678
  await prefs.setString(pinKey, '5678');
  
  // Перевіряємо, чи зберігся PIN-код
  final savedPin = prefs.getString(pinKey);
  print('Saved PIN: $savedPin');
  
  // Перевіряємо, чи правильно працює перевірка PIN-коду
  final enteredPin = '5678';
  final isValid = savedPin == enteredPin;
  print('PIN check result: $isValid');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIN Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PinTestScreen(),
    );
  }
}

class PinTestScreen extends StatefulWidget {
  const PinTestScreen({super.key});

  @override
  State<PinTestScreen> createState() => _PinTestScreenState();
}

class _PinTestScreenState extends State<PinTestScreen> {
  String _pin = '';
  String? _savedPin;
  bool _isValid = false;
  
  @override
  void initState() {
    super.initState();
    _loadPin();
  }
  
  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('user_pin');
    });
  }
  
  void _checkPin() {
    setState(() {
      _isValid = _pin == _savedPin;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Saved PIN: $_savedPin'),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                setState(() {
                  _pin = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Enter PIN',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkPin,
              child: const Text('Check PIN'),
            ),
            const SizedBox(height: 20),
            Text(
              _isValid ? 'PIN is valid' : 'PIN is invalid',
              style: TextStyle(
                color: _isValid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
