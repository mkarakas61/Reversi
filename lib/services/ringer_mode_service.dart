import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mirrors Android's ringer modes. Other platforms always report [normal].
enum RingerMode { normal, vibrate, silent }

/// Queries the device's current ringer mode via a small platform channel.
/// Best-effort: any failure (or a non-Android platform) is treated as
/// [RingerMode.normal].
class RingerModeService {
  RingerModeService._();
  static final RingerModeService instance = RingerModeService._();

  static const _channel = MethodChannel('com.mustafakarakas.reversi/ringer');

  Future<RingerMode> currentMode() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return RingerMode.normal;
    }
    try {
      final mode = await _channel.invokeMethod<int>('getRingerMode');
      switch (mode) {
        case 0:
          return RingerMode.silent;
        case 1:
          return RingerMode.vibrate;
        default:
          return RingerMode.normal;
      }
    } catch (e) {
      debugPrint('getRingerMode failed: $e');
      return RingerMode.normal;
    }
  }
}
