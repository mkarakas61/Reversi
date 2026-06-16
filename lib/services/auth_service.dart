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

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    // On Android the server client id is read from google-services.json
    // (default_web_client_id), so the returned idToken is one Firebase accepts.
    await GoogleSignIn.instance.initialize();
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
