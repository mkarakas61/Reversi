import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';
import '../models/week_id.dart';

/// Reads the leaderboard: lifetime totals from `users` (all-time) or this
/// ISO week's denormalized counters from `leaderboards/{weekId}/players`
/// (weekly, written server-side by `finish_game.ts` — REV-55). Read-only;
/// both sources are Cloud-Functions-write-only per firestore.rules.
class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  static const int topN = 50;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
      LeaderboardPeriod period) {
    if (period == LeaderboardPeriod.allTime) {
      return _db.collection('users');
    }
    return _db
        .collection('leaderboards')
        .doc(weekId(DateTime.now()))
        .collection('players');
  }

  String _field(LeaderboardPeriod period, LeaderboardMetric metric) {
    if (period == LeaderboardPeriod.allTime) {
      return metric == LeaderboardMetric.trophy
          ? 'online.trophies'
          : 'online.wins';
    }
    return metric == LeaderboardMetric.trophy ? 'trophyGained' : 'wins';
  }

  /// The top [topN] entries for a period/metric combination, best first.
  Future<List<LeaderboardEntry>> top(
    LeaderboardPeriod period,
    LeaderboardMetric metric,
  ) async {
    final snap = await _collection(period)
        .orderBy(_field(period, metric), descending: true)
        .limit(topN)
        .get();
    return snap.docs
        .map((d) => period == LeaderboardPeriod.allTime
            ? LeaderboardEntry.fromAllTimeUser(d.id, d.data())
            : LeaderboardEntry.fromWeeklyPlayer(d.id, d.data()))
        .toList();
  }

  /// This week's counters for [uid], or null if they haven't played a ranked
  /// game this week (no doc yet).
  Future<LeaderboardEntry?> myWeeklyEntry(String uid) async {
    final snap = await _collection(LeaderboardPeriod.weekly).doc(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return LeaderboardEntry.fromWeeklyPlayer(uid, data);
  }

  /// 1-based rank for a player whose sort-field value is [myValue]. Counts
  /// how many entries strictly exceed it and adds one; ties share the same
  /// rank as whoever is ahead of them (v1 simplification — no tie-breaking).
  Future<int> myRank(
    LeaderboardPeriod period,
    LeaderboardMetric metric,
    int myValue,
  ) async {
    final higher = await _collection(period)
        .where(_field(period, metric), isGreaterThan: myValue)
        .count()
        .get();
    return (higher.count ?? 0) + 1;
  }
}
