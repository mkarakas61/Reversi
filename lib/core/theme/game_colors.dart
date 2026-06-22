import 'package:flutter/material.dart';

class GameColors {
  GameColors._();

  static const accent = Color(0xFF13A99C);
  static const accent2 = Color(0xFFF4552C);

  static const creamTop = Color(0xFFFFF6E9);
  static const creamBottom = Color(0xFFFFEDD6);

  static const bannerTop = Color(0xFF2FD4C2);
  static const bannerMid = Color(0xFF14B3A6);
  static const bannerBottom = Color(0xFF0E9C91);

  static const ink = Color(0xFF20302E);
  static const inkSoft = Color(0xFF3A4A48);
  static const onAccent = Color(0xFF1F6F67);

  static const avatarDarkTop = Color(0xFF19C2B2);
  static const avatarDarkBottom = Color(0xFF0E9C91);
  static const avatarLightTop = Color(0xFFFF9A4D);
  static const avatarLightBottom = Color(0xFFF4552C);

  static const chipDarkTop = Color(0xFF4A5468);
  static const chipDarkBottom = Color(0xFF11141D);
  static const chipLightTop = Color(0xFFFFFFFF);
  static const chipLightBottom = Color(0xFFC4C8D2);

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

  static const gridLine = Color(0x9E2E1B0B);
  static const gridHi = Color(0x33FFE8C4);
  static const starDot = Color(0xD9281709);
}

const creamShellGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [GameColors.creamTop, GameColors.creamBottom],
);

const bannerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [GameColors.bannerTop, GameColors.bannerMid, GameColors.bannerBottom],
  stops: [0.0, 0.6, 1.0],
);
