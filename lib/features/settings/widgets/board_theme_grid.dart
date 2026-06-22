import 'package:flutter/material.dart';

import '../../../core/game/reversi_game.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/board_palette.dart';
import '../../../core/theme/game_colors.dart';

class BoardThemeGrid extends StatelessWidget {
  const BoardThemeGrid({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final BoardTheme selected;
  final ValueChanged<BoardTheme> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final theme in BoardTheme.values)
          _BoardTile(
            theme: theme,
            label: strings.boardThemeLabel(theme),
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
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? GameColors.accent : Colors.transparent,
                width: 3,
              ),
            ),
            child: _BoardPreview(theme: theme),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 88,
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

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({required this.theme});

  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    final palette = boardPalettes[theme];

    final BoxDecoration frame = palette == null
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            image: const DecorationImage(
              image: AssetImage('assets/wood/wood-frame.png'),
              fit: BoxFit.cover,
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: palette.frameGradient,
          );

    final BoxDecoration surface = palette == null
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            image: const DecorationImage(
              image: AssetImage('assets/wood/wood-surface.png'),
              fit: BoxFit.cover,
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: palette.surfaceGradient,
          );

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: frame,
      child: DecoratedBox(
        decoration: surface,
        child: SizedBox.expand(
          child: CustomPaint(painter: _MiniGridPainter(palette: palette)),
        ),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  _MiniGridPainter({required this.palette});

  final BoardPalette? palette;

  @override
  void paint(Canvas canvas, Size size) {
    final n = ReversiGame.size;
    final cell = size.width / n;
    final paint = Paint()
      ..color = palette == null
          ? GameColors.gridLine
          : palette!.line.withValues(alpha: 0.55)
      ..strokeWidth = 0.6;
    for (var i = 1; i < n; i++) {
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), paint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), paint);
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter old) => old.palette != palette;
}
