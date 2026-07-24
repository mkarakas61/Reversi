import 'package:flutter/foundation.dart';

/// Which board the leaderboard shows: this ISO week's counters, or the
/// lifetime `users` totals.
enum LeaderboardPeriod { weekly, allTime }

/// Which stat the leaderboard ranks by. For [LeaderboardPeriod.weekly],
/// [trophy] ranks by net trophies gained *this week* (there's no weekly rank,
/// so trophy climb is the closest weekly analog).
enum LeaderboardMetric { trophy, wins }

/// One ranked row. Only the fields relevant to the source collection are
/// populated — see [LeaderboardEntry.fromAllTimeUser] /
/// [LeaderboardEntry.fromWeeklyPlayer].
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.trophies,
    this.wins,
    this.trophyGained,
  });

  final String uid;
  final String? displayName;
  final String? photoUrl;

  /// Lifetime trophy total (all-time board).
  final int? trophies;
  final int? wins;

  /// Net trophies gained this ISO week (weekly board).
  final int? trophyGained;

  factory LeaderboardEntry.fromAllTimeUser(
      String uid, Map<String, dynamic> data) {
    final online = data['online'] as Map<String, dynamic>?;
    return LeaderboardEntry(
      uid: uid,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      trophies: (online?['trophies'] as num?)?.toInt() ?? 0,
      wins: (online?['wins'] as num?)?.toInt() ?? 0,
    );
  }

  factory LeaderboardEntry.fromWeeklyPlayer(
      String uid, Map<String, dynamic> data) {
    return LeaderboardEntry(
      uid: uid,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      trophyGained: (data['trophyGained'] as num?)?.toInt() ?? 0,
    );
  }
}
