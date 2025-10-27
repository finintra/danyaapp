import 'package:flutter/material.dart';
import 'services/sound_service.dart';

void main() {
  runApp(const TestSoundApp());
}

class TestSoundApp extends StatelessWidget {
  const TestSoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Sound',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestSoundScreen(),
    );
  }
}

class TestSoundScreen extends StatefulWidget {
  const TestSoundScreen({super.key});

  @override
  State<TestSoundScreen> createState() => _TestSoundScreenState();
}

class _TestSoundScreenState extends State<TestSoundScreen> {
  final SoundService _soundService = SoundService();
  String _log = '';

  void _addLog(String message) {
    setState(() {
      _log = '$message\n$_log';
    });
    print(message);
  }

  @override
  void initState() {
    super.initState();
    _addLog('Sound service initialized');
  }

  Future<void> _playSound() async {
    try {
      _addLog('Playing scan success sound...');
      await _soundService.playScanSuccessSound();
      _addLog('Sound playback completed');
    } catch (e) {
      _addLog('Error playing sound: $e');
    }
  }

  Future<void> _playErrorSound() async {
    try {
      _addLog('Playing error sound...');
      await _soundService.playErrorSound();
      _addLog('Error sound playback completed');
    } catch (e) {
      _addLog('Error playing error sound: $e');
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      _addLog('Playing success sound...');
      await _soundService.playSuccessSound();
      _addLog('Success sound playback completed');
    } catch (e) {
      _addLog('Error playing success sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sound'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _playSound,
              child: const Text('Play Scan Sound'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _playErrorSound,
              child: const Text('Play Error Sound'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _playSuccessSound,
              child: const Text('Play Success Sound'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Log:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_log),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
