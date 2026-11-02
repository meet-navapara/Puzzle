import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_config.dart';
import '../core/firebase_bootstrap.dart';

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

  bool get _firebaseUsable =>
      AppConfig.firebaseEnabled &&
      FirebaseBootstrap.ready &&
      Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!_firebaseUsable) {
      status = AuthStatus.guest;
      notifyListeners();
      return;
    }
    try {
      await _googleSignIn.initialize(
        serverClientId: AppConfig.googleWebClientId,
      );
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
    status = AuthStatus.signingIn;
    errorMessage = null;
    notifyListeners();
    // A slow start can leave Firebase down; try again now the player asked.
    if (!_firebaseUsable) await FirebaseBootstrap.ensureInitialized();
    if (!_firebaseUsable) {
      errorMessage =
          'Google Sign-In is unavailable right now. Play as a guest '
          'and link your account later from Settings.';
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    try {
      _auth ??= FirebaseAuth.instance;
      await _googleSignIn.initialize(
        serverClientId: AppConfig.googleWebClientId,
      );
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
        debugPrint('Google Sign-In failed: ${e.code} ${e.description}');
        errorMessage =
            'Google Sign-In failed. Check your connection and try again.';
        status = AuthStatus.error;
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      errorMessage = 'Sign-in failed. Check your connection and try again.';
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    if (status == AuthStatus.error) status = AuthStatus.guest;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      if (_firebaseUsable) {
        await _auth?.signOut();
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    user = null;
    status = AuthStatus.guest;
    notifyListeners();
  }

  /// Re-authenticates with Google so sensitive Auth actions (delete) succeed.
  Future<bool> reauthenticateWithGoogle() async {
    if (!_firebaseUsable || user == null) return false;
    try {
      _auth ??= FirebaseAuth.instance;
      await _googleSignIn.initialize(
        serverClientId: AppConfig.googleWebClientId,
      );
      final account = await _googleSignIn.authenticate();
      final googleAuth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await user!.reauthenticateWithCredential(credential);
      user = _auth!.currentUser;
      notifyListeners();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        errorMessage = 'Sign-in canceled. Account was not deleted.';
      } else {
        errorMessage = 'Could not re-authenticate with Google.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Re-authentication failed. Try again.';
      notifyListeners();
      return false;
    }
  }

  /// Deletes Firebase Auth user. Prefer calling [reauthenticateWithGoogle] first.
  /// Cloud data deletion is handled by CloudSaveService.
  Future<bool> deleteAccount({bool reauthenticateFirst = true}) async {
    if (!_firebaseUsable || user == null) return false;
    try {
      if (reauthenticateFirst) {
        final ok = await reauthenticateWithGoogle();
        if (!ok) return false;
      }
      await user!.delete();
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      user = null;
      status = AuthStatus.guest;
      errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Account deletion requires recent sign-in. Confirm Google Sign-In, then retry.';
      } else {
        errorMessage = 'Account deletion failed (${e.code}).';
      }
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Account deletion failed. Try again.';
      notifyListeners();
      return false;
    }
  }
}
