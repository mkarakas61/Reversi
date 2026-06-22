import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';

class TimeUpOverlay extends StatelessWidget {
  const TimeUpOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const ColoredBox(color: Color(0x42000000)),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(
                scale: 0.85 + 0.15 * v.clamp(0.0, 1.0),
                child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      offset: Offset(0, 14),
                      blurRadius: 34,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_off_outlined,
                      size: 38,
                      color: Color(0xFFE0312B),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        height: 1.25,
                        color: GameColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
