import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// A stub implementation of speech service when the actual plugin is not available
class SpeechService {
  bool _isEnabled = false;

  SpeechService() {
    debugPrint(
        'Using SpeechService stub implementation - using mock speech recognition');
  }

  /// Mock implementation that will return true and simulate speech recognition
  Future<bool> listen({required Function(String) onResult}) async {
    _isEnabled = true;

    // Simulate speech recognition after a short delay
    Future.delayed(Duration(seconds: 2), () {
      if (_isEnabled) {
        // Randomly select either English or Urdu sample text
        final isUrdu = math.Random().nextBool();

        final text = isUrdu
            ? "اقبال شاعری" // Urdu sample: "Iqbal poetry"
            : "sample voice search"; // English sample

        // Call the callback with sample text
        onResult(text);

        // Auto stop after returning a result
        stop();
      }
    });

    return true;
  }

  /// Stop the mock speech recognition
  Future<void> stop() async {
    _isEnabled = false;
  }

  /// Speech recognition is available with this mock implementation
  bool get isAvailable => true;
}
