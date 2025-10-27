import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'services/storage_service.dart';
import 'services/sound_service.dart';

void main() async {
  // Важливо ініціалізувати Flutter перед використанням SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Складський сканер',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();
  final SoundService _soundService = SoundService();
  bool _isLoading = true;
  String _debugInfo = '';
  
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _testSound();
  }
  
  Future<void> _testSound() async {
    try {
      print('Testing sound playback...');
      await Future.delayed(const Duration(seconds: 2));
      await _soundService.playScanSuccessSound();
      setState(() {
        _debugInfo += '\nТест звуку: Запущено';
      });
    } catch (e) {
      print('Error testing sound: $e');
      setState(() {
        _debugInfo += '\nПомилка тесту звуку: $e';
      });
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      setState(() {
        _debugInfo = 'Перевірка статусу авторизації...';
      });
      
      print('DEBUG: SplashScreen: Checking auth status...');
      
      // Перевіряємо, чи є валідний токен
      final token = await _storageService.getToken();
      setState(() {
        _debugInfo += '\nТокен: ${token != null ? "Існує" : "Відсутній"}';
      });
      
      if (token != null) {
        final isTokenValid = await _storageService.isTokenValid();
        setState(() {
          _debugInfo += '\nТокен валідний: $isTokenValid';
        });
      }
      
      final isLoggedIn = await _storageService.isLoggedIn();
      print('DEBUG: SplashScreen: Is logged in: $isLoggedIn');
      
      setState(() {
        _debugInfo += '\nКористувач авторизований: $isLoggedIn';
      });
      
      if (!mounted) return;
      
      await Future.delayed(const Duration(seconds: 3)); // Затримка для відображення дебаг-інформації
      
      if (isLoggedIn) {
        // Якщо токен валідний, переходимо на екран введення PIN-коду
        print('DEBUG: SplashScreen: Token is valid, navigating to PIN entry screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PinEntryScreen()),
        );
      } else {
        // Якщо токен невалідний або відсутній, переходимо на екран входу
        print('DEBUG: SplashScreen: Token is invalid or missing, navigating to login screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('DEBUG: SplashScreen: Error checking auth status: $e');
      setState(() {
        _debugInfo += '\nПомилка: $e';
      });
      
      if (mounted) {
        await Future.delayed(const Duration(seconds: 3)); // Затримка для відображення помилки
        // У разі помилки також переходимо на екран входу
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип або назва додатку
            const Text(
              'СКЛАДСЬКИЙ\nСКАНЕР',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Індикатор завантаження
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            // Версія додатку
            Text(
              'Версія 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // Дебаг-інформація
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _debugInfo,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
