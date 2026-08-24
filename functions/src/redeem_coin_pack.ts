import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {coinPack, receiptId} from "./coin_packs";
import {verifyPlayPurchase} from "./play_billing";

/**
 * Credits a coin pack the player bought with real money.
 *
 * Not callable today: `verifyPlayPurchase` refuses until Play Billing is
 * configured, so every call ends in `failed-precondition` before a single coin
 * is written. Deployed or not, it cannot mint coins. See `play_billing.ts` for
 * what has to happen first.
 *
 * The shape is the same one the working version will have, and the two
 * guarantees it has to make are already here:
 *
 * 1. **The client never says how many coins.** It sends a pack id; the amount
 *    comes from the server catalog, exactly like item prices in `purchase.ts`.
 * 2. **A receipt is worth coins once.** Play retries, a flaky network, a
 *    player reinstalling - all of them can replay the same purchase token. The
 *    receipt document is created inside the same transaction that credits the
 *    balance, so a replay finds it and stops. This is why the credit is a
 *    transaction and not a bare `FieldValue.increment`.
 */
export const redeemCoinPack = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const packId = request.data?.packId;
  if (typeof packId !== "string" || packId.length === 0) {
    throw new HttpsError("invalid-argument", "packId is required.");
  }

  const purchaseToken = request.data?.purchaseToken;
  if (typeof purchaseToken !== "string" || purchaseToken.length === 0) {
    throw new HttpsError("invalid-argument", "purchaseToken is required.");
  }

  const pack = coinPack(packId);
  if (!pack) {
    throw new HttpsError("not-found", `Unknown coin pack: ${packId}`);
  }

  // Before anything is written: Google has to confirm the purchase is real.
  await verifyPlayPurchase(pack, purchaseToken);

  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  // Top-level and unmentioned in firestore.rules, so clients cannot read or
  // write it - the rules deny everything that is not explicitly allowed.
  const receiptRef = db
    .collection("receipts")
    .doc(receiptId(packId, purchaseToken));

  const credited = await db.runTransaction(async (tx) => {
    const receipt = await tx.get(receiptRef);
    if (receipt.exists) return false;

    tx.create(receiptRef, {
      uid,
      packId,
      coins: pack.coins,
      at: FieldValue.serverTimestamp(),
    });
    tx.set(
      userRef,
      {
        coins: FieldValue.increment(pack.coins),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
    return true;
  });

  // `ok` either way: a replayed receipt is not an error for the player, whose
  // coins are already in the balance. `credited` says whether this call is the
  // one that put them there.
  return {ok: true, packId, coins: pack.coins, credited};
});
