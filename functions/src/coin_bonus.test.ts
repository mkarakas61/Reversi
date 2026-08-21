import {test} from "node:test";
import * as assert from "node:assert/strict";

import {
  coinMultiplier,
  isHappyHour,
  istanbulHour,
  waitBonusCoins,
  HAPPY_HOUR_MULTIPLIER,
  WAIT_BONUS_CAP,
} from "./coin_bonus";

/** An instant expressed as Istanbul wall-clock time (UTC+3). */
function istanbul(hour: number, minute = 0): Date {
  return new Date(Date.UTC(2026, 7, 21, hour - 3, minute));
}

test("istanbulHour reads the local hour, not UTC", () => {
  assert.equal(istanbulHour(new Date(Date.UTC(2026, 7, 21, 17, 0))), 20);
  // Just before midnight local time is still the same UTC day + 3h.
  assert.equal(istanbulHour(new Date(Date.UTC(2026, 7, 21, 20, 59))), 23);
});

test("happy hour covers 20:00 up to but not including 22:00", () => {
  assert.equal(isHappyHour(istanbul(19, 59)), false);
  assert.equal(isHappyHour(istanbul(20, 0)), true);
  assert.equal(isHappyHour(istanbul(21, 59)), true);
  assert.equal(isHappyHour(istanbul(22, 0)), false);
  assert.equal(isHappyHour(istanbul(3)), false);
});

test("the multiplier is 2 inside the window and 1 outside", () => {
  assert.equal(coinMultiplier(istanbul(21)), HAPPY_HOUR_MULTIPLIER);
  assert.equal(coinMultiplier(istanbul(9)), 1);
});

test("wait bonus pays one coin per whole minute", () => {
  assert.equal(waitBonusCoins(0), 0);
  assert.equal(waitBonusCoins(59_000), 0);
  assert.equal(waitBonusCoins(60_000), 1);
  assert.equal(waitBonusCoins(3 * 60_000 + 30_000), 3);
});

test("wait bonus is capped below a win", () => {
  assert.equal(waitBonusCoins(9 * 60_000), WAIT_BONUS_CAP);
  assert.equal(waitBonusCoins(60 * 60_000), WAIT_BONUS_CAP);
  assert.ok(WAIT_BONUS_CAP < 10, "cap must stay under the win reward");
});

test("a missing or nonsense wait is worth nothing", () => {
  assert.equal(waitBonusCoins(undefined), 0);
  assert.equal(waitBonusCoins(null), 0);
  assert.equal(waitBonusCoins("120000"), 0);
  assert.equal(waitBonusCoins(-60_000), 0);
  assert.equal(waitBonusCoins(Number.NaN), 0);
});
