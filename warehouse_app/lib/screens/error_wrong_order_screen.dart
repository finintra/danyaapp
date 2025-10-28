import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class ErrorWrongOrderScreen extends StatefulWidget {
  const ErrorWrongOrderScreen({super.key});

  @override
  State<ErrorWrongOrderScreen> createState() => _ErrorWrongOrderScreenState();
}

class _ErrorWrongOrderScreenState extends State<ErrorWrongOrderScreen> {
  final SoundService _soundService = SoundService();
  
  @override
  void initState() {
    super.initState();
    
    // Відтворюємо звук помилки
    _playErrorSound();
    
    // Автоматически возвращаемся на предыдущий экран через 800 мс
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  
  Future<void> _playErrorSound() async {
    try {
      await _soundService.playErrorSound();
      print('Error sound played on ErrorWrongOrderScreen');
    } catch (e) {
      print('Error playing error sound on ErrorWrongOrderScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.errorColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'ЦЕЙ ТОВАР СКАНУВАТИ РАНО',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Спочатку закінчіть сканування поточного товару',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
