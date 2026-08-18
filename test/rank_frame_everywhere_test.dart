import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/leaderboard_entry.dart';
import 'package:reversi/core/models/rank.dart';

// REV-106: an earned frame has to show up wherever the player's name does.
// REV-61 parked the leaderboard half of that on a claim that turned out to be
// wrong — that the weekly board had no `trophies` field to read a rank from.
// The server has been stamping it every game all along (finish_game.ts); only
// the client model was dropping it. These tests keep it read.
void main() {
  group('LeaderboardEntry rank source', () {
    test('the weekly board carries the lifetime total, so it has a rank', () {
      final entry = LeaderboardEntry.fromWeeklyPlayer('u1', {
        'displayName': 'Ali',
        'wins': 3,
        'trophyGained': 42,
        'trophies': 320,
      });

      expect(entry.trophies, 320);
      // 320 is past the fourth threshold, so this row is not the base rank —
      // if the field were dropped, every row would wear the same frame.
      expect(rankFor(entry.trophies!).id, isNot(rankFor(0).id));
    });

    test('weekly ranking still comes from the weekly gain, not the total', () {
      final entry = LeaderboardEntry.fromWeeklyPlayer('u1', {
        'trophyGained': 42,
        'trophies': 320,
      });

      // The two must stay separate: trophies is identity (the frame),
      // trophyGained is what the weekly board sorts on.
      expect(entry.trophyGained, 42);
      expect(entry.trophies, 320);
    });

    test('a row written before the field existed goes unframed, not broken',
        () {
      final entry = LeaderboardEntry.fromWeeklyPlayer('u1', {
        'displayName': 'Eski',
        'wins': 1,
        'trophyGained': 5,
      });

      expect(entry.trophies, isNull);
    });

    test('the all-time board reads its own total', () {
      final entry = LeaderboardEntry.fromAllTimeUser('u1', {
        'displayName': 'Ali',
        'online': {'trophies': 1200, 'wins': 40},
      });

      expect(entry.trophies, 1200);
    });
  });

  group('every rank can be worn', () {
    test('each rank resolves to a frame asset', () {
      for (final rank in kRanks) {
        expect(rank.frame.asset, isNotEmpty, reason: rank.id.name);
      }
    });

    test('a trophy count anywhere on the ladder yields a frame', () {
      for (final trophies in [0, 29, 30, 99, 100, 249, 550, 1000, 99999]) {
        expect(rankFor(trophies).frame.asset, isNotEmpty,
            reason: '$trophies trophies');
      }
    });
  });
}
