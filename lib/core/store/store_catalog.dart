import '../settings/app_settings.dart';

/// What a store item hands over when it is owned.
enum StoreItemKind {
  /// The board surface.
  board,

  /// One disc skin.
  disc,

  /// The app-wide look (menus, headers, page chrome).
  appTheme,
}

/// One thing the store sells, or gives away.
///
/// **Everything is sold on its own** — a board is not bundled with the discs
/// drawn to match it (Mustafa, 2026-08-23). Bundles would make each purchase a
/// long saving-up project; small separate items let a player spend the coins
/// they have now, which is the part that feels like a reward. The catalogue is
/// still deep enough that it cannot be cleared in a few days.
class StoreItem {
  const StoreItem({
    required this.id,
    required this.kind,
    this.coinPrice,
    this.free = false,
    this.boards = const [],
    this.discs = const [],
    this.theme,
  });

  /// Stable identifier, and the exact string stored in the player's server-side
  /// `ownedItems`. **Mirrors `CATALOG` in `functions/src/catalog.ts` — the same
  /// ids and the same prices must appear on both sides.** Renaming one takes
  /// the item away from everyone who owns it.
  final String id;

  final StoreItemKind kind;

  /// Price in coins, or null when coins cannot buy it.
  ///
  /// Real-money items deliberately have no coin price: anything reachable by
  /// playing is a reason not to subscribe, so the subscription and the Güzelsi
  /// theme stay outside the coin economy.
  final int? coinPrice;

  /// Everyone owns it, including guests and brand-new accounts.
  final bool free;

  final List<BoardTheme> boards;
  final List<CoinColor> discs;
  final AppThemeId? theme;

  bool get isFree => free;
  bool get buyableWithCoins => coinPrice != null;
}

/// Coin prices, in one place so the economy can be read at a glance.
///
/// Scale: a win pays 10 coins, doubled between 20:00–22:00. So a disc is about
/// ten wins — close enough that the first purchase arrives within days — and a
/// board about thirty. The whole shop is 1200 coins, roughly 120 wins, which
/// keeps something left to want without putting the first item out of reach.
class StorePrices {
  const StorePrices._();

  /// Every disc costs the same: the player picks the one they like, not the
  /// one that happens to be cheap.
  static const int disc = 100;

  static const int board = 300;
}

/// The free set — a complete-looking game for someone who never pays.
///
/// Three boards that do not look like each other (warm wood, turquoise, navy)
/// and the four drawn discs. A starter set that feels like a choice is worth
/// more than one that feels like a demo, and it is what makes the paid items
/// read as extras rather than as the missing half of the game.
const StoreItem _starterSet = StoreItem(
  id: 'starter',
  kind: StoreItemKind.board,
  free: true,
  boards: [BoardTheme.wood, BoardTheme.turkuaz, BoardTheme.gece],
  discs: [
    CoinColor.black,
    CoinColor.white,
    CoinColor.turquoise,
    CoinColor.orange,
  ],
  theme: AppThemeId.original,
);

const StoreItem _marbleBoard = StoreItem(
  id: 'board_marble',
  kind: StoreItemKind.board,
  coinPrice: StorePrices.board,
  boards: [BoardTheme.mermer],
);

const StoreItem _flowerBoard = StoreItem(
  id: 'board_flower',
  kind: StoreItemKind.board,
  coinPrice: StorePrices.board,
  boards: [BoardTheme.cicek],
);

const StoreItem _walnutDisc = StoreItem(
  id: 'disc_walnut',
  kind: StoreItemKind.disc,
  coinPrice: StorePrices.disc,
  discs: [CoinColor.walnut],
);

const StoreItem _mapleDisc = StoreItem(
  id: 'disc_maple',
  kind: StoreItemKind.disc,
  coinPrice: StorePrices.disc,
  discs: [CoinColor.maple],
);

const StoreItem _marbleBlackDisc = StoreItem(
  id: 'disc_marble_black',
  kind: StoreItemKind.disc,
  coinPrice: StorePrices.disc,
  discs: [CoinColor.marbleBlack],
);

const StoreItem _marbleWhiteDisc = StoreItem(
  id: 'disc_marble_white',
  kind: StoreItemKind.disc,
  coinPrice: StorePrices.disc,
  discs: [CoinColor.marbleWhite],
);

const StoreItem _flowerPurpleDisc = StoreItem(
  id: 'disc_flower_purple',
  kind: StoreItemKind.disc,
  coinPrice: StorePrices.disc,
  discs: [CoinColor.flowerPurple],
);

const StoreItem _flowerPinkDisc = StoreItem(
  id: 'disc_flower_pink',
  kind: StoreItemKind.disc,
  coinPrice: StorePrices.disc,
  discs: [CoinColor.flowerPink],
);

/// The Güzelsi look. Real money only — see [StoreItem.coinPrice].
const StoreItem _guzelsiTheme = StoreItem(
  id: 'theme_guzelsi',
  kind: StoreItemKind.appTheme,
  theme: AppThemeId.wood,
);

/// Everything the store knows about, in display order.
const List<StoreItem> kStoreItems = [
  _starterSet,
  _marbleBoard,
  _flowerBoard,
  _walnutDisc,
  _mapleDisc,
  _marbleBlackDisc,
  _marbleWhiteDisc,
  _flowerPurpleDisc,
  _flowerPinkDisc,
  _guzelsiTheme,
];

/// Items a player can buy with coins, in display order.
List<StoreItem> get coinItems =>
    kStoreItems.where((i) => i.buyableWithCoins).toList();

/// The item that grants [board], or null if no item does (which would be a bug
/// — every board must be reachable, free or paid).
StoreItem? itemForBoard(BoardTheme board) {
  for (final item in kStoreItems) {
    if (item.boards.contains(board)) return item;
  }
  return null;
}

/// The item that grants [disc].
StoreItem? itemForDisc(CoinColor disc) {
  for (final item in kStoreItems) {
    if (item.discs.contains(disc)) return item;
  }
  return null;
}

/// The item that grants [theme].
StoreItem? itemForTheme(AppThemeId theme) {
  for (final item in kStoreItems) {
    if (item.theme == theme) return item;
  }
  return null;
}

/// The item with [id], or null when the catalogue does not know it — an id
/// stored by an older or newer build, for instance.
StoreItem? itemById(String id) {
  for (final item in kStoreItems) {
    if (item.id == id) return item;
  }
  return null;
}
