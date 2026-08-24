import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/rank.dart';
import 'package:reversi/core/models/wallet.dart';

// The "How to Play" screen now states the trophy and coin rules outright: win
// +3, a bigger win more, this rank loses that much. Those numbers come from
// Dart mirrors of server files that nobody edits together with the app.
//
// A drifted mirror is worse than no mirror: the player is told a rule, plays by
// it, and the server does something else. So these tests read the TypeScript
// and compare, rather than trusting a "keep in sync" comment.
void main() {
  final trophyTs = File('functions/src/trophy.ts').readAsStringSync();
  final xpTs = File('functions/src/xp_level.ts').readAsStringSync();
  final bonusTs = File('functions/src/coin_bonus.ts').readAsStringSync();

  int constant(String source, String name) {
    final match =
        RegExp('$name = (-?\\d+)').firstMatch(source);
    expect(match, isNotNull, reason: '$name not found');
    return int.parse(match!.group(1)!);
  }

  group('trophies mirror trophy.ts', () {
    test('win base, draw and the biggest margin bonus', () {
      expect(TrophyRewards.winBase, constant(trophyTs, 'WIN_BASE'));
      expect(TrophyRewards.drawGain, constant(trophyTs, 'DRAW_GAIN'));
      expect(TrophyRewards.maxWinBonus, constant(trophyTs, 'MAX_WIN_BONUS'));
    });

    test('the margin bonus divides the score gap by the same number', () {
      // trophyDelta: Math.min(Math.round(Math.abs(scoreDiff) / 8), MAX)
      expect(
        trophyTs.contains(
            'Math.abs(scoreDiff) / ${TrophyRewards.scoreDiffPerBonus}'),
        isTrue,
      );
    });

    test('every rank has a loss penalty, and it matches the server', () {
      for (final rank in kRanks) {
        final penalty = TrophyRewards.lossPenalty[rank.id];
        expect(penalty, isNotNull, reason: '${rank.id} has no penalty');
        expect(
          trophyTs.contains(
              '{id: "${rank.id.name}", minTrophies: ${rank.minTrophies}, '
              'lossPenalty: $penalty}'),
          isTrue,
          reason: '${rank.id.name} differs from trophy.ts',
        );
      }
    });

    test('penalties never shrink as the ladder is climbed', () {
      var previous = 0;
      for (final rank in kRanks) {
        final penalty = TrophyRewards.lossPenalty[rank.id]!;
        expect(penalty, greaterThanOrEqualTo(previous));
        previous = penalty;
      }
    });

    test('break-even win rate: 0% while nothing is lost, then rising', () {
      expect(TrophyRewards.breakEvenWinRatePercent(RankId.caylak), 0);
      expect(TrophyRewards.breakEvenWinRatePercent(RankId.kalfa), 25);
      expect(TrophyRewards.breakEvenWinRatePercent(RankId.usta), 40);
      expect(TrophyRewards.breakEvenWinRatePercent(RankId.buyukusta), 57);
      expect(TrophyRewards.breakEvenWinRatePercent(RankId.efsane), 67);
    });
  });

  group('coins mirror the server', () {
    test('win / draw / loss', () {
      expect(CoinRewards.win, constant(xpTs, 'COIN_WIN'));
      expect(CoinRewards.draw, constant(xpTs, 'COIN_DRAW'));
      expect(CoinRewards.loss, constant(xpTs, 'COIN_LOSS'));
    });

    test('happy hour window and multiplier', () {
      expect(HappyHour.startHour, constant(bonusTs, 'HAPPY_HOUR_START_HOUR'));
      expect(HappyHour.endHour, constant(bonusTs, 'HAPPY_HOUR_END_HOUR'));
      expect(HappyHour.multiplier, constant(bonusTs, 'HAPPY_HOUR_MULTIPLIER'));
    });

    test('waiting bonus rate and cap', () {
      expect(CoinRewards.waitBonusPerMinute,
          constant(bonusTs, 'WAIT_BONUS_PER_MINUTE'));
      expect(CoinRewards.waitBonusCap, constant(bonusTs, 'WAIT_BONUS_CAP'));
    });

    test('waiting can never out-earn winning', () {
      expect(CoinRewards.waitBonusCap, lessThan(CoinRewards.win));
    });
  });
}
