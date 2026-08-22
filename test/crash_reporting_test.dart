import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/services/crash_reporting_service.dart';

// REV-94. Crashlytics itself cannot run in a unit test (no Firebase, no
// platform channels), so what is worth pinning here is the other half: the
// service has to be harmless when Firebase never started. `main` already keeps
// the app usable offline, and crash reporting must not be the thing that turns
// a failed init into a broken launch.
void main() {
  group('CrashReportingService without Firebase', () {
    test('reports itself as disabled', () {
      expect(CrashReportingService().isEnabled, isFalse);
    });

    test('install() leaves the existing error handler alone', () {
      final original = FlutterError.onError;
      addTearDown(() => FlutterError.onError = original);

      var seen = 0;
      FlutterError.onError = (_) => seen++;
      final installed = FlutterError.onError;

      CrashReportingService().install();

      expect(FlutterError.onError, same(installed),
          reason: 'nothing to report to, so nothing should be wrapped');
      FlutterError.onError!(FlutterErrorDetails(exception: Exception('boom')));
      expect(seen, 1);
    });

    test('setUser and recordError do nothing instead of throwing', () async {
      final service = CrashReportingService();
      await service.setUser('some-uid');
      await service.setUser(null);
      await service.recordError(Exception('boom'), StackTrace.current);
    });
  });
}
