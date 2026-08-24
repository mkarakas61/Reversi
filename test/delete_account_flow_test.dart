import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';
import 'package:reversi/features/settings/delete_account_flow.dart';

// Deleting an account is the one action in this app that cannot be undone by
// anyone, us included. It is now offered from the profile screen as well as
// from App & Account (Mustafa, 2026-08-24), which is exactly why the guard has
// to be tested rather than eyeballed: an easier door must not mean an easier
// mistake.
//
// The tests stop at the last button. Pressing it would call the server, and
// what happens after is `deleteAccount`'s job (covered in
// functions/src/delete_account.test.ts).

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => confirmAndDeleteAccount(context),
              child: const Text('start'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens both dialogs and stops on the second, without letting the countdown
/// run out.
Future<void> _reachFinalStep(WidgetTester tester, AppStrings strings) async {
  await tester.tap(find.text('start'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, strings.deleteAccountSend));
  // Long enough for the dialog to open, short enough that the countdown is
  // still running — pumpAndSettle here would spend the whole five seconds.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  final strings = AppStrings(const Locale('tr'));

  testWidgets('the first tap only opens a warning', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(find.text(strings.deleteAccountTitle), findsOneWidget);
    expect(find.text(strings.deleteAccountBody), findsOneWidget);
    // Cancelling on the first screen ends it — no second dialog behind it.
    await tester.tap(find.widgetWithText(TextButton, strings.cancel));
    await tester.pumpAndSettle();
    expect(find.text(strings.deleteAccountFinalTitle), findsNothing);
  });

  testWidgets('confirming once is not enough: a second dialog follows',
      (tester) async {
    await _pump(tester);
    await _reachFinalStep(tester, strings);

    expect(find.text(strings.deleteAccountFinalTitle), findsOneWidget);
    expect(find.text(strings.deleteAccountFinalHint), findsOneWidget);
  });

  testWidgets('the delete button is dead until the countdown ends',
      (tester) async {
    await _pump(tester);
    await _reachFinalStep(tester, strings);

    final counting = tester.widget<TextButton>(
      find.widgetWithText(TextButton, strings.deleteAccountCountdown(5)),
    );
    expect(counting.onPressed, isNull, reason: 'deletable before the wait');

    // Halfway through it is still counting, and still dead.
    await tester.pump(const Duration(seconds: 3));
    expect(find.widgetWithText(TextButton, strings.deleteAccountCountdown(2)),
        findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    final ready = tester.widget<TextButton>(
      find.widgetWithText(TextButton, strings.deleteAccountSend),
    );
    expect(ready.onPressed, isNotNull, reason: 'still dead after the wait');
  });

  testWidgets('the buttons do not move when the countdown ends', (tester) async {
    // Caught on the phone: while counting, the delete label is longer, which
    // made the dialog's action bar wrap it onto its own row — and it jumped
    // back up the instant the label shrank. A confirmation dialog that
    // rearranges itself is a confirmation dialog that gets tapped wrong.
    await _pump(tester);
    await _reachFinalStep(tester, strings);

    final keep = find.widgetWithText(FilledButton, strings.deleteAccountKeep);
    final before = tester.getRect(keep);
    final dangerBefore =
        tester.getRect(find.widgetWithText(TextButton, strings.deleteAccountCountdown(5)));

    await tester.pump(const Duration(seconds: 6));

    expect(tester.getRect(keep), before, reason: '"keep" moved');
    expect(
      tester.getRect(find.widgetWithText(TextButton, strings.deleteAccountSend)),
      dangerBefore,
      reason: 'the delete button moved under the thumb',
    );
  });

  testWidgets('keeping the account is the easy button, and it closes the flow',
      (tester) async {
    await _pump(tester);
    await _reachFinalStep(tester, strings);

    // The prominent one is "keep", not "delete": the wrong tap should be the
    // harmless tap.
    expect(find.widgetWithText(FilledButton, strings.deleteAccountKeep),
        findsOneWidget);

    await tester
        .tap(find.widgetWithText(FilledButton, strings.deleteAccountKeep));
    await tester.pumpAndSettle();
    expect(find.text(strings.deleteAccountFinalTitle), findsNothing);
  });
}
