import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/game/reversi_game.dart';
import '../online_tokens.dart';

/// 3D tilted wooden board faithful to the "Online Oyna" handoff: a board-crop
/// PNG with an 8x8 grid of disc PNGs overlaid, legal-move hints, and a
/// last-move ring. Walnut = black/you, Maple = white/opponent.
class OnlineBoard extends StatefulWidget {
  const OnlineBoard({
    super.key,
    required this.board,
    required this.validMoves,
    required this.lastMove,
    required this.showHints,
    required this.onCellTap,
  });

  final List<List<Disc?>> board;
  final Set<Position> validMoves;
  final Position? lastMove;
  final bool showHints;
  final ValueChanged<Position> onCellTap;

  @override
  State<OnlineBoard> createState() => _OnlineBoardState();
}

class _OnlineBoardState extends State<OnlineBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: OnlineTokens.boardAspect,
      child: Transform(
        alignment: const Alignment(0.0, 0.2), // origin: center 60%
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014) // perspective
          ..rotateX(-20 * math.pi / 180),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final left = w * OnlineTokens.gridLeft;
            final top = h * OnlineTokens.gridTop;
            final right = w * OnlineTokens.gridRight;
            final bottom = h * OnlineTokens.gridBottom;
            final cellW = (w - left - right) / 8;
            final cellH = (h - top - bottom) / 8;

            // Board image is the container's DecorationImage so the playfield
            // and the disc grid share a single RenderObject — this keeps them
            // aligned under the perspective transform.
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage(OnlineTokens.boardImage),
                  fit: BoxFit.fill,
                ),
                boxShadow: const [
                  // Stacked-edge depth (board thickness)
                  BoxShadow(color: Color(0xFF3A2613), offset: Offset(0, 4)),
                  BoxShadow(color: Color(0xFF311F0F), offset: Offset(0, 8)),
                  BoxShadow(color: Color(0xFF29190B), offset: Offset(0, 12)),
                  BoxShadow(color: Color(0xFF221407), offset: Offset(0, 16)),
                  BoxShadow(color: Color(0xFF1B1005), offset: Offset(0, 20)),
                  BoxShadow(
                    color: Color(0x8C000000),
                    offset: Offset(0, 26),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(left, top, right, bottom),
                child: _grid(cellW, cellH),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _grid(double cellW, double cellH) {
    return Column(
      children: List.generate(8, (r) {
        return Row(
          children: List.generate(8, (col) {
            final disc = widget.board[r][col];
            final pos = Position(r, col);
            final isHint = widget.showHints && widget.validMoves.contains(pos);
            final isLast = widget.lastMove == pos;
            return SizedBox(
              width: cellW,
              height: cellH,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onCellTap(pos),
                child: _cell(disc, isHint, isLast, math.min(cellW, cellH)),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _cell(Disc? disc, bool isHint, bool isLast, double cell) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (disc != null)
          Padding(
            padding: EdgeInsets.all(cell * 0.09),
            child: _Disc(disc: disc, isLast: isLast, pulse: _pulse),
          ),
        if (isHint) _Hint(cell: cell, pulse: _pulse),
      ],
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.disc, required this.isLast, required this.pulse});

  final Disc disc;
  final bool isLast;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final asset =
        disc == Disc.black ? OnlineTokens.discWalnut : OnlineTokens.discMaple;
    Widget image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(anim),
          child: child,
        ),
      ),
      child: Image.asset(asset, key: ValueKey<Disc>(disc), fit: BoxFit.contain),
    );

    if (!isLast) return image;

    // Last-move ring (rev-ring): pulsing accent border on the disc.
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = (math.sin(pulse.value * 2 * math.pi) + 1) / 2;
        return Stack(
          alignment: Alignment.center,
          children: [
            child!,
            Positioned.fill(
              child: Transform.scale(
                scale: 0.9 + 0.15 * t,
                child: Opacity(
                  opacity: 0.4 + 0.55 * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OnlineTokens.lastMoveRing,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: image,
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.cell, required this.pulse});

  final double cell;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final size = cell * 0.3;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = (math.sin(pulse.value * 2 * math.pi) + 1) / 2;
        return Transform.scale(
          scale: 0.82 + 0.18 * t,
          child: Opacity(
            opacity: 0.5 + 0.45 * t,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: OnlineTokens.hintFill,
                shape: BoxShape.circle,
                border: Border.all(color: OnlineTokens.hintRing, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
