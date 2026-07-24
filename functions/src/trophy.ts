// Trophy (kupa) ladder for the online ranked system (REV-73, 2026-07-23
// family meeting decision). A single climbing/falling currency that defines a
// player's rank. Keep in sync with the Dart mirror (REV-67 client model).
//
// Design (canonical: PROGRESS.md §7C-3):
//   - win:  +3 base + score-margin bonus (bigger win = more trophies)
//   - draw: +1
//   - loss: −penalty of the player's PRE-GAME rank; 0 below Kalfa, growing
//           with rank so holding a rank needs an ever-higher win rate. The
//           break-even win rate is penalty / (WIN_BASE + penalty): Kalfa 25%,
//           Usta 40%, Büyük Usta 57%, Efsane 67% — self-balancing, no manual
//           tuning. Trophies never drop below 0 (the caller clamps).

import {GameOutcome} from "./xp_level";

export type RankId =
  | "caylak"
  | "acemi"
  | "kalfa"
  | "usta"
  | "buyukusta"
  | "efsane";

export interface Rank {
  id: RankId;
  /** Inclusive trophy floor for this rank. */
  minTrophies: number;
  /** Trophies subtracted on a defeat suffered while at this rank (≥ 0). */
  lossPenalty: number;
}

/** Base trophies for any win, before the score-margin bonus. */
export const WIN_BASE = 3;
/** Trophies for a draw. */
export const DRAW_GAIN = 1;
/** Largest score-margin bonus a single win can add on top of [WIN_BASE]. */
export const MAX_WIN_BONUS = 3;

// Geometric thresholds — each gap larger than the last, so upper ranks take
// longer. Starting values (tunable from live data; the client mirror in
// REV-67 must match). Order matters: ascending by minTrophies.
export const RANKS: readonly Rank[] = [
  {id: "caylak", minTrophies: 0, lossPenalty: 0},
  {id: "acemi", minTrophies: 30, lossPenalty: 0},
  {id: "kalfa", minTrophies: 100, lossPenalty: 1},
  {id: "usta", minTrophies: 250, lossPenalty: 2},
  {id: "buyukusta", minTrophies: 550, lossPenalty: 4},
  {id: "efsane", minTrophies: 1000, lossPenalty: 6},
];

/** The rank held at [trophies] (never below the first rank, Çaylak). */
export function rankFor(trophies: number): Rank {
  let current = RANKS[0];
  for (const r of RANKS) {
    if (trophies >= r.minTrophies) current = r;
    else break;
  }
  return current;
}

/**
 * Trophy change for one finished game, from this player's perspective.
 *
 * [scoreDiff]   — |black − white| final disc count (used for the win bonus).
 * [preTrophies] — this player's trophies BEFORE the game (sets the loss rank).
 *
 * The result can be negative on a loss; the caller clamps the running total to
 * ≥ 0 (a player can never go below zero trophies).
 */
export function trophyDelta(
  outcome: GameOutcome,
  scoreDiff: number,
  preTrophies: number
): number {
  if (outcome === "win") {
    const bonus = Math.min(Math.round(Math.abs(scoreDiff) / 8), MAX_WIN_BONUS);
    return WIN_BASE + bonus;
  }
  if (outcome === "draw") return DRAW_GAIN;
  // Avoid returning -0 when the rank has no penalty (Çaylak / Acemi).
  const penalty = rankFor(preTrophies).lossPenalty;
  return penalty === 0 ? 0 : -penalty;
}
