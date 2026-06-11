import 'package:flutter/material.dart';

import '../game/reversi_game.dart';
import '../theme/game_theme.dart';
import 'coin_view.dart';

/// The tilted wooden Reversi table. The slab (frame + felt + engraved grid) is
/// warped into a trapezoid — bottom edge flush to the screen edges, top edge
/// inset — so it reads as a real table receding away from the viewer. Coins
/// are billboarded on top at the projected cell centres; taps are mapped back
/// through the inverse transform.
class WoodBoard extends StatelessWidget {
  const WoodBoard({
    super.key,
    required this.board,
    required this.validMoves,
    required this.lastMove,
    required this.onCellTap,
  });

  final List<List<Disc?>> board;
  final Set<Position> validMoves;
  final Position? lastMove;
  final ValueChanged<Position> onCellTap;

  static const _framePad = 14.0; // wood border around the felt

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : w * 1.1;

        // Slab is described in its own local square of side [s]; the homography
        // maps that square onto the on-screen trapezoid.
        const s = 1000.0;
        final feltSize = s - _framePad * 2;
        final cell = feltSize / ReversiGame.size;

        // Target trapezoid corners (TL, TR, BR, BL) in stage space. A square
        // board tilted back reads wider than tall on screen, so the vertical
        // extent is a foreshortened fraction of the width; the bottom edge is
        // full-bleed and the top edge tapers inward.
        final insetX = w * 0.12; // top edge inset from the screen edges
        final boardH = (w * 0.82).clamp(0.0, h * 0.95);
        final topY = (h - boardH) / 2; // vertically centred in the stage
        final botY = topY + boardH;
        final corners = <Offset>[
          Offset(insetX, topY), // TL
          Offset(w - insetX, topY), // TR
          Offset(w, botY), // BR (flush right)
          Offset(0, botY), // BL (flush left)
        ];

        final transform = _squareToQuad(s, corners);
        final inverse = Matrix4.inverted(transform);

        Offset project(Offset p) =>
            MatrixUtils.transformPoint(transform, p);

        final coinWidgets = <Widget>[];
        for (var r = 0; r < ReversiGame.size; r++) {
          for (var c = 0; c < ReversiGame.size; c++) {
            final disc = board[r][c];
            final pos = Position(r, c);
            final isHint = disc == null && validMoves.contains(pos);
            if (disc == null && !isHint) continue;

            final centerLocal =
                Offset(_framePad + (c + 0.5) * cell, _framePad + (r + 0.5) * cell);
            final center = project(centerLocal);
            final edge = project(centerLocal + Offset(cell / 2, 0));
            final coinW = (edge.dx - center.dx).abs() * 2 * 0.86;

            if (isHint) {
              final hintSize = coinW * 0.34;
              coinWidgets.add(Positioned(
                left: center.dx - hintSize / 2,
                top: center.dy - hintSize / 2,
                child: _Hint(size: hintSize),
              ));
              continue;
            }

            const faceSquash = 0.74;
            const thicknessFactor = 0.18;
            final faceHeight = coinW * faceSquash;
            final totalH = faceHeight + coinW * thicknessFactor;
            coinWidgets.add(Positioned(
              left: center.dx - coinW / 2,
              // Centre the whole cylinder (face + wall) on the cell.
              top: center.dy - totalH / 2,
              child: CoinView(
                tone: disc!,
                width: coinW,
                faceSquash: faceSquash,
                thicknessFactor: thicknessFactor,
              ),
            ));
          }
        }

        return SizedBox(
          width: w,
          height: h,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final boardPt =
                  MatrixUtils.transformPoint(inverse, details.localPosition);
              final fx = (boardPt.dx - _framePad) / cell;
              final fy = (boardPt.dy - _framePad) / cell;
              if (fx < 0 || fy < 0 || fx >= 8 || fy >= 8) return;
              onCellTap(Position(fy.floor(), fx.floor()));
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Transform(
                  transform: transform,
                  child: OverflowBox(
                    minWidth: s,
                    maxWidth: s,
                    minHeight: s,
                    maxHeight: s,
                    alignment: Alignment.topLeft,
                    child: _Slab(feltSize: feltSize, framePad: _framePad),
                  ),
                ),
                ...coinWidgets,
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a Matrix4 mapping the local square [0,size]² onto the quad
  /// [q0,q1,q2,q3] (TL, TR, BR, BL) — a planar perspective homography.
  static Matrix4 _squareToQuad(double size, List<Offset> q) {
    final x0 = q[0].dx, y0 = q[0].dy;
    final x1 = q[1].dx, y1 = q[1].dy;
    final x2 = q[2].dx, y2 = q[2].dy;
    final x3 = q[3].dx, y3 = q[3].dy;

    final dx1 = x1 - x2, dx2 = x3 - x2, dx3 = x0 - x1 + x2 - x3;
    final dy1 = y1 - y2, dy2 = y3 - y2, dy3 = y0 - y1 + y2 - y3;
    final den = dx1 * dy2 - dx2 * dy1;
    final g = (dx3 * dy2 - dx2 * dy3) / den;
    final hh = (dx1 * dy3 - dx3 * dy1) / den;

    var a = x1 - x0 + g * x1;
    var b = x3 - x0 + hh * x3;
    final c = x0;
    var d = y1 - y0 + g * y1;
    var e = y3 - y0 + hh * y3;
    final f = y0;
    var gg = g, hhh = hh;

    // Fold the source scale (1/size) into the homography.
    a /= size;
    b /= size;
    d /= size;
    e /= size;
    gg /= size;
    hhh /= size;

    return Matrix4(
      a, d, 0, gg, // col 0
      b, e, 0, hhh, // col 1
      0, 0, 1, 0, // col 2
      c, f, 0, 1, // col 3
    );
  }
}

class _Slab extends StatelessWidget {
  const _Slab({required this.feltSize, required this.framePad});

  final double feltSize;
  final double framePad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(framePad),
      decoration: const BoxDecoration(
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
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
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
        ),
        child: SizedBox(
          width: feltSize,
          height: feltSize,
          child: CustomPaint(painter: _GridPainter()),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final n = ReversiGame.size;
    final cell = size.width / n;

    final hi = Paint()
      ..color = GameColors.gridHi
      ..strokeWidth = 3.0;
    final line = Paint()
      ..color = GameColors.gridLine
      ..strokeWidth = 3.0;

    for (var i = 0; i <= n; i++) {
      final p = i * cell;
      canvas.drawLine(Offset(p + 1.6, 1.6), Offset(p + 1.6, size.height), hi);
      canvas.drawLine(Offset(1.6, p + 1.6), Offset(size.width, p + 1.6), hi);
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), line);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), line);
    }

    final star = Paint()..color = GameColors.starDot;
    for (final st in const [
      Offset(2, 2),
      Offset(6, 2),
      Offset(2, 6),
      Offset(6, 6),
    ]) {
      canvas.drawCircle(Offset(st.dx * cell, st.dy * cell), cell * 0.09, star);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _Hint extends StatefulWidget {
  const _Hint({required this.size});

  final double size;

  @override
  State<_Hint> createState() => _HintState();
}

class _HintState extends State<_Hint> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x2E281709),
          border: Border.all(color: const Color(0x73FFF0D2), width: 2),
        ),
      ),
    );
  }
}
