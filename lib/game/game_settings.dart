enum GameMode { singlePlayer, twoPlayer }

enum Difficulty { easy, normal, hard }

/// Per-move time limit for two-player games. When the clock runs out the turn
/// is forfeited to the opponent.
enum TimeLimit {
  thirtySeconds(30),
  oneMinute(60),
  threeMinutes(180),
  none(null);

  const TimeLimit(this.seconds);

  /// Seconds per move, or `null` for untimed play.
  final int? seconds;
}
