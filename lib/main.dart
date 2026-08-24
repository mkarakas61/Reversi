import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/reversi_app.dart';
import 'features/online/screens/opponent_preview_screen.dart';
import 'core/auth/auth_scope.dart';
import 'core/profile/profile_scope.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/onboarding_storage.dart';
import 'core/services/settings_storage.dart';
import 'core/services/sound_service.dart';
import 'core/settings/app_settings.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SoundService.instance.init();

  // One-off: gives devices that already saw the welcome tour one more look at
  // it (OnboardingStorage._resetTicket). Self-limiting — see that comment.
  await const OnboardingStorage().applyPendingReset();

  final settingsStorage = SettingsStorage();
  final settings = await settingsStorage.load();
  final settingsController = SettingsController(settings, settingsStorage);

  FirebaseAnalytics? firebaseAnalytics;
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseAnalytics = FirebaseAnalytics.instance;
    firebaseReady = true;
  } catch (e) {
    // Keep the app usable offline even if Firebase can't start.
    debugPrint('Firebase init failed: $e');
    firebaseAnalytics = null;
  }

  // Crash reporting is installed as early as Firebase allows, so a crash in
  // the first frames is still reported (REV-94).
  final crashReporting = CrashReportingService(
    crashlytics: firebaseReady ? FirebaseCrashlytics.instance : null,
  );
  crashReporting.install();

  final authController =
      AuthController(firebaseReady ? FirebaseAuth.instance : null);
  final profileController = ProfileController(authController);

  // Reports carry the uid and nothing else about the player. Signing out
  // clears it, so nobody inherits the previous account's identifier.
  void syncCrashUser() => crashReporting.setUser(authController.user?.uid);
  syncCrashUser();
  authController.addListener(syncCrashUser);

  // Keeps this device's push token attached to whoever is signed in (REV-111).
  // Nothing is *asked* here — permission is requested in context, where the
  // player can see what it is for. This only acts on a yes that already
  // exists, which is why it can run on every launch: a player who granted
  // permission months ago is re-registered without a word, and one who never
  // did is left alone.
  void syncPushDevice() {
    final profile = profileController.profile;
    if (profile == null || profile.isGuest) return;
    unawaited(NotificationService.instance.registerDevice(
      uid: profile.uid,
      isGuest: profile.isGuest,
      lang: settingsController.settings.locale?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    ));
  }

  syncPushDevice();
  profileController.addListener(syncPushDevice);

  // A tapped "opponent found" notification opens the match itself (REV-114).
  // Deferred to after the first frame because it navigates, and a cold start
  // launched *by* a notification has no navigator until then.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(NotificationService.instance.installTapHandling((gameId) {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) return;
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => OpponentPreviewScreen(gameId: gameId),
      ));
    }));
  });

  runApp(ReversiApp(
    analytics: AnalyticsService(analytics: firebaseAnalytics),
    settings: settingsController,
    auth: authController,
    profile: profileController,
  ));
}
