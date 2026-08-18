import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game/reversi_game.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/board_palette.dart';
import '../../shared/widgets/disc_view.dart';
import '../../shared/widgets/last_move_marker.dart';
import 'board_move.dart';
import 'painters/slab_painter.dart';
import 'widgets/hint_widget.dart';

class WoodBoard extends StatefulWidget {
  const WoodBoard({
    super.key,
    required this.board,
    required this.validMoves,
    required this.lastMove,
    required this.onCellTap,
    this.theme = BoardTheme.wood,
    this.blackCoin = CoinColor.black,
    this.whiteCoin = CoinColor.white,
    this.move,
  });

  final List<List<Disc?>> board;
  final Set<Position> validMoves;
  final Position? lastMove;
  final ValueChanged<Position> onCellTap;
  final BoardTheme theme;
  final CoinColor blackCoin;
  final CoinColor whiteCoin;
  final BoardMove? move;

  @override
  State<WoodBoard> createState() => _WoodBoardState();
}

class _WoodBoardState extends State<WoodBoard>
    with SingleTickerProviderStateMixin {
  static const _framePad = 14.0;
  // One coin's turn takes [_coinMs]. [_staggerMs] is the per-ring delay
  // of a ripple wave — kept at 0 so all coins turn together: waiting for
  // a ripple to finish made moves feel slow.
  static const _coinMs = 1400;
  static const _staggerMs = 0;

  late final AnimationController _flip;
  BoardMove? _anim;
  int _lastAnimatedId = 0;
  int _totalMs = _coinMs;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _coinMs));
    _flip.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _anim = null);
      }
    });
    _lastAnimatedId = widget.move?.id ?? 0;
  }

  @override
  void didUpdateWidget(WoodBoard old) {
    super.didUpdateWidget(old);
    final move = widget.move;
    if (move != null && move.id != _lastAnimatedId) {
      _lastAnimatedId = move.id;
      _anim = move;
      var maxDist = 0;
      for (final f in move.flipped) {
        final d = max(
          (f.row - move.placed.row).abs(),
          (f.col - move.placed.col).abs(),
        );
        if (d > maxDist) maxDist = d;
      }
      _totalMs = _coinMs + _staggerMs * maxDist;
      _flip.duration = Duration(milliseconds: _totalMs);
      _flip.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  CoinColor _coinFor(Disc disc) =>
      disc == Disc.black ? widget.blackCoin : widget.whiteCoin;

  @override
  Widget build(BuildContext context) {
    final palette = boardPalettes[widget.theme];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : w * 1.1;

        const s = 1000.0;
        final feltSize = s - _framePad * 2;
        final cell = feltSize / ReversiGame.size;

        final insetX = w * 0.12;
        final boardH = (w * 0.82).clamp(0.0, h * 0.95);
        final topY = (h - boardH) / 2;
        final botY = topY + boardH;
        final corners = <Offset>[
          Offset(insetX, topY),
          Offset(w - insetX, topY),
          Offset(w, botY),
          Offset(0, botY),
        ];

        final transform = _squareToQuad(s, corners);
        final inverse = Matrix4.inverted(transform);

        Offset project(Offset p) => MatrixUtils.transformPoint(transform, p);

        (Offset, double) cellGeometry(int r, int c) {
          // Derive the coin from the SAME projected square the checker/grid
          // painters draw, so piece and cell share one source of truth. Using
          // the projected quad's visual (area) center — not the projection of
          // the cell's center point — matches where the eye reads the square's
          // middle under perspective, which is where the misalignment came from.
          final x0 = _framePad + c * cell;
          final y0 = _framePad + r * cell;
          final tl = project(Offset(x0, y0));
          final tr = project(Offset(x0 + cell, y0));
          final br = project(Offset(x0 + cell, y0 + cell));
          final bl = project(Offset(x0, y0 + cell));
          final center = Offset(
            (tl.dx + tr.dx + br.dx + bl.dx) / 4,
            (tl.dy + tr.dy + br.dy + bl.dy) / 4,
          );
          final topW = (tr.dx - tl.dx).abs();
          final botW = (br.dx - bl.dx).abs();
          final coinW = (topW + botW) / 2 * 0.86;
          return (center, coinW);
        }

        return AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final anim = _anim;
            final p = _flip.value;
            final affected = anim == null
                ? const <Position>{}
                : {anim.placed, ...anim.flipped};

            final coinWidgets = <Widget>[];

            for (var r = 0; r < ReversiGame.size; r++) {
              for (var c = 0; c < ReversiGame.size; c++) {
                final pos = Position(r, c);
                if (affected.contains(pos)) continue;
                final disc = widget.board[r][c];
                final isHint =
                    disc == null && widget.validMoves.contains(pos);
                if (disc == null && !isHint) continue;

                final (center, coinW) = cellGeometry(r, c);

                if (isHint) {
                  // Big enough to read at a glance on a busy board, and to
                  // stay distinct from the last-move pip (REV-101).
                  final hintSize = coinW * 0.46;
                  coinWidgets.add(Positioned(
                    left: center.dx - hintSize / 2,
                    top: center.dy - hintSize / 2,
                    child: HintWidget(size: hintSize, palette: palette),
                  ));
                  continue;
                }

                coinWidgets.add(Positioned(
                  left: center.dx - coinW / 2,
                  top: center.dy - coinW / 2,
                  child: AnimatedDiscView(coin: _coinFor(disc!), size: coinW),
                ));
              }
            }

            if (anim != null) {
              final newCoin = _coinFor(anim.color);
              final oldDisc = anim.color == Disc.black ? Disc.white : Disc.black;
              final oldCoin = _coinFor(oldDisc);

              for (final pos in affected) {
                final (center, coinW) = cellGeometry(pos.row, pos.col);

                // The disc you just played is simply set down — only the discs
                // it captures turn over (REV-86).
                if (pos == anim.placed) {
                  coinWidgets.add(Positioned(
                    left: center.dx - coinW / 2,
                    top: center.dy - coinW / 2,
                    child: DiscView(coin: newCoin, size: coinW),
                  ));
                  continue;
                }

                // Wave timing: this coin's own 0..1 progress, delayed by its
                // ring distance from the placed coin.
                final dist = max(
                  (pos.row - anim.placed.row).abs(),
                  (pos.col - anim.placed.col).abs(),
                );
                final lp = ((p * _totalMs - dist * _staggerMs) / _coinMs)
                    .clamp(0.0, 1.0);

                // One perspective flip for every coin skin (REV-82/84), the
                // same on every board.
                coinWidgets.add(Positioned(
                  left: center.dx - coinW / 2,
                  top: center.dy - coinW / 2,
                  child: AnimatedDiscView(
                    coin: newCoin,
                    size: coinW,
                    flipFrom: oldCoin,
                    t: lp,
                  ),
                ));
              }
            }

            // Laid on top of the disc that was played last, so the move stays
            // findable now that the placed disc doesn't animate (REV-87).
            final lastMove = widget.lastMove;
            final lastDisc =
                lastMove == null ? null : widget.board[lastMove.row][lastMove.col];
            if (lastMove != null && lastDisc != null) {
              final (center, coinW) = cellGeometry(lastMove.row, lastMove.col);
              coinWidgets.add(Positioned(
                left: center.dx - coinW / 2,
                top: center.dy - coinW / 2,
                child: LastMoveMarker(coin: _coinFor(lastDisc), size: coinW),
              ));
            }

            return SizedBox(
              width: w,
              height: h,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final boardPt = MatrixUtils.transformPoint(
                      inverse, details.localPosition);
                  final fx = (boardPt.dx - _framePad) / cell;
                  final fy = (boardPt.dy - _framePad) / cell;
                  if (fx < 0 || fy < 0 || fx >= 8 || fy >= 8) return;
                  widget.onCellTap(Position(fy.floor(), fx.floor()));
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
                        child: Slab(
                          feltSize: feltSize,
                          framePad: _framePad,
                          palette: palette,
                        ),
                      ),
                    ),
                    ...coinWidgets,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Matrix4 _squareToQuad(double size, List<Offset> q) {
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

  a /= size; b /= size; d /= size; e /= size; gg /= size; hhh /= size;

  return Matrix4(
    a, d, 0, gg,
    b, e, 0, hhh,
    0, 0, 1, 0,
    c, f, 0, 1,
  );
}
