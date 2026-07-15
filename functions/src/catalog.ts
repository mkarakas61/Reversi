/** A purchasable store item. Prices are coins; defined server-side only — the
 * client can never influence what something costs. */
export interface CatalogItem {
  id: string;
  category: "frame" | "board" | "coinSkin";
  price: number;
}

/**
 * The full store catalog. Empty for now — populated once the Epic 12 design
 * deliverables land (REV-61 profile frames, REV-62 board/theme culling) and
 * `purchaseItem` gets real items to sell (REV-68/70). Until then, every
 * `purchaseItem` call safely fails with "not-found".
 */
export const CATALOG: Record<string, CatalogItem> = {};

export function catalogItem(id: string): CatalogItem | undefined {
  return CATALOG[id];
}
