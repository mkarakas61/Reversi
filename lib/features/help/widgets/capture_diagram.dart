import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/coin_palette.dart';
import '../../../core/theme/wood_theme.dart';

/// The before/after pair that explains a capture (REV-103): a line of the
/// opponent's discs closed off at both ends, then the same line turned over.
///
/// Deliberately a *schematic*, not a small copy of the real board: flat cells
/// and flat circles, drawn straight down. The real board is seen at a tilt and
/// its discs are squashed to match (see [DiscView]); reproducing that here
/// would put an ellipse in a square cell, because a diagram this small has no
/// room to establish the perspective that makes the pose read correctly. It
/// borrows the player's own chosen disc colours instead, so the example is in
/// the colours they actually play with.
class CaptureDiagram extends StatelessWidget {
  const CaptureDiagram({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = SettingsScope.of(context).settings;
    final you = coinAccentColor(settings.yourCoin);
    final rival = coinAccentColor(settings.opponentCoin);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two boards and the arrow between them share the width; the cell size
        // follows from what is left, so the pair never overflows a narrow
        // phone.
        const arrow = 34.0;
        final boardWidth = ((constraints.maxWidth - arrow) / 2)
            .clamp(96.0, 150.0);
        final cell = boardWidth / _cols;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Panel(
              label: strings.htpBefore,
              cell: cell,
              cells: _before,
              you: you,
              rival: rival,
            ),
            SizedBox(
              width: arrow,
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: isWoodTheme(context)
                    ? WoodTheme.goldText
                    : Colors.black.withValues(alpha: 0.45),
              ),
            ),
            _Panel(
              label: strings.htpAfter,
              cell: cell,
              cells: _after,
              you: you,
              rival: rival,
            ),
          ],
        );
      },
    );
  }
}

enum _Cell { empty, you, rival, target }

const int _cols = 4;
const int _rows = 3;

/// The middle row carries the example; the rest is empty board so the diagram
/// still reads as a board rather than a row of counters.
const List<_Cell> _before = [
  _Cell.empty, _Cell.empty, _Cell.empty, _Cell.empty, //
  _Cell.target, _Cell.rival, _Cell.rival, _Cell.you, //
  _Cell.empty, _Cell.empty, _Cell.empty, _Cell.empty, //
];

const List<_Cell> _after = [
  _Cell.empty, _Cell.empty, _Cell.empty, _Cell.empty, //
  _Cell.you, _Cell.you, _Cell.you, _Cell.you, //
  _Cell.empty, _Cell.empty, _Cell.empty, _Cell.empty, //
];

class _Panel extends StatelessWidget {
  const _Panel({
    required this.label,
    required this.cell,
    required this.cells,
    required this.you,
    required this.rival,
  });

  final String label;
  final double cell;
  final List<_Cell> cells;
  final Color you;
  final Color rival;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            size: Size(cell * _cols, cell * _rows),
            painter: _DiagramPainter(cells: cells, you: you, rival: rival),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: wood
                ? WoodTheme.goldText
                : Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// Board and discs in one painter — one canvas, one coordinate system, so a
/// disc cannot drift off its cell.
class _DiagramPainter extends CustomPainter {
  _DiagramPainter({
    required this.cells,
    required this.you,
    required this.rival,
  });

  final List<_Cell> cells;
  final Color you;
  final Color rival;

  static const Color _surface = Color(0xFF3E7D63);
  static const Color _line = Color(0x66123726);
  static const Color _ring = Color(0xCCFFF3D6);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _cols;

    canvas.drawRect(Offset.zero & size, Paint()..color = _surface);

    final grid = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var c = 1; c < _cols; c++) {
      canvas.drawLine(Offset(c * cell, 0), Offset(c * cell, size.height), grid);
    }
    for (var r = 1; r < _rows; r++) {
      canvas.drawLine(Offset(0, r * cell), Offset(size.width, r * cell), grid);
    }

    final radius = cell * 0.34;
    for (var i = 0; i < cells.length; i++) {
      final centre = Offset(
        (i % _cols) * cell + cell / 2,
        (i ~/ _cols) * cell + cell / 2,
      );
      switch (cells[i]) {
        case _Cell.empty:
          break;
        case _Cell.you:
          _disc(canvas, centre, radius, you);
        case _Cell.rival:
          _disc(canvas, centre, radius, rival);
        case _Cell.target:
          // The same ring the board draws on a legal square (REV-101), so the
          // diagram and the game teach the same mark.
          canvas.drawCircle(
            centre,
            radius,
            Paint()
              ..color = _ring
              ..style = PaintingStyle.stroke
              ..strokeWidth = radius * 0.3,
          );
      }
    }
  }

  void _disc(Canvas canvas, Offset centre, double radius, Color color) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(color, Colors.white, 0.34)!,
            color,
            Color.lerp(color, Colors.black, 0.28)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_DiagramPainter old) =>
      old.cells != cells || old.you != you || old.rival != rival;
}
