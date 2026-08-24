import {
  getFirestore,
  FieldValue,
  Timestamp,
  DocumentData,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {TURN_SECONDS} from "./matchmaking";

// The join window (REV-114): the gap between "you have been matched" and "the
// game is on".
//
// It exists because matchmaking stopped requiring both players to be looking at
// the screen. Once a match can be made while one side has the app closed, the
// game cannot start the instant it is created — the absent player would be
// losing a game they never saw. So a matched game opens as `pending`, both
// sides are notified, and it becomes `active` only when both have said they are
// here.
//
// Everything that follows is about the two ways that can go wrong: the waiting
// player must not be punished for the absent one, and a pending game must not
// be mistaken for a live one by the disconnect logic (REV-108, 30 s) or the
// sweep (REV-48, 2 min) — both of which assume a game that has started.

/// How long a player has to join after being told a match is ready
/// (Mustafa, 2026-08-24). Long enough to see a notification and pick the phone
/// up; short enough that the other side is not left staring at a screen.
export const JOIN_SECONDS = 60;

/// How long a queue ticket survives with nobody to match against
/// (Mustafa, 2026-08-24). A day, so someone who queues in the evening can be
/// matched the next morning — which is the entire point while there are few
/// players. Past that, "an opponent is waiting" would arrive as a surprise
/// about a queue the player has long forgotten.
export const TICKET_TTL_MS = 24 * 60 * 60 * 1000;

/// Whether every player in [playerUids] has joined.
export function allJoined(
  joined: Record<string, unknown> | null | undefined,
  playerUids: string[],
): boolean {
  if (!joined) return false;
  return playerUids.every((uid) => joined[uid] === true);
}

/// Whether a pending game's join window has closed.
///
/// A game with no deadline is treated as expired rather than eternal: an
/// unstartable game that nobody can cancel would sit in `findActiveGame` and
/// block both players from ever matching again.
export function joinWindowExpired(
  joinDeadline: {toMillis(): number} | null | undefined,
  nowMs: number,
): boolean {
  if (!joinDeadline || typeof joinDeadline.toMillis !== "function") return true;
  return nowMs >= joinDeadline.toMillis();
}

/// The ticket a player is given back when their match fell through, rebuilt
/// from the `playerInfo` snapshot the game already carries.
///
/// Requeued rather than left to re-enter by hand, and with the original
/// `waitedMs` carried over, because none of this was their doing: they answered
/// in time and the other side did not.
export function requeueTicket(
  info: DocumentData | undefined,
  waitedMs: unknown,
): DocumentData {
  return {
    status: "waiting",
    displayName: info?.name ?? null,
    photoUrl: info?.photo ?? null,
    trophies: info?.trophies ?? 0,
    wins: info?.wins ?? 0,
    losses: info?.losses ?? 0,
    draws: info?.draws ?? 0,
    bestStreak: info?.bestStreak ?? 0,
    createdAt: FieldValue.serverTimestamp(),
    // Time already spent waiting is not forfeited by a failed match; the
    // bonus is capped anyway (REV-110), so this cannot be farmed.
    carriedWaitMs: typeof waitedMs === "number" ? waitedMs : 0,
  };
}

/// "I am here" — called when a player opens the opponent preview for a pending
/// game, whether they got there from the queue or from a notification.
///
/// The second caller starts the game. Doing that here rather than in a
/// Firestore trigger keeps it off the write path of every single move: a
/// trigger on `games/{gameId}` fires sixty times a match, this fires twice.
export const joinGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const gameId = request.data?.gameId;
  if (typeof gameId !== "string" || gameId.length === 0) {
    throw new HttpsError("invalid-argument", "gameId is required.");
  }

  const db = getFirestore();
  const ref = db.collection("games").doc(gameId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const game = snap.data();
    if (!game) throw new HttpsError("not-found", "No such game.");

    const playerUids = (game.playerUids as string[] | undefined) ?? [];
    if (!playerUids.includes(uid)) {
      throw new HttpsError("permission-denied", "Not your game.");
    }

    // Already running, or already over: joining is a no-op the client can act
    // on, not an error. A player who taps a notification twice, or opens one
    // for a game their opponent already started, should just see the board.
    if (game.status !== "pending") {
      return {ok: true, status: game.status as string};
    }

    if (joinWindowExpired(game.joinDeadline, Date.now())) {
      throw new HttpsError("deadline-exceeded", "The join window has closed.");
    }

    const joined = {...(game.joined as Record<string, unknown> ?? {}), [uid]: true};
    if (!allJoined(joined, playerUids)) {
      tx.update(ref, {[`joined.${uid}`]: true});
      return {ok: true, status: "pending"};
    }

    // Both here — the game starts now, and the turn clock starts with it. It
    // deliberately does not start when the game was created: the player who
    // joined last would already be seconds down.
    tx.update(ref, {
      [`joined.${uid}`]: true,
      status: "active",
      startedAt: FieldValue.serverTimestamp(),
      turnDeadline: Timestamp.fromMillis(Date.now() + TURN_SECONDS * 1000),
    });
    logger.info(`Game ${gameId} started: both players joined`);
    return {ok: true, status: "active"};
  });
});

/// Called by a player who is walking away from a match that has not started:
/// they looked at the opponent preview and chose not to play.
///
/// Declining is legitimate and always has been — seeing who you drew and
/// deciding against it is the reason the preview screen exists (Mustafa,
/// 2026-08-24). So there is no deadline guard here and no penalty. What does
/// change with the join window is the other side: whoever had already said
/// they were here goes back in the queue instead of being dropped, because the
/// match ending was not their doing.
export const leavePendingGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const gameId = request.data?.gameId;
  if (typeof gameId !== "string" || gameId.length === 0) {
    throw new HttpsError("invalid-argument", "gameId is required.");
  }

  const db = getFirestore();
  const ref = db.collection("games").doc(gameId);
  const snap = await ref.get();
  const game = snap.data();
  if (!game) throw new HttpsError("not-found", "No such game.");

  const playerUids = (game.playerUids as string[] | undefined) ?? [];
  if (!playerUids.includes(uid)) {
    throw new HttpsError("permission-denied", "Not your game.");
  }
  if (game.status !== "pending") {
    return {ok: true, status: game.status as string};
  }

  // The leaver is not requeued: they are leaving, not waiting.
  const requeued = await cancelPendingGame(gameId, game, uid);
  return {ok: true, status: "cancelled", requeued};
});

/// Called by a player whose opponent never turned up: cancels the match and
/// puts the players who *did* join back in the queue.
///
/// Nobody is penalised. A game that never became `active` has no result to
/// record — `finish_game` only ever reads finished games — so there is no loss
/// to award and no trophies to move. That is the rule that keeps notified
/// matchmaking from being a trap for the player who answered.
export const abandonPendingGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const gameId = request.data?.gameId;
  if (typeof gameId !== "string" || gameId.length === 0) {
    throw new HttpsError("invalid-argument", "gameId is required.");
  }

  const db = getFirestore();
  const ref = db.collection("games").doc(gameId);
  const snap = await ref.get();
  const game = snap.data();
  if (!game) throw new HttpsError("not-found", "No such game.");

  const playerUids = (game.playerUids as string[] | undefined) ?? [];
  if (!playerUids.includes(uid)) {
    throw new HttpsError("permission-denied", "Not your game.");
  }
  if (game.status !== "pending") {
    return {ok: true, status: game.status as string};
  }
  // Only once the window has actually closed. Before that, walking away is
  // `leavePendingGame` — the difference matters because this call requeues the
  // caller and that one does not.
  if (!joinWindowExpired(game.joinDeadline, Date.now())) {
    throw new HttpsError("failed-precondition", "The join window is still open.");
  }

  const requeued = await cancelPendingGame(gameId, game);
  return {ok: true, status: "cancelled", requeued};
});

/// Cancels one pending game and requeues whoever joined it. Shared by the
/// callable above and the scheduled sweep, which catches the case nobody is
/// left watching for — both players closed the app before the window ended.
/// [excludeUid], when given, is a player who is deliberately leaving and so is
/// not put back in the queue.
export async function cancelPendingGame(
  gameId: string,
  game: DocumentData,
  excludeUid?: string,
): Promise<string[]> {
  const db = getFirestore();
  const playerUids = (game.playerUids as string[] | undefined) ?? [];
  const joined = (game.joined as Record<string, unknown> | undefined) ?? {};
  const waitMs = (game.waitMs as Record<string, unknown> | undefined) ?? {};
  const playerInfo = (game.playerInfo as Record<string, DocumentData> | undefined) ?? {};

  const batch = db.batch();
  batch.update(db.collection("games").doc(gameId), {
    status: "cancelled",
    cancelledReason: excludeUid ? "declined" : "join window expired",
    cancelledAt: FieldValue.serverTimestamp(),
  });

  const requeued: string[] = [];
  for (const player of playerUids) {
    if (player === excludeUid) continue;
    if (joined[player] !== true) continue;
    batch.set(
      db.collection("matchmaking").doc(player),
      requeueTicket(playerInfo[player], waitMs[player]),
    );
    requeued.push(player);
  }

  await batch.commit();
  logger.info(
    `Game ${gameId} cancelled (join window); requeued ${requeued.length}`,
  );
  return requeued;
}
