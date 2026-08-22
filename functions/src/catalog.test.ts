import {test} from "node:test";
import * as assert from "node:assert/strict";

import {CATALOG, catalogItem} from "./catalog";

// The catalog is the price list that actually charges people, and its ids are
// what sits in every player's `ownedItems`. These tests guard the two ways it
// can go wrong quietly: an id drifting apart from the Dart catalog (the item
// then unlocks nothing, or cannot be bought), and a price typo.

test("catalogItem returns undefined for an unknown id", () => {
  assert.equal(catalogItem("does-not-exist"), undefined);
});

test("the shop window is exactly the eight paid items", () => {
  // Written out rather than derived: this list is the thing that must not
  // change by accident. Adding an item here is a deliberate edit, and the
  // same id has to appear in lib/core/store/store_catalog.dart.
  assert.deepEqual(Object.keys(CATALOG).sort(), [
    "board_flower",
    "board_marble",
    "disc_flower_pink",
    "disc_flower_purple",
    "disc_maple",
    "disc_marble_black",
    "disc_marble_white",
    "disc_walnut",
  ]);
});

test("every entry is keyed by its own id", () => {
  for (const [key, item] of Object.entries(CATALOG)) {
    assert.equal(key, item.id, `entry ${key} carries id ${item.id}`);
  }
});

test("discs all cost the same, boards cost more", () => {
  const discs = Object.values(CATALOG).filter((i) => i.category === "coinSkin");
  const boards = Object.values(CATALOG).filter((i) => i.category === "board");

  assert.ok(discs.length > 0 && boards.length > 0);
  assert.equal(new Set(discs.map((i) => i.price)).size, 1,
    "a cheap disc would make players pick by price, not by taste");
  assert.ok(Math.min(...boards.map((i) => i.price)) >
    Math.max(...discs.map((i) => i.price)),
  "a board changes the whole table; it cannot cost less than a disc");
});

test("no item is free or negative — the free set is never in here", () => {
  for (const item of Object.values(CATALOG)) {
    assert.ok(item.price > 0, `${item.id} price ${item.price}`);
  }
});
