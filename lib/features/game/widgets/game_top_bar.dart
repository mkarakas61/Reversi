import 'package:flutter/material.dart';

import '../../../core/game/game_settings.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';

class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.onBack,
    required this.onNewGame,
    required this.onSettings,
    this.onUndo,
    this.canUndo = false,
    this.showSpeed = false,
    this.gameSpeed = GameSpeed.normal,
    this.onSpeedChanged,
  });

  final VoidCallback onBack;
  final VoidCallback onNewGame;
  final VoidCallback onSettings;

  /// Undo control. When null (e.g. online play) the button is hidden.
  final VoidCallback? onUndo;
  final bool canUndo;

  /// Speed control only makes sense against the AI (single-player).
  final bool showSpeed;
  final GameSpeed gameSpeed;
  final ValueChanged<GameSpeed>? onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wood = isWoodTheme(context);
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          BarButton(
            tooltip: strings.back,
            onTap: onBack,
            child: const Icon(Icons.chevron_left, size: 22),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  strings.appTitle.toUpperCase(),
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: wood ? WoodTheme.displayFont : 'Baloo2',
                    fontWeight: wood ? FontWeight.w400 : FontWeight.w800,
                    fontSize: 23,
                    letterSpacing: 3.4,
                    color: wood ? WoodTheme.inkTitle : Colors.white,
                    shadows: const [
                      Shadow(color: Color(0x1F000000), offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpeed && onSpeedChanged != null) ...[
                SpeedMenuButton(
                  speed: gameSpeed,
                  onChanged: onSpeedChanged!,
                ),
                const SizedBox(width: 9),
              ],
              if (onUndo != null) ...[
                BarButton(
                  tooltip: strings.undo,
                  onTap: onUndo!,
                  enabled: canUndo,
                  child: const Icon(Icons.undo_rounded, size: 19),
                ),
                const SizedBox(width: 9),
              ],
              BarButton(
                tooltip: strings.settings,
                onTap: onSettings,
                child: const Icon(Icons.settings, size: 19),
              ),
              const SizedBox(width: 9),
              BarButton(
                tooltip: strings.newGame,
                onTap: onNewGame,
                child: const Icon(Icons.refresh, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// [GameSpeed] options (Fast / Normal / Slow) that set how long the AI pauses
/// before each move. Styled to match [BarButton] but without its own tap
/// handler — the surrounding [PopupMenuButton] owns the tap.
class SpeedMenuButton extends StatelessWidget {
  const SpeedMenuButton({
    super.key,
    required this.speed,
    required this.onChanged,
  });

  final GameSpeed speed;
  final ValueChanged<GameSpeed> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wood = isWoodTheme(context);
    final fg = wood ? WoodTheme.inkScore : GameColors.onAccent;
    final accent = wood ? WoodTheme.gold : GameColors.accent;
    return PopupMenuButton<GameSpeed>(
      tooltip: strings.gameSpeed,
      initialValue: speed,
      offset: const Offset(0, 46),
      color: wood ? WoodTheme.cardTop : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in GameSpeed.values)
          PopupMenuItem<GameSpeed>(
            value: option,
            child: Row(
              children: [
                Icon(
                  option == speed
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: option == speed ? accent : fg.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 10),
                Text(
                  strings.gameSpeedLabel(option),
                  style: TextStyle(
                    fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: wood ? WoodTheme.cardTop : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: wood ? Border.all(color: WoodTheme.gold, width: 1.2) : null,
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), offset: Offset(0, 3)),
            BoxShadow(
              color: Color(0x1F000000),
              offset: Offset(0, 5),
              blurRadius: 12,
            ),
          ],
        ),
        child: Container(
          height: 38,
          constraints: const BoxConstraints(minWidth: 38),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          child: Icon(Icons.speed_rounded, size: 20, color: fg),
        ),
      ),
    );
  }
}

class BarButton extends StatelessWidget {
  const BarButton({
    super.key,
    required this.child,
    required this.onTap,
    this.tooltip,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    final fg = wood ? WoodTheme.inkScore : GameColors.onAccent;
    final button = Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: wood ? WoodTheme.cardTop : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: wood ? Border.all(color: WoodTheme.gold, width: 1.2) : null,
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), offset: Offset(0, 3)),
            BoxShadow(
              color: Color(0x1F000000),
              offset: Offset(0, 5),
              blurRadius: 12,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: enabled ? onTap : null,
            child: Container(
              height: 38,
              constraints: const BoxConstraints(minWidth: 38),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: fg,
                ),
                child: IconTheme(
                  data: IconThemeData(color: fg, size: 20),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
  }
}
