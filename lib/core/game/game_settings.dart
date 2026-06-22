enum GameMode { singlePlayer, twoPlayer }

enum Difficulty { easy, normal, hard }

enum TimeLimit {
  thirtySeconds(30),
  oneMinute(60),
  threeMinutes(180),
  none(null);

  const TimeLimit(this.seconds);

  final int? seconds;
}
