import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'app_config.dart';

/// Initializes Firebase with retries so a transient plugin-channel race does
/// not permanently disable Auth / Firestore for the session.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool ready = false;

  static Future<bool> ensureInitialized() async {
    if (!AppConfig.firebaseEnabled) {
      ready = false;
      return false;
    }
    if (Firebase.apps.isNotEmpty) {
      ready = true;
      return true;
    }

    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        ready = Firebase.apps.isNotEmpty;
        debugPrint('Firebase ready (attempt $attempt)');
        return ready;
      } catch (e) {
        lastError = e;
        debugPrint('Firebase init attempt $attempt failed: $e');
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }

    ready = false;
    debugPrint('Firebase unavailable after retries: $lastError');
    return false;
  }
}
