import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();

  // Dedicated player for UI feedback sounds.
  // This is separate from the AudioPlayers used for exercise/reference audio.
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _play(String fileName) async {
    try {
      // Prevent feedback sounds from stacking on top of each other.
      await _player.stop();

      await _player.play(AssetSource('soundeffects/$fileName'));
    } catch (e) {
      // Sound failure should never break the exercise flow.
      debugPrint('🔊 SOUND ERROR [$fileName]: $e');
    }
  }

  static Future<void> playCorrect() {
    return _play('correct.mp3');
  }

  static Future<void> playWrong() {
    return _play('wrong.mp3');
  }

  static Future<void> playWin() {
    return _play('win.mp3');
  }

  static Future<void> playLoss() {
    return _play('loss.mp3');
  }

  static Future<void> playPurchase() {
    return _play('purchase.mp3');
  }

  static Future<void> playAttemptLimit() {
    return _play('attemptlimit.mp3');
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('🔊 SOUND STOP ERROR: $e');
    }
  }
}
