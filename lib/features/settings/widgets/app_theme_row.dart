import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';

/// Two-option selector for the app-wide visual theme (Orijinal / Özel).
class AppThemeRow extends StatelessWidget {
  const AppThemeRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AppThemeId selected;
  final ValueChanged<AppThemeId> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tile(
            label: 'Orijinal',
            preview: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [GameColors.bannerTop, GameColors.bannerBottom],
            ),
            previewDot: GameColors.accent2,
            active: selected == AppThemeId.original,
            onTap: () => onSelect(AppThemeId.original),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Tile(
            label: 'Özel',
            preview: WoodTheme.cardGradient,
            previewDot: WoodTheme.gold,
            active: selected == AppThemeId.wood,
            onTap: () => onSelect(AppThemeId.wood),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.preview,
    required this.previewDot,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Gradient preview;
  final Color previewDot;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F1E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? GameColors.accent : const Color(0x1A000000),
              width: active ? 2.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 46,
                decoration: BoxDecoration(
                  gradient: preview,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: previewDot,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                  color: active ? GameColors.onAccent : GameColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
