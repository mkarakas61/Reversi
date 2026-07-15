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
  });

  final DateTime ts;

  /// 'win' | 'loss' | 'draw'.
  final String result;
  final int scoreDiff;
  final int flipped;
  final int oppLevel;

  bool get isWin => result == 'win';

  factory HistoryEntry.fromMap(Map<String, dynamic> data) {
    final ts = data['ts'];
    return HistoryEntry(
      ts: ts is Timestamp ? ts.toDate() : DateTime.now(),
      result: data['result'] as String? ?? 'draw',
      scoreDiff: (data['scoreDiff'] as num?)?.toInt() ?? 0,
      flipped: (data['flipped'] as num?)?.toInt() ?? 0,
      oppLevel: (data['oppLevel'] as num?)?.toInt() ?? 1,
    );
  }
}
