import 'package:flutter/material.dart';

import '../../../core/game/reversi_game.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/coin_palette.dart';
import '../../../core/theme/game_colors.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.side,
    required this.name,
    required this.mono,
    required this.score,
    required this.active,
    required this.statusText,
    required this.coin,
    this.countdown,
    this.countdownUrgent = false,
    this.countdownVisible = true,
  });

  final Disc side;
  final String name;
  final String mono;
  final int score;
  final bool active;
  final String statusText;
  final CoinColor coin;
  final String? countdown;
  final bool countdownUrgent;
  final bool countdownVisible;

  @override
  Widget build(BuildContext context) {
    final isDark = side == Disc.black;
    final accent = isDark ? GameColors.accent : GameColors.accent2;
    final palette = coinPalettes[coin]!;
    final monoColor =
        ThemeData.estimateBrightnessForColor(palette.faceMid) == Brightness.light
            ? GameColors.ink
            : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? accent : Colors.transparent,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, 6)),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (countdown != null)
            AnimatedOpacity(
              opacity: countdownVisible ? 1.0 : 0.15,
              duration: const Duration(milliseconds: 220),
              child: Text(
                countdown!,
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1,
                  color: countdownUrgent
                      ? const Color(0xFFE0312B)
                      : (isDark ? GameColors.accent : GameColors.accent2),
                ),
              ),
            ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.faceTop, palette.faceBottom],
                  ),
                  border:
                      Border.all(color: const Color(0x14000000), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  mono,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: monoColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: GameColors.ink,
                      ),
                    ),
                    SizedBox(
                      height: 15,
                      child: Text(
                        active ? statusText.toLowerCase() : '',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ScoreChip(coin: coin),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  '$score',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    height: 1,
                    color: GameColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ScoreChip extends StatelessWidget {
  const ScoreChip({super.key, required this.coin});

  final CoinColor coin;

  @override
  Widget build(BuildContext context) {
    final palette = coinPalettes[coin]!;
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [palette.faceTop, palette.faceBottom],
          stops: const [0.0, 0.72],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000), blurRadius: 2, spreadRadius: -1),
        ],
      ),
    );
  }
}

class TurnPill extends StatelessWidget {
  const TurnPill({super.key, required this.side, required this.text});

  final Disc side;
  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = side == Disc.black ? GameColors.accent : GameColors.accent2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), offset: Offset(0, 4)),
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 4,
                    spreadRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: GameColors.onAccent,
            ),
          ),
        ],
      ),
    );
  }
}
