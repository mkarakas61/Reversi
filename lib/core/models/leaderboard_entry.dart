import 'package:flutter/foundation.dart';

/// Which board the leaderboard shows: this ISO week's counters, or the
/// lifetime `users` totals.
enum LeaderboardPeriod { weekly, allTime }

/// Which stat the leaderboard ranks by. For [LeaderboardPeriod.weekly],
/// [level] ranks by XP gained *this week* (there's no weekly level, so
/// xpGained is the closest weekly analog to "climbing").
enum LeaderboardMetric { level, wins }

/// One ranked row. Only the fields relevant to the source collection are
/// populated — see [LeaderboardEntry.fromAllTimeUser] /
/// [LeaderboardEntry.fromWeeklyPlayer].
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.level,
    this.wins,
    this.xpGained,
  });

  final String uid;
  final String? displayName;
  final String? photoUrl;
  final int? level;
  final int? wins;
  final int? xpGained;

  factory LeaderboardEntry.fromAllTimeUser(
      String uid, Map<String, dynamic> data) {
    final online = data['online'] as Map<String, dynamic>?;
    return LeaderboardEntry(
      uid: uid,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      level: (data['level'] as num?)?.toInt() ?? 1,
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
      xpGained: (data['xpGained'] as num?)?.toInt() ?? 0,
    );
  }
}
