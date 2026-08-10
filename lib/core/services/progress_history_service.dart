import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/progress_history.dart';

/// Reads a signed-in player's match history (`users/{uid}/history`), written
/// server-side by `finish_game.ts` (REV-54). Guests never have this
/// subcollection — the online stats screen shows a sign-in upsell instead.
class ProgressHistoryService {
  ProgressHistoryService._();
  static final ProgressHistoryService instance = ProgressHistoryService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Streams the most recent games in chronological (oldest-first) order, so
  /// charts can plot them left-to-right as they happened.
  Stream<List<HistoryEntry>> watch(String uid, {int limit = 100}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('ts')
        .limitToLast(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HistoryEntry.fromMap(d.data())).toList());
  }

  /// Streams a single game's history doc (`users/{uid}/history/{gameId}`),
  /// emitting `null` until the reward function has written it. The match-result
  /// screen (REV-74) uses this to reveal the trophy change once it lands.
  Stream<HistoryEntry?> watchReward(String uid, String gameId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('history')
        .doc(gameId)
        .snapshots()
        .map((d) => d.exists ? HistoryEntry.fromMap(d.data()!) : null);
  }
}
