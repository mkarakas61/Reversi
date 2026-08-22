import '../settings/app_settings.dart';
import 'store_catalog.dart';

/// What a player is allowed to use right now.
///
/// Built from two server-owned facts — the item ids in their inventory and
/// whether their subscription is active — plus the free set, which needs no
/// server at all. Guests therefore get a working game offline: they own the
/// starter set like everyone else, and simply cannot buy more (nothing to
/// spend, nowhere to record it).
///
/// Purchases are never decided here. The client only *renders* ownership; the
/// coin balance and the inventory are written by the server, the same rule that
/// keeps scores and trophies honest.
class Entitlements {
  const Entitlements({
    this.ownedItemIds = const {},
    this.premium = false,
  });

  /// Ids of items bought and recorded on the server.
  final Set<String> ownedItemIds;

  /// Active subscription: unlocks everything without owning it item by item.
  /// A lapsed subscription therefore takes the extras back but leaves anything
  /// bought with coins alone — those stay in [ownedItemIds].
  final bool premium;

  /// The free set only — what a guest, or an offline app, can show.
  static const Entitlements freeOnly = Entitlements();

  bool ownsItem(StoreItem item) =>
      item.isFree || premium || ownedItemIds.contains(item.id);

  bool ownsBoard(BoardTheme board) {
    final item = itemForBoard(board);
    return item != null && ownsItem(item);
  }

  bool ownsDisc(CoinColor disc) {
    final item = itemForDisc(disc);
    return item != null && ownsItem(item);
  }

  bool ownsTheme(AppThemeId theme) {
    final item = itemForTheme(theme);
    return item != null && ownsItem(item);
  }

  /// [board] if it is owned, otherwise the default free board.
  ///
  /// Used when settings name something the player may no longer use — a
  /// subscription that lapsed, or a board removed from the game. Showing a
  /// locked board would be worse than moving them: the game must always have a
  /// board to draw.
  BoardTheme boardOrFallback(BoardTheme board) =>
      ownsBoard(board) ? board : BoardTheme.wood;

  CoinColor discOrFallback(CoinColor disc, {required bool isOpponent}) =>
      ownsDisc(disc)
          ? disc
          : (isOpponent ? CoinColor.white : CoinColor.black);

  AppThemeId themeOrFallback(AppThemeId theme) =>
      ownsTheme(theme) ? theme : AppThemeId.original;

  Entitlements copyWith({Set<String>? ownedItemIds, bool? premium}) =>
      Entitlements(
        ownedItemIds: ownedItemIds ?? this.ownedItemIds,
        premium: premium ?? this.premium,
      );
}
