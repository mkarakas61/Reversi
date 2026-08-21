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

  /// Coins per whole minute spent in the matchmaking queue, and the most one
  /// match can pay out (REV-110). Mirrors `WAIT_BONUS_*` in
  /// `functions/src/coin_bonus.ts`. The cap stays under [win] on purpose:
  /// waiting must never out-earn playing.
  static const int waitBonusPerMinute = 1;
  static const int waitBonusCap = 5;
}

/// The daily window where online coins are doubled (REV-109). Mirrors
/// `HAPPY_HOUR_*` in `functions/src/coin_bonus.ts`.
///
/// The server decides the actual reward; everything here is **label only** —
/// what the player is told, and whether the line reads "starts at 20:00" or
/// "is on now". A device with a wrong clock therefore shows the wrong label
/// for a moment and still gets paid correctly.
class HappyHour {
  const HappyHour._();

  static const int startHour = 20;
  static const int endHour = 22;
  static const int multiplier = 2;

  static String get startLabel => '${startHour.toString().padLeft(2, '0')}:00';
  static String get endLabel => '${endHour.toString().padLeft(2, '0')}:00';

  /// Whether the window is open. Turkey is a fixed UTC+3 (no daylight saving
  /// since 2016), so the local hour is UTC + 3 wherever the player is — the
  /// window is the same wall clock for everyone, which is the point of it.
  static bool isActive(DateTime now) {
    final hour = now.toUtc().add(const Duration(hours: 3)).hour;
    if (startHour <= endHour) return hour >= startHour && hour < endHour;
    return hour >= startHour || hour < endHour;
  }
}
