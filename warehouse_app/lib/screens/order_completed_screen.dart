import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import 'confirm_order_screen.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class OrderCompletedScreen extends StatefulWidget {
  final String invoiceNumber;
  final int pickingId;
  final int totalItems;
  
  const OrderCompletedScreen({
    super.key,
    required this.invoiceNumber,
    required this.pickingId,
    this.totalItems = 0,
  });

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
                  '${widget.totalItems} ШТУК',
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
                          builder: (context) => ConfirmOrderScreen(
                            invoiceNumber: widget.invoiceNumber,
                            pickingId: widget.pickingId,
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
              const SizedBox(height: 16),
              SizedBox(
                height: 60,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final uri = Uri.parse('https://my.novaposhta.ua/orders/printMarking100x100/orders/20451280298214/type/pdf/zebra/zebra/apiKey/1a36944a6c98d62870208660d22c072b');
                      final resp = await http.get(uri);
                      if (resp.statusCode >= 200 && resp.statusCode < 300) {
                        final bytes = resp.bodyBytes;
                        await Printing.layoutPdf(onLayout: (_) async => bytes);
                      }
                    } catch (_) {}
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.successColor,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('ДРУК ТТН'),
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
