import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/rank.dart';
import 'package:reversi/shared/widgets/rank_frame_view.dart';

// REV-61 avatar frames. The geometry here is measured off the shipped art, so
// these tests are really about the art and the code staying in step: swap a PNG
// for one with a different opening and the numbers in rank.dart go stale
// silently — the avatar just drifts out of its frame on one rank.
void main() {
  group('RankFrame data', () {
    test('every rank carries a frame under assets/frames/tier/', () {
      for (final rank in kRanks) {
        expect(rank.frame.asset, startsWith('assets/frames/tier/'),
            reason: '${rank.id} frame asset path');
        expect(rank.frame.asset, endsWith('.png'));
      }
    });

    test('no two ranks share the same art', () {
      final assets = kRanks.map((r) => r.frame.asset).toSet();
      expect(assets, hasLength(kRanks.length));
    });

    test('every frame file is really bundled', () async {
      for (final rank in kRanks) {
        final bytes = await rootBundle.load(rank.frame.asset);
        expect(bytes.lengthInBytes, greaterThan(0),
            reason: '${rank.frame.asset} is empty');
      }
    });

    test('openings are fractions that leave a usable hole', () {
      for (final rank in kRanks) {
        final frame = rank.frame;
        // Below ~0.3 the frame would be all ornament and no face; at 1.0 there
        // would be no ring left to see.
        expect(frame.openingFraction, inInclusiveRange(0.3, 1.0),
            reason: '${rank.id} openingFraction');
        expect(frame.centerX, inInclusiveRange(0.0, 1.0));
        expect(frame.centerY, inInclusiveRange(0.0, 1.0));
      }
    });

    test('the opening stays inside the canvas', () {
      for (final rank in kRanks) {
        final f = rank.frame;
        final half = f.openingFraction / 2;
        expect(f.centerX - half, greaterThanOrEqualTo(0.0),
            reason: '${rank.id} opening runs off the left edge');
        expect(f.centerX + half, lessThanOrEqualTo(1.0),
            reason: '${rank.id} opening runs off the right edge');
        expect(f.centerY - half, greaterThanOrEqualTo(0.0),
            reason: '${rank.id} opening runs off the top edge');
        expect(f.centerY + half, lessThanOrEqualTo(1.0),
            reason: '${rank.id} opening runs off the bottom edge');
      }
    });

    test('frameSizeFor scales the canvas up from the wanted opening', () {
      // Çaylak's opening is ~0.73 of the canvas, so a 96pt opening needs a
      // frame a touch over 131pt.
      final caylak = kRanks.first.frame;
      expect(caylak.frameSizeFor(96), closeTo(96 / caylak.openingFraction, 0.01));

      // The crowned frames spend far more canvas on ornament, so the same
      // avatar gets a visibly bigger frame — that is the whole point.
      final efsane = kRanks.last.frame;
      expect(efsane.frameSizeFor(96), greaterThan(caylak.frameSizeFor(96)));
    });
  });

  group('RankFrameView', () {
    testWidgets('around() sizes the frame so the opening matches the avatar',
        (tester) async {
      const key = Key('child');
      final frame = kRanks.last.frame; // Efsane — the smallest opening.

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: RankFrameView.around(
            frame: frame,
            openingDiameter: 96,
            child: Container(key: key, color: const Color(0xFF000000)),
          ),
        ),
      ));

      expect(tester.getSize(find.byKey(key)), const Size(96, 96));
      expect(
        tester.getSize(find.byType(RankFrameView)).width,
        closeTo(frame.frameSizeFor(96), 0.01),
      );
    });

    testWidgets('boxed() keeps the outer box fixed across ranks',
        (tester) async {
      for (final rank in [kRanks.first, kRanks.last]) {
        await tester.pumpWidget(MaterialApp(
          home: Center(
            child: RankFrameView.boxed(frame: rank.frame, size: 56),
          ),
        ));
        expect(tester.getSize(find.byType(RankFrameView)), const Size(56, 56),
            reason: '${rank.id} boxed preview');
      }
    });

    testWidgets('the child sits on the measured opening, not the canvas centre',
        (tester) async {
      const key = Key('child');
      // Efsane's opening is pushed well below centre by the crown.
      final frame = kRanks.last.frame;
      expect(frame.centerY, greaterThan(0.5),
          reason: 'this test only means something for an off-centre opening');

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: RankFrameView.around(
            frame: frame,
            openingDiameter: 96,
            child: Container(key: key, color: const Color(0xFF000000)),
          ),
        ),
      ));

      final frameRect = tester.getRect(find.byType(RankFrameView));
      final childCenter = tester.getCenter(find.byKey(key));
      expect(childCenter.dy, greaterThan(frameRect.center.dy),
          reason: 'child should hang below the canvas centre');
      expect(
        childCenter.dy - frameRect.top,
        closeTo(frameRect.height * frame.centerY, 0.01),
      );
    });
  });
}
