import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SuccessScanScreen extends StatefulWidget {
  final String? nextProductName;
  final bool orderCompleted;

  const SuccessScanScreen({super.key, this.nextProductName, this.orderCompleted = false});

  @override
  State<SuccessScanScreen> createState() => _SuccessScanScreenState();
}

class _SuccessScanScreenState extends State<SuccessScanScreen> {
  @override
  void initState() {
    super.initState();
    
    // Звук уже воспроизводится в product_scan_screen перед переходом сюда
    // Не воспроизводим звук здесь, чтобы избежать двойного воспроизведения
    
    // Автоматично повертаємось на попередній екран через 3000 мс
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
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
