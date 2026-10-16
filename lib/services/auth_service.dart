import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_config.dart';

enum AuthStatus { guest, authenticated, signingIn, error }

class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance {
    _auth = auth;
  }

  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;

  AuthStatus status = AuthStatus.guest;
  String? errorMessage;
  User? user;

  String? get uid => user?.uid;
  bool get isAuthenticated => user != null;
  bool get isGuest => user == null;

  Future<void> initialize() async {
    if (!AppConfig.firebaseEnabled) {
      status = AuthStatus.guest;
      notifyListeners();
      return;
    }
    try {
      _auth ??= FirebaseAuth.instance;
      user = _auth!.currentUser;
      status = user != null ? AuthStatus.authenticated : AuthStatus.guest;
      _auth!.authStateChanges().listen((u) {
        user = u;
        status = u != null ? AuthStatus.authenticated : AuthStatus.guest;
        notifyListeners();
      });
    } catch (e) {
      status = AuthStatus.guest;
      errorMessage = 'Auth unavailable';
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    if (!AppConfig.firebaseEnabled) {
      errorMessage = 'Firebase is not configured yet. Enable AppConfig.firebaseEnabled after adding google-services files.';
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    status = AuthStatus.signingIn;
    errorMessage = null;
    notifyListeners();
    try {
      _auth ??= FirebaseAuth.instance;
      await _googleSignIn.initialize();
      final account = await _googleSignIn.authenticate();
      final googleAuth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await _auth!.signInWithCredential(credential);
      user = result.user;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        errorMessage = null;
        status = AuthStatus.guest;
      } else {
        errorMessage = 'Google Sign-In failed';
        status = AuthStatus.error;
      }
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Sign-in failed. Check network and Firebase setup.';
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      if (AppConfig.firebaseEnabled) {
        await _auth?.signOut();
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    user = null;
    status = AuthStatus.guest;
    notifyListeners();
  }

  /// Deletes Firebase Auth user. Cloud data deletion is handled by CloudSaveService.
  Future<bool> deleteAccount() async {
    if (!AppConfig.firebaseEnabled || user == null) return false;
    try {
      await user!.delete();
      user = null;
      status = AuthStatus.guest;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Account deletion requires recent sign-in. Sign in again, then retry.';
      notifyListeners();
      return false;
    }
  }
}
