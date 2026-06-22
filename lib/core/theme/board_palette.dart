import 'package:flutter/material.dart';

import '../settings/app_settings.dart';

class BoardPalette {
  const BoardPalette({
    required this.frame,
    required this.surface,
    required this.line,
    required this.lineHi,
    required this.star,
  });

  final List<Color> frame;
  final List<Color> surface;
  final Color line;
  final Color lineHi;
  final Color star;

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
};
