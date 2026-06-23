import 'package:flutter/widgets.dart';

import '../services/settings_storage.dart';

enum BoardTheme { wood, turkuaz, gece, antrasit, petrol, mermer }

enum CoinColor { black, white, turquoise, orange }

/// App-wide visual theme. [original] is the classic teal/cream look; [wood] is
/// the warm handcrafted wood + parchment aesthetic from the Online Oyna screen.
enum AppThemeId { original, wood }

@immutable
class AppSettings {
  const AppSettings({
    this.locale,
    this.appTheme = AppThemeId.original,
    this.board = BoardTheme.wood,
    this.yourCoin = CoinColor.black,
    this.opponentCoin = CoinColor.white,
  });

  final Locale? locale;
  final AppThemeId appTheme;
  final BoardTheme board;
  final CoinColor yourCoin;
  final CoinColor opponentCoin;

  AppSettings copyWith({
    Locale? locale,
    bool clearLocale = false,
    AppThemeId? appTheme,
    BoardTheme? board,
    CoinColor? yourCoin,
    CoinColor? opponentCoin,
  }) {
    return AppSettings(
      locale: clearLocale ? null : (locale ?? this.locale),
      appTheme: appTheme ?? this.appTheme,
      board: board ?? this.board,
      yourCoin: yourCoin ?? this.yourCoin,
      opponentCoin: opponentCoin ?? this.opponentCoin,
    );
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController(this._settings, this._storage);

  AppSettings _settings;
  final SettingsStorage _storage;

  AppSettings get settings => _settings;

  void setLocale(Locale locale) {
    if (_settings.locale?.languageCode == locale.languageCode) return;
    _update(_settings.copyWith(locale: locale));
  }

  void setAppTheme(AppThemeId theme) {
    if (_settings.appTheme == theme) return;
    // Keep the board selection valid for the theme: the custom (wood) theme
    // only offers wood + mermer, while the original theme has no mermer.
    var board = _settings.board;
    if (theme == AppThemeId.wood) {
      if (board != BoardTheme.wood && board != BoardTheme.mermer) {
        board = BoardTheme.wood;
      }
    } else if (board == BoardTheme.mermer) {
      board = BoardTheme.wood;
    }
    _update(_settings.copyWith(appTheme: theme, board: board));
  }

  void setBoard(BoardTheme board) {
    if (_settings.board == board) return;
    _update(_settings.copyWith(board: board));
  }

  void setYourCoin(CoinColor color) {
    if (_settings.yourCoin == color) return;
    final opponent =
        color == _settings.opponentCoin ? _settings.yourCoin : _settings.opponentCoin;
    _update(_settings.copyWith(yourCoin: color, opponentCoin: opponent));
  }

  void setOpponentCoin(CoinColor color) {
    if (_settings.opponentCoin == color) return;
    final your =
        color == _settings.yourCoin ? _settings.opponentCoin : _settings.yourCoin;
    _update(_settings.copyWith(opponentCoin: color, yourCoin: your));
  }

  void _update(AppSettings next) {
    _settings = next;
    notifyListeners();
    _storage.save(next);
  }
}

class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope?.notifier != null, 'No SettingsScope found in context');
    return scope!.notifier!;
  }
}
