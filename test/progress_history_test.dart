import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/progress_history.dart';

void main() {
  group('HistoryEntry', () {
    test('fromMap reads all fields', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 6, 19, 12));
      final entry = HistoryEntry.fromMap({
        'ts': ts,
        'result': 'win',
        'scoreDiff': 14,
        'flipped': 22,
        'oppLevel': 7,
      });
      expect(entry.ts, ts.toDate());
      expect(entry.result, 'win');
      expect(entry.isWin, true);
      expect(entry.scoreDiff, 14);
      expect(entry.flipped, 22);
      expect(entry.oppLevel, 7);
    });

    test('isWin is false for a loss or a draw', () {
      expect(HistoryEntry.fromMap(const {'result': 'loss'}).isWin, false);
      expect(HistoryEntry.fromMap(const {'result': 'draw'}).isWin, false);
    });

    test('fromMap tolerates missing numeric fields', () {
      final entry = HistoryEntry.fromMap(const {'result': 'win'});
      expect(entry.scoreDiff, 0);
      expect(entry.flipped, 0);
      expect(entry.oppLevel, 1);
    });
  });
}
