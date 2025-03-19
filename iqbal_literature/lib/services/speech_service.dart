import 'package:flutter/foundation.dart';
import 'speech_service_stub.dart' as stub;

/// A wrapper class for speech-to-text functionality
/// Redirects to our stub implementation since the speech_to_text package is not available
class SpeechService {
  final stub.SpeechService _stubService = stub.SpeechService();

  /// Initialize the speech recognition service
  SpeechService() {
    debugPrint('Using SpeechService redirect to stub implementation');
  }

  /// Start listening for speech
  Future<bool> listen({required Function(String) onResult}) async {
    return _stubService.listen(onResult: onResult);
  }

  /// Stop listening for speech
  Future<void> stop() async {
    await _stubService.stop();
  }

  /// Check if speech recognition is available
  bool get isAvailable => _stubService.isAvailable;
}
