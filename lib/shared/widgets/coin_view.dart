import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/coin_palette.dart';

/// Apparent vertical squash of a resting procedural coin's face: the board is
/// seen at a tilt, so a circle projects to an ellipse this tall.
const double kCoinRestFaceSquash = 0.74;

/// Visible side wall of a resting procedural coin, × its diameter.
const double kCoinRestThickness = 0.17;

/// Paints a coin's top face into [faceRect] — the lit ellipse, its rim
/// highlight and the gloss. Shared by the resting coin ([CoinView]) and the
/// flip animation ([AnimatedDiscView]) so the two can never drift apart.
void paintCoinFace(Canvas canvas, Rect faceRect, CoinPalette palette) {
  final w = faceRect.width;
  final faceHeight = faceRect.height;

  final faceGradient = RadialGradient(
    center: const Alignment(-0.24, -0.36),
    radius: 0.95,
    colors: [palette.faceTop, palette.faceMid, palette.faceBottom],
    stops: const [0.0, 0.5, 1.0],
  );
  canvas.drawOval(
      faceRect, Paint()..shader = faceGradient.createShader(faceRect));

  canvas.drawOval(
    faceRect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceHeight * 0.04
      ..color = Colors.white.withValues(alpha: palette.rimAlpha),
  );

  // The gloss belongs to the face, so it fades out as the face squashes to an
  // edge mid-flip; at rest it is at full strength.
  final glossFade =
      (faceHeight / w / kCoinRestFaceSquash).clamp(0.0, 1.0);
  if (glossFade <= 0.01) return;
  final glossRect = Rect.fromLTWH(
    faceRect.left + w * 0.22,
    faceRect.top + faceHeight * 0.14,
    w * 0.40,
    faceHeight * 0.30,
  );
  final glossGradient = RadialGradient(
    colors: [
      Colors.white.withValues(alpha: palette.glossAlpha * glossFade),
      Colors.white.withValues(alpha: 0.0),
    ],
    stops: const [0.0, 0.72],
  );
  canvas.drawOval(
      glossRect, Paint()..shader = glossGradient.createShader(glossRect));
}

/// Paints the side wall of a coin whose face fills [faceRect]: the cylinder
/// silhouette [wallH] tall, on the near side of the face when [below] (both
/// resting ends of a turn) or over the top when the far rim is coming over
/// mid-turn. [light]/[dark] are the edge tones.
void paintCoinWall(
  Canvas canvas,
  Rect faceRect,
  double wallH,
  bool below,
  Color light,
  Color dark,
) {
  if (wallH <= 0.2) return;
  final faceCenterY = faceRect.center.dy;
  final capRect = faceRect.translate(0, below ? wallH : -wallH);

  final wallPaint = Paint()
    ..shader = LinearGradient(
      colors: [dark, light, dark],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(faceRect);

  // One path: down (or up) one side, around the rim cap, then back along the
  // face's near arc.
  final wallPath = below
      ? (Path()
        ..moveTo(faceRect.left, faceCenterY)
        ..lineTo(faceRect.left, faceCenterY + wallH)
        ..arcTo(capRect, math.pi, -math.pi, false)
        ..lineTo(faceRect.right, faceCenterY)
        ..arcTo(faceRect, 0, math.pi, false)
        ..close())
      : (Path()
        ..moveTo(faceRect.left, faceCenterY)
        ..lineTo(faceRect.left, faceCenterY - wallH)
        ..arcTo(capRect, math.pi, math.pi, false)
        ..lineTo(faceRect.right, faceCenterY)
        ..arcTo(faceRect, 0, -math.pi, false)
        ..close());
  canvas.drawPath(wallPath, wallPaint);
}

class CoinView extends StatelessWidget {
  const CoinView({
    super.key,
    required this.palette,
    required this.width,
    this.faceSquash = kCoinRestFaceSquash,
    this.thicknessFactor = kCoinRestThickness,
  });

  final CoinPalette palette;
  final double width;
  final double faceSquash;
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
          palette: palette,
          faceHeight: faceHeight,
          thickness: thickness,
        ),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter({
    required this.palette,
    required this.faceHeight,
    required this.thickness,
  });

  final CoinPalette palette;
  final double faceHeight;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final faceRect = Rect.fromLTWH(0, 0, size.width, faceHeight);
    paintCoinWall(
        canvas, faceRect, thickness, true, palette.edgeLight, palette.edgeDark);
    paintCoinFace(canvas, faceRect, palette);
  }

  @override
  bool shouldRepaint(_CoinPainter old) =>
      old.palette != palette ||
      old.faceHeight != faceHeight ||
      old.thickness != thickness;
}
