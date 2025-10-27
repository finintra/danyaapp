import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import 'confirm_order_screen.dart';

class OrderCompletedScreen extends StatefulWidget {
  const OrderCompletedScreen({super.key});

  @override
  State<OrderCompletedScreen> createState() => _OrderCompletedScreenState();
}

class _OrderCompletedScreenState extends State<OrderCompletedScreen> {
  final SoundService _soundService = SoundService();
  
  @override
  void initState() {
    super.initState();
    
    // Відтворюємо звук успішного завершення
    _playSuccessSound();
  }
  
  Future<void> _playSuccessSound() async {
    try {
      await _soundService.playSuccessSound();
      print('Success sound played on OrderCompletedScreen');
    } catch (e) {
      print('Error playing success sound on OrderCompletedScreen: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.successColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ЗАМОВЛЕННЯ\nЗІБРАНО',
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  '5 ШТУК',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Text(
                  'НАКЛЕЙТЕ ТТН\nТА НАТИСНІТЬ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 70,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const ConfirmOrderScreen(
                            invoiceNumber: 'OUT/00123',
                            pickingId: 1, // Тимчасове значення, в реальному додатку має передаватися з попереднього екрану
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.successColor,
                      textStyle: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ПІДТВЕРДИТИ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
