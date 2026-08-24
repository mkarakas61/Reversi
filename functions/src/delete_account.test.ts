import {test} from "node:test";
import * as assert from "node:assert/strict";

import {
  retentionCutoffMs,
  RETENTION_DAYS,
  USER_SUBCOLLECTIONS,
} from "./delete_account";

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

// Firestore keeps a document's subcollections when the document is deleted, so
// every one of them has to be named here or it outlives the account. The list
// is the whole defence, and it is only as good as its last update: `devices`
// was added with push (REV-111), and `consents` had been quietly surviving
// deletion since REV-117 shipped.

test("the deletion list names every subcollection under users/{uid}", () => {
  assert.deepEqual([...USER_SUBCOLLECTIONS].sort(), [
    "consents",
    "devices",
    "history",
  ]);
});

test("no subcollection is listed twice", () => {
  assert.equal(new Set(USER_SUBCOLLECTIONS).size, USER_SUBCOLLECTIONS.length);
});

test("the client only ever writes subcollections that get deleted", async () => {
  // Reads the security rules rather than trusting this file to stay honest: a
  // `match /users/{uid}/<name>` block is a place the client can put data, so
  // if one exists that deletion does not know about, an account can leave
  // something behind. (`log` is nested under consents and handled with it.)
  const {readFileSync} = await import("node:fs");
  const {join} = await import("node:path");
  // Compiled to functions/lib/, so the repo root is two levels up.
  const rules = readFileSync(
    join(__dirname, "..", "..", "firestore.rules"),
    "utf8"
  );
  // Only the blocks nested inside `match /users/{uid}` — from just after that
  // line to where the next top-level match begins.
  const start =
    rules.indexOf("match /users/{uid}") + "match /users/{uid}".length;
  const end = rules.indexOf("match /leaderboards", start);
  assert.ok(end > start, "could not find the end of the users block");
  const usersBlock = rules.slice(start, end);
  const names = new Set(
    [...usersBlock.matchAll(/match \/(\w+)\/\{/g)].map((m) => m[1])
  );
  names.delete("log"); // nested under consents, deleted with it
  for (const name of names) {
    assert.ok(
      (USER_SUBCOLLECTIONS as readonly string[]).includes(name),
      `users/{uid}/${name} is writable but never deleted`
    );
  }
});
