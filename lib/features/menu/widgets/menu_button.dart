import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  /// A quieter second line under [label] — what this button will actually do,
  /// where the label alone leaves it open. "Continue" grows one (REV-100).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    final Color fg;
    final Decoration decoration;
    if (wood) {
      fg = primary ? WoodTheme.buttonText : WoodTheme.inkScore;
      decoration = BoxDecoration(
        gradient: primary ? WoodTheme.buttonGradient : WoodTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WoodTheme.gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x213E2A1E),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
    } else {
      fg = primary ? Colors.white : GameColors.onAccent;
      decoration = BoxDecoration(
        color: primary ? GameColors.accent2 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      );
    }
    final sub = subtitle;
    return SizedBox(
      width: 260,
      // The subtitle earns its own height rather than squeezing the label.
      height: sub == null ? 58 : 72,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: fg, size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily:
                                wood ? WoodTheme.displayFont : 'Baloo2',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: fg,
                          ),
                        ),
                        if (sub != null)
                          Text(
                            sub,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.25,
                              color: fg.withValues(alpha: 0.82),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
