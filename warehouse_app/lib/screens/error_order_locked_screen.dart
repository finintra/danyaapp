import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import 'invoice_scan_screen.dart';

class ErrorOrderLockedScreen extends StatefulWidget {
  const ErrorOrderLockedScreen({super.key});

  @override
  State<ErrorOrderLockedScreen> createState() => _ErrorOrderLockedScreenState();
}

class _ErrorOrderLockedScreenState extends State<ErrorOrderLockedScreen> {
  final SoundService _soundService = SoundService();
  
  @override
  void initState() {
    super.initState();
    
    // Відтворюємо звук помилки
    _playErrorSound();
    
    // Автоматически возвращаемся на экран сканирования накладной через 3000 мс
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const InvoiceScanScreen()),
          (route) => false,
        );
      }
    });
  }
  
  Future<void> _playErrorSound() async {
    try {
      await _soundService.playErrorSound();
    } catch (e) {
      print('Error playing error sound on ErrorOrderLockedScreen: $e');
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
            const SizedBox(height: 20),
            Text(
              'ЗАМОВЛЕННЯ\nВЖЕ ЗІБРАНО',
              style: TextStyle(
                fontSize: 50,
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

