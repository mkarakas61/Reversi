import 'dart:math';

import 'package:flutter/material.dart';

import '../game/app_settings.dart';
import '../game/reversi_game.dart';
import '../theme/game_theme.dart';
import 'coin_view.dart';

/// The tilted wooden Reversi table. The slab (frame + felt + engraved grid) is
/// warped into a trapezoid — bottom edge flush to the screen edges, top edge
/// inset — so it reads as a real table receding away from the viewer. Coins
/// are billboarded on top at the projected cell centres; taps are mapped back
/// through the inverse transform.
/// Describes the most recent placement so [WoodBoard] can play the flip
/// animation. [id] increments per move; the board animates whenever it changes.
class BoardMove {
  const BoardMove({
    required this.id,
    required this.placed,
    required this.flipped,
    required this.color,
  });

  final int id;

  /// Cell where the new disc was dropped.
  final Position placed;

  /// Cells whose discs were captured (and so flip to [color]).
  final Set<Position> flipped;

  /// Colour of the player who moved — the new colour of every affected cell.
  final Disc color;
}

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

  /// Slab look. [BoardTheme.wood] keeps the image-textured table; the rest are
  /// flat-colour palettes from [boardPalettes].
  final BoardTheme theme;

  /// Coin skins for the [Disc.black] (bottom / "Sen") and [Disc.white]
  /// (top / "Aria") sides.
  final CoinColor blackCoin;
  final CoinColor whiteCoin;

  /// The move to animate, or `null` for a static board.
  final BoardMove? move;

  @override
  State<WoodBoard> createState() => _WoodBoardState();
}

class _WoodBoardState extends State<WoodBoard>
    with SingleTickerProviderStateMixin {
  static const _framePad = 14.0; // wood border around the felt
  static const _faceSquash = 0.74;
  static const _thicknessFactor = 0.18;

  // The whole place + flip + drop choreography. A calmer one-second tempo to
  // match the deliberate pace of the game.
  static const _duration = Duration(milliseconds: 1000);
  // Fraction of the timeline spent rising and spinning; the rest is the drop.
  static const _riseFrac = 0.6;

  late final AnimationController _flip;
  BoardMove? _anim; // the move currently animating (null when settled)
  int _lastAnimatedId = 0;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(vsync: this, duration: _duration);
    _flip.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _anim = null);
      }
    });
    _lastAnimatedId = widget.move?.id ?? 0; // don't replay the initial board
  }

  @override
  void didUpdateWidget(WoodBoard old) {
    super.didUpdateWidget(old);
    final move = widget.move;
    if (move != null && move.id != _lastAnimatedId) {
      _lastAnimatedId = move.id;
      _anim = move;
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
    final palette = boardPalettes[widget.theme]; // null → wooden slab
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

        // Projected centre and on-screen diameter for cell (r, c).
        (Offset, double) cellGeometry(int r, int c) {
          final centerLocal = Offset(
              _framePad + (c + 0.5) * cell, _framePad + (r + 0.5) * cell);
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

            // ── settled coins + move hints ────────────────────────────
            for (var r = 0; r < ReversiGame.size; r++) {
              for (var c = 0; c < ReversiGame.size; c++) {
                final pos = Position(r, c);
                if (affected.contains(pos)) continue; // drawn by the animation
                final disc = widget.board[r][c];
                final isHint = disc == null && widget.validMoves.contains(pos);
                if (disc == null && !isHint) continue;

                final (center, coinW) = cellGeometry(r, c);

                if (isHint) {
                  final hintSize = coinW * 0.34;
                  coinWidgets.add(Positioned(
                    left: center.dx - hintSize / 2,
                    top: center.dy - hintSize / 2,
                    child: _Hint(size: hintSize, palette: palette),
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

            // ── animating coins (place + flips) ───────────────────────
            if (anim != null) {
              final newPalette = coinPalettes[_coinFor(anim.color)]!;
              final oldDisc =
                  anim.color == Disc.black ? Disc.white : Disc.black;
              final oldPalette = coinPalettes[_coinFor(oldDisc)]!;

              // Drop progress (0 until the rise/flip finishes, then 0→1).
              final drop = p <= _riseFrac
                  ? 0.0
                  : Curves.easeInCubic
                      .transform(((p - _riseFrac) / (1 - _riseFrac)));
              final riseP = (p / _riseFrac).clamp(0.0, 1.0);

              for (final pos in affected) {
                final (center, coinW) = cellGeometry(pos.row, pos.col);
                final hover = coinW * 1.15;
                final faceHeight = coinW * _faceSquash;
                final totalH = faceHeight + coinW * _thicknessFactor;
                final isPlaced = pos == anim.placed;

                if (isPlaced) {
                  // Forms above the cell, waits, then drops straight down.
                  final yUp = hover * (1 - drop);
                  final opacity = (p / 0.10).clamp(0.0, 1.0);
                  coinWidgets.add(Positioned(
                    left: center.dx - coinW / 2,
                    top: center.dy - totalH / 2 - yUp,
                    child: Opacity(
                      opacity: opacity,
                      child: CoinView(
                        palette: newPalette,
                        width: coinW,
                        faceSquash: _faceSquash,
                        thicknessFactor: _thicknessFactor,
                      ),
                    ),
                  ));
                } else {
                  // Rises while spinning 1.5 turns (so it lands on the new
                  // colour), then drops with the others without spinning.
                  final yUp = p <= _riseFrac
                      ? hover * Curves.easeOutCubic.transform(riseP)
                      : hover * (1 - drop);
                  final angle = p <= _riseFrac
                      ? (3 * pi) * Curves.easeInOut.transform(riseP)
                      : 3 * pi;
                  // Align the flip coin's face centre with a settled coin's.
                  final faceCenterY = center.dy - coinW * _thicknessFactor / 2;
                  coinWidgets.add(Positioned(
                    left: center.dx - coinW / 2,
                    top: faceCenterY - coinW / 2 - yUp,
                    child: _FlipCoin(
                      width: coinW,
                      angle: angle,
                      front: oldPalette,
                      back: newPalette,
                    ),
                  ));
                }
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
                        child: _Slab(
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

/// Builds a Matrix4 mapping the local square [0,size]² onto the quad
/// [q0,q1,q2,q3] (TL, TR, BR, BL) — a planar perspective homography.
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

/// A coin caught mid-flip: a billboarded disc spinning about its horizontal
/// axis. The face foreshortens with the rotation and swaps colour as it turns,
/// so both faces show during the spin.
class _FlipCoin extends StatelessWidget {
  const _FlipCoin({
    required this.width,
    required this.angle,
    required this.front,
    required this.back,
  });

  final double width;

  /// Rotation about the horizontal axis, in radians.
  final double angle;

  /// Palette shown at angle 0 (the original colour) …
  final CoinPalette front;

  /// … and the palette shown once flipped (the new colour).
  final CoinPalette back;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width,
      child: CustomPaint(
        painter: _FlipCoinPainter(angle: angle, front: front, back: back),
      ),
    );
  }
}

class _FlipCoinPainter extends CustomPainter {
  _FlipCoinPainter({
    required this.angle,
    required this.front,
    required this.back,
  });

  final double angle;
  final CoinPalette front;
  final CoinPalette back;

  static const _faceSquash = 0.74;
  static const _thicknessFactor = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, size.height / 2);
    final cosA = cos(angle);
    final ac = cosA.abs();
    // The face we see depends on which way the coin is turned.
    final pal = cosA >= 0 ? front : back;

    final faceH = w * _faceSquash * ac;
    final edgeH = max(faceH, w * _thicknessFactor);

    // Rim / edge band — all that remains when the coin is near edge-on.
    final edgeRect = Rect.fromCenter(center: center, width: w, height: edgeH);
    final edgeShader = LinearGradient(
      colors: [pal.edgeDark, pal.edgeLight, pal.edgeDark],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(edgeRect);
    canvas.drawOval(edgeRect, Paint()..shader = edgeShader);

    if (faceH > 0.5) {
      final faceRect = Rect.fromCenter(
        center: center,
        width: w * 0.93,
        height: faceH * 0.93,
      );
      final faceShader = RadialGradient(
        center: const Alignment(-0.24, -0.36),
        radius: 0.95,
        colors: [pal.faceTop, pal.faceMid, pal.faceBottom],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(faceRect);
      canvas.drawOval(faceRect, Paint()..shader = faceShader);

      // rim shading
      canvas.drawOval(
        faceRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceH * 0.05
          ..color = Colors.white.withValues(alpha: pal.rimAlpha),
      );

      // gloss highlight, fading out as the face turns edge-on
      if (ac > 0.25) {
        final glossRect = Rect.fromLTWH(
          faceRect.left + w * 0.24,
          faceRect.top + faceH * 0.12,
          w * 0.34,
          faceH * 0.26,
        );
        final glossShader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: pal.glossAlpha * ac),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.72],
        ).createShader(glossRect);
        canvas.drawOval(glossRect, Paint()..shader = glossShader);
      }
    }
  }

  @override
  bool shouldRepaint(_FlipCoinPainter old) =>
      old.angle != angle || old.front != front || old.back != back;
}

class _Slab extends StatelessWidget {
  const _Slab({
    required this.feltSize,
    required this.framePad,
    required this.palette,
  });

  final double feltSize;
  final double framePad;

  /// `null` renders the original wooden textures; otherwise a flat-colour slab.
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
          child: CustomPaint(painter: _GridPainter(palette: p)),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.palette});

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
      canvas.drawLine(Offset(1.6, pos + 1.6), Offset(size.width, pos + 1.6), hi);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), line);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), line);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.palette != palette;
}

class _Hint extends StatefulWidget {
  const _Hint({required this.size, required this.palette});

  final double size;
  final BoardPalette? palette;

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
    final p = widget.palette;
    // Wood keeps the cream-on-walnut engraved spot; colour boards reuse their
    // own engraved-line palette so the hint reads against any felt.
    final fill = p == null ? const Color(0x2E281709) : p.line;
    final ring = p == null ? const Color(0x73FFF0D2) : p.lineHi;
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: ring, width: 2),
        ),
      ),
    );
  }
}
