import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorNotInOrderScreen extends StatefulWidget {
  const ErrorNotInOrderScreen({super.key});

  @override
  State<ErrorNotInOrderScreen> createState() => _ErrorNotInOrderScreenState();
}

class _ErrorNotInOrderScreenState extends State<ErrorNotInOrderScreen> {
  @override
  void initState() {
    super.initState();
    // Автоматически возвращаемся на предыдущий экран через 800 мс
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.errorColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '✕',
              style: TextStyle(
                fontSize: 100,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'ЦЬОГО ТОВАРУ\nНЕМАЄ У\nЗАМОВЛЕННІ',
              style: TextStyle(
                fontSize: 50,
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
