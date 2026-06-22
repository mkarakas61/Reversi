import 'package:flutter/material.dart';

import '../../../core/theme/board_palette.dart';

class HintWidget extends StatefulWidget {
  const HintWidget({super.key, required this.size, required this.palette});

  final double size;
  final BoardPalette? palette;

  @override
  State<HintWidget> createState() => _HintWidgetState();
}

class _HintWidgetState extends State<HintWidget>
    with SingleTickerProviderStateMixin {
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
