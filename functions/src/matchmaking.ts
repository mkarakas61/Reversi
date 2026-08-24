import {
  getFirestore,
  FieldValue,
  Timestamp,
  DocumentData,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {JOIN_SECONDS} from "./match_join";
import {opponentFoundText, sendToUser} from "./push";

// The Admin app is initialized once in index.ts.

/// Initial per-move window. The full disconnect/forfeit handling is REV-48.
/// Shared with the rematch function (REV-98) so a rematch opens on the same
/// clock as a matched game.
export const TURN_SECONDS = 40;

/// A pairing the transaction actually made, carried out of it so the
/// notification can be sent after the commit.
interface Pairing {
  gameId: string;
  uids: string[];
}

/// Pairs waiting players into a game. Triggered on any write to a matchmaking
/// ticket (`matchmaking/{uid}`) — the initial create or a periodic client
/// "ping" — so a simultaneous join whose first trigger missed its partner
/// self-heals on the next ping. Runs a transaction: either ticket may initiate,
/// and because both attempts write the same two ticket docs, the loser retries,
/// sees a now-"matched" ticket and bails — exactly one game is created.
export const onMatchmakingTicketWritten = onDocumentWritten(
  "matchmaking/{uid}",
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return; // ticket deleted (e.g. cancelled)
    const myUid = event.params.uid;
    if (after.data()!.status !== "waiting") return;

    const db = getFirestore();
    const mm = db.collection("matchmaking");

    // Set by the transaction when it is the attempt that actually paired.
    let matched: Pairing | null = null;

    await db.runTransaction(async (tx) => {
      // --- reads (all reads must precede writes) ---
      const myRef = mm.doc(myUid);
      const mySnap = await tx.get(myRef);
      if (!mySnap.exists || mySnap.data()!.status !== "waiting") return;

      const waiting = await tx.get(mm.where("status", "==", "waiting").limit(10));
      let partnerId: string | null = null;
      for (const d of waiting.docs) {
        if (d.id !== myUid) {
          partnerId = d.id;
          break;
        }
      }
      if (partnerId == null) return; // nobody else waiting yet — stay queued

      // Both players' create-triggers race to pair. Rather than have one defer
      // to the other (which left both waiting when that trigger fired alone or
      // was delayed/dropped — REV-46), either trigger may initiate: both writes
      // touch the same two ticket docs, so concurrent attempts conflict and the
      // loser retries, re-reads a now-"matched" ticket, and bails. Exactly one
      // game is ever created.
      const partnerRef = mm.doc(partnerId);
      const partnerSnap = await tx.get(partnerRef);
      if (!partnerSnap.exists || partnerSnap.data()!.status !== "waiting") {
        return; // taken or cancelled in the meantime
      }

      // --- writes ---
      const gameRef = db.collection("games").doc();
      // How long each player waited in the queue (REV-110). Recorded here
      // because this is the only place both tickets are in hand; the payout
      // happens in finish_game.ts, and only if the game is actually played
      // out. Sourced from the ticket's server `createdAt`, never the client.
      const waitMs = {
        [myUid]: waitedMs(mySnap.data()!, Date.now()),
        [partnerId]: waitedMs(partnerSnap.data()!, Date.now()),
      };
      const blackIsMe = Math.random() < 0.5;
      const blackUid = blackIsMe ? myUid : partnerId;
      const whiteUid = blackIsMe ? partnerId : myUid;

      tx.set(gameRef, {
        playerUids: [myUid, partnerId],
        players: {black: blackUid, white: whiteUid},
        playerInfo: {
          [myUid]: playerInfo(mySnap.data()!),
          [partnerId]: playerInfo(partnerSnap.data()!),
        },
        board: initialBoard(),
        currentPlayer: "black",
        lastMove: null,
        moves: [],
        moveCount: 0,
        // `pending`, not `active` (REV-114). A match can now be made while one
        // side has the app shut, so the game cannot start the moment it is
        // created — the absent player would be losing a game they never saw.
        // It becomes `active` in `joinGame`, once both have said they are here.
        //
        // The distinction also keeps the disconnect logic honest: REV-108's
        // 30 s claim and the 2-minute sweep both mean "a live game has gone
        // quiet", and neither is true of a game that has not begun.
        status: "pending",
        joined: {},
        joinDeadline: Timestamp.fromMillis(Date.now() + JOIN_SECONDS * 1000),
        winner: null,
        // No turn clock yet: it starts when the game does, so whoever joins
        // second is not already seconds down.
        turnDeadline: null,
        createdAt: FieldValue.serverTimestamp(),
        waitMs,
      });
      tx.update(myRef, {status: "matched", gameId: gameRef.id});
      tx.update(partnerRef, {status: "matched", gameId: gameRef.id});
      logger.info(`Matched ${myUid} vs ${partnerId} -> game ${gameRef.id}`);
      matched = {gameId: gameRef.id, uids: [myUid, partnerId]};
    });

    // Outside the transaction, and deliberately after it commits: a push is a
    // side effect that cannot be rolled back, and a transaction may run more
    // than once. Notifying inside it would send "opponent found" for a pairing
    // that then lost the race and never existed.
    // Re-read through the declared type: TypeScript's flow analysis assumes a
    // callback may never run, so it narrows `matched` to `never` here.
    const pairing = matched as Pairing | null;
    if (pairing) {
      const text = opponentFoundText(JOIN_SECONDS);
      await Promise.all(
        pairing.uids.map((uid) =>
          sendToUser(uid, text, {type: "match_found", gameId: pairing.gameId}),
        ),
      );
    }
  },
);

/// The standard Reversi opening position as a 64-char row-major string
/// ("b"/"w"/"-"), matching the client's board codec.
export function initialBoard(): string {
  const cells = new Array<string>(64).fill("-");
  cells[3 * 8 + 3] = "w";
  cells[3 * 8 + 4] = "b";
  cells[4 * 8 + 3] = "b";
  cells[4 * 8 + 4] = "w";
  return cells.join("");
}

/// Milliseconds a ticket sat in the queue. Zero when the ticket carries no
/// usable `createdAt` — the server timestamp of a just-created ticket can still
/// be resolving when the trigger runs — and never negative, so a clock skew
/// cannot turn into a reward.
function waitedMs(ticket: DocumentData, now: number): number {
  // Time carried over from a match that fell through (REV-114): the player
  // waited it, and losing it because someone else failed to show up would
  // punish them for the other side's absence. The payout is capped either way.
  const carried =
    typeof ticket.carriedWaitMs === "number" && ticket.carriedWaitMs > 0
      ? ticket.carriedWaitMs
      : 0;
  const createdAt = ticket.createdAt;
  if (!(createdAt instanceof Timestamp)) return carried;
  return carried + Math.max(0, now - createdAt.toMillis());
}

/// The opponent-preview snapshot stored on the game so REV-45 can show basic
/// stats without extra reads. Sourced from the matchmaking ticket.
function playerInfo(ticket: DocumentData) {
  return {
    name: ticket.displayName ?? null,
    photo: ticket.photoUrl ?? null,
    trophies: ticket.trophies ?? 0,
    wins: ticket.wins ?? 0,
    losses: ticket.losses ?? 0,
    draws: ticket.draws ?? 0,
    bestStreak: ticket.bestStreak ?? 0,
  };
}
