import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'invoice_scan_screen.dart';

class CancelPickingScreen extends StatefulWidget {
  final int pickingId;

  const CancelPickingScreen({
    super.key,
    required this.pickingId,
  });

  @override
  State<CancelPickingScreen> createState() => _CancelPickingScreenState();
}

class _CancelPickingScreenState extends State<CancelPickingScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _confirmCancel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Вызываем API для сброса прогресса
      final apiService = ApiService();
      final response = await apiService.cancelPicking(widget.pickingId);
      
      if (!response.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = response.error ?? 'Ошибка при отмене сборки';
        });
        return;
      }

      if (mounted) {
        // После отмены сборки возвращаемся на экран сканирования накладной
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

  void _continueWork() {
    Navigator.of(context).pop();
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
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'ВІДМІНИТИ ЗБІРКУ?',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Прогрес буде втрачено',
                  style: TextStyle(
                    fontSize: 25,
                    color: AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    minimumSize: const Size(double.infinity, 75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('ТАК, ВІДМІНИТИ'),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _isLoading ? null : _continueWork,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: const Size(double.infinity, 75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('НІ, ПРОДОВЖИТИ'),
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
