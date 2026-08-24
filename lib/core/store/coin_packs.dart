/// Coins bought with real money instead of earned by playing (Mustafa,
/// 2026-08-24). Three sizes: 500, 1000, 5000.
///
/// **None of them can be bought yet**, and the store says so. Play Billing
/// needs the app uploaded to Play Console, which waits on the publisher
/// decision (PROGRESS.md, 2026-08-23). What exists now is everything that can
/// be built and tested without Play: the packs themselves, the shop-window row
/// for each, and the server function that credits one. The purchase itself goes
/// through [BillingService], which today reports that billing is unavailable
/// and starts nothing.
///
/// **Mirrors `COIN_PACKS` in `functions/src/coin_packs.ts`: same ids, same coin
/// amounts.** The ids are Play Console product ids — once a product exists
/// under an id, that id is permanent.
///
/// **No prices here, on purpose.** What a pack costs is whatever Play charges
/// in the player's own country and currency, and Play is what quotes it
/// (`ProductDetails.price`). A price written into the app would be a second
/// price list, wrong the day a currency moves or a country is added.
library;

class CoinPack {
  const CoinPack({required this.id, required this.coins});

  /// Play Console product id, and the id sent to `redeemCoinPack`.
  final String id;

  /// Coins credited once the purchase is verified. Shown to the player as the
  /// name of the pack — the amount *is* the product.
  final int coins;
}

/// The packs, smallest first.
///
/// Three sizes and no more: enough that a player who wants "a board now" and a
/// player who wants "everything" both have an obvious choice, few enough that
/// picking one is not a decision to postpone.
const List<CoinPack> kCoinPacks = [
  CoinPack(id: 'coins_500', coins: 500),
  CoinPack(id: 'coins_1000', coins: 1000),
  CoinPack(id: 'coins_5000', coins: 5000),
];

/// The pack with [id], or null when this build does not know it.
CoinPack? coinPackById(String id) {
  for (final pack in kCoinPacks) {
    if (pack.id == id) return pack;
  }
  return null;
}
