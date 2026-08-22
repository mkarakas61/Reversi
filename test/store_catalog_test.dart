import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/settings/app_settings.dart';
import 'package:reversi/core/store/entitlements.dart';
import 'package:reversi/core/store/store_catalog.dart';

// The store's shop window, decided 2026-08-23: free = wood + turquoise +
// midnight and the four drawn discs; every other board and every other disc is
// sold **on its own** for coins (disc 100, board 300); the Güzelsi theme and
// the subscription are real money only.
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

    test('every disc costs the same and a board costs more', () {
      final discPrices = coinItems
          .where((i) => i.kind == StoreItemKind.disc)
          .map((i) => i.coinPrice)
          .toSet();
      final boardPrices = coinItems
          .where((i) => i.kind == StoreItemKind.board)
          .map((i) => i.coinPrice!)
          .toSet();

      expect(discPrices, hasLength(1),
          reason: 'a cheap disc would be picked for its price, not its look');
      expect(boardPrices.reduce((a, b) => a < b ? a : b),
          greaterThan(discPrices.single!));
    });

    test('nothing is sold in bundles — one board or one disc per item', () {
      for (final item in coinItems) {
        expect(item.boards.length + item.discs.length, 1,
            reason: '${item.id} hands over more than one thing');
      }
    });

    test('ids match the ones the server charges for', () {
      // Mirrors CATALOG in functions/src/catalog.ts. An id that drifts apart
      // there either cannot be bought or unlocks nothing once bought.
      expect(coinItems.map((i) => i.id).toSet(), {
        'board_marble',
        'board_flower',
        'disc_walnut',
        'disc_maple',
        'disc_marble_black',
        'disc_marble_white',
        'disc_flower_purple',
        'disc_flower_pink',
      });
    });

    test('itemById finds a stored id and shrugs at an unknown one', () {
      expect(itemById('board_marble')?.boards, [BoardTheme.mermer]);
      expect(itemById('pack_marble'), isNull,
          reason: 'an id from an older build must not silently match');
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

    test('an item unlocks only itself — boards and discs are sold apart', () {
      const e = Entitlements(ownedItemIds: {'board_marble'});
      expect(e.ownsBoard(BoardTheme.mermer), isTrue);
      expect(e.ownsDisc(CoinColor.marbleBlack), isFalse,
          reason: 'the marble discs are their own purchase');
      expect(e.ownsBoard(BoardTheme.cicek), isFalse);
    });

    test('discs are owned one at a time', () {
      const e = Entitlements(ownedItemIds: {'disc_walnut'});
      expect(e.ownsDisc(CoinColor.walnut), isTrue);
      expect(e.ownsDisc(CoinColor.maple), isFalse);
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
      const lapsed = Entitlements(ownedItemIds: {'board_marble'});
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
