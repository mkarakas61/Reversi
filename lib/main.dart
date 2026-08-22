import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/reversi_app.dart';
import 'core/auth/auth_scope.dart';
import 'core/profile/profile_scope.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_reporting_service.dart';
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

  runApp(ReversiApp(
    analytics: AnalyticsService(analytics: firebaseAnalytics),
    settings: settingsController,
    auth: authController,
    profile: profileController,
  ));
}
