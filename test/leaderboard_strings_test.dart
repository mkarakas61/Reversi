import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';

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
        // units exist to remove, so the two must not read alike.
        expect(s.leaderboardUnitWins, isNot(equals(s.leaderboardUnitTrophies)));
      }
    });
  });
}
