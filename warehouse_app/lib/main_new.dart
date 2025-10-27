import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'services/storage_service.dart';

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
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      print('SplashScreen: Checking auth status...');
      
      // Перевіряємо, чи є валідний токен
      final isLoggedIn = await _storageService.isLoggedIn();
      print('SplashScreen: Is logged in: $isLoggedIn');
      
      if (!mounted) return;
      
      if (isLoggedIn) {
        // Якщо токен валідний, переходимо на екран введення PIN-коду
        print('SplashScreen: Token is valid, navigating to PIN entry screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PinEntryScreen()),
        );
      } else {
        // Якщо токен невалідний або відсутній, переходимо на екран входу
        print('SplashScreen: Token is invalid or missing, navigating to login screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('SplashScreen: Error checking auth status: $e');
      if (mounted) {
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
          ],
        ),
      ),
    );
  }
}
