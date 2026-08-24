import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';
import 'package:reversi/core/services/notification_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Push permission (REV-111). The platform gives an app one prompt: Android 13+
// never shows it twice, and a refusal cannot be revisited from inside the app.
// So the rules about *when* to spend it matter more than the plumbing around
// them, and they are tested here without Firebase in the room.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('when to ask', () {
    test('a signed-in player who has never been asked, is asked', () {
      expect(
        shouldAskForNotifications(
          signedIn: true,
          isGuest: false,
          alreadyAsked: false,
          alreadyGranted: false,
        ),
        isTrue,
      );
    });

    test('a guest is never asked — a guest has nowhere to store a token', () {
      // The token lives under users/{uid}, and a guest has no such document.
      // "A guest leaves no server trace" (REV-53/57) is not negotiable.
      expect(
        shouldAskForNotifications(
          signedIn: true,
          isGuest: true,
          alreadyAsked: false,
          alreadyGranted: false,
        ),
        isFalse,
      );
    });

    test('a signed-out player is never asked', () {
      expect(
        shouldAskForNotifications(
          signedIn: false,
          isGuest: false,
          alreadyAsked: false,
          alreadyGranted: false,
        ),
        isFalse,
      );
    });

    test('asking twice never happens, whatever the answer was', () {
      expect(
        shouldAskForNotifications(
          signedIn: true,
          isGuest: false,
          alreadyAsked: true,
          alreadyGranted: false,
        ),
        isFalse,
      );
    });

    test('an already-granted player is not asked again', () {
      expect(
        shouldAskForNotifications(
          signedIn: true,
          isGuest: false,
          alreadyAsked: false,
          alreadyGranted: true,
        ),
        isFalse,
      );
    });
  });

  group('when to register a device', () {
    test('granted and signed in: yes', () {
      expect(
        shouldRegisterDevice(signedIn: true, isGuest: false, granted: true),
        isTrue,
      );
    });

    test('a guest never registers, even having granted permission', () {
      // The permission dialog is the platform's and can be granted from the
      // system settings, so "granted" and "may store a token" are genuinely
      // separate questions.
      expect(
        shouldRegisterDevice(signedIn: true, isGuest: true, granted: true),
        isFalse,
      );
    });

    test('no permission means no token, signed in or not', () {
      expect(
        shouldRegisterDevice(signedIn: true, isGuest: false, granted: false),
        isFalse,
      );
      expect(
        shouldRegisterDevice(signedIn: false, isGuest: false, granted: true),
        isFalse,
      );
    });
  });

  group('the record of having asked', () {
    test('a fresh install has not been asked', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await const NotificationPrefs().hasAsked(), isFalse);
    });

    test('the record sticks, so the question is spent', () async {
      SharedPreferences.setMockInitialValues({});
      const prefs = NotificationPrefs();
      await prefs.markAsked();
      expect(await prefs.hasAsked(), isTrue);
    });
  });

  group('what the ask says', () {
    for (final lang in const ['tr', 'en']) {
      test('it is written in $lang', () {
        final strings = AppStrings(Locale(lang));
        expect(strings.notifyAskTitle, isNotEmpty);
        expect(strings.notifyAskBody, isNotEmpty);
        expect(strings.notifyAskAccept, isNotEmpty);
        expect(strings.notifyAskDecline, isNotEmpty);
      });
    }

    test('it promises no advertising, in both languages', () {
      // The one sentence people actually want answered before granting a
      // permission. If it is ever removed, it should be a deliberate edit.
      expect(AppStrings(const Locale('tr')).notifyAskBody.toLowerCase(),
          contains('reklam'));
      expect(AppStrings(const Locale('en')).notifyAskBody.toLowerCase(),
          contains('advertising'));
    });
  });
}
