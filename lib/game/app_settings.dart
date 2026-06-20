import 'package:flutter/widgets.dart';

import '../services/settings_storage.dart';
import 'game_settings.dart';

/// App-wide visual theme. [classic] is the original turquoise/cream look;
/// [wood] re-skins the whole shell (banner, background, accents, text) in warm
/// walnut tones to match the wooden board.
enum AppTheme { classic, wood }

/// The theme currently in effect, read by the static palette getters in
/// `game_theme.dart`. Mutated by [SettingsController] *before* it notifies
/// listeners so the next rebuild resolves the right colours. Kept as a plain
/// global (rather than threaded through [BuildContext]) so the hundreds of
/// existing `GameColors.x` call sites keep working untouched. Lives here, not
/// in `game_theme.dart`, to avoid a circular import.
AppTheme activeAppTheme = AppTheme.classic;

/// Visual palette chosen for the board slab. [wood] keeps the original
/// image-textured table; the rest are the flat colour schemes from the
/// "Renkli Tahta" design.
enum BoardTheme { wood, turkuaz, gece, antrasit, petrol }

/// The four coin skins a player can wear. The engine still uses
/// [Disc.black]/[Disc.white] for the two sides; these only re-colour them.
enum CoinColor { black, white, turquoise, orange }

/// App-wide visual preferences. Defaults reproduce the original look (wooden
/// board, black vs white coins) so existing players see no change.
@immutable
class AppSettings {
  const AppSettings({
    this.locale,
    this.appTheme = AppTheme.classic,
    this.board = BoardTheme.wood,
    this.yourCoin = CoinColor.black,
    this.opponentCoin = CoinColor.white,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.gameSpeed = GameSpeed.normal,
  });

  /// Explicit language override. `null` follows the device locale.
  final Locale? locale;

  /// Overall app skin (classic turquoise vs. wood).
  final AppTheme appTheme;
  final BoardTheme board;

  /// Skin for the bottom side ([Disc.black] / "Sen").
  final CoinColor yourCoin;

  /// Skin for the top side ([Disc.white] / "Aria").
  final CoinColor opponentCoin;

  /// One-shot sound effects on/off.
  final bool soundEnabled;

  /// Background music on/off.
  final bool musicEnabled;

  /// How long the AI pauses before each move in single-player.
  final GameSpeed gameSpeed;

  AppSettings copyWith({
    Locale? locale,
    bool clearLocale = false,
    AppTheme? appTheme,
    BoardTheme? board,
    CoinColor? yourCoin,
    CoinColor? opponentCoin,
    bool? soundEnabled,
    bool? musicEnabled,
    GameSpeed? gameSpeed,
  }) {
    return AppSettings(
      locale: clearLocale ? null : (locale ?? this.locale),
      appTheme: appTheme ?? this.appTheme,
      board: board ?? this.board,
      yourCoin: yourCoin ?? this.yourCoin,
      opponentCoin: opponentCoin ?? this.opponentCoin,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      gameSpeed: gameSpeed ?? this.gameSpeed,
    );
  }
}

/// Holds the live [AppSettings] and persists every change. Lives above the
/// [MaterialApp] (see [SettingsScope]) so the menu, the game screen, and even
/// an open settings sheet all react to a change immediately.
class SettingsController extends ChangeNotifier {
  SettingsController(this._settings, this._storage) {
    activeAppTheme = _settings.appTheme;
  }

  AppSettings _settings;
  final SettingsStorage _storage;

  AppSettings get settings => _settings;

  void setLocale(Locale locale) {
    if (_settings.locale?.languageCode == locale.languageCode) return;
    _update(_settings.copyWith(locale: locale));
  }

  /// Switches the whole-app skin. The board follows the theme (wood theme →
  /// wooden board, classic → the turquoise slab) so the two never look mixed;
  /// players can still fine-tune the board afterwards from the board grid.
  void setAppTheme(AppTheme theme) {
    if (_settings.appTheme == theme) return;
    final board =
        theme == AppTheme.wood ? BoardTheme.wood : BoardTheme.turkuaz;
    _update(_settings.copyWith(appTheme: theme, board: board));
  }

  void setBoard(BoardTheme board) {
    if (_settings.board == board) return;
    _update(_settings.copyWith(board: board));
  }

  /// Sets the [Disc.black] side's coin. If it collides with the opponent's
  /// colour, the two swap so the sides always stay distinct.
  void setYourCoin(CoinColor color) {
    if (_settings.yourCoin == color) return;
    final opponent = color == _settings.opponentCoin
        ? _settings.yourCoin
        : _settings.opponentCoin;
    _update(_settings.copyWith(yourCoin: color, opponentCoin: opponent));
  }

  void setOpponentCoin(CoinColor color) {
    if (_settings.opponentCoin == color) return;
    final your = color == _settings.yourCoin
        ? _settings.opponentCoin
        : _settings.yourCoin;
    _update(_settings.copyWith(opponentCoin: color, yourCoin: your));
  }

  void setSoundEnabled(bool enabled) {
    if (_settings.soundEnabled == enabled) return;
    _update(_settings.copyWith(soundEnabled: enabled));
  }

  void setMusicEnabled(bool enabled) {
    if (_settings.musicEnabled == enabled) return;
    _update(_settings.copyWith(musicEnabled: enabled));
  }

  void setGameSpeed(GameSpeed speed) {
    if (_settings.gameSpeed == speed) return;
    _update(_settings.copyWith(gameSpeed: speed));
  }

  void _update(AppSettings next) {
    _settings = next;
    activeAppTheme = next.appTheme;
    notifyListeners();
    _storage.save(next);
  }
}

/// Exposes the [SettingsController] to the whole widget tree and rebuilds
/// dependents when settings change.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope?.notifier != null, 'No SettingsScope found in context');
    return scope!.notifier!;
  }
}
