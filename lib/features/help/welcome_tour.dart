import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/services/onboarding_storage.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/game_colors.dart' show GameColors, creamShellGradient;
import '../../core/theme/wood_theme.dart';
import '../../shared/widgets/disc_view.dart';
import '../menu/widgets/menu_button.dart';
import 'how_to_play_screen.dart';
import 'widgets/capture_diagram.dart';

/// The one-time welcome tour (REV-103): four swipeable cards shown on a fresh
/// install, always skippable.
///
/// Cards rather than spotlights over the real screens: coach marks have to know
/// where every button lands, which makes them break on the next layout change
/// and behave differently on a phone and a tablet — both of which this project
/// ships to. Cards say the same things and cannot fall out of alignment.
///
/// It teaches the two rules a newcomer cannot guess (the goal, and how a
/// capture works) and then the two things that are invisible from the menu:
/// that the board and discs are theirs to choose, and that online play exists.
/// Anything longer belongs in [HowToPlayScreen], which is always reachable.
class WelcomeTour extends StatefulWidget {
  const WelcomeTour({super.key});

  /// Shows the tour once per install. Safe to call on every launch: it returns
  /// immediately when the tour has already been seen or skipped.
  static Future<void> showIfFirstLaunch(
    BuildContext context, {
    OnboardingStorage storage = const OnboardingStorage(),
  }) async {
    if (await storage.hasSeenTour()) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WelcomeTour(),
        fullscreenDialog: true,
      ),
    );
    await storage.markTourSeen();
  }

  @override
  State<WelcomeTour> createState() => _WelcomeTourState();
}

class _WelcomeTourState extends State<WelcomeTour> {
  final PageController _pages = PageController();
  int _page = 0;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      Navigator.of(context).maybePop();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = SettingsScope.of(context).settings;
    final wood = settings.appTheme == AppThemeId.wood;
    final last = _page == _pageCount - 1;

    return Scaffold(
      backgroundColor: wood ? WoodTheme.surface : GameColors.creamTop,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: wood ? WoodTheme.pageBackground : creamShellGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    strings.tourSkip,
                    style: TextStyle(
                      fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: wood
                          ? WoodTheme.goldText
                          : GameColors.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _TourPage(
                      title: strings.tourWelcomeTitle,
                      body: strings.tourWelcomeBody,
                      art: _DiscPairArt(
                        you: settings.yourCoin,
                        rival: settings.opponentCoin,
                      ),
                    ),
                    _TourPage(
                      title: strings.tourCaptureTitle,
                      body: strings.tourCaptureBody,
                      art: const CaptureDiagram(),
                    ),
                    _TourPage(
                      title: strings.tourCustomizeTitle,
                      body: strings.tourCustomizeBody,
                      art: const _CoinShowcase(),
                    ),
                    _TourPage(
                      title: strings.tourOnlineTitle,
                      body: strings.tourOnlineBody,
                      art: Icon(
                        Icons.public_rounded,
                        size: 92,
                        color: wood
                            ? WoodTheme.goldText
                            : GameColors.accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              _Dots(count: _pageCount, current: _page, wood: wood),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                child: MenuButton(
                  label: last ? strings.tourStart : strings.tourNext,
                  icon: last
                      ? Icons.play_arrow_rounded
                      : Icons.arrow_forward_rounded,
                  primary: true,
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourPage extends StatelessWidget {
  const _TourPage({required this.title, required this.body, required this.art});

  final String title;
  final String body;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    // Centred in the page, but still scrollable: the cards are short enough to
    // centre on a phone and long enough to overflow a small landscape window,
    // and `Center` alone would clip in that case.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 130, child: Center(child: art)),
              const SizedBox(height: 26),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: wood ? WoodTheme.displayFont : 'Baloo2',
                  fontWeight: wood ? FontWeight.w400 : FontWeight.w800,
                  fontSize: 24,
                  color: wood ? WoodTheme.inkTitle : GameColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  height: 1.5,
                  color: wood
                      ? WoodTheme.inkName
                      : GameColors.ink.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The player's two discs side by side — the pieces the whole game is about.
class _DiscPairArt extends StatelessWidget {
  const _DiscPairArt({required this.you, required this.rival});

  final CoinColor you;
  final CoinColor rival;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DiscView(coin: you, size: 76),
        const SizedBox(width: 14),
        DiscView(coin: rival, size: 76),
      ],
    );
  }
}

/// A spread of the discs on offer — the point of the customisation card is that
/// there is a choice, which a paragraph alone does not convey.
class _CoinShowcase extends StatelessWidget {
  const _CoinShowcase();

  static const List<CoinColor> _sample = [
    CoinColor.walnut,
    CoinColor.marbleWhite,
    CoinColor.flowerPurple,
    CoinColor.turquoise,
    CoinColor.orange,
    CoinColor.maple,
  ];

  static const double _size = 52;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Three per row by construction. Left to its own devices the row wraps
      // 5 + 1 on a phone, which reads as a mistake rather than a spread.
      width: _size * 3 + _gap * 2,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: _gap,
        runSpacing: 8,
        children: [
          for (final coin in _sample) DiscView(coin: coin, size: _size),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current, required this.wood});

  final int count;
  final int current;
  final bool wood;

  @override
  Widget build(BuildContext context) {
    final on = wood ? WoodTheme.goldText : GameColors.accent;
    final off =
        (wood ? WoodTheme.goldText : GameColors.ink).withValues(alpha: 0.22);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? on : off,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
