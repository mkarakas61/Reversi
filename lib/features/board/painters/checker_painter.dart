import 'package:flutter/material.dart';

import '../../../core/game/reversi_game.dart';
import '../../../core/theme/game_colors.dart';

/// Paints the 8x8 checkerboard on the wood board. Semi-transparent tints are
/// layered over the wood-surface texture so the grain shows through: dark
/// squares read as walnut, light squares as maple. Uses the same cell grid as
/// the coins, so squares and pieces stay perfectly aligned.
class CheckerPainter extends CustomPainter {
  const CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final n = ReversiGame.size;
    final cell = size.width / n;
    final dark = Paint()..color = GameColors.checkerDark;
    final light = Paint()..color = GameColors.checkerLight;

    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final rect = Rect.fromLTWH(col * cell, row * cell, cell, cell);
        canvas.drawRect(rect, (row + col).isEven ? light : dark);
      }
    }
  }

  @override
  bool shouldRepaint(CheckerPainter oldDelegate) => false;
}
