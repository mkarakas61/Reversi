import {test} from "node:test";
import * as assert from "node:assert/strict";

import {rankFor, trophyDelta, RANKS, WIN_BASE, DRAW_GAIN} from "./trophy";

test("rankFor returns Çaylak at zero and below the first threshold", () => {
  assert.equal(rankFor(0).id, "caylak");
  assert.equal(rankFor(29).id, "caylak");
});

test("rankFor lands exactly on each threshold", () => {
  assert.equal(rankFor(30).id, "acemi");
  assert.equal(rankFor(100).id, "kalfa");
  assert.equal(rankFor(250).id, "usta");
  assert.equal(rankFor(550).id, "buyukusta");
  assert.equal(rankFor(1000).id, "efsane");
});

test("rankFor stays at Efsane far above the top threshold", () => {
  assert.equal(rankFor(99999).id, "efsane");
});

test("rankFor is monotonic and never below Çaylak for negatives", () => {
  // Trophies never go negative in practice, but be defensive.
  assert.equal(rankFor(-5).id, "caylak");
});

test("win gives base +3 for a razor-thin margin", () => {
  // |diff| = 2 → round(2/8) = 0 bonus.
  assert.equal(trophyDelta("win", 2, 0), WIN_BASE);
});

test("win adds a score-margin bonus, capped at +3 (so ≤ +6)", () => {
  assert.equal(trophyDelta("win", 8, 0), WIN_BASE + 1); // round(8/8)=1
  assert.equal(trophyDelta("win", 20, 0), WIN_BASE + 3); // round(20/8)=3 (cap)
  assert.equal(trophyDelta("win", 64, 0), WIN_BASE + 3); // capped
});

test("draw gives a flat +1 regardless of rank", () => {
  assert.equal(trophyDelta("draw", 0, 0), DRAW_GAIN);
  assert.equal(trophyDelta("draw", 10, 1000), DRAW_GAIN);
});

test("loss costs nothing below Kalfa (Çaylak / Acemi)", () => {
  assert.equal(trophyDelta("loss", 10, 0), 0); // Çaylak
  assert.equal(trophyDelta("loss", 10, 30), 0); // Acemi
});

test("loss penalty grows with the pre-game rank", () => {
  assert.equal(trophyDelta("loss", 10, 100), -1); // Kalfa
  assert.equal(trophyDelta("loss", 10, 250), -2); // Usta
  assert.equal(trophyDelta("loss", 10, 550), -4); // Büyük Usta
  assert.equal(trophyDelta("loss", 10, 1000), -6); // Efsane
});

test("loss penalty uses PRE-game trophies, not the score", () => {
  // Same rank (Usta) regardless of how badly they lost.
  assert.equal(trophyDelta("loss", 2, 300), -2);
  assert.equal(trophyDelta("loss", 40, 300), -2);
});

test("break-even win rate rises with rank (self-balancing property)", () => {
  // A rank holds when wins*gain ≈ losses*penalty. With a base win of +3 the
  // break-even win rate is penalty/(WIN_BASE+penalty). Assert the intended
  // ladder feel: harder to hold each rung up.
  const holdRate = (penalty: number) => penalty / (WIN_BASE + penalty);
  const kalfa = holdRate(RANKS.find((r) => r.id === "kalfa")!.lossPenalty);
  const usta = holdRate(RANKS.find((r) => r.id === "usta")!.lossPenalty);
  const efsane = holdRate(RANKS.find((r) => r.id === "efsane")!.lossPenalty);
  assert.ok(kalfa < usta && usta < efsane);
  assert.equal(Math.round(efsane * 100), 67); // ~67% to hold Efsane
});
