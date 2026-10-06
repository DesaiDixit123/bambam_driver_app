import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:bam_bam_driver/app/utils/asset_constants.dart';
import 'package:vibration/vibration.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Timer? _autoStopTimer;

  static Future<void> playRingtone({int timeoutSeconds = 30}) async {
    try {
      print("AudioService: Attempting to play ringtone with ${timeoutSeconds}s timeout...");

      // Cancel previous auto-stop timer if any
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      final assetPath = AssetConstants.ringtone.replaceFirst('assets/', '');
      print("AudioService: Asset path: $assetPath");

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      await _audioPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.notificationRingtone,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
      }

      // Hard auto-stop timer: Automatically stops audio & vibration after timeoutSeconds (30s)
      _autoStopTimer = Timer(Duration(seconds: timeoutSeconds), () {
        print("AudioService: Timeout (${timeoutSeconds}s) reached, stopping ringtone and vibration.");
        stopRingtone();
      });
    } catch (e) {
      print("AudioService: Error playing ringtone: $e");
    }
  }

  static Future<void> stopRingtone() async {
    try {
      print("AudioService: Stopping ringtone & canceling vibration...");
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      await _audioPlayer.stop();
      Vibration.cancel();
    } catch (e) {
      print("AudioService: Error stopping ringtone: $e");
    }
  }
}
