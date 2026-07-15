import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps Firebase Auth + Google Sign-In (google_sign_in v7). Best-effort: a
/// user cancellation returns null, while real configuration/network failures
/// rethrow so the UI can surface a message. Offline play never depends on this.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleReady = false;

  /// The project's OAuth 2.0 Web client id (client_type 3 in
  /// google-services.json). google_sign_in v7 requires it explicitly on
  /// Android — it does NOT read default_web_client_id — to mint an idToken
  /// that Firebase accepts. This is a public client id, safe to commit.
  static const String _serverClientId =
      '819735082028-hfgggneicbf3550n57ivrm7pigvmmh9d.apps.googleusercontent.com';

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _googleReady = true;
  }

  /// Runs the interactive Google sign-in and links it to Firebase. Returns the
  /// signed-in [User], or null if the user cancelled the picker.
  Future<User?> signInWithGoogle() async {
    await _ensureGoogleReady();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('Google sign-in failed: $e');
      rethrow;
    }
  }

  /// Signs the device in as an anonymous Firebase user, for guest online play.
  /// No Google account is involved and no Firestore profile doc is created.
  Future<User?> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return result.user;
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleReady();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google sign-out issue: $e');
    }
    await _auth.signOut();
  }
}
