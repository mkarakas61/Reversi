// Coin bonuses layered on top of the flat per-result reward in `xp_level.ts`.
//
// Both exist for the same reason: at launch there are too few players online
// for two of them to be searching at the same moment. The happy hour pulls
// scattered players into one window; the wait bonus pays back the player whose
// wait produced a real game. Neither one touches trophies — the ladder is
// self-balancing and must stay that way.

/** Buluşma saati (REV-109): coins earned in this window are multiplied. */
export const HAPPY_HOUR_START_HOUR = 20;
export const HAPPY_HOUR_END_HOUR = 22;
export const HAPPY_HOUR_MULTIPLIER = 2;

/// Turkey has been on a fixed UTC+3 since 2016 — no daylight saving switch —
/// so the window can be a plain offset instead of a timezone database lookup.
/// If that ever changes this is the one line to fix.
const ISTANBUL_OFFSET_MS = 3 * 60 * 60 * 1000;

/** The hour of day in Istanbul (0-23) for an instant. */
export function istanbulHour(now: Date): number {
  return new Date(now.getTime() + ISTANBUL_OFFSET_MS).getUTCHours();
}

/**
 * Whether `now` falls inside the happy hour. Evaluated when the game
 * *finishes*, not when it starts: the player sees the multiplier on the result
 * screen, and a game that ends inside the window was played inside it.
 */
export function isHappyHour(now: Date): boolean {
  const hour = istanbulHour(now);
  if (HAPPY_HOUR_START_HOUR <= HAPPY_HOUR_END_HOUR) {
    return hour >= HAPPY_HOUR_START_HOUR && hour < HAPPY_HOUR_END_HOUR;
  }
  // A window that crosses midnight (e.g. 22:00-01:00) — supported so the hours
  // can be retuned from here without touching the logic.
  return hour >= HAPPY_HOUR_START_HOUR || hour < HAPPY_HOUR_END_HOUR;
}

/** Coin multiplier in effect at `now`: 2 during the happy hour, else 1. */
export function coinMultiplier(now: Date): number {
  return isHappyHour(now) ? HAPPY_HOUR_MULTIPLIER : 1;
}

/** Bekleme ikramiyesi (REV-110). */
export const WAIT_BONUS_PER_MINUTE = 1;
export const WAIT_BONUS_CAP = 5;

/**
 * Coins for time spent in the matchmaking queue before this game was made.
 *
 * Paid only when the game is *finished*, which is the whole design: a player
 * parked in the queue with no intention of playing never reaches a payout, so
 * idling can never out-earn playing. The cap keeps it under a win (10) for the
 * same reason.
 *
 * Anything that isn't a positive number — a rematch (no queue), a game created
 * before the field existed, a malformed value — is worth 0.
 */
export function waitBonusCoins(waitMs: unknown): number {
  if (typeof waitMs !== "number" || !Number.isFinite(waitMs) || waitMs <= 0) {
    return 0;
  }
  const minutes = Math.floor(waitMs / 60000);
  return Math.min(WAIT_BONUS_CAP, minutes * WAIT_BONUS_PER_MINUTE);
}
