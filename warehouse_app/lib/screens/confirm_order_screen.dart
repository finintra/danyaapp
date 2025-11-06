import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'invoice_scan_screen.dart';
import 'cancel_picking_screen.dart';

class ConfirmOrderScreen extends StatefulWidget {
  final String invoiceNumber;
  final int pickingId;

  const ConfirmOrderScreen({
    super.key,
    required this.invoiceNumber,
    required this.pickingId,
  });

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _confirmOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      
      // Отримуємо деталі накладної для формування payload
      final detailsResponse = await apiService.getPickingDetails(widget.pickingId);
      
      if (!detailsResponse.success) {
        throw Exception(detailsResponse.error ?? 'Помилка отримання деталей накладної');
      }
      
      // Формуємо payload з усіх рядків накладної
      final lines = detailsResponse.data['lines'] as List<dynamic>;
      final payload = lines.map((line) => {
        'line_id': line['line_id'],
        'product_id': line['product_id'],
        'qty': line['done'], // Використовуємо відскановану кількість
      }).toList();
      
      // Викликаємо API для підтвердження накладної
      final response = await apiService.validatePicking(widget.pickingId, payload);
      
      if (!response.success) {
        throw Exception(response.error ?? 'Помилка підтвердження накладної');
      }

      if (mounted) {
        // После успешного подтверждения возвращаемся на экран сканирования накладной
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const InvoiceScanScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка: $e';
        });
      }
    }
  }

  void _cancelOrder() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CancelPickingScreen(
          pickingId: widget.pickingId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    minimumSize: const Size(double.infinity, 120),
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ЗАТВЕРДИТИ ЦЕ ЗАМОВЛЕННЯ',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '(${widget.invoiceNumber})',
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _cancelOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.warningColor,
                      minimumSize: const Size(double.infinity, 80),
                      side: const BorderSide(
                        color: AppTheme.warningColor,
                        width: 3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('ВІДМІНИ ЗАМОВЛЕННЯ'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Натисніть для підтвердження',
                  style: TextStyle(
                    fontSize: 25,
                    color: AppTheme.textColor.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
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
