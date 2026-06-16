import 'package:flutter/foundation.dart';

/// Lifetime online (ranked) statistics for a player, stored under the
/// `online` map of the Firestore `users/{uid}` document. Kept separate from the
/// local single-player stats ([GameStats]) because online win/loss is ranked
/// and server-authoritative — only Cloud Functions (REV-50) ever write these
/// fields; the client only reads them.
@immutable
class OnlineStats {
  const OnlineStats({
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalFlipped = 0,
    this.bestScoreDiff = 0,
  });

  final int wins;
  final int losses;
  final int draws;

  /// Consecutive online wins up to the most recent game; 0 after a loss/draw.
  final int currentStreak;
  final int bestStreak;

  /// Total discs flipped across online games — also the basis for XP/coins.
  final int totalFlipped;

  /// Largest score gap in a won online game.
  final int bestScoreDiff;

  static const empty = OnlineStats();

  int get totalGames => wins + losses + draws;

  /// Win rate in `[0, 1]`, or 0 when no online games have been played.
  double get winRate => totalGames == 0 ? 0 : wins / totalGames;

  /// Parses the `online` map from a Firestore user document. Tolerates missing
  /// or partial data so older/empty profiles decode cleanly.
  factory OnlineStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return empty;
    int read(String key) => (data[key] as num?)?.toInt() ?? 0;
    return OnlineStats(
      wins: read('wins'),
      losses: read('losses'),
      draws: read('draws'),
      currentStreak: read('currentStreak'),
      bestStreak: read('bestStreak'),
      totalFlipped: read('totalFlipped'),
      bestScoreDiff: read('bestScoreDiff'),
    );
  }

  Map<String, dynamic> toMap() => {
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'totalFlipped': totalFlipped,
        'bestScoreDiff': bestScoreDiff,
      };
}
