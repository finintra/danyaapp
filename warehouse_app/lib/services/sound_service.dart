import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  /// Відтворює звук успішного сканування (Scanned.wav) - зелений екран
  Future<void> playScanSuccessSound() async {
    if (_isMuted) return;
    await _playSound('sounds/Scanned.wav');
  }

  /// Відтворює звук помилки (wrong product.wav) - товар відсутній в замовленні
  Future<void> playErrorSound() async {
    if (_isMuted) return;
    await _playSound('sounds/wrong product.wav');
  }

  /// Відтворює звук для додаткового товару (more then needed.wav) - лишній товар
  Future<void> playExtraItemSound() async {
    if (_isMuted) return;
    await _playSound('sounds/more then needed.wav');
  }

  /// Відтворює звук завершення товару (productdone.wav) - всі товари відскановані
  Future<void> playSuccessSound() async {
    if (_isMuted) return;
    await _playSound('sounds/productdone.wav');
  }

  Future<void> _playSound(String assetPath) async {
    try {
      // Зупиняємо попередній звук
      await _player.stop();
      
      // Встановлюємо режим відтворення
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setVolume(1.0);
      
      // Відтворюємо звук
      await _player.play(AssetSource(assetPath));
      
      print('Sound played: $assetPath');
    } catch (e) {
      print('Error playing sound $assetPath: $e');
      // Спробуємо альтернативний метод через rootBundle
      try {
        final ByteData data = await rootBundle.load(assetPath);
        final Uint8List bytes = data.buffer.asUint8List();
        await _player.play(BytesSource(bytes));
        print('Sound played via BytesSource: $assetPath');
      } catch (e2) {
        print('Error playing sound via BytesSource: $e2');
      }
    }
  }

  void setMuted(bool muted) {
    _isMuted = muted;
  }

  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  void dispose() {
    _player.dispose();
  }
}
