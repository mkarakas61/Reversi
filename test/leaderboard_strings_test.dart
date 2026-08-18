import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';
import 'package:reversi/core/theme/metric_marks.dart';

// REV-97: the leaderboard's "your rank" header used to read 'Senin sıran' in
// Turkish — word for word the in-game "your move" label. "Sıra" means both
// *turn* and *ranking*, so on the leaderboard it read as the wrong one. These
// tests keep the two apart and keep the ranked value from losing its unit.
void main() {
  final tr = AppStrings(const Locale('tr'));
  final en = AppStrings(const Locale('en'));

  group('leaderboard wording', () {
    test('"your rank" is never the same string as "your move"', () {
      for (final s in [tr, en]) {
        expect(s.leaderboardYourRank, isNot(equals(s.yourMove)),
            reason: '${s.locale.languageCode}: rank label collides with turn '
                'label — the REV-97 bug');
      }
    });

    test('Turkish "your rank" reads as a ranking, not a turn', () {
      expect(tr.leaderboardYourRank, 'Sıralaman');
    });

    test('both metrics carry a unit in every locale', () {
      for (final s in [tr, en]) {
        expect(s.leaderboardUnitWins, isNotEmpty);
        expect(s.leaderboardUnitTrophies, isNotEmpty);
        // A bare number under a swappable metric column is the ambiguity the
        // units exist to remove, so the two must not read alike. Rows show a
        // mark instead; these words are what screen readers get.
        expect(s.leaderboardUnitWins, isNot(equals(s.leaderboardUnitTrophies)));
      }
    });
  });

  group('metric marks', () {
    test('wins and trophies never share a mark', () {
      // The two metrics swap under the same column, so a shared mark would put
      // the reader back where REV-97 started.
      expect(kWinsMark, isNot(equals(kTrophyMark)));
    });

    test('marks are present', () {
      expect(kWinsMark, isNotEmpty);
      expect(kTrophyMark, isNotEmpty);
    });
  });
}
