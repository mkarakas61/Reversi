import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/rank.dart';

/// Small rank pill: a medal icon in the rank's identity colour plus its title
/// (optionally the trophy count). Used on the profile and online-stats
/// screens, and — [compact] — above player names on the match screen (REV-75).
///
/// The colour + title come from the REV-60 ramp via [Rank] / [AppStrings]. The
/// frame art from REV-61 will later replace the medal icon; nothing else needs
/// to change.
class RankBadge extends StatelessWidget {
  const RankBadge({
    super.key,
    required this.rank,
    this.trophies,
    this.compact = false,
  });

  final Rank rank;

  /// When set, shown after the title (e.g. "Usta · 312").
  final int? trophies;

  /// Icon + title only, smaller — for tight headers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final title = strings.rankTitle(rank.id);
    final text = trophies == null ? title : '$title · $trophies';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: rank.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: rank.color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.military_tech,
            size: compact ? 14 : 18,
            color: rank.color,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 14,
              // Darken the identity colour a touch so the title stays readable
              // on the light tinted pill.
              color: Color.alphaBlend(const Color(0x33000000), rank.color),
            ),
          ),
        ],
      ),
    );
  }
}
