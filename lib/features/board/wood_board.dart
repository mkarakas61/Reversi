import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/game/reversi_game.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/board_palette.dart';
import '../../core/theme/coin_palette.dart';
import '../../shared/widgets/coin_view.dart';
import 'board_move.dart';
import 'painters/flip_coin_painter.dart';
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
  static const _faceSquash = 0.74;
  static const _thicknessFactor = 0.18;
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
          final centerLocal =
              Offset(_framePad + (c + 0.5) * cell, _framePad + (r + 0.5) * cell);
          final center = project(centerLocal);
          final edge = project(centerLocal + Offset(cell / 2, 0));
          final coinW = (edge.dx - center.dx).abs() * 2 * 0.86;
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
                  final hintSize = coinW * 0.34;
                  coinWidgets.add(Positioned(
                    left: center.dx - hintSize / 2,
                    top: center.dy - hintSize / 2,
                    child: HintWidget(size: hintSize, palette: palette),
                  ));
                  continue;
                }

                final faceHeight = coinW * _faceSquash;
                final totalH = faceHeight + coinW * _thicknessFactor;
                coinWidgets.add(Positioned(
                  left: center.dx - coinW / 2,
                  top: center.dy - totalH / 2,
                  child: CoinView(
                    palette: coinPalettes[_coinFor(disc!)]!,
                    width: coinW,
                    faceSquash: _faceSquash,
                    thicknessFactor: _thicknessFactor,
                  ),
                ));
              }
            }

            if (anim != null) {
              final newPalette = coinPalettes[_coinFor(anim.color)]!;
              final oldDisc = anim.color == Disc.black ? Disc.white : Disc.black;
              final oldPalette = coinPalettes[_coinFor(oldDisc)]!;

              for (final pos in affected) {
                final (center, coinW) = cellGeometry(pos.row, pos.col);
                final hover = coinW * 1.15;
                final faceHeight = coinW * _faceSquash;
                final totalH = faceHeight + coinW * _thicknessFactor;
                final isPlaced = pos == anim.placed;

                // Wave timing: this coin's own 0..1 progress, delayed by its
                // ring distance from the placed coin.
                final dist = max(
                  (pos.row - anim.placed.row).abs(),
                  (pos.col - anim.placed.col).abs(),
                );
                final lp = ((p * _totalMs - dist * _staggerMs) / _coinMs)
                    .clamp(0.0, 1.0);

                if (lp == 0) {
                  // The wave hasn't reached this coin yet: flipped coins still
                  // rest in their old color; the placed coin isn't there yet.
                  if (isPlaced) continue;
                  coinWidgets.add(Positioned(
                    left: center.dx - coinW / 2,
                    top: center.dy - totalH / 2,
                    child: CoinView(
                      palette: oldPalette,
                      width: coinW,
                      faceSquash: _faceSquash,
                      thicknessFactor: _thicknessFactor,
                    ),
                  ));
                  continue;
                }

                // Same choreography for every coin, like turning a hand
                // over: a gentle gravity arc with a single half-turn at
                // constant angular speed, coming to rest the moment the turn
                // completes — no impact effects. The placed coin simply has
                // its own color on both faces.
                // Brisk launch, then a gentle float down that settles with
                // zero vertical speed — no abrupt "click" at touchdown.
                final height =
                    sin(pi * Curves.easeOutSine.transform(lp));
                final yUp = hover * height;
                final angle = pi * lp;

                // The placed coin pops in almost instantly (no ghost).
                final opacity =
                    isPlaced ? (lp / 0.05).clamp(0.0, 1.0) : 1.0;
                final faceCenterY = center.dy - coinW * _thicknessFactor / 2;

                // A single clean half-turn drawn by FlipCoinPainter: the
                // face shortens with |cos|, the color changes exactly at
                // the edge-on midpoint, and the edge keeps a minimum
                // thickness so the coin never vanishes mid-turn. The
                // placed coin shows its own color on both faces.
                coinWidgets.add(Positioned(
                  left: center.dx - coinW / 2,
                  top: faceCenterY - coinW / 2 - yUp,
                  child: Opacity(
                    opacity: opacity,
                    child: FlipCoin(
                      width: coinW,
                      angle: angle,
                      front: isPlaced ? newPalette : oldPalette,
                      back: newPalette,
                    ),
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
