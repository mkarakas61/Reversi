import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/game_colors.dart';
import '../../../shared/widgets/board_preview.dart';

class BoardThemeGrid extends StatelessWidget {
  const BoardThemeGrid({
    super.key,
    required this.selected,
    required this.onSelect,
    this.themes,
    this.labelOverrides,
  });

  final BoardTheme selected;
  final ValueChanged<BoardTheme> onSelect;

  /// Which themes to show. Defaults to all [BoardTheme.values].
  final List<BoardTheme>? themes;

  /// Per-theme label overrides (e.g. wood shows as "Ahşap" in the custom theme).
  final Map<BoardTheme, String>? labelOverrides;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final items = themes ?? BoardTheme.values;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final theme in items)
          _BoardTile(
            theme: theme,
            label: labelOverrides?[theme] ?? strings.boardThemeLabel(theme),
            active: theme == selected,
            onTap: () => onSelect(theme),
          ),
      ],
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({
    required this.theme,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final BoardTheme theme;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? GameColors.accent : Colors.transparent,
                width: 3,
              ),
            ),
            child: BoardPreview(theme: theme),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: active ? GameColors.onAccent : GameColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
