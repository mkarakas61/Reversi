import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Generates and persists the device's guest display name ("Misafir-XXXX"),
/// so a returning guest keeps the same name across app restarts without ever
/// touching Firestore.
class GuestIdentityService {
  GuestIdentityService._();
  static final GuestIdentityService instance = GuestIdentityService._();

  static const _nameKey = 'guest_display_name';

  Future<String> displayName() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_nameKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final number = Random().nextInt(9000) + 1000; // 1000-9999
    final name = 'Misafir-$number';
    await prefs.setString(_nameKey, name);
    return name;
  }
}
