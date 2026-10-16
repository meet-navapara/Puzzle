// Generated for PetalGrid from android/app/google-services.json.
// Re-run `flutterfire configure` after adding iOS or updating Firebase apps.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS yet.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCn6mc6VyujL1nVHHs0HO6jaGDVnRkSb0E',
    appId: '1:712821429659:android:9fc385cfe8831e4b52fd3e',
    messagingSenderId: '712821429659',
    projectId: 'petalgrid-e7287',
    storageBucket: 'petalgrid-e7287.firebasestorage.app',
  );
}
