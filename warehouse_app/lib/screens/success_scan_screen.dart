import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SuccessScanScreen extends StatefulWidget {
  const SuccessScanScreen({super.key});

  @override
  State<SuccessScanScreen> createState() => _SuccessScanScreenState();
}

class _SuccessScanScreenState extends State<SuccessScanScreen> {
  @override
  void initState() {
    super.initState();
    // Автоматически возвращаемся на предыдущий экран через 400 мс
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
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
