enum GameMode { singlePlayer, twoPlayer }

enum Difficulty { easy, normal, hard }

/// How long the AI pauses before each move in single-player. Lets players who
/// find the default pause tedious speed it up (or slow it down). A small random
/// jitter is added on top of [aiDelayMs] so moves don't feel mechanical.
enum GameSpeed {
  fast(1000),
  normal(2000),
  slow(3000);

  const GameSpeed(this.aiDelayMs);

  /// Base milliseconds the AI waits before playing.
  final int aiDelayMs;
}

enum TimeLimit {
  thirtySeconds(30),
  oneMinute(60),
  threeMinutes(180),
  none(null);

  const TimeLimit(this.seconds);

  final int? seconds;
}
