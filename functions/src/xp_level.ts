// XP rewards and level thresholds for the online ranked system.
// Keep in sync with lib/models/xp_level.dart (Dart side).
//
// Level curve:  xpForLevel(L) = 50 × L × (L − 1)
//               level(xp)     = floor((1 + sqrt(1 + 8×xp/100)) / 2)

const BASE_WIN = 100;
const BASE_DRAW = 40;
const BASE_LOSS = 15;

/** Total XP required to reach level L. Level 1 needs 0 XP. */
export function xpForLevel(L: number): number {
  return 50 * L * (L - 1);
}

/** Level for a player with `xp` total XP (always ≥ 1). */
export function level(xp: number): number {
  if (xp <= 0) return 1;
  return Math.max(1, Math.floor((1 + Math.sqrt(1 + (8 * xp) / 100)) / 2));
}

/** XP accumulated within the current level. */
export function xpIntoLevel(xp: number): number {
  return xp - xpForLevel(level(xp));
}

export type GameOutcome = "win" | "draw" | "loss";

export interface GameResult {
  outcome: GameOutcome;
  /** |black − white| disc count */
  scoreDiff: number;
  /** Total discs flipped by this player */
  flippedPieces: number;
  /** Player's level before the game */
  myLevel: number;
  /** Opponent's level before the game */
  oppLevel: number;
  /** Consecutive wins immediately before this game */
  streak: number;
}

/** XP earned for one online game. */
export function earnedXp(r: GameResult): number {
  const base =
    r.outcome === "win" ? BASE_WIN : r.outcome === "draw" ? BASE_DRAW : BASE_LOSS;
  const scoreBonus = r.outcome === "win" ? Math.min(r.scoreDiff, 30) : 0;
  const flipBonus = Math.floor(r.flippedPieces / 8);
  const levelBonus =
    r.outcome === "win"
      ? Math.min(Math.max(r.oppLevel - r.myLevel, -4), 8) * 8
      : 0;
  const streakBonus = Math.min(r.streak, 5) * 5;
  return base + scoreBonus + flipBonus + levelBonus + streakBonus;
}

// ── Coins (soft currency) ───────────────────────────────────────────────────
// Awarded from launch (REV-50 product decision) toward the planned v1.1 IAP
// economy. Amounts are intentionally simple and tunable from here.
const COIN_WIN = 10;
const COIN_DRAW = 5;
const COIN_LOSS = 2;

/** Coins earned for one online game. */
export function earnedCoins(outcome: GameOutcome): number {
  return outcome === "win"
    ? COIN_WIN
    : outcome === "draw"
      ? COIN_DRAW
      : COIN_LOSS;
}
