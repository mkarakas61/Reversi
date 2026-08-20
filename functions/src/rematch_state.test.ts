import {test} from "node:test";
import * as assert from "node:assert/strict";
import {Timestamp} from "firebase-admin/firestore";

import {
  actionForRequest,
  actionForResponse,
  isExpired,
  RematchState,
} from "./rematch_state";

const NOW = 1_700_000_000_000;
const ALICE = "uid-alice";
const BOB = "uid-bob";

function pending(by: string, expiresInMs = 30_000): RematchState {
  return {
    by,
    status: "pending",
    at: Timestamp.fromMillis(NOW),
    expiresAt: Timestamp.fromMillis(NOW + expiresInMs),
    gameId: null,
  };
}

test("no state at all means make an offer", () => {
  assert.deepEqual(actionForRequest(undefined, ALICE, NOW), {kind: "offer"});
});

test("tapping again while your own offer stands changes nothing", () => {
  const action = actionForRequest(pending(ALICE), ALICE, NOW);
  assert.deepEqual(action, {kind: "already-offered"});
});

test("tapping while the opponent is offering accepts instead of re-offering", () => {
  // Both players tapping "Play again" at the same moment is the likeliest way
  // this is used; a second offer would leave two standing and no game.
  const action = actionForRequest(pending(BOB), ALICE, NOW);
  assert.deepEqual(action, {kind: "accept"});
});

test("an expired offer is not live, so a tap starts a fresh one", () => {
  const stale = pending(BOB, -1); // expired a millisecond ago
  assert.deepEqual(actionForRequest(stale, ALICE, NOW), {kind: "offer"});
});

test("a declined offer is not live either", () => {
  const declined: RematchState = {...pending(BOB), status: "declined"};
  assert.deepEqual(actionForRequest(declined, ALICE, NOW), {kind: "offer"});
});

test("once accepted, every later tap returns the same game", () => {
  const accepted: RematchState = {
    by: BOB,
    status: "accepted",
    gameId: "game-2",
  };
  assert.deepEqual(actionForRequest(accepted, ALICE, NOW), {
    kind: "already-accepted",
    gameId: "game-2",
  });
  assert.deepEqual(actionForResponse(accepted, ALICE, true, NOW), {
    kind: "already-accepted",
    gameId: "game-2",
  });
  // Even the player who offered it gets the game, not a duplicate.
  assert.deepEqual(actionForRequest(accepted, BOB, NOW), {
    kind: "already-accepted",
    gameId: "game-2",
  });
});

test("accepting the opponent's live offer creates the game", () => {
  const action = actionForResponse(pending(BOB), ALICE, true, NOW);
  assert.deepEqual(action, {kind: "accept"});
});

test("you cannot accept your own offer", () => {
  // Otherwise one player could open a game the other never agreed to.
  const action = actionForResponse(pending(ALICE), ALICE, true, NOW);
  assert.deepEqual(action, {kind: "already-offered"});
});

test("refusing declines, and so does withdrawing your own offer", () => {
  assert.deepEqual(actionForResponse(pending(BOB), ALICE, false, NOW), {
    kind: "decline",
  });
  // Leaving the result screen withdraws your offer through the same path.
  assert.deepEqual(actionForResponse(pending(ALICE), ALICE, false, NOW), {
    kind: "decline",
  });
});

test("answering an offer that already timed out is reported, not an error", () => {
  // The client is a moment behind the document; that is not the player's fault.
  const action = actionForResponse(pending(BOB, -1), ALICE, true, NOW);
  assert.deepEqual(action, {kind: "nothing-to-answer", status: "pending"});
});

test("answering when there was never an offer reports declined", () => {
  const action = actionForResponse(undefined, ALICE, true, NOW);
  assert.deepEqual(action, {kind: "nothing-to-answer", status: "declined"});
});

test("an offer with no expiry never goes stale", () => {
  // Defensive: documents written before expiresAt existed must not read as
  // expired, which would silently disable the feature for them.
  const noExpiry: RematchState = {by: BOB, status: "pending"};
  assert.equal(isExpired(noExpiry, NOW), false);
  assert.deepEqual(actionForRequest(noExpiry, ALICE, NOW), {kind: "accept"});
});

test("expiry is judged against the passed clock, not the wall clock", () => {
  const offer = pending(BOB, 30_000);
  assert.equal(isExpired(offer, NOW + 29_999), false);
  assert.equal(isExpired(offer, NOW + 30_001), true);
});
