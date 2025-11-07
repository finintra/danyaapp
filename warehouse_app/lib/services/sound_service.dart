import 'dart:typed_data';
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
    await _playSound('Scanned.wav');
  }

  /// Відтворює звук помилки (wrong_product.wav) - товар відсутній в замовленні
  Future<void> playErrorSound() async {
    if (_isMuted) return;
    await _playSound('wrong_product.wav');
  }

  /// Відтворює звук для додаткового товару (more_then_needed.wav) - лишній товар
  Future<void> playExtraItemSound() async {
    if (_isMuted) return;
    await _playSound('more_then_needed.wav');
  }

  /// Відтворює звук завершення товару (productdone.wav) - всі товари відскановані
  Future<void> playSuccessSound() async {
    if (_isMuted) return;
    await _playSound('productdone.wav');
  }

  Future<void> _playSound(String fileName) async {
    final assetSourcePath = 'sounds/$fileName';
    final bundlePath = 'assets/sounds/$fileName';

    try {
      // Зупиняємо попередній звук
      await _player.stop();
      
      // Встановлюємо режим відтворення
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setVolume(1.0);
      
      // Відтворюємо звук з assets через AssetSource (працює з pubspec шляхом без префіксу assets/)
      await _player.play(AssetSource(assetSourcePath));
      
      print('Sound played: $bundlePath');
    } catch (e) {
      print('Error playing sound $bundlePath: $e');
      // Спробуємо альтернативний метод через rootBundle
      try {
        final ByteData data = await rootBundle.load(bundlePath);
        final Uint8List bytes = data.buffer.asUint8List();
        await _player.setPlayerMode(PlayerMode.mediaPlayer);
        await _player.play(BytesSource(bytes));
        print('Sound played via BytesSource: $bundlePath');
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
