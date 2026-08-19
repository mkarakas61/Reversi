import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/game_colors.dart'
    show GameColors, bannerGradient, creamShellGradient;
import '../../core/theme/wood_theme.dart';
import '../../shared/widgets/info_card.dart';
import '../menu/widgets/menu_button.dart';
import '../settings/settings_screen.dart';
import '../settings/widgets/settings_header.dart';
import 'widgets/capture_diagram.dart';

/// The permanent rules-and-features reference (REV-103).
///
/// The first-launch tour ([WelcomeTour]) is the short, one-time version of this
/// page; this is the version that stays. Anyone who skipped the tour, forgot a
/// rule, or never knew Reversi in the first place can reach it from the menu's
/// "?" button and from Settings.
///
/// It covers features as well as rules on purpose: "the board and the discs are
/// yours to choose" is invisible otherwise, and a player who never opens
/// Settings never learns it.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wood = SettingsScope.of(context).settings.appTheme == AppThemeId.wood;

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
                    title: strings.howToPlay,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        InfoCard(
                          title: strings.htpGoalTitle,
                          child: InfoText(strings.htpGoalBody),
                        ),
                        InfoCard(
                          title: strings.htpMoveTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoText(strings.htpMoveBody),
                              const SizedBox(height: 14),
                              const CaptureDiagram(),
                            ],
                          ),
                        ),
                        InfoCard(
                          title: strings.htpHintsTitle,
                          child: InfoText(strings.htpHintsBody),
                        ),
                        InfoCard(
                          title: strings.htpPassTitle,
                          child: InfoText(strings.htpPassBody),
                        ),
                        InfoCard(
                          title: strings.htpEndTitle,
                          child: InfoText(strings.htpEndBody),
                        ),
                        InfoCard(
                          title: strings.htpCustomizeTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoText(strings.htpCustomizeBody),
                              const SizedBox(height: 12),
                              MenuButton(
                                label: strings.htpOpenSettings,
                                icon: Icons.tune_rounded,
                                onTap: () {
                                  // Replaces rather than stacks: arriving from
                                  // Settings and pushing Settings again would
                                  // leave two of them on the stack.
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        InfoCard(
                          title: strings.htpOnlineTitle,
                          child: InfoText(strings.htpOnlineBody),
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
