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

/// A disc that can flip from one skin to another with a single consistent
/// card-flip (REV-82 — one animation for every coin on every board): the face
/// squashes vertically to an edge at the midpoint, swapping skins there.
///
/// - [flipFrom] null → static disc showing [coin].
/// - [appear] true → the just-placed disc fades in (its color is on both faces,
///   so no skin swap is needed).
class AnimatedDiscView extends StatelessWidget {
  const AnimatedDiscView({
    super.key,
    required this.coin,
    required this.size,
    this.flipFrom,
    this.t = 1.0,
    this.appear = false,
  });

  /// The disc's final skin (the current board color's chosen coin).
  final CoinColor coin;
  final double size;

  /// The skin before the flip; null for a static (non-flipping) disc.
  final CoinColor? flipFrom;

  /// Flip progress in [0, 1].
  final double t;

  /// Whether this is the freshly placed disc (fades in instead of flipping).
  final bool appear;

  @override
  Widget build(BuildContext context) {
    if (flipFrom == null || flipFrom == coin) {
      final disc = DiscView(coin: coin, size: size);
      if (!appear) return disc;
      return Opacity(opacity: (t / 0.06).clamp(0.0, 1.0), child: disc);
    }

    // Card-flip: 0..0.5 shows the old skin shrinking to an edge, 0.5..1 shows
    // the new skin growing back — a single half-turn, color swapped at the edge.
    final showNew = t >= 0.5;
    final shown = showNew ? coin : flipFrom!;
    final scaleY = (showNew ? (2 * t - 1) : (1 - 2 * t)).clamp(0.0, 1.0);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(1.0, scaleY == 0 ? 0.001 : scaleY, 1.0),
      child: DiscView(coin: shown, size: size),
    );
  }
}
