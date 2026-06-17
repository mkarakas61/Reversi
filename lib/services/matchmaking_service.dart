import 'package:cloud_firestore/cloud_firestore.dart';

import '../game/profile_scope.dart';
import '../models/online_stats.dart';

/// Client side of matchmaking. Writes the player's "waiting" ticket and lets
/// the UI listen for the server pairing function (onMatchmakingTicketCreated)
/// to turn it into a game. The ticket carries the profile/stats snapshot the
/// function copies into the game's playerInfo for the opponent preview.
class MatchmakingService {
  MatchmakingService._();
  static final MatchmakingService instance = MatchmakingService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ticket(String uid) =>
      _db.collection('matchmaking').doc(uid);

  Future<void> joinQueue(Profile profile, OnlineStats stats) {
    return _ticket(profile.uid).set({
      'uid': profile.uid,
      'displayName': profile.displayName,
      'photoUrl': profile.photoUrl,
      'level': profile.level,
      'wins': stats.wins,
      'losses': stats.losses,
      'draws': stats.draws,
      'bestStreak': stats.bestStreak,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Re-stamps the waiting ticket so the pairing function re-runs (it listens to
  /// ticket writes, not just creates). Lets a simultaneous join that missed its
  /// initial pairing self-heal within a few seconds. No-op if the ticket's gone.
  Future<void> touch(String uid) async {
    try {
      await _ticket(uid).update({'pingAt': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  /// Streams the player's ticket so the UI reacts when it becomes "matched".
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchTicket(String uid) =>
      _ticket(uid).snapshots();

  Future<void> cancel(String uid) async {
    try {
      await _ticket(uid).delete();
    } catch (_) {}
  }
}
