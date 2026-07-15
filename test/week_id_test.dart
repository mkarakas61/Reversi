import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/week_id.dart';

void main() {
  group('weekId', () {
    test('returns the ISO week for an ordinary mid-year date', () {
      expect(weekId(DateTime.utc(2026, 6, 19, 12)), '2026-W25');
    });

    test('handles the first ISO week of a year', () {
      expect(weekId(DateTime.utc(2026, 1, 1, 12)), '2026-W01');
    });

    test('assigns late-December dates to next year\'s week 1 when applicable',
        () {
      expect(weekId(DateTime.utc(2025, 12, 29, 12)), '2026-W01');
    });

    test('handles a 53-week year\'s final week', () {
      expect(weekId(DateTime.utc(2026, 12, 31, 12)), '2026-W53');
    });
  });
}
