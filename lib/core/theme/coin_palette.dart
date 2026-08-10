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

/// Image-disc skins (REV-82): the walnut/maple wood discs, marble discs and
/// floral discs, previously baked into the wood/marble/flower boards, are now
/// first-class selectable coins usable on any board. A coin is procedural when
/// it has a [coinPalettes] entry, and an image disc when it has one here.
const Map<CoinColor, String> coinAssets = {
  CoinColor.walnut: 'assets/wood/disc-walnut.png',
  CoinColor.maple: 'assets/wood/disc-maple.png',
  CoinColor.marbleBlack: 'assets/marble/disc-marble-black.png',
  CoinColor.marbleWhite: 'assets/marble/disc-marble-white.png',
  CoinColor.flowerPurple: 'assets/flower/disc-flower-black.png',
  CoinColor.flowerPink: 'assets/flower/disc-flower-white.png',
};

/// Whether [coin] is an image disc (vs a procedural coin).
bool isAssetCoin(CoinColor coin) => coinAssets.containsKey(coin);

// Representative accent colour for the image discs (for score chips, brightness
// checks and small color cues where a full disc isn't drawn).
const Map<CoinColor, Color> _coinAccents = {
  CoinColor.walnut: Color(0xFF5A3A1E),
  CoinColor.maple: Color(0xFFD9B071),
  CoinColor.marbleBlack: Color(0xFF2A2A2E),
  CoinColor.marbleWhite: Color(0xFFDBD6CC),
  CoinColor.flowerPurple: Color(0xFF7A3B52),
  CoinColor.flowerPink: Color(0xFFD9A9A6),
};

/// A single representative colour for any coin — the procedural coin's mid tone,
/// or the image disc's accent. Used where code needs a colour, not a full disc.
Color coinAccentColor(CoinColor coin) =>
    coinPalettes[coin]?.faceMid ?? _coinAccents[coin]!;
