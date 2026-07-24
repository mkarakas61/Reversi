import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/online_stats.dart';

/// Another player's public profile + ranked stats, read from `users/{uid}`.
class PublicProfile {
  const PublicProfile({
    required this.stats,
    this.name,
    this.photoUrl,
  });

  final OnlineStats stats;
  final String? name;
  final String? photoUrl;
}

/// One-shot reader for another player's public profile — used to show the
/// opponent's rank + full online stats on the match screen (REV-75). Profiles
/// are world-readable to signed-in users (firestore.rules), so this needs no
/// extra permission. Guests have no `users/{uid}` doc, so they read as null.
class PlayerProfileService {
  PlayerProfileService._();
  static final PlayerProfileService instance = PlayerProfileService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Fetches `users/{uid}`. Returns null for guests (no doc) or on any error —
  /// the caller then simply shows no rank / stats for that player.
  Future<PublicProfile?> fetch(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return PublicProfile(
        stats: OnlineStats.fromMap(data['online'] as Map<String, dynamic>?),
        name: data['displayName'] as String?,
        photoUrl: data['photoUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
