import {test} from "node:test";
import * as assert from "node:assert/strict";

import {
  allJoined,
  joinWindowExpired,
  requeueTicket,
  JOIN_SECONDS,
  TICKET_TTL_MS,
} from "./match_join";

// The join window (REV-114). Matchmaking no longer needs both players on the
// screen, which means a game can be created for someone who is not looking —
// and the two ways that goes wrong are both here: a game that starts without
// them, and a player punished for the other side's absence.

const stamp = (ms: number) => ({toMillis: () => ms});

test("the agreed window is 60 seconds and the ticket lives a day", () => {
  // Mustafa, 2026-08-24. Written out so a change is a deliberate edit.
  assert.equal(JOIN_SECONDS, 60);
  assert.equal(TICKET_TTL_MS, 24 * 60 * 60 * 1000);
});

test("a game starts only when every player has joined", () => {
  const players = ["a", "b"];
  assert.equal(allJoined({}, players), false);
  assert.equal(allJoined({a: true}, players), false);
  assert.equal(allJoined({a: true, b: true}, players), true);
});

test("a missing or malformed joined map never starts a game", () => {
  assert.equal(allJoined(null, ["a"]), false);
  assert.equal(allJoined(undefined, ["a"]), false);
  // Only a literal `true` counts: a stray value must not be read as presence.
  assert.equal(allJoined({a: "yes"}, ["a"]), false);
  assert.equal(allJoined({a: false}, ["a"]), false);
});

test("someone else's join does not count as mine", () => {
  assert.equal(allJoined({a: true, c: true}, ["a", "b"]), false);
});

test("the window closes exactly on the deadline", () => {
  const now = 1_000_000;
  assert.equal(joinWindowExpired(stamp(now + 1), now), false);
  assert.equal(joinWindowExpired(stamp(now), now), true);
  assert.equal(joinWindowExpired(stamp(now - 1), now), true);
});

test("a game with no deadline counts as expired, not as eternal", () => {
  // The opposite reading would leave an unstartable game sitting in
  // findActiveGame forever, barring both players from matching again.
  assert.equal(joinWindowExpired(null, 1), true);
  assert.equal(joinWindowExpired(undefined, 1), true);
  assert.equal(joinWindowExpired({} as never, 1), true);
});

test("a requeued ticket goes back as waiting, with the profile intact", () => {
  const ticket = requeueTicket(
    {name: "Ada", photo: "p", trophies: 120, wins: 9, losses: 3, draws: 1,
      bestStreak: 4},
    45_000,
  );
  assert.equal(ticket.status, "waiting");
  assert.equal(ticket.displayName, "Ada");
  assert.equal(ticket.trophies, 120);
  assert.equal(ticket.wins, 9);
  assert.equal(ticket.bestStreak, 4);
});

test("time already waited is carried into the new ticket", () => {
  // The player waited it; losing it because the other side never showed up
  // would charge them for someone else's absence (REV-110 caps the payout).
  assert.equal(requeueTicket({}, 45_000).carriedWaitMs, 45_000);
});

test("a missing or nonsense wait time carries nothing rather than NaN", () => {
  assert.equal(requeueTicket({}, undefined).carriedWaitMs, 0);
  assert.equal(requeueTicket({}, "45s").carriedWaitMs, 0);
  assert.equal(requeueTicket({}, null).carriedWaitMs, 0);
});

test("a requeued ticket for a player with no snapshot is still valid", () => {
  // playerInfo can be missing for a game written by an older build; the ticket
  // must still be one matchmaking can read rather than a document of nulls
  // that crashes the pairing query.
  const ticket = requeueTicket(undefined, 0);
  assert.equal(ticket.status, "waiting");
  assert.equal(ticket.trophies, 0);
  assert.equal(ticket.displayName, null);
});

test("the push channel matches the one the app creates", async () => {
  // The Android channel is created in MainActivity.kt and named in the
  // manifest; a message aimed at a channel that does not exist is silently
  // demoted to the system's "Miscellaneous" bucket.
  const {ANDROID_CHANNEL_ID} = await import("./push");
  const {readFileSync} = await import("node:fs");
  const {join} = await import("node:path");
  const manifest = readFileSync(
    join(__dirname, "..", "..", "android", "app", "src", "main",
      "AndroidManifest.xml"),
    "utf8",
  );
  assert.ok(
    manifest.includes(`android:value="${ANDROID_CHANNEL_ID}"`),
    `manifest does not declare channel ${ANDROID_CHANNEL_ID}`,
  );
});

test("the notification names the window the player actually has", async () => {
  const {opponentFoundText} = await import("./push");
  const text = opponentFoundText(JOIN_SECONDS);
  assert.ok(text.tr.body.includes(String(JOIN_SECONDS)));
  assert.ok(text.en.body.includes(String(JOIN_SECONDS)));
});

test("a device's language picks its text, defaulting to Turkish", async () => {
  const {textFor, opponentFoundText} = await import("./push");
  const text = opponentFoundText(60);
  assert.equal(textFor(text, "en").title, text.en.title);
  assert.equal(textFor(text, "tr").title, text.tr.title);
  // A device that never recorded a language, or recorded a nonsense one.
  assert.equal(textFor(text, undefined).title, text.tr.title);
  assert.equal(textFor(text, "de").title, text.tr.title);
});
