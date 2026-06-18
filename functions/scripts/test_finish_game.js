// End-to-end emulator test for the onGameFinished function (REV-51/REV-50).
// Run via:
//   firebase emulators:exec --only firestore,functions \
//     'node functions/scripts/test_finish_game.js'
//
// Creates two user profiles and an active game with a legal move log, then
// marks the game finished. The onGameFinished trigger should replay the moves,
// derive the winner, and credit both players' XP, level, and online stats.

"use strict";

process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
admin.initializeApp({projectId: "reversi-3a506"});
const db = admin.firestore();

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function clear(col) {
  const s = await db.collection(col).get();
  await Promise.all(s.docs.map((d) => d.ref.delete()));
}

async function main() {
  await clear("users");
  await clear("games");

  // ---- Player profiles -------------------------------------------------------
  await db.collection("users").doc("p1").set({
    displayName: "Player1",
    photoUrl: null,
    xp: 0,
    level: 1,
    online: {
      wins: 0,
      losses: 0,
      draws: 0,
      currentStreak: 0,
      bestStreak: 0,
      totalFlipped: 0,
      bestScoreDiff: 0,
    },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection("users").doc("p2").set({
    displayName: "Player2",
    photoUrl: null,
    xp: 0,
    level: 1,
    online: {
      wins: 0,
      losses: 0,
      draws: 0,
      currentStreak: 0,
      bestStreak: 0,
      totalFlipped: 0,
      bestScoreDiff: 0,
    },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // ---- Active game with a valid (replayed) two-move log ----------------------
  // Opening position, black plays d3 (row=2,col=3), then white plays c3
  // (row=2,col=2). Both moves are legal.
  const gameRef = db.collection("games").doc("eg1");
  await gameRef.set({
    playerUids: ["p1", "p2"],
    players: {black: "p1", white: "p2"},
    playerInfo: {
      p1: {name: "Player1", photo: null},
      p2: {name: "Player2", photo: null},
    },
    board: "----------------------------------------------------------------",
    currentPlayer: "white",
    lastMove: {row: 2, col: 2},
    moves: [
      {row: 2, col: 3, by: "p1"},
      {row: 2, col: 2, by: "p2"},
    ],
    moveCount: 2,
    status: "active",
    winner: null,
    rewarded: false,
    lastSeen: {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Mark the game as finished (simulates claimDisconnectWin / resign / end-of-game).
  // The function fires on the active → finished transition.
  await gameRef.update({status: "finished", winner: "black"});

  console.log("Waiting for onGameFinished trigger (8 s)…");
  await sleep(8000);

  // ---- Assertions ------------------------------------------------------------
  const [gSnap, p1Snap, p2Snap] = await Promise.all([
    gameRef.get(),
    db.collection("users").doc("p1").get(),
    db.collection("users").doc("p2").get(),
  ]);

  const g = gSnap.data();
  const p1 = p1Snap.data();
  const p2 = p2Snap.data();

  let ok = true;
  const check = (label, condition) => {
    if (condition) {
      console.log(`  PASS  ${label}`);
    } else {
      console.error(`  FAIL  ${label}`);
      ok = false;
    }
  };

  console.log("\n=== onGameFinished results ===");
  check("game has rewarded=true", g?.rewarded === true);
  check("game has no rewardError", !g?.rewardError);
  check("p1 (winner) gained xp", (p1?.xp ?? 0) > 0);
  check("p2 (loser) gained xp", (p2?.xp ?? 0) > 0);
  check("p1 online.wins incremented", p1?.online?.wins === 1);
  check("p2 online.losses incremented", p2?.online?.losses === 1);
  check("p1 online.currentStreak is 1", p1?.online?.currentStreak === 1);
  check("p2 online.currentStreak reset to 0", p2?.online?.currentStreak === 0);
  check("p1 level is at least 1", (p1?.level ?? 0) >= 1);
  check("p2 level is at least 1", (p2?.level ?? 0) >= 1);

  console.log("\n" + "=".repeat(40));
  console.log(ok ? "ALL PASS" : "SOME FAILED");
  process.exit(ok ? 0 : 1);
}

main().catch((e) => {
  console.error("Fatal:", e);
  process.exit(1);
});
