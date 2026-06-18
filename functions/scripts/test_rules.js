// Firestore security rules tests for REV-51.
// Run via:
//   firebase emulators:exec --only auth,firestore \
//     'node functions/scripts/test_rules.js'
//
// Verifies:
//   1. Profile update — client cannot write xp/level/online.*
//   2. Game move — only the current player can submit a move
//   3. Opponent cannot write a move out of turn
//   4. Any participant can write a heartbeat (lastSeen)
//   5. Any participant can resign (write status=finished)
//   6. Write to a finished game is blocked

"use strict";

process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";

const admin = require("firebase-admin");
admin.initializeApp({projectId: "reversi-3a506"});
const db = admin.firestore();
const auth = admin.auth();

const FS_HOST = process.env.FIRESTORE_EMULATOR_HOST;
const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const PROJECT = "reversi-3a506";

let passed = 0;
let failed = 0;

async function assert(name, expected, fn) {
  try {
    const actual = await fn();
    if (actual === expected) {
      console.log(`  PASS  ${name}`);
      passed++;
    } else {
      console.error(`  FAIL  ${name}  (expected ${expected}, got ${actual})`);
      failed++;
    }
  } catch (e) {
    console.error(`  FAIL  ${name}  (threw: ${e.message})`);
    failed++;
  }
}

// Exchange a custom token for a Firebase ID token via the Auth emulator.
async function idTokenFor(uid) {
  const customToken = await auth.createCustomToken(uid);
  const url = `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake`;
  const r = await fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({token: customToken, returnSecureToken: true}),
  });
  const body = await r.json();
  if (!body.idToken) throw new Error(`sign-in failed: ${JSON.stringify(body)}`);
  return body.idToken;
}

// Make a Firestore REST PATCH (update) as a specific user.
// Returns the HTTP status code.
async function patchAs(uid, path, fields) {
  const token = await idTokenFor(uid);
  const fieldMask = Object.keys(fields).join(",");
  const url = `http://${FS_HOST}/v1/projects/${PROJECT}/databases/(default)/documents/${path}?updateMask.fieldPaths=${encodeURIComponent(fieldMask)}`;
  const body = {
    fields: Object.fromEntries(
      Object.entries(fields).map(([k, v]) => {
        if (typeof v === "string") return [k, {stringValue: v}];
        if (typeof v === "number") return [k, {integerValue: String(v)}];
        if (typeof v === "boolean") return [k, {booleanValue: v}];
        return [k, {stringValue: JSON.stringify(v)}];
      }),
    ),
  };
  const r = await fetch(url, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  return r.status;
}

// Make a Firestore REST GET as a specific user. Returns status code.
async function getAs(uid, path) {
  const token = await idTokenFor(uid);
  const url = `http://${FS_HOST}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`;
  const r = await fetch(url, {
    headers: {Authorization: `Bearer ${token}`},
  });
  return r.status;
}

// Clear a collection using admin SDK.
async function clear(name) {
  const snap = await db.collection(name).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

async function main() {
  console.log("=== REV-51 Firestore Rules Tests ===\n");

  await clear("users");
  await clear("games");

  // ---- Setup ----------------------------------------------------------------

  // Two players
  await db.collection("users").doc("alice").set({
    displayName: "Alice",
    photoUrl: null,
    xp: 100,
    level: 1,
    online: {wins: 0, losses: 0, draws: 0},
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection("users").doc("bob").set({
    displayName: "Bob",
    photoUrl: null,
    xp: 50,
    level: 1,
    online: {wins: 0, losses: 0, draws: 0},
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // An active game where it's Alice's turn (black)
  await db.collection("games").doc("game1").set({
    playerUids: ["alice", "bob"],
    players: {black: "alice", white: "bob"},
    playerInfo: {},
    board: "----------------------------------------------------------------".replace(/-/g, "-"),
    currentPlayer: "black",
    lastMove: null,
    moves: [],
    moveCount: 0,
    status: "active",
    winner: null,
    lastSeen: {},
  });

  // A finished game for write-block test
  await db.collection("games").doc("finished").set({
    playerUids: ["alice", "bob"],
    players: {black: "alice", white: "bob"},
    playerInfo: {},
    board: "",
    currentPlayer: "black",
    lastMove: null,
    moves: [],
    moveCount: 3,
    status: "finished",
    winner: "black",
    lastSeen: {},
  });

  // ---- Tests ----------------------------------------------------------------

  console.log("1. Profile update rules");
  await assert(
    "alice can update her displayName",
    200,
    () => patchAs("alice", "users/alice", {displayName: "Alicia", updatedAt: "now"}),
  );
  await assert(
    "alice cannot write xp to her own profile",
    403,
    () => patchAs("alice", "users/alice", {xp: 9999}),
  );
  await assert(
    "alice cannot write level to her own profile",
    403,
    () => patchAs("alice", "users/alice", {level: 99}),
  );
  await assert(
    "alice cannot update bob's profile",
    403,
    () => patchAs("alice", "users/bob", {displayName: "Hacked"}),
  );

  console.log("\n2. Game read access");
  await assert(
    "alice can read game1 (she is a participant)",
    200,
    () => getAs("alice", "games/game1"),
  );
  await assert(
    "outsider (carol) cannot read game1",
    403,
    () => getAs("carol", "games/game1"),
  );

  console.log("\n3. Move submission — turn enforcement");
  // Alice is black / current player — board write should be allowed
  await assert(
    "alice (current player, black) can submit a move",
    200,
    () => patchAs("alice", "games/game1", {
      board: "x".repeat(64),
      currentPlayer: "white",
      moveCount: 1,
    }),
  );
  // Reset for next test
  await db.collection("games").doc("game1").update({
    currentPlayer: "black",
    moveCount: 0,
  });
  await assert(
    "bob (out of turn, white) cannot submit a move when it is black's turn",
    403,
    () => patchAs("bob", "games/game1", {
      board: "y".repeat(64),
      currentPlayer: "white",
      moveCount: 1,
    }),
  );

  console.log("\n4. Heartbeat — any participant can update lastSeen");
  await assert(
    "alice can write her own lastSeen (heartbeat)",
    200,
    () => patchAs("alice", "games/game1", {"lastSeen.alice": "ts"}),
  );
  await assert(
    "bob can write his own lastSeen (heartbeat)",
    200,
    () => patchAs("bob", "games/game1", {"lastSeen.bob": "ts"}),
  );

  console.log("\n5. Resign / cancel — any participant can end the game");
  await assert(
    "bob can resign (write status=finished) without it being his turn",
    200,
    () => patchAs("bob", "games/game1", {status: "finished", winner: "black"}),
  );

  console.log("\n6. Finished game is read-only");
  await assert(
    "alice cannot update a finished game",
    403,
    () => patchAs("alice", "games/finished", {"lastSeen.alice": "ts"}),
  );

  console.log("\n" + "=".repeat(40));
  console.log(`Results: ${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error("Fatal error:", e);
  process.exit(1);
});
