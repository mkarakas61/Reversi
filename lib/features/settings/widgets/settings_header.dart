import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 12),
          RoundButton(icon: Icons.chevron_left, onTap: onBack),
          Expanded(
            child: Center(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: wood ? WoodTheme.displayFont : 'Baloo2',
                  fontWeight: wood ? FontWeight.w400 : FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: wood ? 3 : 2.2,
                  color: wood ? WoodTheme.buttonText : Colors.white,
                  shadows: const [
                    Shadow(color: Color(0x1F000000), offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 54),
        ],
      ),
    );
  }
}

class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wood ? WoodTheme.cardTop : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: wood ? Border.all(color: WoodTheme.gold, width: 1.2) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), offset: Offset(0, 3)),
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 38,
            child: Icon(icon,
                color: wood ? WoodTheme.inkScore : GameColors.onAccent,
                size: 24),
          ),
        ),
      ),
    );
  }
}
