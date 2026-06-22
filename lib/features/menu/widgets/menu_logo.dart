import 'package:flutter/material.dart';

class MenuLogo extends StatelessWidget {
  const MenuLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [_tile(false), _tile(true)]),
          Row(mainAxisSize: MainAxisSize.min, children: [_tile(true), _tile(false)]),
        ],
      ),
    );
  }

  Widget _tile(bool dark) => Container(
        margin: const EdgeInsets.all(3),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFFCE9C8),
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: dark
                  ? const [Color(0xFF4A5468), Color(0xFF11141D)]
                  : const [Colors.white, Color(0xFFC4C8D2)],
              stops: const [0.0, 0.75],
            ),
          ),
        ),
      );
}
