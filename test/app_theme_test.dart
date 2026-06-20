import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/game/app_settings.dart';
import 'package:reversi/services/settings_storage.dart';
import 'package:reversi/theme/game_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    activeAppTheme = AppTheme.classic;
  });

  test('default theme is classic and palette is turquoise', () {
    final controller = SettingsController(const AppSettings(), SettingsStorage());
    expect(controller.settings.appTheme, AppTheme.classic);
    expect(activeAppTheme, AppTheme.classic);
    expect(GameColors.accent, const Color(0xFF13A99C));
  });

  test('switching to wood re-skins the palette and forces the wood board', () {
    final controller = SettingsController(const AppSettings(), SettingsStorage());

    controller.setAppTheme(AppTheme.wood);

    expect(activeAppTheme, AppTheme.wood);
    expect(controller.settings.appTheme, AppTheme.wood);
    // Shell tokens resolve to the wood values.
    expect(GameColors.accent, const Color(0xFFBE8B3D));
    expect(GameColors.bannerTop, const Color(0xFF7B5734));
    // The board follows the theme.
    expect(controller.settings.board, BoardTheme.wood);
  });

  test('switching back to classic restores the turquoise board', () {
    final controller = SettingsController(
      const AppSettings(appTheme: AppTheme.wood, board: BoardTheme.wood),
      SettingsStorage(),
    );
    expect(activeAppTheme, AppTheme.wood);

    controller.setAppTheme(AppTheme.classic);

    expect(activeAppTheme, AppTheme.classic);
    expect(controller.settings.board, BoardTheme.turkuaz);
    expect(GameColors.accent, const Color(0xFF13A99C));
  });

  test('app theme survives a save/load round-trip', () async {
    final storage = SettingsStorage();
    await storage.save(const AppSettings(appTheme: AppTheme.wood));

    final restored = await storage.load();

    expect(restored.appTheme, AppTheme.wood);
  });

  test('controller constructor syncs the global theme from loaded settings', () {
    activeAppTheme = AppTheme.classic;
    SettingsController(
      const AppSettings(appTheme: AppTheme.wood),
      SettingsStorage(),
    );
    expect(activeAppTheme, AppTheme.wood);
  });
}
