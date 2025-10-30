import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class ErrorAlreadyScannedScreen extends StatefulWidget {
  const ErrorAlreadyScannedScreen({super.key});

  @override
  State<ErrorAlreadyScannedScreen> createState() => _ErrorAlreadyScannedScreenState();
}

class _ErrorAlreadyScannedScreenState extends State<ErrorAlreadyScannedScreen> {
  final SoundService _soundService = SoundService();
  
  @override
  void initState() {
    super.initState();
    _playErrorSound();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _playErrorSound() async {
    try {
      await _soundService.playErrorSound();
      print('Error sound played on ErrorAlreadyScannedScreen');
    } catch (e) {
      print('Error playing error sound on ErrorAlreadyScannedScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.errorColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.check_circle_outline,
              size: 110,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              'ЦЕЙ ТОВАР ВЖЕ ВІДСКАНОВАНО',
              style: TextStyle(
                fontSize: 40,
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


