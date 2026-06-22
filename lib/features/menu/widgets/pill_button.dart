import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.child, required this.onTap});

  final Widget child;
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
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: GameColors.onAccent,
              ),
              child: IconTheme(
                data: const IconThemeData(color: GameColors.onAccent, size: 20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
