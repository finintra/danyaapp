import 'package:audioplayers/audioplayers.dart';

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

  /// Відтворює звук успішного сканування (Scanned.wav)
  Future<void> playScanSuccessSound() async {
    if (_isMuted) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/Scanned.wav'));
    } catch (e) {
      print('Error playing scan success sound: $e');
    }
  }

  /// Відтворює звук помилки (wrong product.wav)
  Future<void> playErrorSound() async {
    if (_isMuted) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/wrong product.wav'));
    } catch (e) {
      print('Error playing error sound: $e');
    }
  }

  /// Відтворює звук для додаткового товару (more then needed.wav)
  Future<void> playExtraItemSound() async {
    if (_isMuted) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/more then needed.wav'));
    } catch (e) {
      print('Error playing extra item sound: $e');
    }
  }

  /// Відтворює звук завершення товару (productdone.wav)
  Future<void> playSuccessSound() async {
    if (_isMuted) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/productdone.wav'));
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
