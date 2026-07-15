import {test} from "node:test";
import * as assert from "node:assert/strict";

import {catalogItem} from "./catalog";

test("catalogItem returns undefined for an unknown id", () => {
  assert.equal(catalogItem("does-not-exist"), undefined);
});
