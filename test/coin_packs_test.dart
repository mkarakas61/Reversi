import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/store/coin_packs.dart';
import 'package:reversi/core/store/store_catalog.dart';

// Coin packs are the one thing in the app bought with real money, so the tests
// that matter are about the two sides agreeing. The Dart list decides what the
// player is shown; `functions/src/coin_packs.ts` decides what they are actually
// credited. If those drift, someone pays for 5000 coins and receives 1000 — and
// nothing in the app would notice.
void main() {
  group('the packs themselves', () {
    test('three sizes: 500, 1000, 5000', () {
      expect(kCoinPacks.map((p) => p.coins), [500, 1000, 5000]);
    });

    test('ids are the Play product ids, and unique', () {
      expect(kCoinPacks.map((p) => p.id), [
        'coins_500',
        'coins_1000',
        'coins_5000',
      ]);
      expect(kCoinPacks.map((p) => p.id).toSet(), hasLength(kCoinPacks.length));
    });

    test('lookup by id, null for anything else', () {
      expect(coinPackById('coins_1000')?.coins, 1000);
      expect(coinPackById('coins_999'), isNull);
      expect(coinPackById(''), isNull);
    });

    test('a pack id is never also a store item id', () {
      // Both are sent to the server as ids; a collision would let a coin pack
      // be bought through the coin-spending path, or the reverse.
      final itemIds = kStoreItems.map((i) => i.id).toSet();
      for (final pack in kCoinPacks) {
        expect(itemIds.contains(pack.id), isFalse, reason: pack.id);
      }
    });

    test('bigger packs cost more coins, in order', () {
      for (var i = 1; i < kCoinPacks.length; i++) {
        expect(kCoinPacks[i].coins, greaterThan(kCoinPacks[i - 1].coins));
      }
    });
  });

  test('the server catalogue lists exactly the same packs', () {
    // Reads the TypeScript source rather than trusting a comment: this pair of
    // files is the whole contract between what the player is shown and what
    // the server credits.
    final source = File('functions/src/coin_packs.ts').readAsStringSync();
    for (final pack in kCoinPacks) {
      expect(
        source.contains('${pack.id}: {id: "${pack.id}", coins: ${pack.coins}}'),
        isTrue,
        reason: '${pack.id} (${pack.coins}) is missing from coin_packs.ts',
      );
    }
    // And nothing extra on the server side that the app never shows.
    final serverIds = RegExp(r'coins_\d+: \{id: "(coins_\d+)"')
        .allMatches(source)
        .map((m) => m.group(1))
        .toSet();
    expect(serverIds, kCoinPacks.map((p) => p.id).toSet());
  });
}
