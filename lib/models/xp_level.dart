import 'dart:math';

import 'game_stats.dart';

/// XP rewards and level thresholds for the online ranked system.
///
/// XP formula per game:
///   - Base: win=100, draw=40, loss=15
///   - +min(scoreDiff, 30)            — win only
///   - +floor(flippedPieces / 8)
///   - +clamp(oppLevel − myLevel, −4, +8) × 8   — win only
///   - +min(streak, 5) × 5
///
/// Level curve:  xpForLevel(L) = 50 × L × (L − 1)
///               level(xp)     = floor((1 + sqrt(1 + 8×xp/100)) / 2)
abstract final class XpLevel {
  static const int _baseWin = 100;
  static const int _baseDraw = 40;
  static const int _baseLoss = 15;

  /// Total XP required to reach level [L]. Level 1 needs 0 XP.
  static int xpForLevel(int L) {
    assert(L >= 1, 'Level must be ≥ 1');
    return 50 * L * (L - 1);
  }

  /// Level for a player with [xp] total XP (always ≥ 1).
  static int level(int xp) {
    if (xp <= 0) return 1;
    return max(1, ((1 + sqrt(1 + 8 * xp / 100)) / 2).floor());
  }

  /// XP accumulated within the current level (progress toward the next level).
  static int xpIntoLevel(int xp) => xp - xpForLevel(level(xp));

  /// Total XP span of the current level (from its floor to the next level's floor).
  static int xpRangeForLevel(int xp) {
    final L = level(xp);
    return xpForLevel(L + 1) - xpForLevel(L);
  }

  /// Progress through the current level in [0, 1].
  static double levelProgress(int xp) {
    final range = xpRangeForLevel(xp);
    if (range == 0) return 1.0;
    return (xpIntoLevel(xp) / range).clamp(0.0, 1.0);
  }

  /// XP earned for one online game.
  ///
  /// [outcome]       — result from this player's perspective
  /// [scoreDiff]     — |black − white| disc count
  /// [flippedPieces] — total discs flipped by this player
  /// [myLevel]       — this player's level before the game
  /// [oppLevel]      — opponent's level before the game
  /// [streak]        — consecutive wins immediately before this game
  static int earnedXp({
    required GameOutcome outcome,
    required int scoreDiff,
    required int flippedPieces,
    required int myLevel,
    required int oppLevel,
    required int streak,
  }) {
    final base = switch (outcome) {
      GameOutcome.win => _baseWin,
      GameOutcome.draw => _baseDraw,
      GameOutcome.loss => _baseLoss,
    };
    final scoreBonus = outcome == GameOutcome.win ? min(scoreDiff, 30) : 0;
    final flipBonus = (flippedPieces / 8).floor();
    final levelBonus =
        outcome == GameOutcome.win ? (oppLevel - myLevel).clamp(-4, 8) * 8 : 0;
    final streakBonus = min(streak, 5) * 5;
    return base + scoreBonus + flipBonus + levelBonus + streakBonus;
  }
}
