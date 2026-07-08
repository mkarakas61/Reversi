import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_stats.dart';

/// Persists the lifetime [GameStats] across launches.
class StatsStorage {
  static const _key = 'game_stats_v1';

  Future<GameStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return GameStats.empty;
    }
    try {
      return GameStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_key);
      return GameStats.empty;
    }
  }

  Future<void> save(GameStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(stats.toJson()));
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
