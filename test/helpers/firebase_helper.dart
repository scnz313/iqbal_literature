import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

class MockFirebasePlatform extends FirebasePlatform {
  static const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_core');
  static MockFirebasePlatform get instance => _instance;
  static MockFirebasePlatform _instance = MockFirebasePlatform();

  static void registerInstance(MockFirebasePlatform instance) {
    FirebasePlatform.instance = instance;
    _instance = instance;
  }
}

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MockFirebasePlatform.channel.setMockMethodCallHandler((MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Firebase#initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'test-api-key',
              'appId': 'test-app-id',
              'messagingSenderId': 'test-sender-id',
              'projectId': 'test-project-id',
            },
            'pluginConstants': {},
          }
        ];
      case 'Firebase#initializeApp':
        return {
          'name': methodCall.arguments['appName'],
          'options': methodCall.arguments['options'],
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });

  MockFirebasePlatform.registerInstance(MockFirebasePlatform());
}