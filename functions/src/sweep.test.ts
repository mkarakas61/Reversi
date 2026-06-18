import {test} from "node:test";
import * as assert from "node:assert/strict";

import {lastActivityMs, shouldSweep} from "./sweep";

const stamp = (ms: number) => ({toMillis: () => ms});
const ABANDON = 2 * 60 * 1000; // matches ABANDON_MS in sweep.ts

test("lastActivityMs uses the most recent heartbeat of either player", () => {
  assert.equal(lastActivityMs({a: stamp(1000), b: stamp(5000)}, stamp(10)), 5000);
  assert.equal(lastActivityMs({a: stamp(9000), b: stamp(5000)}, stamp(10)), 9000);
});

test("lastActivityMs falls back to createdAt when there are no heartbeats", () => {
  assert.equal(lastActivityMs({}, stamp(700)), 700);
  assert.equal(lastActivityMs(undefined, stamp(700)), 700);
  assert.equal(lastActivityMs(null, stamp(700)), 700);
});

test("lastActivityMs returns null when nothing is known", () => {
  assert.equal(lastActivityMs(undefined, undefined), null);
  assert.equal(lastActivityMs({}, undefined), null);
});

test("shouldSweep keeps a game with a recent heartbeat", () => {
  const now = 1_000_000;
  assert.equal(shouldSweep({a: stamp(now - 5_000)}, stamp(0), now, ABANDON), false);
});

test("shouldSweep cancels once both sides are stale past the threshold", () => {
  const now = 1_000_000;
  assert.equal(
    shouldSweep({a: stamp(now - 130_000), b: stamp(now - 200_000)}, stamp(0), now, ABANDON),
    true,
  );
});

test("shouldSweep keeps a game kept alive by one present player", () => {
  const now = 1_000_000;
  // A long gone, but B heartbeated 5 s ago — still live.
  assert.equal(
    shouldSweep({a: stamp(now - 500_000), b: stamp(now - 5_000)}, stamp(0), now, ABANDON),
    false,
  );
});

test("shouldSweep cancels a never-played game by its creation time", () => {
  const now = 1_000_000;
  assert.equal(shouldSweep({}, stamp(now - 130_000), now, ABANDON), true);
  assert.equal(shouldSweep(undefined, stamp(now - 5_000), now, ABANDON), false);
});

test("shouldSweep keeps a game whose activity can't be determined", () => {
  assert.equal(shouldSweep(undefined, undefined, 1_000, 100), false);
});
