import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/coin_palette.dart';

class FlipCoin extends StatelessWidget {
  const FlipCoin({
    super.key,
    required this.width,
    required this.angle,
    required this.front,
    required this.back,
  });

  final double width;
  final double angle;
  final CoinPalette front;
  final CoinPalette back;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width,
      child: CustomPaint(
        painter: FlipCoinPainter(angle: angle, front: front, back: back),
      ),
    );
  }
}

class FlipCoinPainter extends CustomPainter {
  FlipCoinPainter({
    required this.angle,
    required this.front,
    required this.back,
  });

  final double angle;
  final CoinPalette front;
  final CoinPalette back;

  static const _faceSquash = 0.74;
  static const _thicknessFactor = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // True projection of a coin tipping over toward the viewer, at the
    // viewing tilt implied by the resting squash. The choreography this
    // produces: the old face first turns square to the camera, then rolls
    // UNDER the far rim as that rim comes over the top, the coin stands
    // edge-on, and the new face opens from beneath — the old color
    // visibly ends up underneath, like a hand turning over.
    final e = asin(_faceSquash); // camera elevation from the rest squash
    final phase = angle + e;
    final faceK = sin(phase); // signed apparent face squash
    final ac = faceK.abs();
    final pal = faceK >= 0 ? front : back;

    final faceH = w * ac;
    // Visible rim: gone while the face is square to the camera, full
    // checkers-piece thickness when the coin stands on edge.
    final wallK = cos(phase);
    final wallH = w * _thicknessFactor * wallK.abs() / cos(e);
    // Which side of the face the rim shows on: below at both resting
    // ends, above while the far rim is coming over the top mid-turn.
    final below = faceK * wallK >= 0;

    // Face ellipse anchored at the box center — at both ends of the turn
    // this overlays the resting CoinView exactly, so the handoff to the
    // static coin is seamless.
    final faceCenterY = size.height / 2;
    final faceRect = Rect.fromCenter(
      center: Offset(w / 2, faceCenterY),
      width: w,
      height: max(faceH, 1.0),
    );
    final capRect = faceRect.translate(0, below ? wallH : -wallH);

    // Cylinder silhouette in one path: along one side, around the rim
    // cap, back along the face's near arc.
    final wallPaint = Paint()
      ..shader = LinearGradient(
        colors: [pal.edgeDark, pal.edgeLight, pal.edgeDark],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(faceRect);
    final wallPath = below
        ? (Path()
          ..moveTo(faceRect.left, faceCenterY)
          ..lineTo(faceRect.left, faceCenterY + wallH)
          ..arcTo(capRect, pi, -pi, false)
          ..lineTo(faceRect.right, faceCenterY)
          ..arcTo(faceRect, 0, pi, false)
          ..close())
        : (Path()
          ..moveTo(faceRect.left, faceCenterY)
          ..lineTo(faceRect.left, faceCenterY - wallH)
          ..arcTo(capRect, pi, pi, false)
          ..lineTo(faceRect.right, faceCenterY)
          ..arcTo(faceRect, 0, -pi, false)
          ..close());
    canvas.drawPath(wallPath, wallPaint);

    if (faceH > 0.5) {
      final faceShader = RadialGradient(
        center: const Alignment(-0.24, -0.36),
        radius: 0.95,
        colors: [pal.faceTop, pal.faceMid, pal.faceBottom],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(faceRect);
      canvas.drawOval(faceRect, Paint()..shader = faceShader);

      canvas.drawOval(
        faceRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceH * 0.04
          ..color = Colors.white.withValues(alpha: pal.rimAlpha),
      );

      if (ac > 0.25) {
        final glossRect = Rect.fromLTWH(
          faceRect.left + w * 0.24,
          faceRect.top + faceH * 0.12,
          w * 0.34,
          faceH * 0.26,
        );
        final glossShader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: pal.glossAlpha * ac),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.72],
        ).createShader(glossRect);
        canvas.drawOval(glossRect, Paint()..shader = glossShader);
      }
    }
  }

  @override
  bool shouldRepaint(FlipCoinPainter old) =>
      old.angle != angle || old.front != front || old.back != back;
}
