import {test} from "node:test";
import * as assert from "node:assert/strict";

import {weekId} from "./leaderboard";

const at = (iso: string) => new Date(`${iso}T12:00:00Z`);

test("weekId returns the ISO week for an ordinary mid-year date", () => {
  assert.equal(weekId(at("2026-06-19")), "2026-W25");
});

test("weekId handles the first ISO week of a year", () => {
  assert.equal(weekId(at("2026-01-01")), "2026-W01");
});

test("weekId assigns late-December dates to next year's week 1 when applicable", () => {
  assert.equal(weekId(at("2025-12-29")), "2026-W01");
});

test("weekId handles a 53-week year's final week", () => {
  assert.equal(weekId(at("2026-12-31")), "2026-W53");
});
