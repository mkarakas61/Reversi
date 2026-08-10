import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/coin_palette.dart';
import 'coin_view.dart';

/// A small pip laid on the disc that was played last (REV-87). The just-placed
/// disc no longer animates (REV-86), so this is what tells you where the last
/// move went.
///
/// It sits on top of the disc, which means it has to read on every skin we
/// ship — from the near-black coin to the near-white marble — and on every
/// board under them. No single flat colour does that, so the pip is three
/// tones: an amber body (the game's existing hint/last-move colour), a light
/// inner highlight, and a dark outline that fences it off from pale discs.
class LastMoveMarker extends StatelessWidget {
  const LastMoveMarker({super.key, required this.coin, required this.size});

  /// The skin of the disc underneath — it decides where the disc's face centre
  /// is, so the pip lands on the face rather than below it.
  final CoinColor coin;

  /// The disc's diameter.
  final double size;

  /// Pip diameter as a fraction of the disc.
  static const double _pipFactor = 0.30;

  /// Amber body — saturated enough to separate from the warm wood discs.
  static const Color amber = Color(0xFFFFB300);

  /// Dark warm outline that keeps the pip legible on pale discs.
  static const Color outline = Color(0xCC3B2200);

  /// Where a procedural coin's face centre lands, as a fraction of the disc
  /// box: the squashed face and its side wall are centred together, so the face
  /// alone ends up above the middle.
  static const double _proceduralFaceCenter =
      (1 - (kCoinRestFaceSquash + kCoinRestThickness)) / 2 +
          kCoinRestFaceSquash / 2;

  @override
  Widget build(BuildContext context) {
    // An image disc's perspective is baked into the PNG and rests dead centre;
    // a procedural coin's face sits higher (see above).
    final faceShift =
        isAssetCoin(coin) ? 0.0 : size * (_proceduralFaceCenter - 0.5);

    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, faceShift),
            child: SizedBox.square(
              dimension: size * _pipFactor,
              child: const CustomPaint(painter: _PipPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  const _PipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    // Dark outline first, so the amber body sits inside it.
    canvas.drawCircle(
      center,
      r,
      Paint()..color = LastMoveMarker.outline,
    );
    canvas.drawCircle(
      center,
      r * 0.80,
      Paint()..color = LastMoveMarker.amber,
    );
    // Light highlight, up and to the left like every other lit surface here.
    canvas.drawCircle(
      center.translate(-r * 0.20, -r * 0.20),
      r * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_PipPainter old) => false;
}
