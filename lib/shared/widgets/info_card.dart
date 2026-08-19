import 'package:flutter/material.dart';

import '../../core/theme/game_colors.dart';
import '../../core/theme/wood_theme.dart';

/// A titled card on a settings-style page: the raised panel used by the
/// Settings screen and by How to Play, so the two read as one place.
///
/// Was private to the Settings screen until How to Play needed the same panel
/// (REV-103); shared rather than copied so the two cannot drift apart.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Container(
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: wood ? WoodTheme.cardTop : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border:
            wood ? Border.all(color: WoodTheme.cardIdleBorder, width: 1) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, 6)),
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: wood ? WoodTheme.displayFont : 'Baloo2',
              fontWeight: wood ? FontWeight.w400 : FontWeight.w800,
              fontSize: wood ? 16 : 15,
              color: wood ? WoodTheme.inkScore : GameColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Body copy inside an [InfoCard] — the paragraph voice of How to Play.
class InfoText extends StatelessWidget {
  const InfoText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.45,
        color: wood
            ? WoodTheme.inkName
            : GameColors.ink.withValues(alpha: 0.82),
      ),
    );
  }
}
