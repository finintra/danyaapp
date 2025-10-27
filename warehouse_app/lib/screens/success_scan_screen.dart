import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class SuccessScanScreen extends StatefulWidget {
  const SuccessScanScreen({super.key});

  @override
  State<SuccessScanScreen> createState() => _SuccessScanScreenState();
}

class _SuccessScanScreenState extends State<SuccessScanScreen> {
  final SoundService _soundService = SoundService();
  
  @override
  void initState() {
    super.initState();
    
    // Відтворюємо звук успішного сканування
    _playSuccessSound();
    
    // Автоматически возвращаемся на предыдущий экран через 400 мс
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  
  Future<void> _playSuccessSound() async {
    try {
      await _soundService.playScanSuccessSound();
      print('Success sound played on SuccessScanScreen');
    } catch (e) {
      print('Error playing success sound on SuccessScanScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.successColor,
      body: Center(
        child: Text(
          '✓',
          style: TextStyle(
            fontSize: 150,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
