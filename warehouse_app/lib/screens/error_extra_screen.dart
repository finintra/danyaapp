import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class ErrorExtraScreen extends StatefulWidget {
  const ErrorExtraScreen({super.key});

  @override
  State<ErrorExtraScreen> createState() => _ErrorExtraScreenState();
}

class _ErrorExtraScreenState extends State<ErrorExtraScreen> {
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
      print('Error sound played on ErrorExtraScreen');
    } catch (e) {
      print('Error playing error sound on ErrorExtraScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.errorColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '⚠',
              style: TextStyle(
                fontSize: 120,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'ЦЕЙ ТОВАР\nВЖЕ ВІДСКАНОВАНО',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
