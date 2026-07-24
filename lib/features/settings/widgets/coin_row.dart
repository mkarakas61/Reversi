import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/coin_palette.dart';
import '../../../core/theme/game_colors.dart';

class CoinRow extends StatelessWidget {
  const CoinRow({
    super.key,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onSelect,
  });

  final String label;
  final CoinColor selected;
  final CoinColor disabled;
  final ValueChanged<CoinColor> onSelect;

  @override
  Widget build(BuildContext context) {
    // Label on top, the 10 disc skins wrapping below (REV-82) — fits the
    // compact settings layout on one screen.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: GameColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in CoinColor.values)
              _CoinSwatch(
                color: color,
                active: color == selected,
                disabled: color == disabled,
                onTap: () => onSelect(color),
              ),
          ],
        ),
      ],
    );
  }
}

class _CoinSwatch extends StatelessWidget {
  const _CoinSwatch({
    required this.color,
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  final CoinColor color;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = coinPalettes[color];
    // Procedural coins draw a radial-gradient disc; image discs (walnut/marble/
    // flower) show their PNG, which has its own shape + shading (REV-82).
    final Widget coin = palette != null
        ? Container(
            width: 38,
            height: 38,
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
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2)),
              ],
            ),
          )
        : SizedBox(
            width: 38,
            height: 38,
            child: Image.asset(coinAssets[color]!, fit: BoxFit.contain),
          );

    return Opacity(
      opacity: disabled ? 0.28 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? GameColors.accent : Colors.transparent,
              width: 3,
            ),
          ),
          child: coin,
        ),
      ),
    );
  }
}
