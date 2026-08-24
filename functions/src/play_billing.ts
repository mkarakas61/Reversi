// The one part of the coin-pack chain that cannot be written yet: asking Google
// whether a purchase actually happened.
//
// Why it is a stub. Verification needs a Play Developer API service account
// with access to the app, and the app has not been uploaded to Play Console -
// the publisher decision comes first (PROGRESS.md, 2026-08-23). Until then
// there is no purchase to verify and no credential to verify it with.
//
// Why the stub throws instead of returning true. This function is the only
// thing standing between a client-supplied string and a coin balance. If it
// were ever deployed while returning `true`, anyone could call `redeemCoinPack`
// with a made-up token and mint themselves 5000 coins. Refusing is the safe
// default, and it stays safe if this file is forgotten.
//
// What replaces it, in order:
//   1. Play Console: create the three managed products (`coins_500`,
//      `coins_1000`, `coins_5000` - see `coin_packs.ts`).
//   2. Google Cloud: a service account, granted "View financial data" on the
//      Play Console account, linked to the Play Developer API.
//   3. Here: `androidpublisher.purchases.products.get({packageName, productId,
//      token})`, then check `purchaseState === 0` (purchased) and
//      `consumptionState === 0` (not yet consumed).
//   4. Acknowledge/consume the purchase - Play refunds anything left
//      unacknowledged for three days.
// The idempotency guard in `redeem_coin_pack.ts` stays either way: an
// acknowledged purchase can still be replayed by a client that retries.

import {HttpsError} from "firebase-functions/v2/https";

import {CoinPack} from "./coin_packs";

/** Whether real purchase verification is wired up. Always false today. */
export function isBillingConfigured(): boolean {
  return false;
}

/**
 * Confirms with Google that [purchaseToken] is a real, paid, unconsumed
 * purchase of [pack]. Throws otherwise - never returns false.
 */
export async function verifyPlayPurchase(
  pack: CoinPack,
  purchaseToken: string
): Promise<void> {
  if (!isBillingConfigured()) {
    throw new HttpsError(
      "failed-precondition",
      `Play Billing is not configured; cannot verify a purchase of ${pack.id}.`
    );
  }
  // Unreachable until the steps in this file's header are done.
  void purchaseToken;
  throw new HttpsError("internal", "Purchase verification is not implemented.");
}
