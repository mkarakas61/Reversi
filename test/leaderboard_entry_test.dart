import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry', () {
    test('fromAllTimeUser reads level and nested online.wins', () {
      final entry = LeaderboardEntry.fromAllTimeUser('u1', const {
        'displayName': 'Ada',
        'photoUrl': 'https://example.com/a.png',
        'level': 12,
        'online': {'wins': 34},
      });
      expect(entry.uid, 'u1');
      expect(entry.displayName, 'Ada');
      expect(entry.level, 12);
      expect(entry.wins, 34);
      expect(entry.xpGained, null);
    });

    test('fromAllTimeUser tolerates missing fields', () {
      final entry = LeaderboardEntry.fromAllTimeUser('u2', const {});
      expect(entry.level, 1);
      expect(entry.wins, 0);
    });

    test('fromWeeklyPlayer reads wins and xpGained', () {
      final entry = LeaderboardEntry.fromWeeklyPlayer('u3', const {
        'displayName': 'Beto',
        'wins': 5,
        'xpGained': 420,
      });
      expect(entry.wins, 5);
      expect(entry.xpGained, 420);
      expect(entry.level, null);
    });
  });
}
