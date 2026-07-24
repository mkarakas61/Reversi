import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry', () {
    test('fromAllTimeUser reads nested online.trophies and online.wins', () {
      final entry = LeaderboardEntry.fromAllTimeUser('u1', const {
        'displayName': 'Ada',
        'photoUrl': 'https://example.com/a.png',
        'online': {'trophies': 312, 'wins': 34},
      });
      expect(entry.uid, 'u1');
      expect(entry.displayName, 'Ada');
      expect(entry.trophies, 312);
      expect(entry.wins, 34);
      expect(entry.trophyGained, null);
    });

    test('fromAllTimeUser tolerates missing fields', () {
      final entry = LeaderboardEntry.fromAllTimeUser('u2', const {});
      expect(entry.trophies, 0);
      expect(entry.wins, 0);
    });

    test('fromWeeklyPlayer reads wins and trophyGained', () {
      final entry = LeaderboardEntry.fromWeeklyPlayer('u3', const {
        'displayName': 'Beto',
        'wins': 5,
        'trophyGained': 18,
      });
      expect(entry.wins, 5);
      expect(entry.trophyGained, 18);
      expect(entry.trophies, null);
    });
  });
}
