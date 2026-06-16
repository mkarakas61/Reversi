import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reads and writes the player's Firestore profile (`users/{uid}`). Only the
/// identity fields (name/photo) are written here; xp, level and online stats
/// are owned by Cloud Functions (Admin SDK) and are read-only for the client.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  // Lazy so merely referencing the singleton never touches Firebase (keeps
  // widget tests that don't initialize Firebase working).
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  /// Creates the profile on first sign-in, or refreshes the identity fields on
  /// later sign-ins. Field sets match the create/update security rules.
  Future<void> ensureProfile(User user) async {
    final ref = _doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Live stream of the profile document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String uid) =>
      _doc(uid).snapshots();
}
