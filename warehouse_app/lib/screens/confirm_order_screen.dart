import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
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
      // Викликаємо API для підтвердження замовлення
      final apiService = ApiService();
      final response = await apiService.confirmOrder(widget.pickingId);
      
      if (!response.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = response.error ?? 'Помилка при підтвердженні замовлення';
        });
        return;
      }
      
      // Зберігаємо дані для навігації в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Встановлюємо прапорець авторизації та спеціальний прапорець для навігації
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('navigate_to_invoice_scan', true);
      
      // Зберігаємо тимчасовий токен
      await prefs.setString('auth_token', 'temporary_token_for_navigation');
      
      print('Set navigation flags and temporary token');
      
      // Додаємо затримку перед переходом
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Створюємо новий екземпляр InvoiceScanScreen замість використання const
      if (mounted) {
        print('Navigating to InvoiceScanScreen with pushReplacement');
        
        // Використовуємо pushReplacement замість pushAndRemoveUntil
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => InvoiceScanScreen()),
        );
      }
    } catch (e) {
      print('Error in _confirmOrder: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Помилка: $e';
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
                        'ЗАТВЕРДИТИ\nЦЕ ЗАМОВЛЕННЯ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '(${widget.invoiceNumber})',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
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
                  child: const Text(
                    'ВІДМІНИТИ ЗАМОВЛЕННЯ',
                    textAlign: TextAlign.center,
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
