import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/rank.dart';

// Mirrors functions/src/trophy.test.ts — the client rank thresholds MUST match
// the server. If one side changes, this parity test (and its TS twin) breaks.
void main() {
  group('rankFor', () {
    test('Çaylak at zero and below the first threshold', () {
      expect(rankFor(0).id, RankId.caylak);
      expect(rankFor(29).id, RankId.caylak);
    });

    test('lands exactly on each threshold', () {
      expect(rankFor(30).id, RankId.acemi);
      expect(rankFor(100).id, RankId.kalfa);
      expect(rankFor(250).id, RankId.usta);
      expect(rankFor(550).id, RankId.buyukusta);
      expect(rankFor(1000).id, RankId.efsane);
    });

    test('stays at Efsane far above the top threshold', () {
      expect(rankFor(99999).id, RankId.efsane);
    });

    test('never below Çaylak for negatives', () {
      expect(rankFor(-5).id, RankId.caylak);
    });
  });

  group('trophiesToNext', () {
    test('counts trophies to the next threshold', () {
      expect(trophiesToNext(0), 30); // to Acemi
      expect(trophiesToNext(90), 10); // to Kalfa (100)
    });

    test('is null at the top rank', () {
      expect(trophiesToNext(1000), isNull);
      expect(trophiesToNext(5000), isNull);
    });
  });

  group('rankProgress', () {
    test('is 0 at a rank floor and ~1 just below the next', () {
      expect(rankProgress(100), 0.0); // Kalfa floor
      expect(rankProgress(250) > 0.99, isFalse); // 250 is the Usta floor → 0
      expect(rankProgress(175), closeTo(0.5, 0.001)); // halfway 100→250
    });

    test('is 1.0 at the top rank', () {
      expect(rankProgress(1000), 1.0);
      expect(rankProgress(3000), 1.0);
    });
  });
}
