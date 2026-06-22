import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 2.2,
                  color: Colors.white,
                  shadows: [
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
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
            child: Icon(icon, color: GameColors.onAccent, size: 24),
          ),
        ),
      ),
    );
  }
}
