import 'package:flutter/material.dart';

import '../settings/app_settings.dart';

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
  final double rimAlpha;
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
