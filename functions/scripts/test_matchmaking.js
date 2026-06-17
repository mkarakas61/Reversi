// Emulator integration test for the matchmaking trigger (REV-43).
// Run via:  firebase emulators:exec --only firestore,functions \
//             'node functions/scripts/test_matchmaking.js'
// Writes two waiting tickets to the Firestore emulator; the functions emulator
// runs onMatchmakingTicketCreated, which should create exactly one game and
// mark both tickets matched.
const admin = require("firebase-admin");

process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
admin.initializeApp({projectId: "reversi-3a506"});
const db = admin.firestore();

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function clear(name) {
  const s = await db.collection(name).get();
  await Promise.all(s.docs.map((d) => d.ref.delete()));
}

function ticket(uid, name) {
  return db.collection("matchmaking").doc(uid).set({
    uid,
    displayName: name,
    photoUrl: null,
    level: 1,
    wins: 0,
    losses: 0,
    draws: 0,
    bestStreak: 0,
    status: "waiting",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function main() {
  await clear("matchmaking");
  await clear("games");

  await ticket("userA", "Ada");
  await sleep(1500);
  await ticket("userB", "Bora");
  await sleep(6000); // let the trigger run

  const games = await db.collection("games").get();
  const tickets = await db.collection("matchmaking").get();

  console.log("GAMES:", games.size);
  games.forEach((g) => console.log("GAME", JSON.stringify(g.data())));
  tickets.forEach((t) =>
    console.log("TICKET", t.id, t.data().status, t.data().gameId || ""),
  );

  let ok = games.size === 1;
  if (ok) {
    const g = games.docs[0].data();
    ok =
      Array.isArray(g.playerUids) &&
      g.playerUids.includes("userA") &&
      g.playerUids.includes("userB") &&
      !!g.players.black &&
      !!g.players.white &&
      g.players.black !== g.players.white &&
      g.status === "active" &&
      !!g.playerInfo.userA &&
      !!g.playerInfo.userB;
    const allMatched = tickets.docs.every(
      (t) => t.data().status === "matched" && t.data().gameId === games.docs[0].id,
    );
    ok = ok && allMatched;
  }
  console.log(ok ? "MATCH_OK" : "MATCH_FAIL");
  process.exit(ok ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
