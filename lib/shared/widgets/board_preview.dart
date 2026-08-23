import 'package:flutter/material.dart';

import '../../core/game/reversi_game.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/board_palette.dart';
import '../../core/theme/game_colors.dart';

/// A small board thumbnail — the same drawing in the settings picker and in
/// the store, so a board a player buys looks exactly like the one they saw.
class BoardPreview extends StatelessWidget {
  const BoardPreview({super.key, required this.theme});

  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    // The floral board is a single baked-in image (border + grid included),
    // so its preview is just the image, scaled to fill the tile.
    if (theme == BoardTheme.cicek) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: const Image(
          image: AssetImage('assets/flower/flower-board.png'),
          fit: BoxFit.cover,
        ),
      );
    }

    final palette = boardPalettes[theme];

    final BoxDecoration frame = palette == null
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            image: const DecorationImage(
              image: AssetImage('assets/wood/wood-frame.png'),
              fit: BoxFit.cover,
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: palette.frameGradient,
          );

    final BoxDecoration surface = palette == null
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            image: const DecorationImage(
              image: AssetImage('assets/wood/wood-surface.png'),
              fit: BoxFit.cover,
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: palette.surfaceGradient,
          );

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: frame,
      child: DecoratedBox(
        decoration: surface,
        child: SizedBox.expand(
          child: CustomPaint(painter: MiniGridPainter(palette: palette)),
        ),
      ),
    );
  }
}

class MiniGridPainter extends CustomPainter {
  MiniGridPainter({required this.palette});

  final BoardPalette? palette;

  @override
  void paint(Canvas canvas, Size size) {
    final n = ReversiGame.size;
    final cell = size.width / n;
    if (palette?.marble ?? false) paintMarbleVeins(canvas, size);
    final paint = Paint()
      ..color = palette == null
          ? GameColors.gridLine
          : palette!.line.withValues(alpha: 0.55)
      ..strokeWidth = 0.6;
    for (var i = 1; i < n; i++) {
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), paint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), paint);
    }
  }

  @override
  bool shouldRepaint(MiniGridPainter old) => old.palette != palette;
}
