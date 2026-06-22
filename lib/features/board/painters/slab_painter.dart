import 'package:flutter/material.dart';

import '../../../core/game/reversi_game.dart';
import '../../../core/theme/board_palette.dart';
import '../../../core/theme/game_colors.dart';

class Slab extends StatelessWidget {
  const Slab({
    super.key,
    required this.feltSize,
    required this.framePad,
    required this.palette,
  });

  final double feltSize;
  final double framePad;
  final BoardPalette? palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;

    final BoxDecoration frameDecoration = p == null
        ? const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            image: DecorationImage(
              image: AssetImage('assets/wood/wood-frame.png'),
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          )
        : BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            gradient: p.frameGradient,
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          );

    final BoxDecoration surfaceDecoration = p == null
        ? const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            image: DecorationImage(
              image: AssetImage('assets/wood/wood-surface.png'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x61000000),
                blurRadius: 9,
                spreadRadius: -2,
                offset: Offset(0, 3),
              ),
            ],
          )
        : BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            gradient: p.surfaceGradient,
            boxShadow: const [
              BoxShadow(
                color: Color(0x61000000),
                blurRadius: 9,
                spreadRadius: -2,
                offset: Offset(0, 3),
              ),
            ],
          );

    return Container(
      padding: EdgeInsets.all(framePad),
      decoration: frameDecoration,
      child: DecoratedBox(
        decoration: surfaceDecoration,
        child: SizedBox(
          width: feltSize,
          height: feltSize,
          child: CustomPaint(painter: GridPainter(palette: p)),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter({required this.palette});

  final BoardPalette? palette;

  @override
  void paint(Canvas canvas, Size size) {
    final n = ReversiGame.size;
    final cell = size.width / n;
    final p = palette;
    final hi = Paint()
      ..color = p == null ? GameColors.gridHi : p.lineHi
      ..strokeWidth = 3.0;
    final line = Paint()
      ..color = p == null ? GameColors.gridLine : p.line
      ..strokeWidth = 3.0;

    for (var i = 0; i <= n; i++) {
      final pos = i * cell;
      canvas.drawLine(
          Offset(pos + 1.6, 1.6), Offset(pos + 1.6, size.height), hi);
      canvas.drawLine(
          Offset(1.6, pos + 1.6), Offset(size.width, pos + 1.6), hi);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), line);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), line);
    }
  }

  @override
  bool shouldRepaint(GridPainter old) => old.palette != palette;
}
