import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/coin_palette.dart';
import 'coin_view.dart';

/// A single disc face, sized to fit a [size]×[size] square and centered. Draws
/// a procedural coin ([coinPalettes]) or an image disc ([coinAssets]) — so any
/// selectable coin renders on any board (REV-82).
class DiscView extends StatelessWidget {
  const DiscView({super.key, required this.coin, required this.size});

  final CoinColor coin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = coinPalettes[coin];
    final Widget disc = palette != null
        ? CoinView(palette: palette, width: size)
        : Image.asset(
            coinAssets[coin]!,
            width: size,
            height: size,
            fit: BoxFit.contain,
          );
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: disc),
    );
  }
}

/// A disc turning over with a real perspective flip: it pops off the board on a
/// gravity arc, tips end-over-end with its side wall showing (so it reads as a
/// solid piece, not a flat card), swaps skins while edge-on, and settles flush
/// with the resting disc.
///
/// One choreography for every coin on every board (REV-82's goal), but each
/// half-turn is drawn by the skin it shows — a procedural coin's painted face or
/// an image disc's PNG — so a marble disc can turn into a turquoise coin and
/// both ends still land exactly on their resting look.
///
/// Only captured discs turn: the disc a player just placed is set down as a
/// resting [DiscView] (REV-86). With [flipFrom] null this widget is exactly
/// that resting disc.
class AnimatedDiscView extends StatelessWidget {
  const AnimatedDiscView({
    super.key,
    required this.coin,
    required this.size,
    this.flipFrom,
    this.t = 1.0,
  });

  /// The disc's final skin (the current board color's chosen coin).
  final CoinColor coin;
  final double size;

  /// The skin before the flip; null for a static (non-flipping) disc.
  final CoinColor? flipFrom;

  /// Flip progress in [0, 1].
  final double t;

  /// Side wall when the disc stands edge-on, × diameter. Chosen so a procedural
  /// coin's wall at rest comes out at [kCoinRestThickness].
  static const double _thickness = 0.25;

  /// Peak lift of the flight arc, × diameter.
  static const double _hover = 0.45;

  /// Growth toward the camera at the top of the arc.
  static const double _hoverScale = 0.12;

  /// Apparent face squash of [coin] at rest: image discs have their perspective
  /// baked into the PNG and rest full height, procedural coins rest as
  /// [CoinView]'s ellipse.
  static double _restSquash(CoinColor coin) =>
      isAssetCoin(coin) ? 1.0 : kCoinRestFaceSquash;

  /// Edge tones for [coin]'s side wall: the procedural coin's own edge colours,
  /// or shades derived from an image disc's representative colour.
  static (Color, Color) _wallColors(CoinColor coin) {
    final palette = coinPalettes[coin];
    if (palette != null) return (palette.edgeLight, palette.edgeDark);
    final accent = coinAccentColor(coin);
    return (
      Color.lerp(accent, Colors.white, 0.18)!,
      Color.lerp(accent, Colors.black, 0.42)!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final from = flipFrom;
    if (from == null) return DiscView(coin: coin, size: size);

    final p = t.clamp(0.0, 1.0);

    // The turn as a coin tipping over in front of a tilted camera: `phase` runs
    // from the resting elevation of the old skin, through pi (edge-on, always
    // at the halfway point so mismatched skins still meet), to pi plus the new
    // skin's resting elevation. sin(phase) is the apparent face squash and
    // cos(phase) the visible side wall, which is what makes the turn read as
    // depth rather than a vertical squeeze.
    final firstHalf = p < 0.5;
    final shown = firstHalf ? from : coin;
    final eFrom = math.asin(_restSquash(from));
    final eTo = math.asin(_restSquash(coin));
    final phase = firstHalf
        ? eFrom + (math.pi - eFrom) * (p / 0.5)
        : math.pi + eTo * ((p - 0.5) / 0.5);

    final faceK = math.sin(phase);
    final wallK = math.cos(phase);
    final faceH = size * faceK.abs();
    final wallH = size * _thickness * wallK.abs();
    // The rim sits under the face at both resting ends; mid-turn the far rim
    // comes over the top and the old face rolls under it.
    final below = faceK * wallK >= 0;

    final (light, dark) = _wallColors(shown);
    final palette = coinPalettes[shown];
    // Image discs carry transparent padding around the disc, so their wall is
    // inset slightly to stay under the artwork.
    final inset = palette == null ? size * 0.03 : 0.0;

    final coinBox = SizedBox(
      width: size,
      height: math.max(faceH + wallH, 1.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FlipWallPainter(
                light: light,
                dark: dark,
                faceH: faceH,
                wallH: wallH,
                below: below,
                inset: inset,
              ),
            ),
          ),
          if (faceH > 0.5)
            Positioned(
              left: 0,
              right: 0,
              top: below ? 0 : wallH,
              height: faceH,
              child: palette != null
                  ? CustomPaint(painter: _CoinFacePainter(palette: palette))
                  : Image.asset(coinAssets[shown]!, fit: BoxFit.fill),
            ),
        ],
      ),
    );

    // Flight arc: brisk launch, then a gentle float down that settles with zero
    // vertical speed — no abrupt click at touchdown.
    final lift = math.sin(math.pi * Curves.easeOutSine.transform(p));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The shadow stays on the board while the disc is airborne.
          _GroundShadow(size: size, lift: lift),
          FractionalTranslation(
            translation: Offset(0, -_hover * lift),
            child: Transform.scale(
              scale: 1.0 + _hoverScale * lift,
              child: Center(child: coinBox),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the tipping disc's side wall across the full painter box.
class _FlipWallPainter extends CustomPainter {
  _FlipWallPainter({
    required this.light,
    required this.dark,
    required this.faceH,
    required this.wallH,
    required this.below,
    required this.inset,
  });

  final Color light;
  final Color dark;
  final double faceH;
  final double wallH;
  final bool below;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final faceRect = Rect.fromLTWH(
      inset,
      below ? 0 : wallH,
      size.width - inset * 2,
      math.max(faceH, 1.0),
    );
    paintCoinWall(canvas, faceRect, wallH, below, light, dark);
  }

  @override
  bool shouldRepaint(_FlipWallPainter old) =>
      old.light != light ||
      old.dark != dark ||
      old.faceH != faceH ||
      old.wallH != wallH ||
      old.below != below ||
      old.inset != inset;
}

/// Draws a procedural coin's face squashed into the painter box.
class _CoinFacePainter extends CustomPainter {
  _CoinFacePainter({required this.palette});

  final CoinPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    paintCoinFace(canvas, Offset.zero & size, palette);
  }

  @override
  bool shouldRepaint(_CoinFacePainter old) => old.palette != palette;
}

/// Soft elliptical shadow under an airborne disc: fades in and shrinks as the
/// disc lifts away from the board, grounding the flight arc.
class _GroundShadow extends StatelessWidget {
  const _GroundShadow({required this.size, required this.lift});

  final double size;

  /// 0 = resting, 1 = highest point.
  final double lift;

  @override
  Widget build(BuildContext context) {
    if (lift <= 0.01) return const SizedBox.shrink();
    final d = size * (0.95 - 0.22 * lift);
    return Positioned(
      bottom: size * 0.02,
      child: Transform.scale(
        scaleY: 0.34,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.black.withValues(alpha: 0.34 * lift),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
