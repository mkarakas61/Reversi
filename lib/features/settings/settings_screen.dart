import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/game_colors.dart'
    show GameColors, bannerGradient, creamShellGradient;
import '../../core/theme/wood_theme.dart';
import 'widgets/app_theme_row.dart';
import 'widgets/board_theme_grid.dart';
import 'widgets/coin_row.dart';
import 'widgets/language_row.dart';
import 'widgets/settings_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final controller = SettingsScope.of(context);
    final settings = controller.settings;
    final lang = Localizations.localeOf(context).languageCode;
    final wood = settings.appTheme == AppThemeId.wood;

    return Scaffold(
      backgroundColor: wood ? WoodTheme.surface : GameColors.creamTop,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: wood ? WoodTheme.pageBackground : creamShellGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: wood ? WoodTheme.buttonGradient : bannerGradient,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SettingsHeader(
                    title: strings.settings,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        _Section(
                          title: 'Tema',
                          child: AppThemeRow(
                            selected: settings.appTheme,
                            onSelect: controller.setAppTheme,
                          ),
                        ),
                        _Section(
                          title: strings.language,
                          child: LanguageRow(
                            current: lang,
                            onSelect: (code) =>
                                controller.setLocale(Locale(code)),
                          ),
                        ),
                        _Section(
                          title: strings.boardColor,
                          child: BoardThemeGrid(
                            selected: settings.board,
                            onSelect: controller.setBoard,
                          ),
                        ),
                        _Section(
                          title: strings.coinColor,
                          child: Column(
                            children: [
                              CoinRow(
                                label: strings.yourCoin,
                                selected: settings.yourCoin,
                                disabled: settings.opponentCoin,
                                onSelect: controller.setYourCoin,
                              ),
                              const SizedBox(height: 14),
                              CoinRow(
                                label: strings.opponentCoin,
                                selected: settings.opponentCoin,
                                disabled: settings.yourCoin,
                                onSelect: controller.setOpponentCoin,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(0, size.height * 0.82)
      ..close();
  }

  @override
  bool shouldReclip(_HeaderClipper old) => false;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: wood ? WoodTheme.cardTop : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border:
            wood ? Border.all(color: WoodTheme.cardIdleBorder, width: 1) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, 6)),
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: wood ? WoodTheme.displayFont : 'Baloo2',
              fontWeight: wood ? FontWeight.w400 : FontWeight.w800,
              fontSize: wood ? 18 : 16,
              color: wood ? WoodTheme.inkScore : GameColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
