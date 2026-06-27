import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/game/reversi_game.dart';
import '../../../core/settings/app_settings.dart';
import '../../board/board_move.dart';
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
    this.theme = BoardTheme.wood,
    this.move,
  });

  final List<List<Disc?>> board;
  final Set<Position> validMoves;
  final Position? lastMove;
  final bool showHints;
  final ValueChanged<Position> onCellTap;

  /// Selected board variant. [mermer] renders the marble slab + marble discs;
  /// [cicek] renders the floral board; everything else renders the wood board.
  /// Both wood and cicek reuse the warm wood discs.
  final BoardTheme theme;

  /// Last move's placed + flipped discs, used to drive the 3D flip animation.
  final BoardMove? move;

  @override
  State<OnlineBoard> createState() => _OnlineBoardState();
}

class _OnlineBoardState extends State<OnlineBoard>
    with TickerProviderStateMixin {
  // Disc diameter as a fraction of the cell's short side (centered in cell),
  // leaving a little breathing room inside each square.
  static const double _discFactor = 0.82;

  late final AnimationController _pulse;
  late final AnimationController _flip;
  BoardMove? _animMove;
  int _lastAnimatedId = 0;

  bool get _marble => widget.theme == BoardTheme.mermer;
  bool get _flower => widget.theme == BoardTheme.cicek;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _flip.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _animMove = null);
      }
    });
    _lastAnimatedId = widget.move?.id ?? 0;
  }

  @override
  void didUpdateWidget(OnlineBoard old) {
    super.didUpdateWidget(old);
    final move = widget.move;
    if (move != null && move.id != _lastAnimatedId) {
      _lastAnimatedId = move.id;
      _animMove = move;
      _flip.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _flip.dispose();
    super.dispose();
  }

  String _discAsset(Disc d) {
    if (_marble) {
      return d == Disc.black
          ? OnlineTokens.marbleDiscBlack
          : OnlineTokens.marbleDiscWhite;
    }
    if (_flower) {
      return d == Disc.black
          ? OnlineTokens.flowerDiscBlack
          : OnlineTokens.flowerDiscWhite;
    }
    return d == Disc.black ? OnlineTokens.discWalnut : OnlineTokens.discMaple;
  }

  // Edge (rim) color shown while a disc is rotating on its side, so the flip
  // reads as a real coin with thickness instead of a vanishing flat image.
  Color _discEdge(Disc d) {
    if (_marble) {
      return d == Disc.black
          ? const Color(0xFF111114)
          : const Color(0xFFC9C3B5);
    }
    if (_flower) {
      // Rose-gold rim tones for the flower coins.
      return d == Disc.black
          ? const Color(0xFF5A1B38) // deep wine rim under the purple coin
          : const Color(0xFFD9A9A6); // soft rose rim under the pink coin
    }
    return d == Disc.black
        ? const Color(0xFF2E1C0E)
        : const Color(0xFFB98E55);
  }

  @override
  Widget build(BuildContext context) {
    final double aspect;
    final String boardImage;
    final double gridLeft, gridTop, gridRight, gridBottom;
    final List<BoxShadow> shadow;
    if (_flower) {
      aspect = OnlineTokens.flowerBoardAspect;
      boardImage = OnlineTokens.flowerBoardImage;
      gridLeft = OnlineTokens.flowerGridLeft;
      gridTop = OnlineTokens.flowerGridTop;
      gridRight = OnlineTokens.flowerGridRight;
      gridBottom = OnlineTokens.flowerGridBottom;
      shadow = _flowerShadow;
    } else if (_marble) {
      aspect = OnlineTokens.marbleBoardAspect;
      boardImage = OnlineTokens.marbleBoardImage;
      gridLeft = OnlineTokens.marbleGridLeft;
      gridTop = OnlineTokens.marbleGridTop;
      gridRight = OnlineTokens.marbleGridRight;
      gridBottom = OnlineTokens.marbleGridBottom;
      shadow = _marbleShadow;
    } else {
      aspect = OnlineTokens.boardAspect;
      boardImage = OnlineTokens.boardImage;
      gridLeft = OnlineTokens.gridLeft;
      gridTop = OnlineTokens.gridTop;
      gridRight = OnlineTokens.gridRight;
      gridBottom = OnlineTokens.gridBottom;
      shadow = _woodShadow;
    }

    // All boards share the same 20° tilt / perspective.
    final Matrix4 boardTransform = Matrix4.identity()
      ..setEntry(3, 2, 0.0014) // perspective
      ..rotateX(-20 * math.pi / 180);

    return AspectRatio(
      aspectRatio: aspect,
      child: Transform(
        alignment: const Alignment(0.0, 0.2), // origin: center 60%
        transform: boardTransform,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final left = w * gridLeft;
            final top = h * gridTop;
            final right = w * gridRight;
            final bottom = h * gridBottom;
            final cellW = (w - left - right) / 8;
            final cellH = (h - top - bottom) / 8;

            // Board image is the container's DecorationImage so the playfield
            // and the disc grid share a single RenderObject — this keeps them
            // aligned under the perspective transform.
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(boardImage),
                  fit: BoxFit.fill,
                ),
                boxShadow: shadow,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(left, top, right, bottom),
                child: AnimatedBuilder(
                  animation: _flip,
                  builder: (_, __) => _grid(cellW, cellH),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Stacked-edge depth (board thickness) for the warm wood board.
  static const List<BoxShadow> _woodShadow = [
    BoxShadow(color: Color(0xFF3A2613), offset: Offset(0, 4)),
    BoxShadow(color: Color(0xFF311F0F), offset: Offset(0, 8)),
    BoxShadow(color: Color(0xFF29190B), offset: Offset(0, 12)),
    BoxShadow(color: Color(0xFF221407), offset: Offset(0, 16)),
    BoxShadow(color: Color(0xFF1B1005), offset: Offset(0, 20)),
    BoxShadow(color: Color(0x8C000000), offset: Offset(0, 26), blurRadius: 30),
  ];

  // Cooler, shorter depth for the marble slab.
  static const List<BoxShadow> _marbleShadow = [
    BoxShadow(color: Color(0xFF2A2A2E), offset: Offset(0, 4)),
    BoxShadow(color: Color(0xFF202024), offset: Offset(0, 8)),
    BoxShadow(color: Color(0xFF18181B), offset: Offset(0, 12)),
    BoxShadow(color: Color(0x8C000000), offset: Offset(0, 20), blurRadius: 28),
  ];

  // Stacked cream/beige edge to fake board thickness (a 3D slab), then a soft
  // ground shadow — same idea as the wood board but in warm pale tones.
  static const List<BoxShadow> _flowerShadow = [
    BoxShadow(color: Color(0xFFE7DAC8), offset: Offset(0, 3)),
    BoxShadow(color: Color(0xFFDBCBB4), offset: Offset(0, 6)),
    BoxShadow(color: Color(0xFFCEBC9F), offset: Offset(0, 9)),
    BoxShadow(color: Color(0xFFC1AE8D), offset: Offset(0, 12)),
    BoxShadow(color: Color(0xFFB3A07E), offset: Offset(0, 15)),
    BoxShadow(color: Color(0x8C000000), offset: Offset(0, 24), blurRadius: 30),
  ];

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
                child: _cell(pos, disc, isHint, isLast, math.min(cellW, cellH)),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _cell(Position pos, Disc? disc, bool isHint, bool isLast, double cell) {
    final anim = _animMove;

    // Disc diameter is a fixed fraction of the (square) cell, so every disc is
    // centered and proportionally sized on every board and page. Flower coins
    // sit a touch smaller so they don't crowd their cells.
    final discSize = cell * (_flower ? 0.82 : _discFactor);

    // Animating disc (flip or just-placed) for the current move.
    if (anim != null && disc != null) {
      final t = Curves.easeInOut.transform(_flip.value);
      if (pos == anim.placed) {
        // Newly placed disc: scale + fade in.
        final o = (_flip.value / 0.3).clamp(0.0, 1.0);
        return Center(
          child: SizedBox(
            width: discSize,
            height: discSize,
            child: Opacity(
              opacity: o,
              child: Transform.scale(
                scale: 0.55 + 0.45 * o,
                child: Image.asset(_discAsset(disc), fit: BoxFit.contain),
              ),
            ),
          ),
        );
      }
      if (anim.flipped.contains(pos)) {
        final newColor = disc; // board already holds the post-move color
        final oldColor = newColor == Disc.black ? Disc.white : Disc.black;
        return Center(
          child: _FlipDisc(
            t: t,
            size: discSize,
            frontAsset: _discAsset(oldColor),
            backAsset: _discAsset(newColor),
            frontEdge: _discEdge(oldColor),
            backEdge: _discEdge(newColor),
          ),
        );
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (disc != null)
          Center(
            child: SizedBox(
              width: discSize,
              height: discSize,
              child: _Disc(
                disc: disc,
                asset: _discAsset(disc),
                isLast: isLast,
                pulse: _pulse,
              ),
            ),
          ),
        if (isHint) _Hint(cell: cell, pulse: _pulse, flower: _flower),
      ],
    );
  }
}

/// A disc performing a 3D half-turn flip on its horizontal axis. The face
/// image is squashed vertically as it rotates and an always-visible rim bar
/// gives the disc a real coin thickness, so it never vanishes at the edge-on
/// midpoint. A subtle lift at the peak adds a tactile "snap".
class _FlipDisc extends StatelessWidget {
  const _FlipDisc({
    required this.t,
    required this.size,
    required this.frontAsset,
    required this.backAsset,
    required this.frontEdge,
    required this.backEdge,
  });

  final double t; // eased 0..1
  final double size;
  final String frontAsset; // shown before midpoint (old color)
  final String backAsset; // shown after midpoint (new color)
  final Color frontEdge;
  final Color backEdge;

  static const double _thicknessFactor = 0.16;

  @override
  Widget build(BuildContext context) {
    final angle = t * math.pi; // single half-turn
    final ac = math.cos(angle).abs(); // 1 -> 0 -> 1 (face foreshortening)
    final showBack = t >= 0.5;
    final asset = showBack ? backAsset : frontAsset;
    final edge = showBack ? backEdge : frontEdge;

    final faceH = size * ac;
    final edgeH = math.max(faceH, size * _thicknessFactor);
    final lift = math.sin(t * math.pi); // 0 -> 1 -> 0

    return FractionalTranslation(
      translation: Offset(0, -0.18 * lift),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rim / thickness — always visible, so the edge-on moment reads as
            // a coin standing on its side rather than disappearing.
            Container(
              width: size * 0.95,
              height: edgeH,
              decoration: BoxDecoration(
                color: edge,
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size * 0.475, edgeH / 2),
                ),
              ),
            ),
            // Foreshortened face.
            if (ac > 0.04)
              SizedBox(
                width: size,
                height: faceH,
                child: Image.asset(asset, fit: BoxFit.fill),
              ),
          ],
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.disc,
    required this.asset,
    required this.isLast,
    required this.pulse,
  });

  final Disc disc;
  final String asset;
  final bool isLast;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
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
  const _Hint({required this.cell, required this.pulse, this.flower = false});

  final double cell;
  final AnimationController pulse;
  final bool flower;

  @override
  Widget build(BuildContext context) {
    final size = cell * 0.3;
    // The flower board's pale cream center washes out the amber hint, so use a
    // darker wine/rose dot with high contrast there.
    final fill = flower ? const Color(0x807A3B52) : OnlineTokens.hintFill;
    final ring = flower ? const Color(0xCC5A1B38) : OnlineTokens.hintRing;
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
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
