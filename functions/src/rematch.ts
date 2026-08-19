import {
  getFirestore,
  FieldValue,
  Timestamp,
  DocumentData,
  Transaction,
  DocumentReference,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {initialBoard, TURN_SECONDS} from "./matchmaking";
import {
  actionForRequest,
  actionForResponse,
  RematchState,
} from "./rematch_state";

// The Admin app is initialized once in index.ts.

/// How long an unanswered rematch offer stands. Short on purpose: the offer is
/// made while both players are still looking at the result card, and an offer
/// that outlives that moment would drag someone back into a game they have
/// mentally left.
const OFFER_SECONDS = 60;

/**
 * Rematch (REV-98). Callables rather than client writes, for two reasons.
 *
 * The security rules only let a participant write a game while it is `active`;
 * a finished game is read-only to clients by design, so the offer could not be
 * a client write even if we wanted it to be. More importantly the new game has
 * to be created the way matchmaking creates one — a client that could open a
 * game directly could choose its own opponent and its own colour and farm
 * trophies and coins. So a rematch goes through the server, exactly like
 * `finish_game` does.
 *
 * The state lives on the finished game document under `rematch`, which both
 * clients are already listening to, so the offer, the answer and the handoff
 * to the new game all arrive over the existing stream with no new plumbing.
 *
 * The decision logic lives in `rematch_state.ts` and is unit tested there.
 */

/// Offers a rematch on a finished game — or accepts the opponent's standing
/// offer, when both players tap at the same moment.
export const requestRematch = onCall(async (request) => {
  const uid = requireUid(request.auth?.uid);
  const gameId = requireGameId(request.data?.gameId);

  const db = getFirestore();
  const gameRef = db.collection("games").doc(gameId);

  return await db.runTransaction(async (tx) => {
    const g = await readFinishedGame(tx, gameRef, uid);
    const action = actionForRequest(
      g.rematch as RematchState | undefined,
      uid,
      Date.now()
    );

    switch (action.kind) {
      case "already-accepted":
        return {status: "accepted", gameId: action.gameId};
      case "already-offered":
        return {status: "pending", gameId: null};
      case "accept": {
        const newGameId = await createRematchGame(tx, db, g, gameRef);
        return {status: "accepted", gameId: newGameId};
      }
      default: {
        const now = Date.now();
        tx.update(gameRef, {
          rematch: {
            by: uid,
            status: "pending",
            at: Timestamp.fromMillis(now),
            expiresAt: Timestamp.fromMillis(now + OFFER_SECONDS * 1000),
            gameId: null,
          },
        });
        logger.info(`Rematch offered on ${gameId} by ${uid}`);
        return {status: "pending", gameId: null};
      }
    }
  });
});

/// Answers a standing rematch offer.
///
/// `accept: false` serves both sides: the opponent refusing, and the offering
/// player withdrawing when they leave the result screen. Either way the offer
/// stops standing, which is the only thing that matters — so there is no
/// separate cancel path to keep in sync with this one.
export const respondRematch = onCall(async (request) => {
  const uid = requireUid(request.auth?.uid);
  const gameId = requireGameId(request.data?.gameId);
  const accept = request.data?.accept === true;

  const db = getFirestore();
  const gameRef = db.collection("games").doc(gameId);

  return await db.runTransaction(async (tx) => {
    const g = await readFinishedGame(tx, gameRef, uid);
    const action = actionForResponse(
      g.rematch as RematchState | undefined,
      uid,
      accept,
      Date.now()
    );

    switch (action.kind) {
      case "already-accepted":
        return {status: "accepted", gameId: action.gameId};
      case "accept": {
        const newGameId = await createRematchGame(tx, db, g, gameRef);
        return {status: "accepted", gameId: newGameId};
      }
      case "decline":
        tx.update(gameRef, {"rematch.status": "declined"});
        return {status: "declined", gameId: null};
      case "already-offered":
        // Accepting your own offer would start a game with one player in it.
        throw new HttpsError(
          "failed-precondition",
          "You cannot accept your own rematch offer."
        );
      case "nothing-to-answer":
        return {status: action.status, gameId: null};
      default:
        // actionForResponse never returns "offer"; keep the switch total so a
        // new action kind fails loudly instead of silently doing nothing.
        throw new HttpsError("internal", `Unexpected action: ${action.kind}`);
    }
  });
});

function requireUid(uid: string | undefined): string {
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  return uid;
}

function requireGameId(gameId: unknown): string {
  if (typeof gameId !== "string" || gameId.length === 0) {
    throw new HttpsError("invalid-argument", "gameId is required.");
  }
  return gameId;
}

/// Loads the game and checks the caller may act on it. A rematch is only
/// offered on a game that reached a result: a `cancelled` game never started,
/// and the right move there is to re-queue, not to replay nothing.
async function readFinishedGame(
  tx: Transaction,
  gameRef: DocumentReference,
  uid: string
): Promise<DocumentData> {
  const snap = await tx.get(gameRef);
  const g = snap.data();
  if (!g) throw new HttpsError("not-found", "Game not found.");

  const uids = (g.playerUids as string[] | undefined) ?? [];
  if (!uids.includes(uid)) {
    throw new HttpsError("permission-denied", "Not your game.");
  }
  if (g.status !== "finished") {
    throw new HttpsError("failed-precondition", "Game is not finished.");
  }
  return g;
}

/// Creates the rematch game and points the finished game at it.
///
/// Colours are swapped rather than re-randomised: black moves first and that is
/// a real advantage, so the player who had white gets it back. Over a pair of
/// games the advantage cancels out, which is the point of a rematch.
///
/// Both writes happen in the caller's transaction on the finished game
/// document, so two simultaneous acceptances cannot both create a game — the
/// loser retries, reads `accepted`, and returns the winner's game id.
async function createRematchGame(
  tx: Transaction,
  db: FirebaseFirestore.Firestore,
  g: DocumentData,
  gameRef: DocumentReference
): Promise<string> {
  const players = g.players as {black?: string; white?: string} | undefined;
  const oldBlack = players?.black;
  const oldWhite = players?.white;
  if (!oldBlack || !oldWhite) {
    throw new HttpsError("failed-precondition", "Game has no players.");
  }

  const newBlack = oldWhite;
  const newWhite = oldBlack;

  // Fresh stats for the opponent preview. A guest has no profile document, so
  // their snapshot carries over from the game just played.
  const oldInfo = (g.playerInfo as DocumentData | undefined) ?? {};
  const blackUser = await tx.get(db.collection("users").doc(newBlack));
  const whiteUser = await tx.get(db.collection("users").doc(newWhite));

  const newGameRef = db.collection("games").doc();
  tx.set(newGameRef, {
    playerUids: [newBlack, newWhite],
    players: {black: newBlack, white: newWhite},
    playerInfo: {
      [newBlack]: playerInfoFor(blackUser.data(), oldInfo[newBlack]),
      [newWhite]: playerInfoFor(whiteUser.data(), oldInfo[newWhite]),
    },
    board: initialBoard(),
    currentPlayer: "black",
    lastMove: null,
    moves: [],
    moveCount: 0,
    status: "active",
    winner: null,
    turnDeadline: Timestamp.fromMillis(Date.now() + TURN_SECONDS * 1000),
    createdAt: FieldValue.serverTimestamp(),
    // Where this game came from, so a rematch chain stays traceable.
    rematchOf: gameRef.id,
  });

  tx.update(gameRef, {
    "rematch.status": "accepted",
    "rematch.gameId": newGameRef.id,
  });

  logger.info(`Rematch ${gameRef.id} -> ${newGameRef.id}`);
  return newGameRef.id;
}

/// The preview snapshot stored on a game (REV-45), built from the live profile
/// when there is one and from the previous game's snapshot when there is not.
export function playerInfoFor(
  user: DocumentData | undefined,
  fallback: DocumentData | undefined
) {
  if (!user) return fallback ?? null;
  const online = (user.online as Record<string, number> | undefined) ?? {};
  return {
    name: user.displayName ?? fallback?.name ?? null,
    photo: user.photoUrl ?? fallback?.photo ?? null,
    trophies: online.trophies ?? 0,
    wins: online.wins ?? 0,
    losses: online.losses ?? 0,
    draws: online.draws ?? 0,
    bestStreak: online.bestStreak ?? 0,
  };
}
