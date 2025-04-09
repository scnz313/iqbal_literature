import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:async';

/// A stub implementation of speech service when the actual plugin is not available
class SpeechService {
  bool _isEnabled = false;
  Timer? _simulatedRecordingTimer;

  SpeechService() {
    debugPrint(
        'Using SpeechService stub implementation - using mock speech recognition');
  }

  /// Mock implementation that will return true and simulate speech recognition
  Future<bool> listen({required Function(String) onResult}) async {
    if (_isEnabled) {
      debugPrint(
          'Speech recognition already active - stopping current session');
      await stop();
    }

    _isEnabled = true;
    debugPrint('Speech recognition started (mock)');

    // Simulate the recognition process with a realistic delay
    _simulatedRecordingTimer = Timer(Duration(milliseconds: 2500), () {
      if (_isEnabled) {
        // Randomly select either English or Urdu sample text
        final isUrdu = math.Random().nextBool();
        final randomOption = math.Random().nextInt(3); // 0, 1, or 2

        String text;
        if (isUrdu) {
          // Urdu sample texts
          switch (randomOption) {
            case 0:
              text = "اقبال شاعری"; // "Iqbal poetry"
              break;
            case 1:
              text = "علامہ اقبال"; // "Allama Iqbal"
              break;
            case 2:
            default:
              text = "شاہین اقبال"; // "Shaheen Iqbal"
              break;
          }
        } else {
          // English sample texts
          switch (randomOption) {
            case 0:
              text = "iqbal poetry";
              break;
            case 1:
              text = "allama iqbal";
              break;
            case 2:
            default:
              text = "iqbal works";
              break;
          }
        }

        debugPrint('Speech recognized (mock): "$text"');

        // Call the callback with sample text
        onResult(text);

        // Don't auto-stop, let the calling code handle that
        // This allows for a more realistic experience
      }
    });

    return true;
  }

  /// Stop the mock speech recognition
  Future<void> stop() async {
    debugPrint('Speech recognition stopped (mock)');
    _isEnabled = false;
    _simulatedRecordingTimer?.cancel();
    _simulatedRecordingTimer = null;
  }

  /// Speech recognition is available with this mock implementation
  bool get isAvailable => true;
}
