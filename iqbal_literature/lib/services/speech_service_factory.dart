import 'speech_service_stub.dart';

/// Factory to create speech service instances
class SpeechServiceFactory {
  /// Get an instance of SpeechService
  /// Since we've commented out the dependency in pubspec.yaml,
  /// this will always return the stub implementation
  static SpeechService createSpeechService() {
    return SpeechService();
  }
}
