import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: wood ? WoodTheme.inkScore : GameColors.inkSoft,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: wood ? WoodTheme.gold : GameColors.accent,
        ),
      ],
    );
  }
}
