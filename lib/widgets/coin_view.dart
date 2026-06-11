import 'package:flutter/material.dart';

import '../game/reversi_game.dart';
import '../theme/game_theme.dart';

/// A billboarded 3D cylinder coin: a foreshortened elliptical top face plus a
/// visible side wall, so it reads as a thick Othello piece standing on the
/// tilted board. Drawn upright (not inside the board's 3D transform) so the
/// cylinder side always faces the camera — and so a future flip is a simple
/// face-height + colour animation.
class CoinView extends StatelessWidget {
  const CoinView({
    super.key,
    required this.tone,
    required this.width,
    this.faceSquash = 0.74,
    this.thicknessFactor = 0.17,
  });

  /// Which side is showing.
  final Disc tone;

  /// On-screen width (diameter) of the coin face.
  final double width;

  /// Vertical squash of the face to fake the board tilt (1 = circle).
  final double faceSquash;

  /// Side-wall height as a fraction of [width].
  final double thicknessFactor;

  @override
  Widget build(BuildContext context) {
    final faceHeight = width * faceSquash;
    final thickness = width * thicknessFactor;
    return SizedBox(
      width: width,
      height: faceHeight + thickness,
      child: CustomPaint(
        painter: _CoinPainter(
          tone: tone,
          faceHeight: faceHeight,
          thickness: thickness,
        ),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter({
    required this.tone,
    required this.faceHeight,
    required this.thickness,
  });

  final Disc tone;
  final double faceHeight;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = tone == Disc.black;
    final w = size.width;
    final cx = w / 2;
    final faceCenterY = faceHeight / 2;

    final faceRect = Rect.fromCenter(
      center: Offset(cx, faceCenterY),
      width: w,
      height: faceHeight,
    );
    final bottomRect = faceRect.translate(0, thickness);

    // ── side wall ────────────────────────────────────────────────
    final edgeGradient = LinearGradient(
      colors: isDark
          ? const [
              GameColors.coinDarkEdgeDark,
              GameColors.coinDarkEdgeLight,
              GameColors.coinDarkEdgeDark,
            ]
          : const [
              GameColors.coinLightEdgeDark,
              GameColors.coinLightEdgeLight,
              GameColors.coinLightEdgeDark,
            ],
      stops: const [0.0, 0.5, 1.0],
    );
    final wallPaint = Paint()..shader = edgeGradient.createShader(faceRect);

    final wallPath = Path()
      ..moveTo(faceRect.left, faceCenterY)
      ..lineTo(faceRect.left, faceCenterY + thickness)
      ..arcTo(bottomRect, 3.14159, -3.14159, false)
      ..lineTo(faceRect.right, faceCenterY)
      ..arcTo(faceRect, 0, 3.14159, false)
      ..close();
    canvas.drawPath(wallPath, wallPaint);

    // ── top face ─────────────────────────────────────────────────
    final faceGradient = RadialGradient(
      center: const Alignment(-0.24, -0.36),
      radius: 0.95,
      colors: isDark
          ? const [
              GameColors.coinDarkFaceTop,
              GameColors.coinDarkFaceMid,
              GameColors.coinDarkFaceBottom,
            ]
          : const [
              GameColors.coinLightFaceTop,
              GameColors.coinLightFaceMid,
              GameColors.coinLightFaceBottom,
            ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawOval(faceRect, Paint()..shader = faceGradient.createShader(faceRect));

    // rim shading
    canvas.drawOval(
      faceRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = faceHeight * 0.04
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.85),
    );

    // ── gloss highlight ──────────────────────────────────────────
    final glossRect = Rect.fromLTWH(
      faceRect.left + w * 0.22,
      faceRect.top + faceHeight * 0.14,
      w * 0.40,
      faceHeight * 0.30,
    );
    final glossGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: isDark ? 0.38 : 0.85),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.72],
    );
    canvas.drawOval(
      glossRect,
      Paint()..shader = glossGradient.createShader(glossRect),
    );
  }

  @override
  bool shouldRepaint(_CoinPainter old) =>
      old.tone != tone ||
      old.faceHeight != faceHeight ||
      old.thickness != thickness;
}
