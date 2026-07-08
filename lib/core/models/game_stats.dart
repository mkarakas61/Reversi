import '../game/game_settings.dart';
import '../game/reversi_game.dart';

/// Result of a finished game from the black/"Sen" side's perspective. In
/// single-player this is the human vs the AI; in two-player it is whoever
/// plays as [Disc.black] (the bottom card) vs [Disc.white].
enum GameOutcome { win, loss, draw }

/// The single-player difficulty buckets stats are broken down by. Two-player
/// games are not recorded — with no AI opponent, win/loss has no consistent
/// meaning (the human may have played either side). Kept separate from
/// [Difficulty] so future modes (online play, levels) can be added without
/// touching old saved data.
enum StatsMode {
  singlePlayerEasy,
  singlePlayerNormal,
  singlePlayerHard;

  static StatsMode fromDifficulty(Difficulty? difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return StatsMode.singlePlayerEasy;
      case Difficulty.normal:
      case null:
        return StatsMode.singlePlayerNormal;
      case Difficulty.hard:
        return StatsMode.singlePlayerHard;
    }
  }
}

/// Win/loss/draw tally for one [StatsMode] (or the overall total).
class ModeRecord {
  const ModeRecord({this.wins = 0, this.losses = 0, this.draws = 0});

  final int wins;
  final int losses;
  final int draws;

  int get totalGames => wins + losses + draws;

  /// Win rate in `[0, 1]`, or 0 when no games have been played.
  double get winRate => totalGames == 0 ? 0 : wins / totalGames;

  ModeRecord addOutcome(GameOutcome outcome) {
    switch (outcome) {
      case GameOutcome.win:
        return ModeRecord(wins: wins + 1, losses: losses, draws: draws);
      case GameOutcome.loss:
        return ModeRecord(wins: wins, losses: losses + 1, draws: draws);
      case GameOutcome.draw:
        return ModeRecord(wins: wins, losses: losses, draws: draws + 1);
    }
  }

  Map<String, dynamic> toJson() => {
        'wins': wins,
        'losses': losses,
        'draws': draws,
      };

  factory ModeRecord.fromJson(Map<String, dynamic> json) => ModeRecord(
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        draws: json['draws'] as int? ?? 0,
      );
}

/// Aggregate lifetime statistics, persisted via `StatsStorage`. Designed so
/// new fields (e.g. an XP total derived from [totalFlippedDiscs]) can be
/// added later without breaking older saved data — see
/// `StatsStorage._decode`.
class GameStats {
  const GameStats({
    this.overall = const ModeRecord(),
    this.byMode = const {},
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
    this.bestScoreDiff = 0,
    this.totalFlippedDiscs = 0,
    this.totalPlayTimeSeconds = 0,
  });

  static const empty = GameStats();

  final ModeRecord overall;
  final Map<StatsMode, ModeRecord> byMode;

  /// Consecutive wins right up to the most recent game; resets to 0 on a loss
  /// or draw.
  final int currentWinStreak;

  /// The highest [currentWinStreak] ever reached.
  final int bestWinStreak;

  /// The largest score gap (`|black - white|`) in any won game.
  final int bestScoreDiff;

  /// Total discs flipped across every game ever played — the basis for a
  /// future XP system.
  final int totalFlippedDiscs;

  /// Total time spent playing, summed across every finished game.
  final int totalPlayTimeSeconds;

  int get totalGames => overall.totalGames;

  ModeRecord recordFor(StatsMode mode) => byMode[mode] ?? const ModeRecord();

  /// Returns updated stats after a game finishes.
  GameStats recordGame({
    required StatsMode mode,
    required GameOutcome outcome,
    required int scoreDiff,
    required int flippedDiscs,
    required int durationSeconds,
  }) {
    final nextStreak = outcome == GameOutcome.win ? currentWinStreak + 1 : 0;
    return GameStats(
      overall: overall.addOutcome(outcome),
      byMode: {
        ...byMode,
        mode: recordFor(mode).addOutcome(outcome),
      },
      currentWinStreak: nextStreak,
      bestWinStreak: nextStreak > bestWinStreak ? nextStreak : bestWinStreak,
      bestScoreDiff: outcome == GameOutcome.win && scoreDiff > bestScoreDiff
          ? scoreDiff
          : bestScoreDiff,
      totalFlippedDiscs: totalFlippedDiscs + flippedDiscs,
      totalPlayTimeSeconds: totalPlayTimeSeconds + durationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall.toJson(),
        'byMode': {
          for (final entry in byMode.entries)
            entry.key.name: entry.value.toJson(),
        },
        'currentWinStreak': currentWinStreak,
        'bestWinStreak': bestWinStreak,
        'bestScoreDiff': bestScoreDiff,
        'totalFlippedDiscs': totalFlippedDiscs,
        'totalPlayTimeSeconds': totalPlayTimeSeconds,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) {
    final byModeJson = json['byMode'] as Map<String, dynamic>? ?? const {};
    final byMode = <StatsMode, ModeRecord>{};
    for (final mode in StatsMode.values) {
      final raw = byModeJson[mode.name];
      if (raw is Map<String, dynamic>) {
        byMode[mode] = ModeRecord.fromJson(raw);
      }
    }
    return GameStats(
      overall: json['overall'] is Map<String, dynamic>
          ? ModeRecord.fromJson(json['overall'] as Map<String, dynamic>)
          : const ModeRecord(),
      byMode: byMode,
      currentWinStreak: json['currentWinStreak'] as int? ?? 0,
      bestWinStreak: json['bestWinStreak'] as int? ?? 0,
      bestScoreDiff: json['bestScoreDiff'] as int? ?? 0,
      totalFlippedDiscs: json['totalFlippedDiscs'] as int? ?? 0,
      totalPlayTimeSeconds: json['totalPlayTimeSeconds'] as int? ?? 0,
    );
  }
}

/// Maps a finished [ReversiGame] to the [GameOutcome] from [Disc.black]'s
/// perspective.
GameOutcome outcomeFor(Disc? winner) {
  if (winner == null) return GameOutcome.draw;
  return winner == Disc.black ? GameOutcome.win : GameOutcome.loss;
}
