import 'package:flutter/material.dart';

import '../../core/theme/coin_palette.dart';

class CoinView extends StatelessWidget {
  const CoinView({
    super.key,
    required this.palette,
    required this.width,
    this.faceSquash = 0.74,
    this.thicknessFactor = 0.17,
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
    final w = size.width;
    final cx = w / 2;
    final faceCenterY = faceHeight / 2;

    final faceRect = Rect.fromCenter(
      center: Offset(cx, faceCenterY),
      width: w,
      height: faceHeight,
    );
    final bottomRect = faceRect.translate(0, thickness);

    final edgeGradient = LinearGradient(
      colors: [palette.edgeDark, palette.edgeLight, palette.edgeDark],
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

    final glossRect = Rect.fromLTWH(
      faceRect.left + w * 0.22,
      faceRect.top + faceHeight * 0.14,
      w * 0.40,
      faceHeight * 0.30,
    );
    final glossGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: palette.glossAlpha),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.72],
    );
    canvas.drawOval(
        glossRect, Paint()..shader = glossGradient.createShader(glossRect));
  }

  @override
  bool shouldRepaint(_CoinPainter old) =>
      old.palette != palette ||
      old.faceHeight != faceHeight ||
      old.thickness != thickness;
}
