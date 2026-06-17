import {
  getFirestore,
  FieldValue,
  Timestamp,
  DocumentData,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

// The Admin app is initialized once in index.ts.

/// Initial per-move window. The full disconnect/forfeit handling is REV-48.
const TURN_SECONDS = 40;

/// Pairs waiting players into a game. Triggered when a player writes their
/// matchmaking ticket (`matchmaking/{uid}` with status "waiting"). Runs a
/// transaction so two near-simultaneous tickets can never create two games:
/// only the newer ticket initiates, and both tickets are re-read inside the
/// transaction and must still be "waiting" to be paired.
export const onMatchmakingTicketCreated = onDocumentCreated(
  "matchmaking/{uid}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const myUid = event.params.uid;
    if (snap.data().status !== "waiting") return;

    const db = getFirestore();
    const mm = db.collection("matchmaking");

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
        status: "active",
        winner: null,
        turnDeadline: Timestamp.fromMillis(Date.now() + TURN_SECONDS * 1000),
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.update(myRef, {status: "matched", gameId: gameRef.id});
      tx.update(partnerRef, {status: "matched", gameId: gameRef.id});
      logger.info(`Matched ${myUid} vs ${partnerId} -> game ${gameRef.id}`);
    });
  },
);

/// The standard Reversi opening position as a 64-char row-major string
/// ("b"/"w"/"-"), matching the client's board codec.
function initialBoard(): string {
  const cells = new Array<string>(64).fill("-");
  cells[3 * 8 + 3] = "w";
  cells[3 * 8 + 4] = "b";
  cells[4 * 8 + 3] = "b";
  cells[4 * 8 + 4] = "w";
  return cells.join("");
}

/// The opponent-preview snapshot stored on the game so REV-45 can show basic
/// stats without extra reads. Sourced from the matchmaking ticket.
function playerInfo(ticket: DocumentData) {
  return {
    name: ticket.displayName ?? null,
    photo: ticket.photoUrl ?? null,
    level: ticket.level ?? 1,
    wins: ticket.wins ?? 0,
    losses: ticket.losses ?? 0,
    draws: ticket.draws ?? 0,
    bestStreak: ticket.bestStreak ?? 0,
  };
}
