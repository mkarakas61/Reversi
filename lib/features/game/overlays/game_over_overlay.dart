import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../core/game/reversi_game.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/coin_palette.dart';
import '../../../core/theme/game_colors.dart';
import 'game_over_card.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.winner,
    required this.isSinglePlayer,
    required this.humanDisc,
    required this.blackScore,
    required this.whiteScore,
    required this.yourCoin,
    required this.opponentCoin,
    required this.confettiLeft,
    required this.confettiRight,
    required this.onPlayAgain,
    required this.onMenu,
    required this.strings,
  });

  final Disc? winner;
  final bool isSinglePlayer;
  final Disc humanDisc;
  final int blackScore;
  final int whiteScore;
  final CoinColor yourCoin;
  final CoinColor opponentCoin;
  final ConfettiController confettiLeft;
  final ConfettiController confettiRight;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;
  final ({String? title, String? message, CoinColor? titleCoin}) strings;

  @override
  Widget build(BuildContext context) {
    Color titleColor = GameColors.ink;
    if (strings.titleCoin != null) {
      final mid = coinPalettes[strings.titleCoin]!.faceMid;
      titleColor =
          ThemeData.estimateBrightnessForColor(mid) == Brightness.light
              ? GameColors.ink
              : mid;
    }

    final confettiColors = <Color>[
      GameColors.accent,
      GameColors.accent2,
      const Color(0xFFFFC83D),
      Colors.white,
      coinPalettes[yourCoin]!.faceMid,
      coinPalettes[opponentCoin]!.faceMid,
    ];

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const ColoredBox(color: Color(0x6B000000)),
            ),
          ),
          Align(
            alignment: const Alignment(-0.9, -0.75),
            child: ConfettiWidget(
              confettiController: confettiLeft,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 34,
              minBlastForce: 16,
              maxBlastForce: 48,
              gravity: 0.22,
              particleDrag: 0.04,
              minimumSize: const Size(9, 7),
              maximumSize: const Size(16, 11),
              colors: confettiColors,
            ),
          ),
          Align(
            alignment: const Alignment(0.9, -0.75),
            child: ConfettiWidget(
              confettiController: confettiRight,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 34,
              minBlastForce: 16,
              maxBlastForce: 48,
              gravity: 0.22,
              particleDrag: 0.04,
              minimumSize: const Size(9, 7),
              maximumSize: const Size(16, 11),
              colors: confettiColors,
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(
                scale: 0.85 + 0.15 * v.clamp(0.0, 1.0),
                child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
              ),
              child: GameOverCard(
                title: strings.title,
                titleColor: titleColor,
                message: strings.message,
                yourCoin: yourCoin,
                opponentCoin: opponentCoin,
                blackScore: blackScore,
                whiteScore: whiteScore,
                onPlayAgain: onPlayAgain,
                onMenu: onMenu,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
