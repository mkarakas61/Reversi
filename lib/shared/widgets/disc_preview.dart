import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/coin_palette.dart';

/// One disc skin, drawn the same way in the settings picker and in the store.
///
/// The four starter discs are procedural (a radial gradient), the rest are
/// PNGs with their own shape and shading (REV-82) — which is why this cannot
/// just be a coloured circle.
class DiscPreview extends StatelessWidget {
  const DiscPreview({super.key, required this.color, this.size = 38});

  final CoinColor color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = coinPalettes[color];
    if (palette == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(coinAssets[color]!, fit: BoxFit.contain),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.24, -0.36),
          radius: 0.95,
          colors: [palette.faceTop, palette.faceMid, palette.faceBottom],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
