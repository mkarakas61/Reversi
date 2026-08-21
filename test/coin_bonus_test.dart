import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/progress_history.dart';
import 'package:reversi/core/models/wallet.dart';

/// The happy-hour label and the bonus fields on a history row (REV-109/110).
/// The rewards themselves are the server's — these tests cover only what the
/// app claims about them.
void main() {
  /// An instant expressed as Istanbul wall-clock time (fixed UTC+3).
  DateTime istanbul(int hour, [int minute = 0]) =>
      DateTime.utc(2026, 8, 21, hour - 3, minute);

  group('HappyHour', () {
    test('is on from 20:00 up to but not including 22:00', () {
      expect(HappyHour.isActive(istanbul(19, 59)), isFalse);
      expect(HappyHour.isActive(istanbul(20)), isTrue);
      expect(HappyHour.isActive(istanbul(21, 59)), isTrue);
      expect(HappyHour.isActive(istanbul(22)), isFalse);
      expect(HappyHour.isActive(istanbul(4)), isFalse);
    });

    test('judges the window by Istanbul time, not the device time zone', () {
      // Same instant, two time zones: 20:30 in Istanbul is 17:30 UTC.
      final utc = DateTime.utc(2026, 8, 21, 17, 30);
      expect(HappyHour.isActive(utc), isTrue);
      expect(HappyHour.isActive(utc.toLocal()), isTrue);
    });

    test('labels read as whole hours', () {
      expect(HappyHour.startLabel, '20:00');
      expect(HappyHour.endLabel, '22:00');
    });
  });

  group('waiting bonus rates', () {
    test('one match can never pay more for waiting than for winning', () {
      expect(CoinRewards.waitBonusCap, lessThan(CoinRewards.win));
    });
  });

  group('HistoryEntry bonus fields', () {
    test('reads the breakdown the server wrote', () {
      final entry = HistoryEntry.fromMap(const {
        'result': 'win',
        'coinDelta': 23,
        'coins': 151,
        'coinMultiplier': 2,
        'waitBonus': 3,
      });

      expect(entry.coinDelta, 23);
      expect(entry.coinMultiplier, 2);
      expect(entry.waitBonus, 3);
    });

    test('a row from before the bonuses shipped shows no breakdown', () {
      final entry = HistoryEntry.fromMap(const {
        'result': 'loss',
        'coinDelta': 2,
        'coins': 118,
      });

      expect(entry.coinMultiplier, 1, reason: 'no multiplier means ×1');
      expect(entry.waitBonus, 0);
    });
  });
}
