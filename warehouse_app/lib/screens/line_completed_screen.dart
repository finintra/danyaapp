import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LineCompletedScreen extends StatefulWidget {
  const LineCompletedScreen({super.key});

  @override
  State<LineCompletedScreen> createState() => _LineCompletedScreenState();
}

class _LineCompletedScreenState extends State<LineCompletedScreen> {
  @override
  void initState() {
    super.initState();
    // Автоматически возвращаемся на предыдущий экран через 500 мс
    Future.delayed(const Duration(milliseconds: 500), () {
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
          'ГОТОВО.\nДАЛІ',
          style: TextStyle(
            fontSize: 55,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
