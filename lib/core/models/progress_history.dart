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
    );
  }
}
