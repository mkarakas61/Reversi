import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Win celebration for the Çiçek board: peonies and wisteria sprigs echoing
/// the frame's artwork bloom out of the board's floral border, float calmly
/// upward with a slow spin, and loose petals flutter back down. One unhurried
/// pass, entirely canvas-drawn — no extra image assets.
class FlowerCelebration extends StatefulWidget {
  const FlowerCelebration({super.key, required this.boardKey});

  /// Key of the board widget the flowers grow out of.
  final GlobalKey boardKey;

  @override
  State<FlowerCelebration> createState() => _FlowerCelebrationState();
}

class _FlowerCelebrationState extends State<FlowerCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline;
  List<_Bloom> _blooms = const [];
  List<_Petal> _petals = const [];

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    // The board was laid out on an earlier frame; measure it once we are too.
    WidgetsBinding.instance.addPostFrameCallback((_) => _seed());
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  void _seed() {
    if (!mounted) return;
    final board =
        widget.boardKey.currentContext?.findRenderObject() as RenderBox?;
    final own = context.findRenderObject() as RenderBox?;
    if (board == null || own == null || !board.hasSize || !own.hasSize) return;
    final rect =
        own.globalToLocal(board.localToGlobal(Offset.zero)) & board.size;

    final random = math.Random();
    final w = rect.width;
    final h = rect.height;

    // The painted floral frame occupies roughly the outer tenth of the board
    // image, so everything spawns on a band just inside the rim.
    final band = rect.deflate(w * 0.07);

    _Bloom bloom(_BloomKind kind, Offset origin, double radius) {
      // Outward horizontal lean: left-side flowers drift left, right-side
      // right, so they part around the result card instead of piling behind.
      final lean = (origin.dx - rect.center.dx) / (w / 2);
      return _Bloom(
        kind: kind,
        origin: origin,
        radius: radius,
        delay: random.nextDouble() * 0.30,
        rise: h * (0.32 + random.nextDouble() * 0.36),
        drift: lean * w * 0.08 + (random.nextDouble() - 0.5) * w * 0.05,
        spin: (random.nextDouble() - 0.5) * 0.8,
        swayAmp: w * (0.010 + random.nextDouble() * 0.018),
        swayCycles: 1.2 + random.nextDouble() * 0.8,
        swayPhase: random.nextDouble() * 2 * math.pi,
      );
    }

    final blooms = <_Bloom>[];
    // The frame's corners carry the big peony blossoms: two per corner.
    for (final corner in [
      band.topLeft,
      band.topRight,
      band.bottomRight,
      band.bottomLeft,
    ]) {
      for (var i = 0; i < 2; i++) {
        final jitter = Offset(
          (random.nextDouble() - 0.5) * w * 0.10,
          (random.nextDouble() - 0.5) * w * 0.06,
        );
        blooms.add(bloom(
          random.nextDouble() < 0.62
              ? _BloomKind.pinkPeony
              : _BloomKind.whitePeony,
          corner + jitter,
          w * (0.050 + random.nextDouble() * 0.028),
        ));
      }
    }
    // Wisteria sprigs rise from the edge runs between the corners.
    for (final origin in [
      Offset(band.left + band.width * 0.35, band.top),
      Offset(band.left + band.width * 0.65, band.top),
      Offset(band.left, band.top + band.height * 0.5),
      Offset(band.right, band.top + band.height * 0.5),
      Offset(band.left + band.width * 0.35, band.bottom),
      Offset(band.left + band.width * 0.65, band.bottom),
    ]) {
      blooms.add(bloom(
        _BloomKind.wisteria,
        origin,
        w * (0.045 + random.nextDouble() * 0.020),
      ));
    }

    // Loose petals tossed off the frame that flutter back down.
    final petals = <_Petal>[
      for (var i = 0; i < 18; i++)
        _Petal(
          origin: _onBand(band, random),
          radius: w * (0.011 + random.nextDouble() * 0.009),
          color: _petalPalette[random.nextInt(_petalPalette.length)],
          delay: random.nextDouble() * 0.45,
          up: h * (0.10 + random.nextDouble() * 0.12),
          fall: h * (0.16 + random.nextDouble() * 0.22),
          drift: (random.nextDouble() - 0.5) * w * 0.18,
          spin: (random.nextDouble() - 0.5) * 6,
          swayAmp: w * (0.008 + random.nextDouble() * 0.012),
          swayCycles: 1.5 + random.nextDouble() * 1.5,
          swayPhase: random.nextDouble() * 2 * math.pi,
        ),
    ];

    setState(() {
      _blooms = blooms;
      _petals = petals;
    });
    _timeline.forward(from: 0);
  }

  /// A random point on the frame band's perimeter.
  static Offset _onBand(Rect band, math.Random random) {
    final u = random.nextDouble();
    switch (random.nextInt(4)) {
      case 0:
        return Offset(band.left + band.width * u, band.top);
      case 1:
        return Offset(band.left + band.width * u, band.bottom);
      case 2:
        return Offset(band.left, band.top + band.height * u);
      default:
        return Offset(band.right, band.top + band.height * u);
    }
  }

  static const _petalPalette = [
    Color(0xFFE58FA6), // peony pink
    Color(0xFFF3B7C6), // pale pink
    Color(0xFFB493D6), // wisteria lilac
    Color(0xFFF3E9DC), // cream
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _CelebrationPainter(_timeline, _blooms, _petals),
          ),
        ),
      ),
    );
  }
}

enum _BloomKind { pinkPeony, whitePeony, wisteria }

class _Bloom {
  const _Bloom({
    required this.kind,
    required this.origin,
    required this.radius,
    required this.delay,
    required this.rise,
    required this.drift,
    required this.spin,
    required this.swayAmp,
    required this.swayCycles,
    required this.swayPhase,
  });

  final _BloomKind kind;
  final Offset origin;
  final double radius;
  final double delay; // 0..1 fraction of the timeline before it appears
  final double rise; // total upward travel in px
  final double drift; // total horizontal travel in px
  final double spin; // total rotation in radians (kept small and slow)
  final double swayAmp;
  final double swayCycles;
  final double swayPhase;
}

class _Petal {
  const _Petal({
    required this.origin,
    required this.radius,
    required this.color,
    required this.delay,
    required this.up,
    required this.fall,
    required this.drift,
    required this.spin,
    required this.swayAmp,
    required this.swayCycles,
    required this.swayPhase,
  });

  final Offset origin;
  final double radius;
  final Color color;
  final double delay;
  final double up; // initial toss height in px
  final double fall; // how far below the spawn point it settles
  final double drift;
  final double spin;
  final double swayAmp;
  final double swayCycles;
  final double swayPhase;
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.time, this.blooms, this.petals)
      : super(repaint: time);

  final Animation<double> time;
  final List<_Bloom> blooms;
  final List<_Petal> petals;

  /// Local 0..1 progress of a particle that starts at [delay].
  static double _local(double t, double delay) =>
      ((t - delay) / (1 - delay)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    if (t <= 0 || t >= 1) return;
    for (final p in petals) {
      _paintPetal(canvas, p, _local(t, p.delay));
    }
    for (final b in blooms) {
      _paintBloom(canvas, b, _local(t, b.delay));
    }
  }

  void _paintBloom(Canvas canvas, _Bloom b, double u) {
    if (u <= 0 || u >= 1) return;
    // The flower opens with a quick rigid scale-in, then keeps its shape —
    // afterwards the motion is a calm decelerating rise with a light sway.
    final open = Curves.easeOutCubic.transform((u / 0.24).clamp(0.0, 1.0));
    final lift = Curves.easeOutSine.transform(u);
    final sway =
        math.sin(b.swayPhase + u * b.swayCycles * 2 * math.pi) * b.swayAmp * u;
    final opacity =
        (u / 0.10).clamp(0.0, 1.0) * ((1 - u) / 0.22).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(
        b.origin.dx + b.drift * u + sway, b.origin.dy - b.rise * lift);
    canvas.rotate(b.spin * u);
    canvas.scale(open);
    switch (b.kind) {
      case _BloomKind.pinkPeony:
        _paintPeony(
          canvas,
          b.radius,
          opacity,
          outer: const Color(0xFFDA7E98),
          inner: const Color(0xFFF3B7C6),
          heart: const Color(0xFFF2C97E),
        );
      case _BloomKind.whitePeony:
        _paintPeony(
          canvas,
          b.radius,
          opacity,
          outer: const Color(0xFFEFE2D0),
          inner: const Color(0xFFFBF5EA),
          heart: const Color(0xFFE9B96F),
        );
      case _BloomKind.wisteria:
        _paintWisteria(canvas, b.radius, opacity);
    }
    canvas.restore();
  }

  /// Layered peony: six outer petals, five offset inner petals, golden heart.
  void _paintPeony(
    Canvas canvas,
    double r,
    double opacity, {
    required Color outer,
    required Color inner,
    required Color heart,
  }) {
    final outerPaint = Paint()..color = outer.withValues(alpha: opacity);
    final innerPaint = Paint()..color = inner.withValues(alpha: opacity);
    final heartPaint = Paint()..color = heart.withValues(alpha: opacity);

    final outerPetal = Rect.fromCenter(
        center: Offset(0, -r * 0.55), width: r * 0.68, height: r * 0.95);
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 3);
      canvas.drawOval(outerPetal, outerPaint);
      canvas.restore();
    }
    final innerPetal = Rect.fromCenter(
        center: Offset(0, -r * 0.30), width: r * 0.44, height: r * 0.62);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(math.pi / 5 + i * 2 * math.pi / 5);
      canvas.drawOval(innerPetal, innerPaint);
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, r * 0.20, heartPaint);
  }

  /// Drooping wisteria raceme: florets narrowing toward the tip, two small
  /// leaves at the crown — like the sprigs on the board frame.
  void _paintWisteria(Canvas canvas, double r, double opacity) {
    final light =
        Paint()..color = const Color(0xFFB493D6).withValues(alpha: opacity);
    final mid =
        Paint()..color = const Color(0xFF9678BE).withValues(alpha: opacity);
    final deep =
        Paint()..color = const Color(0xFF7E5DA8).withValues(alpha: opacity);
    final leaf =
        Paint()..color = const Color(0xFF8FAE6B).withValues(alpha: opacity);

    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * r * 0.34, -r * 0.78);
      canvas.rotate(side * 0.7);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: r * 0.52, height: r * 0.20),
        leaf,
      );
      canvas.restore();
    }

    const rows = <(int, double, double)>[
      (3, -0.55, 0.27),
      (3, -0.18, 0.25),
      (2, 0.18, 0.22),
      (2, 0.52, 0.19),
      (1, 0.84, 0.16),
    ];
    for (var rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      final (count, dy, rad) = rows[rowIdx];
      final paint =
          rowIdx == rows.length - 1 ? deep : (rowIdx.isEven ? light : mid);
      for (var i = 0; i < count; i++) {
        final dx = (i - (count - 1) / 2) * r * 0.42;
        canvas.drawCircle(Offset(dx, r * dy), r * rad, paint);
      }
    }
  }

  void _paintPetal(Canvas canvas, _Petal p, double u) {
    if (u <= 0 || u >= 1) return;
    // Tossed up off the frame, then a slow flutter down past it.
    final dy = -p.up * 4 * u * (1 - u) + p.fall * u * u;
    final dx = p.drift * u +
        math.sin(p.swayPhase + u * p.swayCycles * 2 * math.pi) * p.swayAmp;
    final opacity =
        (u / 0.10).clamp(0.0, 1.0) * ((1 - u) / 0.25).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(p.origin.dx + dx, p.origin.dy + dy);
    canvas.rotate(p.spin * u);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero, width: p.radius * 2, height: p.radius * 1.2),
      Paint()..color = p.color.withValues(alpha: opacity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) =>
      old.blooms != blooms || old.petals != petals;
}
