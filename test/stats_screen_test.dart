import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';
import 'package:reversi/core/models/game_stats.dart';
import 'package:reversi/features/stats/stats_screen.dart';
import 'package:reversi/core/services/stats_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: StatsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty state with no games played', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);

    expect(
      find.textContaining("haven't finished a game"),
      findsOneWidget,
    );
    expect(find.text('Reset statistics'), findsNothing);
  });

  testWidgets('shows totals, pie chart and reset action with games played',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StatsStorage();
    await storage.save(GameStats.empty
        .recordGame(
          mode: StatsMode.singlePlayerEasy,
          outcome: GameOutcome.win,
          scoreDiff: 10,
          flippedDiscs: 20,
          durationSeconds: 90,
        )
        .recordGame(
          mode: StatsMode.singlePlayerNormal,
          outcome: GameOutcome.loss,
          scoreDiff: 4,
          flippedDiscs: 12,
          durationSeconds: 60,
        ));

    await pumpScreen(tester);

    expect(find.text('Total games'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('Reset statistics'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Reset statistics'), findsOneWidget);
  });

  testWidgets('reset clears stats after confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StatsStorage();
    await storage.save(GameStats.empty.recordGame(
      mode: StatsMode.singlePlayerNormal,
      outcome: GameOutcome.win,
      scoreDiff: 5,
      flippedDiscs: 5,
      durationSeconds: 5,
    ));

    await pumpScreen(tester);
    await tester.dragUntilVisible(
      find.text('Reset statistics'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Reset statistics'), findsOneWidget);

    await tester.tap(find.text('Reset statistics'));
    await tester.pumpAndSettle();

    // Confirmation dialog.
    expect(find.text('Reset statistics?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset statistics'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("haven't finished a game"),
      findsOneWidget,
    );
    expect(
        await storage.load(), predicate<GameStats>((s) => s.totalGames == 0));
  });
}
