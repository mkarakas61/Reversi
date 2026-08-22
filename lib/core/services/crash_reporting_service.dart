import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash and uncaught-error reporting (REV-94).
///
/// Wraps [FirebaseCrashlytics] the way [AnalyticsService] wraps Analytics: the
/// instance is nullable, so the app keeps running (and tests keep passing) when
/// Firebase never started — `main` already tolerates a failed init.
///
/// **What is sent:** the error, its stack, and at most the signed-in **uid**.
/// Never a name, e-mail or photo — a crash report is a debugging tool, not a
/// second copy of the profile. The uid is what lets a support request ("my game
/// froze") be matched to a report; nothing else here needs to identify anyone.
class CrashReportingService {
  CrashReportingService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics;

  final FirebaseCrashlytics? _crashlytics;

  bool get isEnabled => _crashlytics != null;

  /// Routes framework and platform errors that nobody caught into Crashlytics.
  ///
  /// Both hooks are needed and they catch different things: [FlutterError.onError]
  /// fires for errors thrown inside the framework (build, layout, paint),
  /// [PlatformDispatcher.onError] for everything else that escapes to the root
  /// zone — async gaps, platform-channel replies, timers. `runZonedGuarded` is
  /// the older recipe for the second half and is not needed alongside it.
  ///
  /// The previous [FlutterError.onError] is kept and still runs first, so the
  /// red screen and the console dump stay exactly as they are in debug; the
  /// report is added on top rather than swapped in.
  void install() {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      crashlytics.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      // Handled: returning false would let the error kill the isolate, and a
      // report we cannot see the app recover from helps nobody.
      return true;
    };
  }

  /// Stamps reports with the signed-in [uid], or clears it on sign-out.
  ///
  /// Crashlytics keeps the identifier until it is overwritten, so signing out
  /// must clear it — otherwise the next player's crashes would carry the
  /// previous player's uid.
  Future<void> setUser(String? uid) async {
    await _crashlytics?.setUserIdentifier(uid ?? '');
  }

  /// Reports an error the app caught itself and chose to keep running through.
  Future<void> recordError(Object error, StackTrace? stack,
      {String? reason}) async {
    await _crashlytics?.recordError(error, stack, reason: reason);
  }
}
