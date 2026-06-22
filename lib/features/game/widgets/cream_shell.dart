import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';

class CreamShell extends StatelessWidget {
  const CreamShell({super.key, required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: creamShellGradient),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fullH = MediaQuery.sizeOf(context).height;
                final bandH = lerpDouble(fullH, 210, t)!;
                return ClipPath(
                  clipper: _BannerClipper(t),
                  child: SizedBox(
                    height: bandH,
                    width: double.infinity,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(gradient: bannerGradient),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerClipper extends CustomClipper<Path> {
  const _BannerClipper(this.t);

  final double t;

  @override
  Path getClip(Size size) {
    final brY = lerpDouble(size.height, size.height * 0.60, t)!;
    final blY = lerpDouble(size.height, size.height * 0.80, t)!;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, brY)
      ..lineTo(0, blY)
      ..close();
  }

  @override
  bool shouldReclip(_BannerClipper old) => old.t != t;
}
