import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AccountLockedScreen extends StatelessWidget {
  const AccountLockedScreen({super.key});

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
                const Text(
                  '🔒',
                  style: TextStyle(
                    fontSize: 70,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'АКАУНТ\nДЕАКТИВОВАНО',
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Зверніться до адміністратора',
                  style: TextStyle(
                    fontSize: 25,
                    color: AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('ПОВЕРНУТИСЯ ДО ВХОДУ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
