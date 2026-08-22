import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/settings/app_settings.dart';
import 'package:reversi/core/store/entitlements.dart';
import 'package:reversi/core/store/store_catalog.dart';

// The store's shop window, decided 2026-08-23: free = wood + turquoise +
// midnight and the four drawn discs; coins buy the wooden discs and the marble
// and floral packs; the Güzelsi theme and the subscription are real money only.
//
// These tests are about the catalogue staying honest — every board reachable,
// no board both free and for sale, ids stable — because a mistake here either
// gives away something we sell or locks a player out of a board the game can
// still pick.
void main() {
  group('catalogue covers the game', () {
    test('every board belongs to exactly one item', () {
      for (final board in BoardTheme.values) {
        final owners = kStoreItems.where((i) => i.boards.contains(board));
        expect(owners.length, 1, reason: '$board is sold by ${owners.length} items');
      }
    });

    test('every disc belongs to exactly one item', () {
      for (final disc in CoinColor.values) {
        final owners = kStoreItems.where((i) => i.discs.contains(disc));
        expect(owners.length, 1, reason: '$disc is sold by ${owners.length} items');
      }
    });

    test('every app theme belongs to exactly one item', () {
      for (final theme in AppThemeId.values) {
        final owners = kStoreItems.where((i) => i.theme == theme);
        expect(owners.length, 1, reason: '$theme is sold by ${owners.length} items');
      }
    });

    test('item ids are unique — they are the ownership record', () {
      final ids = kStoreItems.map((i) => i.id).toSet();
      expect(ids, hasLength(kStoreItems.length));
    });

    test('nothing is both free and for sale', () {
      for (final item in kStoreItems) {
        expect(item.isFree && item.buyableWithCoins, isFalse,
            reason: '${item.id} is free but also priced');
      }
    });

    test('the Güzelsi theme and anything premium stay outside the coin economy',
        () {
      final guzelsi = itemForTheme(AppThemeId.wood);
      expect(guzelsi, isNotNull);
      expect(guzelsi!.buyableWithCoins, isFalse,
          reason: 'a coin price here would compete with the subscription');
      expect(guzelsi.isFree, isFalse);
    });

    test('the free set is the starter boards and drawn discs', () {
      final free = kStoreItems.where((i) => i.isFree);
      expect(free, hasLength(1));
      expect(free.single.boards,
          [BoardTheme.wood, BoardTheme.turkuaz, BoardTheme.gece]);
      expect(free.single.theme, AppThemeId.original);
    });

    test('coin prices stay in the range a player can actually reach', () {
      for (final item in coinItems) {
        // A win pays 10 coins. Under ~5 wins the price is decoration; over
        // ~60 it is out of reach for someone who plays a few games a day.
        expect(item.coinPrice, inInclusiveRange(50, 600),
            reason: '${item.id} price');
      }
    });
  });

  group('Entitlements', () {
    test('the free set needs no server', () {
      const e = Entitlements.freeOnly;
      expect(e.ownsBoard(BoardTheme.wood), isTrue);
      expect(e.ownsBoard(BoardTheme.turkuaz), isTrue);
      expect(e.ownsDisc(CoinColor.black), isTrue);
      expect(e.ownsTheme(AppThemeId.original), isTrue);
      expect(e.ownsBoard(BoardTheme.mermer), isFalse);
      expect(e.ownsTheme(AppThemeId.wood), isFalse);
    });

    test('a bought pack unlocks its board and its discs together', () {
      const e = Entitlements(ownedItemIds: {'pack_marble'});
      expect(e.ownsBoard(BoardTheme.mermer), isTrue);
      expect(e.ownsDisc(CoinColor.marbleBlack), isTrue);
      expect(e.ownsDisc(CoinColor.marbleWhite), isTrue);
      expect(e.ownsBoard(BoardTheme.cicek), isFalse);
    });

    test('a subscription unlocks everything without owning it', () {
      const e = Entitlements(premium: true);
      for (final board in BoardTheme.values) {
        expect(e.ownsBoard(board), isTrue, reason: '$board under premium');
      }
      expect(e.ownsTheme(AppThemeId.wood), isTrue);
      expect(e.ownedItemIds, isEmpty,
          reason: 'premium grants use, it does not hand over the items');
    });

    test('coin purchases survive a lapsed subscription', () {
      const lapsed = Entitlements(ownedItemIds: {'pack_marble'});
      expect(lapsed.ownsBoard(BoardTheme.mermer), isTrue);
      expect(lapsed.ownsTheme(AppThemeId.wood), isFalse);
    });

    test('a locked selection falls back instead of drawing nothing', () {
      const e = Entitlements.freeOnly;
      expect(e.boardOrFallback(BoardTheme.mermer), BoardTheme.wood);
      expect(e.boardOrFallback(BoardTheme.gece), BoardTheme.gece);
      expect(e.discOrFallback(CoinColor.marbleBlack, isOpponent: false),
          CoinColor.black);
      expect(e.discOrFallback(CoinColor.marbleWhite, isOpponent: true),
          CoinColor.white);
      expect(e.themeOrFallback(AppThemeId.wood), AppThemeId.original);
    });
  });
}
