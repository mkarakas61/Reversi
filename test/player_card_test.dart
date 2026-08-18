import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/game/reversi_game.dart';
import 'package:reversi/core/services/settings_storage.dart';
import 'package:reversi/core/settings/app_settings.dart';
import 'package:reversi/features/game/widgets/player_card.dart';

// REV-96: on a timed two-player game the clock was a centred Stack layer
// sitting behind the card's row, so it landed on the same pixels as the player
// name and the two drew over each other. The clock is a row member now. These
// tests pin the two apart at a narrow width, where the old layout broke.

/// Narrower than any phone we target, so a layout that only just fits on a
/// large screen still fails here.
const double _narrow = 360.0;

/// The longest name the game actually produces.
const String _longName = 'Bilgisayar düşünüyor…';

Future<void> _pump(
  WidgetTester tester, {
  String? countdown,
  String name = _longName,
}) async {
  tester.view.physicalSize = const Size(_narrow, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    SettingsScope(
      controller: SettingsController(const AppSettings(), SettingsStorage()),
      child: MaterialApp(
        home: Scaffold(
          body: PlayerCard(
            side: Disc.white,
            name: name,
            mono: 'M',
            score: 32,
            active: true,
            statusText: 'senin sıran',
            coin: CoinColor.turquoise,
            countdown: countdown,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Rect _rectOf(WidgetTester tester, String text) =>
    tester.getRect(find.text(text));

void main() {
  group('PlayerCard layout', () {
    testWidgets('clock and name never share space', (tester) async {
      await _pump(tester, countdown: '0:30');

      final name = _rectOf(tester, _longName);
      final clock = _rectOf(tester, '0:30');

      expect(name.overlaps(clock), isFalse,
          reason: 'name $name overlaps clock $clock — the REV-96 bug');
      // The clock belongs to the right-hand region, past the name.
      expect(clock.left, greaterThanOrEqualTo(name.right));
    });

    testWidgets('clock and score never share space', (tester) async {
      await _pump(tester, countdown: '0:30');

      expect(_rectOf(tester, '0:30').overlaps(_rectOf(tester, '32')), isFalse);
    });

    testWidgets('nothing overflows the card at 360dp', (tester) async {
      await _pump(tester, countdown: '0:30');

      // A RenderFlex overflow would already have thrown; this also catches a
      // clock pushed off the right edge without an overflow error.
      expect(_rectOf(tester, '0:30').right, lessThanOrEqualTo(_narrow));
      expect(tester.takeException(), isNull);
    });

    testWidgets('untimed game gives the name the clock\'s space',
        (tester) async {
      await _pump(tester, countdown: '0:30');
      final timedName = _rectOf(tester, _longName).width;

      await _pump(tester);
      final untimedName = _rectOf(tester, _longName).width;

      expect(find.text('0:30'), findsNothing);
      expect(untimedName, greaterThan(timedName));
    });
  });
}
