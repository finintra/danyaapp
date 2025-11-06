import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'pin_entry_screen.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  Future<void> _createPin() async {
    if (_formKey.currentState!.validate()) {
      if (_pinController.text != _pinConfirmController.text) {
        setState(() {
          _errorMessage = 'PIN-коди не співпадають';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.createPin(
        _pinController.text,
        _pinConfirmController.text,
      );

      if (success) {
        if (mounted) {
          // Після успішного створення PIN переходимо на екран введення PIN
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PinEntryScreen()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = authProvider.errorMessage ?? 'Помилка створення PIN-коду';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'СТВОРЕННЯ PIN-КОДУ',
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Введіть PIN-код двічі для підтвердження',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _pinController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'PIN-код',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введіть PIN-код';
                        }
                        if (value.length < 4 || value.length > 10) {
                          return 'PIN-код повинен бути від 4 до 10 символів';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _pinConfirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Підтвердіть PIN-код',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Підтвердіть PIN-код';
                        }
                        if (value != _pinController.text) {
                          return 'PIN-коди не співпадають';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      height: 70,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createPin,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('СТВОРИТИ PIN-КОД'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



