import {
  getFirestore,
  FieldValue,
  Transaction,
  DocumentReference,
  DocumentData,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";

import {replay, ReplayMove, Disc} from "./reversi";
import {earnedXp, earnedCoins, level, GameOutcome} from "./xp_level";

// The Admin app is initialized once in index.ts.

/// Awards XP, level, ranked stats and coins when an online game ends (REV-50).
/// Fires on the active -> finished transition, re-derives the result by
/// replaying the move log server-side (REV-49 engine) so a client can never
/// claim a win it didn't earn, and writes both players' profiles in one
/// transaction. Idempotent via the game's `rewarded` flag.
export const onGameFinished = onDocumentUpdated(
  "games/{gameId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    // Only the moment a game becomes finished.
    if (before.status === "finished" || after.status !== "finished") return;

    const gameId = event.params.gameId;
    const db = getFirestore();
    const gameRef = db.collection("games").doc(gameId);

    await db.runTransaction(async (tx) => {
      // --- reads (all reads must precede writes) ---
      const gameSnap = await tx.get(gameRef);
      const g = gameSnap.data();
      if (!g || g.rewarded === true) return; // already processed

      const players = g.players as {black?: string; white?: string} | undefined;
      const blackUid = players?.black;
      const whiteUid = players?.white;
      if (!blackUid || !whiteUid) {
        tx.update(gameRef, {rewarded: true, rewardError: "missing players"});
        return;
      }

      // Map the move log to colours and replay it to validate legality.
      const rawMoves =
        (g.moves as Array<{row: number; col: number; by: string}>) ?? [];
      const colorOf: Record<string, Disc> = {[blackUid]: "b", [whiteUid]: "w"};
      const moves: ReplayMove[] = [];
      let mappable = true;
      for (const m of rawMoves) {
        const by = colorOf[m.by];
        if (
          by === undefined ||
          typeof m.row !== "number" ||
          typeof m.col !== "number"
        ) {
          mappable = false;
          break;
        }
        moves.push({row: m.row, col: m.col, by});
      }

      const rep = mappable ? replay(moves) : null;
      if (!rep || !rep.valid) {
        // Tampered or unmappable move log — do not reward.
        tx.update(gameRef, {rewarded: true, rewardError: "invalid move log"});
        logger.warn(`game ${gameId}: invalid move log, no reward`);
        return;
      }

      // Authoritative outcome:
      //  - Natural finish: trust the replayed winner (fully validated).
      //  - Resign / forfeit (log valid but board not played out): trust the
      //    recorded winner. Replay-based forfeit checks land with REV-48/51.
      let winnerColor: Disc | null;
      let validated: boolean;
      if (rep.naturallyOver) {
        winnerColor = rep.winner;
        validated = true;
      } else {
        const claimed = g.winner as string | null;
        if (claimed == null) {
          tx.update(gameRef, {rewarded: true, rewardError: "no winner"});
          return;
        }
        winnerColor = claimed === "black" ? "b" : claimed === "white" ? "w" : null;
        validated = false;
      }

      const scoreDiff = Math.abs(rep.black - rep.white);
      const blackRef = db.collection("users").doc(blackUid);
      const whiteRef = db.collection("users").doc(whiteUid);
      const [blackSnap, whiteSnap] = await Promise.all([
        tx.get(blackRef),
        tx.get(whiteRef),
      ]);

      // --- writes ---
      applyReward(
        tx, blackRef, blackSnap.data(), "b",
        winnerColor, scoreDiff, rep.flippedBy.b, whiteSnap.data()
      );
      applyReward(
        tx, whiteRef, whiteSnap.data(), "w",
        winnerColor, scoreDiff, rep.flippedBy.w, blackSnap.data()
      );

      tx.update(gameRef, {
        rewarded: true,
        validated,
        finalBlack: rep.black,
        finalWhite: rep.white,
        rewardedAt: FieldValue.serverTimestamp(),
      });
      logger.info(
        `Rewarded game ${gameId} (validated=${validated}, ` +
          `winner=${winnerColor ?? "draw"})`
      );
    });
  }
);

/// Credits one player's profile with the XP, level, ranked stats and coins
/// earned for a finished game. Reads carry the pre-game values; the `online`
/// map is rewritten from them so nothing is lost.
function applyReward(
  tx: Transaction,
  ref: DocumentReference,
  data: DocumentData | undefined,
  myColor: Disc,
  winnerColor: Disc | null,
  scoreDiff: number,
  myFlips: number,
  oppData: DocumentData | undefined
): void {
  const xp = (data?.xp as number) ?? 0;
  const coins = (data?.coins as number) ?? 0;
  const online = (data?.online as Record<string, number>) ?? {};
  const wins = online.wins ?? 0;
  const losses = online.losses ?? 0;
  const draws = online.draws ?? 0;
  const currentStreak = online.currentStreak ?? 0;
  const bestStreak = online.bestStreak ?? 0;
  const totalFlipped = online.totalFlipped ?? 0;
  const bestScoreDiff = online.bestScoreDiff ?? 0;

  const outcome: GameOutcome =
    winnerColor === null ? "draw" : winnerColor === myColor ? "win" : "loss";

  const gainedXp = earnedXp({
    outcome,
    scoreDiff,
    flippedPieces: myFlips,
    myLevel: level(xp),
    oppLevel: level((oppData?.xp as number) ?? 0),
    streak: currentStreak,
  });
  const newXp = xp + gainedXp;
  const newStreak = outcome === "win" ? currentStreak + 1 : 0;

  tx.set(
    ref,
    {
      xp: newXp,
      level: level(newXp),
      coins: coins + earnedCoins(outcome),
      online: {
        wins: wins + (outcome === "win" ? 1 : 0),
        losses: losses + (outcome === "loss" ? 1 : 0),
        draws: draws + (outcome === "draw" ? 1 : 0),
        currentStreak: newStreak,
        bestStreak: Math.max(bestStreak, newStreak),
        totalFlipped: totalFlipped + myFlips,
        bestScoreDiff:
          outcome === "win" ? Math.max(bestScoreDiff, scoreDiff) : bestScoreDiff,
      },
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true}
  );
}
