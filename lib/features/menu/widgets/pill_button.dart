import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    final fg = wood ? WoodTheme.inkScore : GameColors.onAccent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wood ? WoodTheme.cardTop : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: wood
            ? Border.all(color: WoodTheme.gold, width: 1.2)
            : null,
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
              style: TextStyle(
                fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: fg,
              ),
              child: IconTheme(
                data: IconThemeData(color: fg, size: 20),
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
    final wood = isWoodTheme(context);
    final fg = wood ? WoodTheme.inkScore : Colors.white;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.arrow_back, color: fg, size: 20),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
