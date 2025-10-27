import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMuted = false;

  // Singleton pattern
  static final SoundService _instance = SoundService._internal();
  
  factory SoundService() {
    return _instance;
  }
  
  SoundService._internal();

  /// Відтворює звук успішного сканування
  Future<void> playScanSuccessSound() async {
    if (_isMuted) return;
    
    try {
      print('Playing scan success sound: mp3.mp3');
      await _audioPlayer.play(AssetSource('sounds/mp3.mp3'));
    } catch (e) {
      print('Error playing scan success sound: $e');
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
