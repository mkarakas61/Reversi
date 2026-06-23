import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';

class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.onBack,
    required this.onNewGame,
    required this.onSettings,
  });

  final VoidCallback onBack;
  final VoidCallback onNewGame;
  final VoidCallback onSettings;

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

class BarButton extends StatelessWidget {
  const BarButton({
    super.key,
    required this.child,
    required this.onTap,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    final fg = wood ? WoodTheme.inkScore : GameColors.onAccent;
    final button = DecoratedBox(
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
          onTap: onTap,
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
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
  }
}
