import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {onSchedule} from "firebase-functions/v2/scheduler";

import {
  cancelPendingGame,
  joinWindowExpired,
  TICKET_TTL_MS,
} from "./match_join";

// The Admin app is initialized once in index.ts.

/// A value with a `.toMillis()` accessor — i.e. a Firestore Timestamp, but
/// typed structurally so the pure helpers below can be unit-tested with plain
/// stubs and no Admin SDK.
type Stamp = {toMillis(): number};

/// How long a still-`active` game may go without a heartbeat from EITHER player
/// before it is considered abandoned. Far larger than the client's 30 s
/// disconnect-claim window, so a game with any present player is never swept.
const ABANDON_MS = 2 * 60 * 1000; // 2 minutes

/// The ms timestamp of the most recent sign of life in a game: the latest
/// heartbeat from either player, falling back to the creation time for a game
/// that never received a heartbeat. Null when neither is known.
export function lastActivityMs(
  lastSeen: Record<string, Stamp> | null | undefined,
  createdAt: Stamp | null | undefined,
): number | null {
  let latest: number | null = null;
  if (lastSeen) {
    for (const ts of Object.values(lastSeen)) {
      if (ts && typeof ts.toMillis === "function") {
        const ms = ts.toMillis();
        if (latest === null || ms > latest) latest = ms;
      }
    }
  }
  if (latest !== null) return latest;
  if (createdAt && typeof createdAt.toMillis === "function") {
    return createdAt.toMillis();
  }
  return null;
}

/// Whether an `active` game should be swept: both players have been absent for
/// at least [thresholdMs]. Games whose activity can't be determined are kept.
export function shouldSweep(
  lastSeen: Record<string, Stamp> | null | undefined,
  createdAt: Stamp | null | undefined,
  nowMs: number,
  thresholdMs: number,
): boolean {
  const last = lastActivityMs(lastSeen, createdAt);
  if (last === null) return false;
  return nowMs - last >= thresholdMs;
}

/// Periodically cancels online games stuck in `active` after BOTH players
/// disconnected (REV-48 edge case). A present player ends a game himself via
/// `claimDisconnectWin` within ~30 s, so this only catches matches where both
/// sides vanished and no fair winner exists — they are marked `cancelled`
/// (no rewards, no stat changes, like an un-started match), which also frees
/// both players' `findActiveGame` lookup to matchmake again.
export const sweepAbandonedGames = onSchedule("every 5 minutes", async () => {
  const db = getFirestore();
  const now = Date.now();

  const snap = await db
    .collection("games")
    .where("status", "==", "active")
    .get();

  let swept = 0;
  for (const doc of snap.docs) {
    const g = doc.data();
    if (!shouldSweep(g.lastSeen, g.createdAt, now, ABANDON_MS)) continue;
    await doc.ref.update({
      status: "cancelled",
      cancelledReason: "abandoned",
      cancelledAt: FieldValue.serverTimestamp(),
    });
    swept++;
  }

  if (swept > 0) {
    logger.info(`sweep: cancelled ${swept} abandoned game(s)`);
  }

  await sweepPendingGames(now);
  await sweepStaleTickets(now);
});

/// Cancels matches whose join window closed with nobody watching (REV-114).
///
/// The player left waiting normally cancels these themselves the moment the
/// countdown runs out — they are looking at the screen. This is for the case
/// where nobody is: both sides were notified, neither opened the app, and the
/// game would otherwise sit `pending` forever, blocking both players'
/// `findActiveGame` lookup and so barring them from ever matching again.
async function sweepPendingGames(now: number): Promise<void> {
  const db = getFirestore();
  const snap = await db
    .collection("games")
    .where("status", "==", "pending")
    .get();

  let cancelled = 0;
  for (const doc of snap.docs) {
    const g = doc.data();
    if (!joinWindowExpired(g.joinDeadline, now)) continue;
    await cancelPendingGame(doc.id, g);
    cancelled++;
  }
  if (cancelled > 0) {
    logger.info(`sweep: cancelled ${cancelled} un-joined match(es)`);
  }
}

/// Drops queue tickets nobody could be matched with inside [TICKET_TTL_MS]
/// (REV-114, 24 hours).
///
/// The ticket outliving the session is the whole point of notified
/// matchmaking — queue in the evening, get matched in the morning. But it has
/// to end somewhere: "an opponent is waiting" about a queue joined last week
/// is not a welcome surprise, it is a stranger's alarm clock.
async function sweepStaleTickets(now: number): Promise<void> {
  const db = getFirestore();
  const snap = await db
    .collection("matchmaking")
    .where("status", "==", "waiting")
    .get();

  let dropped = 0;
  for (const doc of snap.docs) {
    const createdAt = doc.data().createdAt;
    // A ticket whose server timestamp has not resolved yet is brand new, not
    // ancient: never sweep what cannot be dated.
    if (!createdAt || typeof createdAt.toMillis !== "function") continue;
    if (now - createdAt.toMillis() < TICKET_TTL_MS) continue;
    await doc.ref.delete();
    dropped++;
  }
  if (dropped > 0) {
    logger.info(`sweep: dropped ${dropped} stale queue ticket(s)`);
  }
}
