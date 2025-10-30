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
      
      // Спробуємо відтворити звук з різних місць
      bool soundPlayed = false;
      
      // Спосіб 1: Використання звуку з assets/sounds
      try {
        await _audioPlayer.play(AssetSource('sounds/mp3.mp3'));
        print('Sound played using AssetSource from assets/sounds');
        soundPlayed = true;
      } catch (e) {
        print('Error playing with AssetSource from assets/sounds: $e');
      }
      
      // Якщо не вдалося, спробуємо використати звук з папки sounds
      if (!soundPlayed) {
        try {
          // Використовуємо прямий шлях до файлу
          final soundPath = 'C:/Users/finbe/Downloads/MOBILE APP/warehouse_app/sounds/mp3.mp3';
          await _audioPlayer.play(DeviceFileSource(soundPath));
          print('Sound played using DeviceFileSource from direct path: $soundPath');
          soundPlayed = true;
        } catch (e) {
          print('Error playing with DeviceFileSource from direct path: $e');
        }
      }
      
      // Якщо все ще не вдалося, спробуємо завантажити файл в тимчасову папку
      if (!soundPlayed) {
        try {
          final file = await _loadSoundFile('sounds/mp3.mp3');
          if (file != null) {
            await _audioPlayer.play(DeviceFileSource(file.path));
            print('Sound played using DeviceFileSource from temp file: ${file.path}');
            soundPlayed = true;
          }
        } catch (e) {
          print('Error playing with DeviceFileSource from temp file: $e');
        }
      }
      
      if (!soundPlayed) {
        print('FAILED TO PLAY SOUND: All methods failed');
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

  /// Відтворює звук помилки (wrong.mp3)
  Future<void> playErrorSound() async {
    if (_isMuted) return;
    
    try {
      print('Playing error sound: wrong.mp3');
      bool played = false;
      // 1) Try bundled asset first (works on Android reliably)
      try {
        await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
        print('Error sound played using AssetSource');
        played = true;
      } catch (e) {
        print('Error playing error sound with AssetSource: $e');
      }
      // 2) Fallback to temp file method if needed
      if (!played) {
        try {
          final file = await _loadSoundFile('sounds/wrong.mp3');
          if (file != null) {
            await _audioPlayer.play(DeviceFileSource(file.path));
            print('Error sound played using DeviceFileSource from temp file');
            played = true;
          }
        } catch (e) {
          print('Error playing error sound from temp file: $e');
        }
      }
      if (!played) {
        print('FAILED TO PLAY ERROR SOUND');
      }
    } catch (e) {
      print('Error playing error sound: $e');
    }
  }

  /// Відтворює звук успішного завершення
  Future<void> playSuccessSound() async {
    if (_isMuted) return;
    
    try {
      print('Playing success sound: mp3.mp3');
      
      try {
        // Спробуємо відтворити звук з прямого шляху
        final soundPath = 'C:/Users/finbe/Downloads/MOBILE APP/warehouse_app/sounds/mp3.mp3';
        await _audioPlayer.play(DeviceFileSource(soundPath));
        print('Success sound played using DeviceFileSource from direct path');
      } catch (e) {
        print('Error playing with DeviceFileSource: $e');
        
        // Якщо не вдалося, спробуємо з AssetSource
        try {
          await _audioPlayer.play(AssetSource('sounds/mp3.mp3'));
          print('Success sound played using AssetSource');
        } catch (e) {
          print('Error playing with AssetSource: $e');
        }
      }
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
