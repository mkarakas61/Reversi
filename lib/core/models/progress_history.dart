import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One row from `users/{uid}/history` — a single finished online game, written
/// server-side by `finish_game.ts` (REV-54). Powers the progress trend charts
/// on the online stats screen (REV-58).
@immutable
class HistoryEntry {
  const HistoryEntry({
    required this.ts,
    required this.result,
    required this.scoreDiff,
    required this.flipped,
    required this.oppLevel,
    this.trophyDelta = 0,
    this.trophies = 0,
    this.coinDelta = 0,
    this.coins = 0,
    this.coinMultiplier = 1,
    this.waitBonus = 0,
  });

  final DateTime ts;

  /// 'win' | 'loss' | 'draw'.
  final String result;
  final int scoreDiff;
  final int flipped;
  final int oppLevel;

  /// Trophies gained (+) or lost (−) in this game, and the resulting total
  /// after it (REV-73). Both are 0 on games recorded before the trophy system
  /// shipped. The match-result screen (REV-74) shows these.
  final int trophyDelta;
  final int trophies;

  /// Coins earned in this game and the resulting balance (REV-102). Both are 0
  /// on games recorded before the fields shipped, so the result screen shows
  /// the coin line only when [coinDelta] is greater than 0 — every real online
  /// game pays out at least 2.
  final int coinDelta;
  final int coins;

  /// The breakdown behind [coinDelta] (REV-109/110): the happy-hour multiplier
  /// in effect when the game finished, and the queue-wait bonus folded into it.
  /// Rows written before these shipped read back as 1 and 0, so the result
  /// screen simply shows no breakdown for them.
  final int coinMultiplier;
  final int waitBonus;

  bool get isWin => result == 'win';

  factory HistoryEntry.fromMap(Map<String, dynamic> data) {
    final ts = data['ts'];
    return HistoryEntry(
      ts: ts is Timestamp ? ts.toDate() : DateTime.now(),
      result: data['result'] as String? ?? 'draw',
      scoreDiff: (data['scoreDiff'] as num?)?.toInt() ?? 0,
      flipped: (data['flipped'] as num?)?.toInt() ?? 0,
      oppLevel: (data['oppLevel'] as num?)?.toInt() ?? 1,
      trophyDelta: (data['trophyDelta'] as num?)?.toInt() ?? 0,
      trophies: (data['trophies'] as num?)?.toInt() ?? 0,
      coinDelta: (data['coinDelta'] as num?)?.toInt() ?? 0,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      coinMultiplier: (data['coinMultiplier'] as num?)?.toInt() ?? 1,
      waitBonus: (data['waitBonus'] as num?)?.toInt() ?? 0,
    );
  }
}
