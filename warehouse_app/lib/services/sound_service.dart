import 'package:audioplayers/audioplayers.dart';
import 'dart:io' show File, Platform;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class SoundService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMuted = false;
  bool _isInitialized = false;

  // Singleton pattern
  static final SoundService _instance = SoundService._internal();
  
  factory SoundService() {
    return _instance;
  }
  
  SoundService._internal() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      // Встановлюємо гучність на максимум
      await _audioPlayer.setVolume(1.0);
      print('AudioPlayer initialized with volume 1.0');
      _isInitialized = true;
    } catch (e) {
      print('Error initializing AudioPlayer: $e');
    }
  }

  /// Відтворює звук успішного сканування
  Future<void> playScanSuccessSound() async {
    if (_isMuted) return;
    
    try {
      print('Playing scan success sound: mp3.mp3');
      print('AudioPlayer initialized: $_isInitialized');
      
      // Спосіб 1: Використання AssetSource
      try {
        await _audioPlayer.play(AssetSource('sounds/mp3.mp3'));
        print('Sound played using AssetSource');
      } catch (e) {
        print('Error playing with AssetSource: $e');
      }
      
      // Спосіб 2: Використання BytesSource
      try {
        await Future.delayed(Duration(milliseconds: 1000));
        final bytes = await _loadSoundBytes('sounds/mp3.mp3');
        if (bytes != null) {
          await _audioPlayer.play(BytesSource(bytes));
          print('Sound played using BytesSource');
        }
      } catch (e) {
        print('Error playing with BytesSource: $e');
      }
      
      // Спосіб 3: Використання DeviceFileSource
      try {
        await Future.delayed(Duration(milliseconds: 1000));
        final file = await _loadSoundFile('sounds/mp3.mp3');
        if (file != null) {
          await _audioPlayer.play(DeviceFileSource(file.path));
          print('Sound played using DeviceFileSource: ${file.path}');
        }
      } catch (e) {
        print('Error playing with DeviceFileSource: $e');
      }
    } catch (e) {
      print('Error playing scan success sound: $e');
    }
  }
  
  /// Завантажує звуковий файл як масив байтів
  Future<Uint8List?> _loadSoundBytes(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return byteData.buffer.asUint8List();
    } catch (e) {
      print('Error loading sound bytes: $e');
      return null;
    }
  }
  
  /// Завантажує звуковий файл на пристрій
  Future<File?> _loadSoundFile(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_sound.mp3');
      await tempFile.writeAsBytes(bytes.buffer.asUint8List());
      print('Sound file saved to: ${tempFile.path}');
      return tempFile;
    } catch (e) {
      print('Error loading sound file: $e');
      return null;
    }
  }

  /// Відтворює звук помилки
  Future<void> playErrorSound() async {
    if (_isMuted) return;
    
    try {
      print('Playing error sound: mp3.mp3');
      await _audioPlayer.play(AssetSource('sounds/mp3.mp3'));
    } catch (e) {
      print('Error playing error sound: $e');
    }
  }

  /// Відтворює звук успішного завершення
  Future<void> playSuccessSound() async {
    if (_isMuted) return;
    
    try {
      print('Playing success sound: mp3.mp3');
      await _audioPlayer.play(AssetSource('sounds/mp3.mp3'));
    } catch (e) {
      print('Error playing success sound: $e');
    }
  }

  /// Вмикає або вимикає звуки
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  /// Повертає поточний стан звуку (увімкнено/вимкнено)
  bool get isMuted => _isMuted;

  /// Перемикає стан звуку (увімкнено/вимкнено)
  void toggleMute() {
    _isMuted = !_isMuted;
  }

  /// Звільняє ресурси
  void dispose() {
    _audioPlayer.dispose();
  }
}
