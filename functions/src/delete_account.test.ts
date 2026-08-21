import {test} from "node:test";
import * as assert from "node:assert/strict";

import {retentionCutoffMs, RETENTION_DAYS} from "./delete_account";

const DAY = 24 * 60 * 60 * 1000;
const now = Date.UTC(2026, 7, 21, 12, 0);

test("the retention window is the 12 months the privacy policy promises", () => {
  assert.equal(RETENTION_DAYS, 365);
});

test("the cutoff is exactly one retention window back", () => {
  assert.equal(retentionCutoffMs(now), now - 365 * DAY);
});

test("a match anonymized inside the window is on the keep side of the cutoff", () => {
  const cutoff = retentionCutoffMs(now);
  assert.ok(now - 30 * DAY > cutoff);
  assert.ok(now - 364 * DAY > cutoff);
});

test("a match anonymized at or past the window is on the purge side", () => {
  const cutoff = retentionCutoffMs(now);
  assert.ok(now - 365 * DAY <= cutoff);
  assert.ok(now - 800 * DAY <= cutoff);
});
