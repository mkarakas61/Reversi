import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';
import 'package:reversi/core/services/online_game_service.dart';

// REV-108: a teammate playing on a weak connection was thrown out of a live
// match and the opponent took the win. The claim window was 10 s — barely
// three heartbeats — so ordinary mobile latency read as a quit. The window is
// now 30 s, with a "reconnecting" message covering the wait so the board is
// never silently frozen.
void main() {
  final tr = AppStrings(const Locale('tr'));
  final en = AppStrings(const Locale('en'));

  group('disconnect thresholds', () {
    test('the claim window survives ordinary mobile latency', () {
      // Heartbeats go out every 3 s; anything under ~5 missed writes turns a
      // stalled connection into a lost match.
      expect(OnlineGameService.disconnectAfter,
          greaterThanOrEqualTo(const Duration(seconds: 30)));
    });

    test('the player is told before the match is taken from them', () {
      expect(OnlineGameService.reconnectingAfter,
          lessThan(OnlineGameService.disconnectAfter),
          reason: 'a silent freeze until the claim reads as a broken app');
    });

    test('"reconnecting" exists in both locales and is its own message', () {
      for (final s in [tr, en]) {
        expect(s.opponentReconnecting, isNotEmpty);
        expect(s.opponentReconnecting, isNot(equals(s.opponentTurn)),
            reason: '${s.locale.languageCode}: a stalled opponent must not '
                'read as an ordinary turn');
      }
    });
  });
}
