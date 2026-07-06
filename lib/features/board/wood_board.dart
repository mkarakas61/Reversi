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
  // Flip wave: one coin's turn takes [_coinMs]; coins farther from the
  // placed coin start [_staggerMs] later per ring, rippling outward.
  static const _coinMs = 1400;
  static const _staggerMs = 190;

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

                // One continuous 3D rotation with perspective, driven by the
                // TRUE angle: both faces are real planes on either side of
                // the slab (the back face pre-mirrored so it reads upright
                // once it comes around), with a stack of edge-colored slices
                // as the side wall. The color change is a genuine face
                // change — no crossfades, no flicker.
                final facing = cos(angle);
                final ac = facing.abs();
                final frontPal = isPlaced ? newPalette : oldPalette;
                final edgeMidL = Color.lerp(
                    frontPal.edgeLight, newPalette.edgeLight, lp)!;
                final edgeMidD = Color.lerp(
                    frontPal.edgeDark, newPalette.edgeDark, lp)!;

                final thickness = coinW * 0.17;

                Matrix4 plane(double z, {bool mirrored = false}) {
                  final m = Matrix4.identity()
                    ..setEntry(3, 2, 0.15 / coinW)
                    ..rotateX(angle)
                    ..translateByDouble(0.0, 0.0, z, 1.0);
                  if (mirrored) m.rotateX(pi);
                  return m;
                }

                final frontFace = Transform(
                  alignment: Alignment.center,
                  transform: plane(-thickness / 2),
                  child: FlipCoin(
                    width: coinW,
                    angle: 0,
                    front: frontPal,
                    back: newPalette,
                  ),
                );
                final backFace = Transform(
                  alignment: Alignment.center,
                  transform: plane(thickness / 2, mirrored: true),
                  child: FlipCoin(
                    width: coinW,
                    angle: 0,
                    front: newPalette,
                    back: newPalette,
                  ),
                );

                const sideSlices = 10;
                final slices = <Widget>[
                  for (var i = 0; i <= sideSlices; i++)
                    Builder(builder: (_) {
                      final z =
                          thickness * (i / sideSlices - 0.5); // -T/2..+T/2
                      final zz = 2 * z / thickness; // -1..1
                      final w = coinW * 0.86 * (1 - 0.12 * zz * zz);
                      final h = w * _faceSquash;
                      return Transform(
                        alignment: Alignment.center,
                        transform: plane(z),
                        child: Container(
                          width: w,
                          height: h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [edgeMidL, edgeMidD],
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(w / 2, h / 2),
                            ),
                          ),
                        ),
                      );
                    }),
                ];

                // Thin rim bar bridges the frames where every plane is
                // edge-on and would otherwise vanish.
                final rimOpacity = ((0.08 - ac) / 0.08).clamp(0.0, 1.0);

                coinWidgets.add(Positioned(
                  left: center.dx - coinW / 2,
                  top: faceCenterY - coinW / 2 - yUp,
                  child: Opacity(
                    opacity: opacity,
                    child: SizedBox(
                      width: coinW,
                      height: coinW,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (rimOpacity > 0)
                            Opacity(
                              opacity: rimOpacity,
                              child: Container(
                                width: coinW * 0.86,
                                height: thickness,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    edgeMidD,
                                    edgeMidL,
                                    edgeMidD,
                                  ]),
                                  borderRadius: BorderRadius.all(
                                    Radius.elliptical(
                                        coinW * 0.43, thickness / 2),
                                  ),
                                ),
                              ),
                            ),
                          // Painter's order: far face, side wall, near face.
                          if (facing >= 0) ...[
                            backFace,
                            ...slices.reversed,
                            frontFace,
                          ] else ...[
                            frontFace,
                            ...slices,
                            backFace,
                          ],
                        ],
                      ),
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
