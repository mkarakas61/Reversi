/** A purchasable store item. Prices are coins; defined server-side only — the
 * client can never influence what something costs. */
export interface CatalogItem {
  id: string;
  category: "board" | "coinSkin";
  price: number;
}

/**
 * Coin prices. A win pays 10 coins (doubled 20:00–22:00), so a disc is about
 * ten wins and a board about thirty — the first purchase lands within days
 * while the whole shop (1200 coins) stays weeks away.
 */
const DISC_PRICE = 100;
const BOARD_PRICE = 300;

/**
 * The full store catalog (decided 2026-08-23).
 *
 * **Everything is sold on its own** — a board does not come with the discs
 * drawn to match it. Bundles turn every purchase into a long saving-up
 * project; separate items let a player spend what they have now.
 *
 * ⚠️ **Mirrors `kStoreItems` in `lib/core/store/store_catalog.dart`: same ids,
 * same prices.** The client only renders the shop window — these prices are
 * the ones that get charged — but an id that exists on one side and not the
 * other is either an unbuyable item or an item that unlocks nothing. The ids
 * are also what sits in each player's `ownedItems`, so they can never be
 * renamed once shipped.
 *
 * The free starter set (wood/turquoise/midnight boards, the four drawn discs,
 * the Orijinal theme) is deliberately absent: it is owned by everyone,
 * including guests who have no user document, so it is never bought and never
 * stored. The Güzelsi theme and the subscription are absent too — real money,
 * not coins, and they will arrive through Play Billing.
 */
export const CATALOG: Record<string, CatalogItem> = {
  board_marble: {id: "board_marble", category: "board", price: BOARD_PRICE},
  board_flower: {id: "board_flower", category: "board", price: BOARD_PRICE},
  disc_walnut: {id: "disc_walnut", category: "coinSkin", price: DISC_PRICE},
  disc_maple: {id: "disc_maple", category: "coinSkin", price: DISC_PRICE},
  disc_marble_black: {
    id: "disc_marble_black",
    category: "coinSkin",
    price: DISC_PRICE,
  },
  disc_marble_white: {
    id: "disc_marble_white",
    category: "coinSkin",
    price: DISC_PRICE,
  },
  disc_flower_purple: {
    id: "disc_flower_purple",
    category: "coinSkin",
    price: DISC_PRICE,
  },
  disc_flower_pink: {
    id: "disc_flower_pink",
    category: "coinSkin",
    price: DISC_PRICE,
  },
};

export function catalogItem(id: string): CatalogItem | undefined {
  return CATALOG[id];
}
