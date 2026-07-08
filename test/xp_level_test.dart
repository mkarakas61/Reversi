import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/game_stats.dart';
import 'package:reversi/core/models/xp_level.dart';

void main() {
  group('XpLevel.xpForLevel', () {
    test('level 1 needs 0 XP', () => expect(XpLevel.xpForLevel(1), 0));
    test('level 2 needs 100 XP', () => expect(XpLevel.xpForLevel(2), 100));
    test('level 3 needs 300 XP', () => expect(XpLevel.xpForLevel(3), 300));
    test('level 4 needs 600 XP', () => expect(XpLevel.xpForLevel(4), 600));
    test('level 10 needs 4500 XP', () => expect(XpLevel.xpForLevel(10), 4500));
  });

  group('XpLevel.level', () {
    test('0 XP → level 1', () => expect(XpLevel.level(0), 1));
    test('negative XP → level 1', () => expect(XpLevel.level(-1), 1));
    test('99 XP → level 1', () => expect(XpLevel.level(99), 1));
    test('100 XP → level 2', () => expect(XpLevel.level(100), 2));
    test('299 XP → level 2', () => expect(XpLevel.level(299), 2));
    test('300 XP → level 3', () => expect(XpLevel.level(300), 3));
    test('599 XP → level 3', () => expect(XpLevel.level(599), 3));
    test('600 XP → level 4', () => expect(XpLevel.level(600), 4));
    test('4499 XP → level 9', () => expect(XpLevel.level(4499), 9));
    test('4500 XP → level 10', () => expect(XpLevel.level(4500), 10));

    test('level(xpForLevel(L)) == L for several levels', () {
      for (var L = 1; L <= 20; L++) {
        expect(XpLevel.level(XpLevel.xpForLevel(L)), L,
            reason: 'level(xpForLevel($L)) should be $L');
      }
    });

    test('one XP below a level threshold stays at previous level', () {
      for (var L = 2; L <= 10; L++) {
        expect(XpLevel.level(XpLevel.xpForLevel(L) - 1), L - 1,
            reason: 'xpForLevel($L)-1 should give level ${L - 1}');
      }
    });
  });

  group('XpLevel.levelProgress', () {
    test('exactly at level floor → 0.0', () {
      expect(XpLevel.levelProgress(100), 0.0);
    });
    test('exactly at next level floor → 0.0 (just entered next level)', () {
      expect(XpLevel.levelProgress(300), 0.0);
    });
    test('halfway through level 2 (100–300, range 200)', () {
      expect(XpLevel.levelProgress(200), 0.5);
    });
  });

  group('XpLevel.earnedXp', () {
    test('bare win (no bonuses)', () {
      final xp = XpLevel.earnedXp(
        outcome: GameOutcome.win,
        scoreDiff: 0,
        flippedPieces: 0,
        myLevel: 5,
        oppLevel: 5,
        streak: 0,
      );
      expect(xp, 100);
    });

    test('bare draw', () {
      final xp = XpLevel.earnedXp(
        outcome: GameOutcome.draw,
        scoreDiff: 10,
        flippedPieces: 16,
        myLevel: 3,
        oppLevel: 5,
        streak: 4,
      );
      // base=40, scoreBonus=0 (draw), flipBonus=2, levelBonus=0 (draw), streak≥4 → +20
      expect(xp, 40 + 0 + 2 + 0 + 20);
    });

    test('bare loss', () {
      final xp = XpLevel.earnedXp(
        outcome: GameOutcome.loss,
        scoreDiff: 20,
        flippedPieces: 24,
        myLevel: 3,
        oppLevel: 7,
        streak: 3,
      );
      // base=15, scoreBonus=0 (loss), flipBonus=3, levelBonus=0 (loss), streak=3 → +15
      expect(xp, 15 + 0 + 3 + 0 + 15);
    });

    test('win with all bonuses', () {
      final xp = XpLevel.earnedXp(
        outcome: GameOutcome.win,
        scoreDiff: 40, // capped at 30
        flippedPieces: 24,
        myLevel: 3,
        oppLevel: 7, // oppLevel - myLevel = 4, clamped to +8 → clamp(4,-4,8)=4
        streak: 7, // capped at 5
      );
      // base=100, scoreBonus=30, flipBonus=3, levelBonus=clamp(4,-4,8)*8=32, streak=5*5=25
      expect(xp, 100 + 30 + 3 + 32 + 25);
    });

    test('win — opponent level lower applies penalty (−4 floor)', () {
      final xp = XpLevel.earnedXp(
        outcome: GameOutcome.win,
        scoreDiff: 0,
        flippedPieces: 0,
        myLevel: 10,
        oppLevel: 1, // oppLevel - myLevel = -9, clamped to -4
        streak: 0,
      );
      // base=100, levelBonus=clamp(-9,-4,8)*8 = -32
      expect(xp, 100 - 32);
    });

    test('score bonus is capped at 30', () {
      final full = XpLevel.earnedXp(
        outcome: GameOutcome.win,
        scoreDiff: 50,
        flippedPieces: 0,
        myLevel: 5,
        oppLevel: 5,
        streak: 0,
      );
      final capped = XpLevel.earnedXp(
        outcome: GameOutcome.win,
        scoreDiff: 30,
        flippedPieces: 0,
        myLevel: 5,
        oppLevel: 5,
        streak: 0,
      );
      expect(full, capped);
    });

    test('streak capped at 5 (no extra for streak > 5)', () {
      final atFive = XpLevel.earnedXp(
        outcome: GameOutcome.win,
        scoreDiff: 0,
        flippedPieces: 0,
        myLevel: 5,
        oppLevel: 5,
        streak: 5,
      );
      final aboveFive = XpLevel.earnedXp(
        outcome: GameOutcome.win,
        scoreDiff: 0,
        flippedPieces: 0,
        myLevel: 5,
        oppLevel: 5,
        streak: 10,
      );
      expect(atFive, aboveFive);
    });
  });
}
