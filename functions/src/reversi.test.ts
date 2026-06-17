import {test} from "node:test";
import * as assert from "node:assert/strict";

import {initialBoard, flipsFor, countDiscs, hasAnyMove, replay} from "./reversi";
import {earnedCoins, earnedXp, level} from "./xp_level";

test("opening position has two discs each", () => {
  const board = initialBoard();
  assert.equal(countDiscs(board, "b"), 2);
  assert.equal(countDiscs(board, "w"), 2);
  assert.ok(hasAnyMove(board, "b"));
  assert.ok(hasAnyMove(board, "w"));
});

test("flipsFor finds the single capture of an opening move", () => {
  // Black at d3 (row 2, col 3) captures the white disc at (3,3).
  const flips = flipsFor(initialBoard(), 2, 3, "b");
  assert.deepEqual(flips, [3 * 8 + 3]);
});

test("flipsFor rejects an illegal (non-capturing) move", () => {
  assert.equal(flipsFor(initialBoard(), 0, 0, "b").length, 0);
  // Occupied cell.
  assert.equal(flipsFor(initialBoard(), 3, 3, "b").length, 0);
});

test("replay applies a legal opening move", () => {
  const r = replay([{row: 2, col: 3, by: "b"}]);
  assert.equal(r.valid, true);
  assert.equal(r.black, 4);
  assert.equal(r.white, 1);
  assert.equal(r.flippedBy.b, 1);
  assert.equal(r.naturallyOver, false);
});

test("replay alternates turns across two moves", () => {
  // Black d3, then white must move (it has replies) — both legal.
  const r = replay([
    {row: 2, col: 3, by: "b"},
    {row: 2, col: 2, by: "w"},
  ]);
  assert.equal(r.valid, true);
});

test("replay rejects a move played out of turn", () => {
  const r = replay([{row: 2, col: 3, by: "w"}]);
  assert.equal(r.valid, false);
});

test("replay rejects an illegal placement", () => {
  const r = replay([{row: 0, col: 0, by: "b"}]);
  assert.equal(r.valid, false);
});

test("earnedCoins pays out by outcome", () => {
  assert.equal(earnedCoins("win"), 10);
  assert.equal(earnedCoins("draw"), 5);
  assert.equal(earnedCoins("loss"), 2);
});

test("earnedXp gives the win base plus bonuses", () => {
  const xp = earnedXp({
    outcome: "win",
    scoreDiff: 10,
    flippedPieces: 16,
    myLevel: 1,
    oppLevel: 1,
    streak: 0,
  });
  // base 100 + scoreBonus 10 + flipBonus 2 + levelBonus 0 + streakBonus 0
  assert.equal(xp, 112);
});

test("level grows with xp and starts at 1", () => {
  assert.equal(level(0), 1);
  assert.ok(level(10000) > level(100));
});
