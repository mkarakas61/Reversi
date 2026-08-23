import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/profile/profile_scope.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/game_colors.dart'
    show GameColors, bannerGradient, creamShellGradient;
import '../../core/store/entitlements.dart';
import '../../core/theme/wood_theme.dart';
import '../../shared/widgets/info_card.dart';
import '../help/how_to_play_screen.dart';
import '../store/store_screen.dart';
import '../menu/widgets/menu_button.dart';
import 'app_account_screen.dart';
import 'widgets/app_theme_row.dart';
import 'widgets/board_theme_grid.dart';
import 'widgets/coin_row.dart';
import 'widgets/language_row.dart';
import 'widgets/settings_header.dart';
import 'widgets/toggle_row.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final controller = SettingsScope.of(context);
    final settings = controller.settings;
    final lang = Localizations.localeOf(context).languageCode;
    final wood = settings.appTheme == AppThemeId.wood;

    // Settings offers only what the player owns; locked items live in the
    // store and nowhere else (Mustafa, 2026-08-23). A picker full of padlocks
    // would nag at someone every time they change a colour.
    final entitlements =
        ProfileScope.of(context).profile?.entitlements ?? Entitlements.freeOnly;
    final ownedBoards =
        BoardTheme.values.where(entitlements.ownsBoard).toList();
    final ownedDiscs = CoinColor.values.where(entitlements.ownsDisc).toList();

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
                clipper: const HeaderClipper(),
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
                        InfoCard(
                          title: 'Tema',
                          child: AppThemeRow(
                            selected: settings.appTheme,
                            onSelect: controller.setAppTheme,
                          ),
                        ),
                        InfoCard(
                          title: strings.language,
                          child: LanguageRow(
                            current: lang,
                            onSelect: (code) =>
                                controller.setLocale(Locale(code)),
                          ),
                        ),
                        // The way into the shop window. It sits above the
                        // pickers because that is where someone stands when
                        // they notice they want more than they own.
                        InfoCard(
                          title: strings.storeTitle,
                          child: MenuButton(
                            label: strings.storeOpen,
                            icon: Icons.storefront_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const StoreScreen(),
                              ),
                            ),
                          ),
                        ),
                        // Theme, board and coin are independent (REV-70): every
                        // board and coin the player owns is selectable
                        // regardless of the app theme.
                        InfoCard(
                          title: strings.boardColor,
                          child: BoardThemeGrid(
                            selected: settings.board,
                            themes: ownedBoards,
                            onSelect: controller.setBoard,
                          ),
                        ),
                        InfoCard(
                          title: strings.coinColor,
                          child: Column(
                            children: [
                              CoinRow(
                                label: strings.yourCoin,
                                selected: settings.yourCoin,
                                disabled: settings.opponentCoin,
                                colors: ownedDiscs,
                                onSelect: controller.setYourCoin,
                              ),
                              const SizedBox(height: 14),
                              CoinRow(
                                label: strings.opponentCoin,
                                selected: settings.opponentCoin,
                                disabled: settings.yourCoin,
                                colors: ownedDiscs,
                                onSelect: controller.setOpponentCoin,
                              ),
                            ],
                          ),
                        ),
                        InfoCard(
                          title: strings.help,
                          child: MenuButton(
                            label: strings.howToPlay,
                            icon: Icons.help_outline_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HowToPlayScreen(),
                              ),
                            ),
                          ),
                        ),
                        // Legal, support, licences, version and account
                        // deletion — Play requires all of them to be reachable
                        // from inside the app (REV-91).
                        InfoCard(
                          title: strings.appAndAccount,
                          child: MenuButton(
                            label: strings.appAccountHint,
                            icon: Icons.shield_outlined,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AppAccountScreen(),
                              ),
                            ),
                          ),
                        ),
                        InfoCard(
                          title: strings.sound,
                          child: Column(
                            children: [
                              ToggleRow(
                                label: strings.soundEffects,
                                value: settings.soundEnabled,
                                onChanged: controller.setSoundEnabled,
                              ),
                              const SizedBox(height: 6),
                              ToggleRow(
                                label: strings.music,
                                value: settings.musicEnabled,
                                onChanged: controller.setMusicEnabled,
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
