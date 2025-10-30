import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class SuccessScanScreen extends StatefulWidget {
  final String? nextProductName;
  final bool orderCompleted;

  const SuccessScanScreen({super.key, this.nextProductName, this.orderCompleted = false});

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
    
    // Автоматично повертаємось на попередній екран
    Future.delayed(const Duration(milliseconds: 700), () {
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
    final bool allDone = widget.orderCompleted;
    final String? nextName = widget.nextProductName;

    return Scaffold(
      backgroundColor: AppTheme.successColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '✓',
              style: TextStyle(
                fontSize: 150,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (allDone)
              const Text(
                'ВСЕ ВІДСКАНОВАНО',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (nextName != null && nextName.isNotEmpty) ...[
              const Text(
                'ТЕПЕР СКАНУЙ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nextName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
