import 'package:flutter/material.dart';

class EntrySlide extends StatelessWidget {
  const EntrySlide({
    super.key,
    required this.progress,
    required this.beginOffset,
    required this.child,
  });

  final double progress;
  final Offset beginOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offset = Offset.lerp(beginOffset, Offset.zero, progress)!;
    return FractionalTranslation(
      translation: offset,
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: child,
      ),
    );
  }
}
