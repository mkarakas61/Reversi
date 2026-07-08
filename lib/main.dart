import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/reversi_app.dart';
import 'core/auth/auth_scope.dart';
import 'core/profile/profile_scope.dart';
import 'core/services/analytics_service.dart';
import 'core/services/settings_storage.dart';
import 'core/services/sound_service.dart';
import 'core/settings/app_settings.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SoundService.instance.init();

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

  final authController =
      AuthController(firebaseReady ? FirebaseAuth.instance : null);
  final profileController = ProfileController(authController);

  runApp(ReversiApp(
    analytics: AnalyticsService(analytics: firebaseAnalytics),
    settings: settingsController,
    auth: authController,
    profile: profileController,
  ));
}
