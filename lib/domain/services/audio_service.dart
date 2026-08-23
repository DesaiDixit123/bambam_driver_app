import 'package:audioplayers/audioplayers.dart';
import 'package:bam_bam_driver/app/utils/asset_constants.dart';
import 'package:vibration/vibration.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playRingtone() async {
    try {
      print("AudioService: Attempting to play ringtone...");

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
    } catch (e) {
      print("AudioService: Error playing ringtone: $e");
    }
  }

  static Future<void> stopRingtone() async {
    try {
      print("AudioService: Stopping ringtone...");
      await _audioPlayer.stop();
      Vibration.cancel();
    } catch (e) {
      print("AudioService: Error stopping ringtone: $e");
    }
  }
}
