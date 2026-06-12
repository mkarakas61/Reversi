import 'package:flutter/material.dart';

import '../game/app_settings.dart';

/// Palette and shared styling for the wooden "Ahşap v2" design.
class GameColors {
  GameColors._();

  // Brand accents.
  static const accent = Color(0xFF13A99C); // turquoise (dark side / "Sen")
  static const accent2 = Color(0xFFF4552C); // orange (light side / "Aria")

  // Cream app shell.
  static const creamTop = Color(0xFFFFF6E9);
  static const creamBottom = Color(0xFFFFEDD6);

  // Turquoise banner gradient (top of the game screen / whole menu bg).
  static const bannerTop = Color(0xFF2FD4C2);
  static const bannerMid = Color(0xFF14B3A6);
  static const bannerBottom = Color(0xFF0E9C91);

  // Text.
  static const ink = Color(0xFF20302E);
  static const inkSoft = Color(0xFF3A4A48);
  static const onAccent = Color(0xFF1F6F67);

  // Avatars.
  static const avatarDarkTop = Color(0xFF19C2B2);
  static const avatarDarkBottom = Color(0xFF0E9C91);
  static const avatarLightTop = Color(0xFFFF9A4D);
  static const avatarLightBottom = Color(0xFFF4552C);

  // Chips (small score discs).
  static const chipDarkTop = Color(0xFF4A5468);
  static const chipDarkBottom = Color(0xFF11141D);
  static const chipLightTop = Color(0xFFFFFFFF);
  static const chipLightBottom = Color(0xFFC4C8D2);

  // Coins.
  static const coinDarkFaceTop = Color(0xFF555E6B);
  static const coinDarkFaceMid = Color(0xFF2B3039);
  static const coinDarkFaceBottom = Color(0xFF11141A);
  static const coinDarkEdgeLight = Color(0xFF303641);
  static const coinDarkEdgeDark = Color(0xFF0B0E13);

  static const coinLightFaceTop = Color(0xFFFFFFFF);
  static const coinLightFaceMid = Color(0xFFEEF0F4);
  static const coinLightFaceBottom = Color(0xFFCDD2DC);
  static const coinLightEdgeLight = Color(0xFFDADDE3);
  static const coinLightEdgeDark = Color(0xFF8F96A3);

  // Board grid.
  static const gridLine = Color(0x9E2E1B0B); // rgba(46,27,11,0.62)
  static const gridHi = Color(0x33FFE8C4); // rgba(255,232,196,0.20)
  static const starDot = Color(0xD9281709); // rgba(40,23,9,0.85)
}

class GameText {
  GameText._();

  static const display = TextStyle(
    fontFamily: 'Baloo2',
    fontWeight: FontWeight.w800,
  );

  static const body = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w700,
  );
}

/// The cream → cream vertical shell background.
const creamShellGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [GameColors.creamTop, GameColors.creamBottom],
);

/// The turquoise banner gradient (135deg in the design).
const bannerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [GameColors.bannerTop, GameColors.bannerMid, GameColors.bannerBottom],
  stops: [0.0, 0.6, 1.0],
);

// ─────────────────────────────────────────────────────────────────────────
// Board palettes — flat colour slabs from the "Renkli Tahta" design. [wood]
// is rendered from image textures instead and has no entry here.
// ─────────────────────────────────────────────────────────────────────────

/// Flat-colour board slab description. Frame/surface use gradients; the grid
/// strokes and star dots reuse the engraved-line colours.
class BoardPalette {
  const BoardPalette({
    required this.frame,
    required this.surface,
    required this.line,
    required this.lineHi,
    required this.star,
  });

  /// Frame fill — CSS `linear-gradient(160deg, …)`.
  final List<Color> frame;

  /// Playfield fill — CSS `radial-gradient(135% 135% at 28% 16%, …)`.
  final List<Color> surface;

  final Color line;
  final Color lineHi;
  final Color star;

  /// CSS `160deg` linear gradient mapped to begin/end alignments.
  Gradient get frameGradient => LinearGradient(
        begin: const Alignment(-0.342, -0.940),
        end: const Alignment(0.342, 0.940),
        colors: frame,
      );

  /// CSS `radial-gradient(135% 135% at 28% 16%, …)`.
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

// ─────────────────────────────────────────────────────────────────────────
// Coin skins — the four selectable disc colours.
// ─────────────────────────────────────────────────────────────────────────

/// Colour ramp for a single 3D cylinder coin.
class CoinPalette {
  const CoinPalette({
    required this.faceTop,
    required this.faceMid,
    required this.faceBottom,
    required this.edgeLight,
    required this.edgeDark,
    required this.rimAlpha,
    required this.glossAlpha,
  });

  final Color faceTop;
  final Color faceMid;
  final Color faceBottom;
  final Color edgeLight;
  final Color edgeDark;

  /// White rim-stroke opacity (lighter coins get a brighter rim).
  final double rimAlpha;

  /// Gloss-highlight opacity.
  final double glossAlpha;
}

const Map<CoinColor, CoinPalette> coinPalettes = {
  CoinColor.black: CoinPalette(
    faceTop: Color(0xFF555E6B),
    faceMid: Color(0xFF2B3039),
    faceBottom: Color(0xFF11141A),
    edgeLight: Color(0xFF303641),
    edgeDark: Color(0xFF0B0E13),
    rimAlpha: 0.16,
    glossAlpha: 0.38,
  ),
  CoinColor.white: CoinPalette(
    faceTop: Color(0xFFFFFFFF),
    faceMid: Color(0xFFEEF0F4),
    faceBottom: Color(0xFFCDD2DC),
    edgeLight: Color(0xFFDADDE3),
    edgeDark: Color(0xFF8F96A3),
    rimAlpha: 0.85,
    glossAlpha: 0.85,
  ),
  CoinColor.turquoise: CoinPalette(
    faceTop: Color(0xFF5FE6D8),
    faceMid: Color(0xFF16B8A9),
    faceBottom: Color(0xFF0B8074),
    edgeLight: Color(0xFF1FC7B8),
    edgeDark: Color(0xFF0A6258),
    rimAlpha: 0.55,
    glossAlpha: 0.62,
  ),
  CoinColor.orange: CoinPalette(
    faceTop: Color(0xFFFFB070),
    faceMid: Color(0xFFF4552C),
    faceBottom: Color(0xFFC23415),
    edgeLight: Color(0xFFFF8A52),
    edgeDark: Color(0xFFA82A10),
    rimAlpha: 0.5,
    glossAlpha: 0.6,
  ),
};
