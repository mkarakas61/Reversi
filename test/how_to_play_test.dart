import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';
import 'package:reversi/core/services/onboarding_storage.dart';
import 'package:reversi/core/services/settings_storage.dart';
import 'package:reversi/core/settings/app_settings.dart';
import 'package:reversi/features/help/how_to_play_screen.dart';
import 'package:reversi/features/help/welcome_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';

// REV-103. Two guarantees worth pinning:
//   * the rules page says every rule a newcomer cannot guess, in both
//     languages — a missing map entry throws at lookup, so a half-translated
//     page is a crash, not a cosmetic bug;
//   * the tour runs exactly once per install, and skipping counts as seen.

/// Narrower than any phone we target: the rules page carries the widest thing
/// in the app (the before/after diagram), so it has to survive here.
const double _narrow = 360.0;

Future<void> _pumpHowToPlay(WidgetTester tester, {String lang = 'tr'}) async {
  tester.view.physicalSize = const Size(_narrow, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    SettingsScope(
      controller: SettingsController(const AppSettings(), SettingsStorage()),
      child: MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HowToPlayScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpTour(WidgetTester tester) async {
  tester.view.physicalSize = const Size(_narrow, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    SettingsScope(
      controller: SettingsController(const AppSettings(), SettingsStorage()),
      child: const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: WelcomeTour(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The page scrolls, and a [ListView] does not build what is far below the
/// fold — so "the page says X" has to mean "X is reachable by scrolling",
/// which is also what it means for the player.
Future<void> _expectOnPage(WidgetTester tester, String text) async {
  final target = find.text(text);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 220);
  }
  expect(target, findsOneWidget, reason: 'not on the page: $text');
}

void main() {
  group('How to Play', () {
    for (final lang in const ['tr', 'en']) {
      testWidgets('covers every rule in $lang', (tester) async {
        await _pumpHowToPlay(tester, lang: lang);
        final strings = AppStrings(Locale(lang));

        // The four things a player cannot work out from the board alone.
        // Listed in page order, because each lookup scrolls forward.
        for (final title in [
          strings.htpGoalTitle,
          strings.htpMoveTitle,
          strings.htpPassTitle,
          strings.htpEndTitle,
        ]) {
          await _expectOnPage(tester, title);
        }
      });
    }

    testWidgets('shows the capture diagram with both states', (tester) async {
      await _pumpHowToPlay(tester);
      final strings = AppStrings(const Locale('tr'));

      expect(find.text(strings.htpBefore), findsOneWidget);
      expect(find.text(strings.htpAfter), findsOneWidget);
    });

    testWidgets('the diagram fits a narrow phone', (tester) async {
      await _pumpHowToPlay(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('points at the customisation nobody would find', (
      tester,
    ) async {
      await _pumpHowToPlay(tester);
      final strings = AppStrings(const Locale('tr'));

      // The whole reason features share this page with the rules: a player who
      // never opens Settings never learns the board and discs are theirs.
      await _expectOnPage(tester, strings.htpCustomizeTitle);
      await _expectOnPage(tester, strings.htpOpenSettings);
    });
  });

  group('Welcome tour', () {
    testWidgets('walks four cards and ends on "let\'s play"', (tester) async {
      await _pumpTour(tester);
      final strings = AppStrings(const Locale('tr'));

      expect(find.text(strings.tourWelcomeTitle), findsOneWidget);
      expect(find.text(strings.tourNext), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text(strings.tourNext));
        await tester.pumpAndSettle();
      }

      expect(find.text(strings.tourOnlineTitle), findsOneWidget);
      // Last card swaps the label, so the player knows the tour is over.
      expect(find.text(strings.tourStart), findsOneWidget);
      expect(find.text(strings.tourNext), findsNothing);
    });

    testWidgets('is skippable from the very first card', (tester) async {
      await _pumpTour(tester);
      final strings = AppStrings(const Locale('tr'));

      expect(find.text(strings.tourSkip), findsOneWidget);
    });
  });

  group('OnboardingStorage', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a fresh install has not seen the tour', () async {
      expect(await const OnboardingStorage().hasSeenTour(), isFalse);
    });

    test('marking it seen sticks, so the tour runs once', () async {
      const storage = OnboardingStorage();
      await storage.markTourSeen();
      expect(await storage.hasSeenTour(), isTrue);
    });
  });
}
