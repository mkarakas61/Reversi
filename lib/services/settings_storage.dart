import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/app_settings.dart';

/// Persists [AppSettings] (language, board theme, coin colours) across launches.
class SettingsStorage {
  static const _localeKey = 'settings_locale';
  static const _boardKey = 'settings_board';
  static const _yourCoinKey = 'settings_your_coin';
  static const _opponentCoinKey = 'settings_opponent_coin';
  static const _soundKey = 'settings_sound_enabled';
  static const _musicKey = 'settings_music_enabled';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    Locale? locale;
    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null && localeCode.isNotEmpty) {
      locale = Locale(localeCode);
    }

    return AppSettings(
      locale: locale,
      board: _enumByName(BoardTheme.values, prefs.getString(_boardKey)) ??
          BoardTheme.wood,
      yourCoin: _enumByName(CoinColor.values, prefs.getString(_yourCoinKey)) ??
          CoinColor.black,
      opponentCoin:
          _enumByName(CoinColor.values, prefs.getString(_opponentCoinKey)) ??
              CoinColor.white,
      soundEnabled: prefs.getBool(_soundKey) ?? true,
      musicEnabled: prefs.getBool(_musicKey) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final locale = settings.locale;
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
    await prefs.setString(_boardKey, settings.board.name);
    await prefs.setString(_yourCoinKey, settings.yourCoin.name);
    await prefs.setString(_opponentCoinKey, settings.opponentCoin.name);
    await prefs.setBool(_soundKey, settings.soundEnabled);
    await prefs.setBool(_musicKey, settings.musicEnabled);
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
