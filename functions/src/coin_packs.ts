// Coin packs: coins bought with real money, not earned by playing (Mustafa,
// 2026-08-24). Three sizes only - 500 / 1000 / 5000.
//
// NOTE: nothing here can be bought yet. Play Billing needs the app uploaded to
// Play Console and a Play Developer API service account, both of which wait on
// the publisher decision. What lives in this file is the half that can be
// written and tested without any of that: which packs exist, how many coins
// each is worth, and how a receipt is turned into a document id that can only
// ever be redeemed once. The half that cannot - asking Google whether a
// purchase is real - sits behind `verifyPlayPurchase` in `play_billing.ts` and
// currently refuses every call.
//
// Mirrors `kCoinPacks` in `lib/core/store/coin_packs.dart`: same ids, same coin
// amounts. The ids are Play Console product ids and can never be renamed once a
// product exists under them.
//
// Prices are deliberately absent. A pack's price is whatever Play charges in
// the player's country and currency, and it is Play that quotes it. A number
// written here would be a second, wrong price list the moment a currency moves.

import {createHash} from "node:crypto";

export interface CoinPack {
  /** Play Console product id. */
  id: string;
  /** Coins credited when a purchase of this pack is verified. */
  coins: number;
}

export const COIN_PACKS: Record<string, CoinPack> = {
  coins_500: {id: "coins_500", coins: 500},
  coins_1000: {id: "coins_1000", coins: 1000},
  coins_5000: {id: "coins_5000", coins: 5000},
};

export function coinPack(id: string): CoinPack | undefined {
  return COIN_PACKS[id];
}

/**
 * The document id under `receipts/` for one Play purchase.
 *
 * Hashed rather than used raw: a Play purchase token is long, opaque, and not
 * guaranteed to be a legal Firestore document id, while a SHA-256 is always 64
 * safe hex characters. Hashing also keeps the raw token - which is a bearer
 * credential for that purchase - out of document *names*, which show up in
 * console listings and index keys.
 *
 * The pack id is folded in so the same token can never be redeemed twice under
 * two different packs.
 */
export function receiptId(packId: string, purchaseToken: string): string {
  return createHash("sha256")
    .update(`${packId} ${purchaseToken}`)
    .digest("hex");
}
