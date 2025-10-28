import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
      print('Playing success sound on SuccessScanScreen');
      await _soundService.playScanSuccessSound();
      print('Success sound played on SuccessScanScreen');
    } catch (e) {
      print('Error playing success sound on SuccessScanScreen: $e');
      
      // Спробуємо відтворити звук напряму з файлу
      try {
        final player = AudioPlayer();
        await player.play(DeviceFileSource('C:/Users/finbe/Downloads/MOBILE APP/warehouse_app/sounds/mp3.mp3'));
        print('Sound played directly from SuccessScanScreen');
      } catch (e) {
        print('Error playing sound directly from SuccessScanScreen: $e');
      }
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
