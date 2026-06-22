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
    final center = Offset(w / 2, size.height / 2);
    final cosA = cos(angle);
    final ac = cosA.abs();
    final pal = cosA >= 0 ? front : back;

    final faceH = w * _faceSquash * ac;
    final edgeH = max(faceH, w * _thicknessFactor);

    final edgeRect = Rect.fromCenter(center: center, width: w, height: edgeH);
    final edgeShader = LinearGradient(
      colors: [pal.edgeDark, pal.edgeLight, pal.edgeDark],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(edgeRect);
    canvas.drawOval(edgeRect, Paint()..shader = edgeShader);

    if (faceH > 0.5) {
      final faceRect = Rect.fromCenter(
        center: center,
        width: w * 0.93,
        height: faceH * 0.93,
      );
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
          ..strokeWidth = faceH * 0.05
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
