import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/game/reversi_game.dart';
import '../../../core/settings/app_settings.dart';
import '../../../shared/widgets/disc_view.dart';
import '../../../shared/widgets/last_move_marker.dart';
import '../../board/board_move.dart';
import '../online_tokens.dart';

/// 3D tilted wooden board faithful to the "Online Oyna" handoff: a board-crop
/// PNG with an 8x8 grid of disc PNGs overlaid, legal-move hints, and a
/// last-move marker. Walnut = black/you, Maple = white/opponent.
class OnlineBoard extends StatefulWidget {
  const OnlineBoard({
    super.key,
    required this.board,
    required this.validMoves,
    required this.lastMove,
    required this.showHints,
    required this.onCellTap,
    this.theme = BoardTheme.wood,
    this.blackCoin = CoinColor.walnut,
    this.whiteCoin = CoinColor.maple,
    this.move,
  });

  final List<List<Disc?>> board;
  final Set<Position> validMoves;
  final Position? lastMove;
  final bool showHints;
  final ValueChanged<Position> onCellTap;

  /// The disc skins for each side (REV-82) — any coin renders on any board.
  final CoinColor blackCoin;
  final CoinColor whiteCoin;

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

  // Flip wave: each disc flips for [_flipMs]; discs farther from the placed
  // disc start [_staggerMs] later per ring, so the flip ripples outward.
  static const int _flipMs = 1000;
  // Per-ring ripple delay — 0: all discs turn together (a ripple made
  // the player wait out the wave on long flip lines).
  static const int _staggerMs = 0;

  late final AnimationController _pulse;
  late final AnimationController _flip;
  BoardMove? _animMove;
  int _lastAnimatedId = 0;
  int _totalMs = _flipMs;

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
      duration: const Duration(milliseconds: _flipMs),
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
      _totalMs = _flipMs + _staggerMs * _maxRingDistance(move);
      _flip.duration = Duration(milliseconds: _totalMs);
      _flip.forward(from: 0);
    }
  }

  static int _maxRingDistance(BoardMove move) {
    var maxDist = 0;
    for (final f in move.flipped) {
      final d = math.max(
        (f.row - move.placed.row).abs(),
        (f.col - move.placed.col).abs(),
      );
      if (d > maxDist) maxDist = d;
    }
    return maxDist;
  }

  /// Local 0..1 progress of the disc at Chebyshev ring [dist] from the placed
  /// disc: 0 while the wave hasn't reached it, 1 once its flip is done.
  double _waveT(int dist) {
    final start = dist * _staggerMs / _totalMs;
    final span = _flipMs / _totalMs;
    return ((_flip.value - start) / span).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _flip.dispose();
    super.dispose();
  }

  /// The chosen coin skin for a board color (REV-82): any coin on any board.
  CoinColor _coinFor(Disc d) =>
      d == Disc.black ? widget.blackCoin : widget.whiteCoin;

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

    // Discs captured by the current move turn over. The just-placed disc is
    // simply set down (REV-86), so it falls through to the resting disc below —
    // which is also what carries the last-move marker.
    if (anim != null && disc != null && anim.flipped.contains(pos)) {
      final newColor = disc; // board already holds the post-move color
      final oldColor = newColor == Disc.black ? Disc.white : Disc.black;
      final dist = math.max(
        (pos.row - anim.placed.row).abs(),
        (pos.col - anim.placed.col).abs(),
      );
      // One perspective flip for every coin skin (REV-82/84).
      return Center(
        child: AnimatedDiscView(
          coin: _coinFor(newColor),
          size: discSize,
          flipFrom: _coinFor(oldColor),
          t: _waveT(dist),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (disc != null)
          Center(
            child: SizedBox(
              width: discSize,
              height: discSize,
              child: _Disc(coin: _coinFor(disc), size: discSize),
            ),
          ),
        // Laid on top of the disc played last (REV-87).
        if (disc != null && isLast)
          Center(
            child: LastMoveMarker(coin: _coinFor(disc), size: discSize),
          ),
        if (isHint) _Hint(cell: cell, pulse: _pulse, flower: _flower),
      ],
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.coin, required this.size});

  final CoinColor coin;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(anim),
          child: child,
        ),
      ),
      child: DiscView(key: ValueKey<CoinColor>(coin), coin: coin, size: size),
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
    final size = cell * 0.46;
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
                border: Border.all(color: ring, width: size * 0.15),
              ),
            ),
          ),
        );
      },
    );
  }
}
