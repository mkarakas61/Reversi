import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/online_stats.dart';

void main() {
  group('OnlineStats', () {
    test('empty has zeroed fields and a zero win rate', () {
      const stats = OnlineStats.empty;
      expect(stats.totalGames, 0);
      expect(stats.winRate, 0);
      expect(stats.wins, 0);
    });

    test('totalGames and winRate derive from the tally', () {
      const stats = OnlineStats(wins: 3, losses: 1, draws: 0);
      expect(stats.totalGames, 4);
      expect(stats.winRate, closeTo(0.75, 1e-9));
    });

    test('fromMap reads all fields', () {
      final stats = OnlineStats.fromMap(const {
        'wins': 5,
        'losses': 2,
        'draws': 1,
        'currentStreak': 2,
        'bestStreak': 4,
        'totalFlipped': 120,
        'bestScoreDiff': 30,
      });
      expect(stats.wins, 5);
      expect(stats.losses, 2);
      expect(stats.draws, 1);
      expect(stats.currentStreak, 2);
      expect(stats.bestStreak, 4);
      expect(stats.totalFlipped, 120);
      expect(stats.bestScoreDiff, 30);
      expect(stats.totalGames, 8);
    });

    test('fromMap tolerates null and missing/partial data', () {
      expect(OnlineStats.fromMap(null).totalGames, 0);
      final partial = OnlineStats.fromMap(const {'wins': 2});
      expect(partial.wins, 2);
      expect(partial.losses, 0);
      expect(partial.bestStreak, 0);
    });

    test('toMap round-trips through fromMap', () {
      const original = OnlineStats(
        wins: 7,
        losses: 3,
        draws: 2,
        currentStreak: 1,
        bestStreak: 5,
        totalFlipped: 200,
        bestScoreDiff: 24,
      );
      final restored = OnlineStats.fromMap(original.toMap());
      expect(restored.wins, original.wins);
      expect(restored.losses, original.losses);
      expect(restored.draws, original.draws);
      expect(restored.bestStreak, original.bestStreak);
      expect(restored.totalFlipped, original.totalFlipped);
      expect(restored.bestScoreDiff, original.bestScoreDiff);
    });
  });
}
