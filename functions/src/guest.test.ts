import {test} from "node:test";
import * as assert from "node:assert/strict";

import {isGuestUser} from "./guest";

test("isGuestUser is true for a provider-less (anonymous) account", () => {
  assert.equal(isGuestUser([]), true);
});

test("isGuestUser is false once any provider is linked", () => {
  assert.equal(isGuestUser([{providerId: "google.com"}]), false);
});
