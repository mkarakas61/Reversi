import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/main.dart';
import 'package:reversi/services/analytics_service.dart';

void main() {
  testWidgets('renders the Reversi board and score panel', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(ReversiApp(analytics: AnalyticsService()));
    await tester.pumpAndSettle();

    expect(find.text('Reversi'), findsOneWidget);
    expect(find.text('Black'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('can switch to Turkish locale', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(ReversiApp(analytics: AnalyticsService()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();

    expect(find.text('Siyah'), findsOneWidget);
  });
}
