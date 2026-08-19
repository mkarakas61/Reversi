import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';
import 'package:reversi/core/models/progress_history.dart';
import 'package:reversi/core/models/wallet.dart';
import 'package:reversi/core/profile/profile_scope.dart';
import 'package:reversi/features/menu/widgets/wallet_chip.dart';

// REV-102: the server has been paying coins since REV-66 with nothing in the
// app showing them. These tests pin the two rules that keep the display honest:
// every number shown comes from the server, and a balance is only shown to
// someone who can actually earn one.
void main() {
  group('balance is read, never computed', () {
    test('the profile carries the server balance, defaulting to 0', () {
      const fresh = Profile(uid: 'u1');
      expect(fresh.coins, 0);
      expect(const Profile(uid: 'u1', coins: 128).coins, 128);
    });

    test('a finished game carries its coin reward and the new balance', () {
      final entry = HistoryEntry.fromMap(const {
        'result': 'win',
        'trophyDelta': 4,
        'trophies': 120,
        'coinDelta': 10,
        'coins': 340,
      });
      expect(entry.coinDelta, 10);
      expect(entry.coins, 340);
    });

    test('a game played before the fields shipped reports no reward', () {
      // The result card keys its coin line off `coinDelta > 0`, so an old
      // history row must decode to 0 rather than invent a payout from the
      // outcome — the server never credited one.
      final old = HistoryEntry.fromMap(const {'result': 'win'});
      expect(old.coinDelta, 0);
      expect(old.coins, 0);
    });
  });

  group('who sees a balance', () {
    test('signed-in players do, including at zero', () {
      expect(showsWalletChip(const Profile(uid: 'u1')), true);
      expect(showsWalletChip(const Profile(uid: 'u1', coins: 40)), true);
    });

    test('signed-out and guests do not', () {
      expect(showsWalletChip(null), false);
      expect(showsWalletChip(const Profile(uid: 'g1', isGuest: true)), false);
    });
  });

  group('wording', () {
    final tr = AppStrings(const Locale('tr'));
    final en = AppStrings(const Locale('en'));

    test('the wallet is named in both languages', () {
      for (final s in [tr, en]) {
        expect(s.coins, isNotEmpty);
        expect(s.wallet, isNotEmpty);
        expect(s.walletSpendSoon, isNotEmpty);
      }
    });

    test('the earning rates spell out all three outcomes', () {
      for (final s in [tr, en]) {
        final line = s.walletRates(
          CoinRewards.win,
          CoinRewards.draw,
          CoinRewards.loss,
        );
        for (final amount in [CoinRewards.win, CoinRewards.draw, CoinRewards.loss]) {
          expect(line, contains('$amount'), reason: s.locale.languageCode);
        }
        // An unsubstituted placeholder is the failure this line invites.
        expect(line, isNot(contains('{')), reason: s.locale.languageCode);
      }
    });
  });
}
