import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/game/game_settings.dart';
import 'package:reversi/game/reversi_game.dart';
import 'package:reversi/models/game_stats.dart';

void main() {
  group('StatsMode.fromGame', () {
    test('maps single-player difficulties', () {
      expect(StatsMode.fromGame(GameMode.singlePlayer, Difficulty.easy),
          StatsMode.singlePlayerEasy);
      expect(StatsMode.fromGame(GameMode.singlePlayer, Difficulty.normal),
          StatsMode.singlePlayerNormal);
      expect(StatsMode.fromGame(GameMode.singlePlayer, Difficulty.hard),
          StatsMode.singlePlayerHard);
    });

    test('maps two-player regardless of difficulty', () {
      expect(StatsMode.fromGame(GameMode.twoPlayer, null), StatsMode.twoPlayer);
    });
  });

  group('outcomeFor', () {
    test('black winner is a win, white winner is a loss, null is a draw', () {
      expect(outcomeFor(Disc.black), GameOutcome.win);
      expect(outcomeFor(Disc.white), GameOutcome.loss);
      expect(outcomeFor(null), GameOutcome.draw);
    });
  });

  group('GameStats.recordGame', () {
    test('accumulates totals and per-mode breakdown', () {
      var stats = GameStats.empty;
      stats = stats.recordGame(
        mode: StatsMode.singlePlayerEasy,
        outcome: GameOutcome.win,
        scoreDiff: 20,
        flippedDiscs: 30,
        durationSeconds: 60,
      );
      stats = stats.recordGame(
        mode: StatsMode.twoPlayer,
        outcome: GameOutcome.loss,
        scoreDiff: 4,
        flippedDiscs: 10,
        durationSeconds: 30,
      );

      expect(stats.totalGames, 2);
      expect(stats.overall.wins, 1);
      expect(stats.overall.losses, 1);
      expect(stats.recordFor(StatsMode.singlePlayerEasy).wins, 1);
      expect(stats.recordFor(StatsMode.twoPlayer).losses, 1);
      expect(stats.totalFlippedDiscs, 40);
      expect(stats.totalPlayTimeSeconds, 90);
      expect(stats.bestScoreDiff, 20);
    });

    test('tracks the current and best win streaks', () {
      var stats = GameStats.empty;
      for (var i = 0; i < 3; i++) {
        stats = stats.recordGame(
          mode: StatsMode.twoPlayer,
          outcome: GameOutcome.win,
          scoreDiff: 1,
          flippedDiscs: 1,
          durationSeconds: 1,
        );
      }
      expect(stats.currentWinStreak, 3);
      expect(stats.bestWinStreak, 3);

      stats = stats.recordGame(
        mode: StatsMode.twoPlayer,
        outcome: GameOutcome.loss,
        scoreDiff: 1,
        flippedDiscs: 1,
        durationSeconds: 1,
      );
      expect(stats.currentWinStreak, 0);
      expect(stats.bestWinStreak, 3);
    });

    test('a draw does not raise bestScoreDiff', () {
      final stats = GameStats.empty.recordGame(
        mode: StatsMode.twoPlayer,
        outcome: GameOutcome.draw,
        scoreDiff: 0,
        flippedDiscs: 5,
        durationSeconds: 5,
      );
      expect(stats.bestScoreDiff, 0);
      expect(stats.overall.draws, 1);
    });
  });

  group('JSON round-trip', () {
    test('serializes and restores all fields', () {
      final stats = GameStats.empty
          .recordGame(
            mode: StatsMode.singlePlayerHard,
            outcome: GameOutcome.win,
            scoreDiff: 15,
            flippedDiscs: 25,
            durationSeconds: 120,
          )
          .recordGame(
            mode: StatsMode.singlePlayerHard,
            outcome: GameOutcome.draw,
            scoreDiff: 0,
            flippedDiscs: 18,
            durationSeconds: 90,
          );

      final restored = GameStats.fromJson(stats.toJson());

      expect(restored.overall.wins, stats.overall.wins);
      expect(restored.overall.draws, stats.overall.draws);
      expect(restored.recordFor(StatsMode.singlePlayerHard).totalGames, 2);
      expect(restored.currentWinStreak, stats.currentWinStreak);
      expect(restored.bestWinStreak, stats.bestWinStreak);
      expect(restored.bestScoreDiff, stats.bestScoreDiff);
      expect(restored.totalFlippedDiscs, stats.totalFlippedDiscs);
      expect(restored.totalPlayTimeSeconds, stats.totalPlayTimeSeconds);
    });

    test('missing fields fall back to defaults', () {
      final restored = GameStats.fromJson(const {});
      expect(restored.totalGames, 0);
      expect(restored.totalFlippedDiscs, 0);
      expect(restored.byMode, isEmpty);
    });
  });
}
