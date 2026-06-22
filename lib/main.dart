import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/reversi_app.dart';
import 'core/services/analytics_service.dart';
import 'core/services/settings_storage.dart';
import 'core/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settingsStorage = SettingsStorage();
  final settings = await settingsStorage.load();
  final settingsController = SettingsController(settings, settingsStorage);

  FirebaseAnalytics? firebaseAnalytics;
  try {
    await Firebase.initializeApp();
    firebaseAnalytics = FirebaseAnalytics.instance;
  } catch (_) {
    firebaseAnalytics = null;
  }

  runApp(ReversiApp(
    analytics: AnalyticsService(analytics: firebaseAnalytics),
    settings: settingsController,
  ));
}
