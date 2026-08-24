import {test} from "node:test";
import * as assert from "node:assert/strict";

import {COIN_PACKS, coinPack, receiptId} from "./coin_packs";
import {isBillingConfigured} from "./play_billing";

// Coin packs are bought with real money, so the two failures that matter are
// the quiet ones: a pack drifting apart from the Dart catalog (the player pays
// and the client shows a different number), and a receipt that can be redeemed
// twice (the player pays once and is credited forever).

test("there are exactly three packs, at the agreed sizes", () => {
  assert.deepEqual(Object.keys(COIN_PACKS).sort(), [
    "coins_1000",
    "coins_500",
    "coins_5000",
  ]);
  assert.equal(COIN_PACKS.coins_500.coins, 500);
  assert.equal(COIN_PACKS.coins_1000.coins, 1000);
  assert.equal(COIN_PACKS.coins_5000.coins, 5000);
});

test("every entry is keyed by its own id", () => {
  for (const [key, pack] of Object.entries(COIN_PACKS)) {
    assert.equal(key, pack.id, `entry ${key} carries id ${pack.id}`);
  }
});

test("coinPack returns undefined for an unknown id", () => {
  assert.equal(coinPack("coins_999"), undefined);
  assert.equal(coinPack(""), undefined);
});

test("a pack id is never also a store item id", async () => {
  const {CATALOG} = await import("./catalog");
  for (const id of Object.keys(COIN_PACKS)) {
    assert.equal(id in CATALOG, false, `${id} is in both catalogs`);
  }
});

test("the same receipt always hashes to the same id", () => {
  assert.equal(receiptId("coins_500", "tok"), receiptId("coins_500", "tok"));
});

test("a receipt id is a legal Firestore document id", () => {
  const id = receiptId("coins_5000", "a/b..c__weird//token");
  assert.match(id, /^[0-9a-f]{64}$/);
});

test("the raw purchase token never appears in the id", () => {
  const token = "secret-bearer-token";
  assert.equal(receiptId("coins_500", token).includes(token), false);
});

test("one token cannot be redeemed under two different packs", () => {
  assert.notEqual(receiptId("coins_500", "tok"), receiptId("coins_5000", "tok"));
});

test("packs and tokens cannot be shuffled into the same id", () => {
  // Guards a concatenation with no separator: "coins_500" + "0x" would collide
  // with "coins_5000" + "x" if the two fields were simply glued together.
  assert.notEqual(receiptId("coins_500", "0x"), receiptId("coins_5000", "x"));
});

test("billing is still switched off", () => {
  // The flip side of the redeem function being safe to deploy. When this test
  // fails, real verification has landed - and this file's assumptions with it.
  assert.equal(isBillingConfigured(), false);
});
