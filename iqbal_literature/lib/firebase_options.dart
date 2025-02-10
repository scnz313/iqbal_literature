import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCStJINxRuLDHT2eXY8S6AXhQbig9azqxM',
    appId: '1:832102485805:android:24b6f477ed2aec2a220da4',
    messagingSenderId: '832102485805',
    projectId: 'iqbal-727aa',
    storageBucket: 'iqbal-727aa.firebasestorage.app',
    authDomain: 'iqbal-727aa.firebaseapp.com',
  );

  // Keep your existing android and ios configurations
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCStJINxRuLDHT2eXY8S6AXhQbig9azqxM',
    appId: '1:832102485805:android:24b6f477ed2aec2a220da4',
    messagingSenderId: '832102485805',
    projectId: 'iqbal-727aa',
    storageBucket: 'iqbal-727aa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '832102485805',
    projectId: 'iqbal-727aa',
    storageBucket: 'iqbal-727aa.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.iqbal',
  );
}
