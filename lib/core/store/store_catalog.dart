import '../settings/app_settings.dart';

/// What a store item hands over when it is owned.
enum StoreItemKind {
  /// A board plus the discs drawn to match it.
  boardPack,

  /// Discs only.
  discPair,

  /// The app-wide look (menus, headers, page chrome).
  appTheme,
}

/// One thing the store sells, or gives away.
///
/// An item is the unit of ownership, not a single board or disc: the marble
/// board without its marble discs is a half-bought thing, and a player who
/// paid for it would rightly ask where the rest is.
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

  /// Stable identifier. Written to the player's inventory on the server, so it
  /// must never change once shipped — renaming one takes items away from
  /// everyone who owns it.
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

/// The free set — a complete-looking game for someone who never pays.
///
/// Three boards that do not look like each other (warm wood, turquoise, navy)
/// and the four drawn discs. A starter set that feels like a choice is worth
/// more than one that feels like a demo, and it is what makes the paid packs
/// read as extras rather than as the missing half of the game.
const StoreItem _starterSet = StoreItem(
  id: 'starter',
  kind: StoreItemKind.boardPack,
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

/// Coin prices, in one place so the economy can be read at a glance.
///
/// Scale: a win pays 10 coins, doubled between 20:00–22:00, so the wooden
/// discs are roughly fifteen wins (a first goal worth chasing) and a full pack
/// is around forty (a few days of playing). Prices below that make coins
/// meaningless; far above it makes them decoration.
class StorePrices {
  const StorePrices._();

  static const int woodDiscs = 150;
  static const int marblePack = 400;
  static const int flowerPack = 400;
}

const StoreItem _woodDiscs = StoreItem(
  id: 'discs_wood',
  kind: StoreItemKind.discPair,
  coinPrice: StorePrices.woodDiscs,
  discs: [CoinColor.walnut, CoinColor.maple],
);

const StoreItem _marblePack = StoreItem(
  id: 'pack_marble',
  kind: StoreItemKind.boardPack,
  coinPrice: StorePrices.marblePack,
  boards: [BoardTheme.mermer],
  discs: [CoinColor.marbleBlack, CoinColor.marbleWhite],
);

const StoreItem _flowerPack = StoreItem(
  id: 'pack_flower',
  kind: StoreItemKind.boardPack,
  coinPrice: StorePrices.flowerPack,
  boards: [BoardTheme.cicek],
  discs: [CoinColor.flowerPurple, CoinColor.flowerPink],
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
  _woodDiscs,
  _marblePack,
  _flowerPack,
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
