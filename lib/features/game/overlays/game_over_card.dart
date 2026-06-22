import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/coin_palette.dart';
import '../../../core/theme/game_colors.dart';

class GameOverCard extends StatelessWidget {
  const GameOverCard({
    super.key,
    required this.title,
    required this.titleColor,
    required this.message,
    required this.yourCoin,
    required this.opponentCoin,
    required this.blackScore,
    required this.whiteScore,
    required this.onPlayAgain,
    required this.onMenu,
  });

  final String? title;
  final Color titleColor;
  final String? message;
  final CoinColor yourCoin;
  final CoinColor opponentCoin;
  final int blackScore;
  final int whiteScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 16),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 26,
                height: 1.1,
                color: titleColor,
              ),
            ),
          if (message != null)
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.35,
                color: GameColors.inkSoft,
              ),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScoreBadge(coin: yourCoin, score: blackScore),
              const SizedBox(width: 10),
              const Text(
                '–',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: GameColors.inkSoft,
                ),
              ),
              const SizedBox(width: 10),
              ScoreBadge(coin: opponentCoin, score: whiteScore),
            ],
          ),
          const SizedBox(height: 22),
          GameOverButton(
            label: strings.playAgain,
            icon: Icons.replay_rounded,
            primary: true,
            onTap: onPlayAgain,
          ),
          const SizedBox(height: 12),
          GameOverButton(
            label: strings.mainMenu,
            icon: Icons.home_rounded,
            primary: false,
            onTap: onMenu,
          ),
        ],
      ),
    );
  }
}

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.coin, required this.score});

  final CoinColor coin;
  final int score;

  @override
  Widget build(BuildContext context) {
    final palette = coinPalettes[coin]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [palette.faceTop, palette.faceBottom],
              stops: const [0.0, 0.72],
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x33000000), blurRadius: 2, spreadRadius: -1),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$score',
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 26,
            height: 1,
            color: GameColors.ink,
          ),
        ),
      ],
    );
  }
}

class GameOverButton extends StatelessWidget {
  const GameOverButton({
    super.key,
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : GameColors.onAccent;
    final bg = primary ? GameColors.accent2 : const Color(0xFFF0ECE3);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: primary
              ? const [
                  BoxShadow(color: Color(0x1F000000), offset: Offset(0, 4)),
                  BoxShadow(
                      color: Color(0x24000000),
                      offset: Offset(0, 8),
                      blurRadius: 16),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 21),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
