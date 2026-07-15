import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {catalogItem} from "./catalog";

/**
 * Buys a store item with coins. Server-authoritative: the catalog (and every
 * price) lives only here, never trusts anything the client sends beyond the
 * item id, and the balance/ownership check + debit happen in one transaction
 * so a player can never end up with a negative balance or a duplicate item.
 */
export const purchaseItem = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const itemId = request.data?.itemId;
  if (typeof itemId !== "string" || itemId.length === 0) {
    throw new HttpsError("invalid-argument", "itemId is required.");
  }

  const item = catalogItem(itemId);
  if (!item) {
    throw new HttpsError("not-found", `Unknown item: ${itemId}`);
  }

  const db = getFirestore();
  const ref = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const coins = (data?.coins as number | undefined) ?? 0;
    const owned = (data?.ownedItems as string[] | undefined) ?? [];

    if (owned.includes(itemId)) {
      throw new HttpsError("already-exists", "You already own this item.");
    }
    if (coins < item.price) {
      throw new HttpsError("failed-precondition", "Not enough coins.");
    }

    tx.set(
      ref,
      {
        coins: coins - item.price,
        ownedItems: FieldValue.arrayUnion(itemId),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
  });

  return {ok: true, itemId};
});
