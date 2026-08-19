/// The coin currency earned by playing online.
///
/// Naming: "coin" almost everywhere else in this codebase means the disc on the
/// board (`CoinView`, `CoinColor`, `coin_palette.dart`). The currency lives
/// under "wallet" so the two never get confused in code; only the user-facing
/// text calls it a coin.
///
/// The balance itself is **server-authoritative** — it is written by
/// `finish_game.ts` and read from Firestore, never computed on the client
/// (REV-102). The rates below mirror `COIN_WIN/DRAW/LOSS` in
/// `functions/src/xp_level.ts` and exist for one purpose: telling the player
/// where coins come from. Nothing in the app adds them up.
class CoinRewards {
  const CoinRewards._();

  static const int win = 10;
  static const int draw = 5;
  static const int loss = 2;
}
