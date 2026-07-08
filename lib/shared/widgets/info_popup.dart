import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/game_colors.dart';

/// A small centred card that pops in, lingers, then dismisses itself (or on a
/// tap) — used for transient notices like an invalid move or a forced pass.
/// Shared by the local game ([main.dart]) and the online game screen.
class InfoPopup extends StatefulWidget {
  const InfoPopup({
    super.key,
    required this.message,
    required this.onDismissed,
    this.duration = const Duration(seconds: 2),
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<InfoPopup> createState() => _InfoPopupState();
}

class _InfoPopupState extends State<InfoPopup> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onDismissed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onDismissed,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Transform.scale(
              scale: 0.85 + 0.15 * v.clamp(0.0, 1.0),
              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 10),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  height: 1.25,
                  color: GameColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
