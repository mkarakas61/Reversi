import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/settings/app_settings.dart';
import 'package:reversi/core/theme/coin_palette.dart';
import 'package:reversi/shared/widgets/coin_view.dart';
import 'package:reversi/shared/widgets/disc_view.dart';

// REV-89: every disc lying on the board rests at the same elevation. Procedural
// coins always did; image discs used to be stamped at full height, so half the
// board looked at from above and half from the board's own angle. These tests
// lock the two kinds to one pose — the pose AnimatedDiscView settles into, so a
// finished turn lands flush with the resting disc rather than popping.

const double _size = 100.0;

/// The squashed PNG of the image disc [tester] just pumped.
Rect _faceRect(WidgetTester tester) => tester.getRect(find.byType(Image));

/// The whole image disc — face plus the wall under it. Found through the Image
/// so it cannot pick up MaterialApp's own full-screen painters.
Rect _discRect(WidgetTester tester) => tester.getRect(
      find
          .ancestor(of: find.byType(Image), matching: find.byType(Stack))
          .first,
    );

Future<void> _pump(WidgetTester tester, CoinColor coin) => tester.pumpWidget(
      MaterialApp(
        home: Center(child: DiscView(coin: coin, size: _size)),
      ),
    );

void main() {
  group('resting disc elevation', () {
    testWidgets('an image disc rests squashed, not full height',
        (tester) async {
      await _pump(tester, CoinColor.walnut);

      final face = _faceRect(tester);
      expect(face.width, closeTo(_size, 0.01));
      // Full height would mean the PNG is stamped straight down — the bug.
      expect(face.height, closeTo(_size * kCoinRestFaceSquash, 0.01));
    });

    testWidgets('every image disc rests at the same elevation',
        (tester) async {
      for (final coin in coinAssets.keys) {
        await _pump(tester, coin);
        expect(_faceRect(tester).height, closeTo(_size * kCoinRestFaceSquash, 0.01),
            reason: '$coin face height');
      }
    });

    testWidgets('an image disc stands on a wall, so it reads as solid',
        (tester) async {
      await _pump(tester, CoinColor.maple);

      // The disc's box is the face plus the side wall under it.
      final wall = _discRect(tester).height - _size * kCoinRestFaceSquash;
      final expected =
          _size * 0.25 * math.cos(math.asin(kCoinRestFaceSquash));
      expect(wall, closeTo(expected, 0.01));
      // Same wall a procedural coin rests on, so the two kinds sit level.
      expect(wall / _size, closeTo(kCoinRestThickness, 0.01));
    });

    testWidgets('image and procedural discs occupy the same height',
        (tester) async {
      await _pump(tester, CoinColor.walnut);
      final assetBox = _discRect(tester).height;

      await _pump(tester, CoinColor.turquoise);
      final proceduralBox = tester.getRect(find.byType(CoinView)).height;

      expect(assetBox, closeTo(proceduralBox, 1.0));
    });
  });
}
