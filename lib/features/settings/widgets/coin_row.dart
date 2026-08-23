import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/game_colors.dart';
import '../../../shared/widgets/disc_preview.dart';

class CoinRow extends StatelessWidget {
  const CoinRow({
    super.key,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onSelect,
    this.colors,
  });

  final String label;
  final CoinColor selected;
  final CoinColor disabled;
  final ValueChanged<CoinColor> onSelect;

  /// Which skins to offer. Defaults to all of them; the settings screen passes
  /// only the ones the player owns, so nothing locked is shown there at all
  /// (the store is where locked items live).
  final List<CoinColor>? colors;

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
            for (final color in colors ?? CoinColor.values)
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
    // Both looks live in DiscPreview so the store shows the same disc.
    final Widget coin = DiscPreview(color: color);

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
