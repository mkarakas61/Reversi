import 'package:flutter/material.dart';

import '../../core/models/rank.dart';

/// A rank's avatar frame (REV-61), optionally with something sitting inside it.
///
/// The six frames do not share an opening: the crowned ones spend canvas on the
/// crown and wings, so their opening is smaller and sits lower (see [RankFrame]).
/// That gives two different ways to ask for a frame, and picking the wrong one
/// is the easy mistake here:
///
/// * [RankFrameView.around] sizes the frame so its *opening* matches the given
///   diameter. Use it wherever a frame wraps an avatar — the avatar then stays
///   the same size across ranks and the frames grow around it, so Efsane reads
///   as grander than Çaylak. Outer footprint varies by rank.
/// * [RankFrameView.boxed] fits the whole frame into a fixed square. Use it for
///   previews in lists and cards, where every row must be the same height and
///   there is no avatar to line up with.
class RankFrameView extends StatelessWidget {
  /// Frame sized so its opening is [openingDiameter] across; [child] is centred
  /// in that opening. The widget's own box is the frame's full extent.
  const RankFrameView.around({
    super.key,
    required this.frame,
    required double openingDiameter,
    this.child,
  })  : _openingDiameter = openingDiameter,
        _boxSize = null;

  /// Whole frame fitted into a [size] × [size] box; [child] is centred in the
  /// opening, which is [size] × `openingFraction` across.
  const RankFrameView.boxed({
    super.key,
    required this.frame,
    required double size,
    this.child,
  })  : _openingDiameter = null,
        _boxSize = size;

  final RankFrame frame;

  /// What goes inside the opening — an avatar, or nothing at all.
  final Widget? child;

  final double? _openingDiameter;
  final double? _boxSize;

  @override
  Widget build(BuildContext context) {
    final frameSize = _boxSize ?? frame.frameSizeFor(_openingDiameter!);
    final opening = _openingDiameter ?? _boxSize! * frame.openingFraction;

    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The opening is off-centre on the crowned frames, so the child is
          // placed against the measured centre rather than the canvas centre.
          Positioned(
            left: frameSize * frame.centerX - opening / 2,
            top: frameSize * frame.centerY - opening / 2,
            width: opening,
            height: opening,
            child: ClipOval(
              child: SizedBox(
                width: opening,
                height: opening,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
          // Frame art last: the crown and wings are meant to overlap whatever
          // sits in the opening.
          Positioned.fill(
            child: Image.asset(
              frame.asset,
              width: frameSize,
              height: frameSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              // The art is 512², but most uses are thumbnail-sized. Without a
              // cache hint all six decode at full size, which is ~6 MB of
              // resident bitmap for the rank road's 56pt previews alone.
              cacheWidth: (frameSize *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
            ),
          ),
        ],
      ),
    );
  }
}
