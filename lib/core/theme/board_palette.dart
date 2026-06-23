import 'package:flutter/material.dart';

import '../settings/app_settings.dart';

class BoardPalette {
  const BoardPalette({
    required this.frame,
    required this.surface,
    required this.line,
    required this.lineHi,
    required this.star,
    this.marble = false,
  });

  final List<Color> frame;
  final List<Color> surface;
  final Color line;
  final Color lineHi;
  final Color star;

  /// When true, painters overlay soft diagonal veins for a marble look.
  final bool marble;

  Gradient get frameGradient => LinearGradient(
        begin: const Alignment(-0.342, -0.940),
        end: const Alignment(0.342, 0.940),
        colors: frame,
      );

  Gradient get surfaceGradient => RadialGradient(
        center: const Alignment(-0.44, -0.68),
        radius: 1.35,
        colors: surface,
        stops: const [0.0, 0.55, 1.0],
      );
}

const Map<BoardTheme, BoardPalette> boardPalettes = {
  BoardTheme.turkuaz: BoardPalette(
    frame: [Color(0xFF15A99C), Color(0xFF0C7D72)],
    surface: [Color(0xFF1AB9AA), Color(0xFF119A8C), Color(0xFF0C8175)],
    line: Color.fromRGBO(4, 46, 42, 0.50),
    lineHi: Color.fromRGBO(220, 255, 249, 0.18),
    star: Color.fromRGBO(4, 46, 42, 0.78),
  ),
  BoardTheme.gece: BoardPalette(
    frame: [Color(0xFF36425F), Color(0xFF232C44)],
    surface: [Color(0xFF3F4D70), Color(0xFF2E3A58), Color(0xFF232C44)],
    line: Color.fromRGBO(9, 14, 30, 0.55),
    lineHi: Color.fromRGBO(190, 206, 255, 0.14),
    star: Color.fromRGBO(9, 14, 30, 0.82),
  ),
  BoardTheme.antrasit: BoardPalette(
    frame: [Color(0xFF15A99C), Color(0xFF0B6F66)],
    surface: [Color(0xFF3A434F), Color(0xFF2C333D), Color(0xFF242A33)],
    line: Color.fromRGBO(8, 11, 16, 0.52),
    lineHi: Color.fromRGBO(205, 222, 235, 0.12),
    star: Color.fromRGBO(8, 11, 16, 0.80),
  ),
  BoardTheme.petrol: BoardPalette(
    frame: [Color(0xFF0D7268), Color(0xFF06433D)],
    surface: [Color(0xFF0F8478), Color(0xFF0A655C), Color(0xFF074C45)],
    line: Color.fromRGBO(2, 30, 27, 0.55),
    lineHi: Color.fromRGBO(180, 255, 246, 0.13),
    star: Color.fromRGBO(2, 30, 27, 0.82),
  ),
  BoardTheme.mermer: BoardPalette(
    frame: [Color(0xFF9298A0), Color(0xFF595E66)],
    surface: [Color(0xFFA8AEB6), Color(0xFF8B9199), Color(0xFF6F757D)],
    line: Color.fromRGBO(38, 42, 48, 0.50),
    lineHi: Color.fromRGBO(232, 236, 240, 0.32),
    star: Color.fromRGBO(34, 38, 44, 0.70),
    marble: true,
  ),
};

/// Draws soft, semi-transparent diagonal veins to evoke a polished marble
/// surface. Coordinates are fractions of [size] so veins scale with the board;
/// stroke widths scale relative to a ~320px reference board.
void paintMarbleVeins(Canvas canvas, Size size) {
  void vein(double x1, double y1, double cx, double cy, double x2, double y2,
      Color color, double width) {
    final path = Path()
      ..moveTo(x1 * size.width, y1 * size.height)
      ..quadraticBezierTo(
          cx * size.width, cy * size.height, x2 * size.width, y2 * size.height);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * (size.width / 320)
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
    );
  }

  vein(0.04, 0.0, 0.42, 0.34, 0.82, 1.0, const Color(0x3A262A30), 2.6);
  vein(0.50, 0.0, 0.66, 0.28, 1.0, 0.52, const Color(0x30262A30), 1.9);
  vein(0.0, 0.42, 0.22, 0.55, 0.46, 0.82, const Color(0x28262A30), 1.6);
  vein(0.22, 0.0, 0.40, 0.50, 0.60, 1.0, const Color(0x26FFFFFF), 1.4);
  vein(0.60, 0.10, 0.78, 0.40, 0.95, 0.85, const Color(0x20FFFFFF), 1.2);
}
