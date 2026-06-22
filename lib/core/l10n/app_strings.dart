import 'package:flutter/widgets.dart';

import '../settings/app_settings.dart';
import '../game/game_settings.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('tr')];

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static const _values = {
    'en': {
      'appTitle': 'Reversi',
      'newGame': 'New game',
      'language': 'Language',
      'black': 'Black',
      'white': 'White',
      'turn': '{player} to move',
      'score': 'Score',
      'invalidMove': 'Choose a highlighted square to capture at least one disc.',
      'forcedPass': '{player} has no legal move and passes.',
      'gameOver': 'Game over',
      'winner': '{player} wins',
      'draw': 'Draw',
      'validMoveHint': 'Legal move',
      'lastMoveHint': 'Last move',
      'restartTitle': 'Restart game?',
      'restartBody': 'The current board will be cleared.',
      'cancel': 'Cancel',
      'restart': 'Restart',
      'onePlayer': 'Single Player',
      'twoPlayer': 'Two Players',
      'chooseDifficulty': 'Choose difficulty',
      'easy': 'Easy',
      'normal': 'Normal',
      'hard': 'Hard',
      'back': 'Back',
      'startGame': 'Start',
      'modeTwoPlayer': '2 Players',
      'modeSinglePlayer': '1 Player · {difficulty}',
      'aiThinking': 'Computer is thinking…',
      'leaveTitle': 'Leave game?',
      'leaveBody': 'You can continue this game later from the menu.',
      'leave': 'Leave',
      'continueGame': 'Continue',
      'playerYou': 'You',
      'playerAi': 'AI',
      'yourMove': 'Your move',
      'toMove': 'to move',
      'newGameTitle': 'New Game',
      'gameMode': 'Game mode',
      'settings': 'Settings',
      'boardColor': 'Board color',
      'coinColor': 'Coin color',
      'yourCoin': 'Your coin',
      'opponentCoin': 'Opponent coin',
      'themeWood': 'Wood',
      'themeTurkuaz': 'Turquoise',
      'themeGece': 'Midnight Blue',
      'themeAntrasit': 'Anthracite',
      'themePetrol': 'Deep Petrol',
      'coinBlack': 'Black',
      'coinWhite': 'White',
      'coinTurquoise': 'Turquoise',
      'coinOrange': 'Orange',
      'youWon': 'You Won!',
      'winnerTitle': '{name} Wins!',
      'drawTitle': "It's a Draw!",
      'aiLuckyMessage': 'Sorry, I just got lucky. Shall we play again?',
      'playAgain': 'Play Again',
      'mainMenu': 'Main Menu',
      'chooseTimeLimit': 'Choose time limit',
      'time30s': '30 sec limit',
      'time1m': '1 min limit',
      'time3m': '3 min limit',
      'timeNone': 'No time limit',
      'timeUp': "Time's up. Opponent's turn!",
    },
    'tr': {
      'appTitle': 'Reversi',
      'newGame': 'Yeni oyun',
      'language': 'Dil',
      'black': 'Siyah',
      'white': 'Beyaz',
      'turn': 'Sıra {player}',
      'score': 'Skor',
      'invalidMove': 'En az bir taşı çevirmek için işaretli karelerden birini seçin.',
      'forcedPass': '{player} için geçerli hamle yok, sıra pas geçildi.',
      'gameOver': 'Oyun bitti',
      'winner': '{player} kazandı',
      'draw': 'Berabere',
      'validMoveHint': 'Geçerli hamle',
      'lastMoveHint': 'Son hamle',
      'restartTitle': 'Oyunu yeniden başlat?',
      'restartBody': 'Mevcut tahta temizlenecek.',
      'cancel': 'Vazgeç',
      'restart': 'Yeniden başlat',
      'onePlayer': 'Tek Oyuncu',
      'twoPlayer': 'İki Oyuncu',
      'chooseDifficulty': 'Zorluk seçin',
      'easy': 'Kolay',
      'normal': 'Normal',
      'hard': 'Zor',
      'back': 'Geri',
      'startGame': 'Başla',
      'modeTwoPlayer': '2 Oyuncu',
      'modeSinglePlayer': '1 Oyuncu · {difficulty}',
      'aiThinking': 'Bilgisayar düşünüyor…',
      'leaveTitle': 'Oyundan çıkılsın mı?',
      'leaveBody': 'Bu oyuna daha sonra menüden devam edebilirsin.',
      'leave': 'Çık',
      'continueGame': 'Devam Et',
      'playerYou': 'Sen',
      'playerAi': 'Yapay Zeka',
      'yourMove': 'Senin sıran',
      'toMove': 'sırada',
      'newGameTitle': 'Yeni Oyun',
      'gameMode': 'Oyun modu',
      'settings': 'Ayarlar',
      'boardColor': 'Tahta rengi',
      'coinColor': 'Taş rengi',
      'yourCoin': 'Senin taşın',
      'opponentCoin': 'Rakip taşı',
      'themeWood': 'Ahşap',
      'themeTurkuaz': 'Turkuaz',
      'themeGece': 'Gece Mavisi',
      'themeAntrasit': 'Antrasit',
      'themePetrol': 'Koyu Petrol',
      'coinBlack': 'Siyah',
      'coinWhite': 'Beyaz',
      'coinTurquoise': 'Turkuaz',
      'coinOrange': 'Turuncu',
      'youWon': 'Sen Kazandın!',
      'winnerTitle': '{name} Kazandı!',
      'drawTitle': 'Berabere!',
      'aiLuckyMessage': 'Üzgünüm, sadece şanslıydım. Tekrar oynayalım mı?',
      'playAgain': 'Tekrar Oyna',
      'mainMenu': 'Ana Menü',
      'chooseTimeLimit': 'Süre sınırı seçin',
      'time30s': '30 sn süre sınırı',
      'time1m': '1 dk süre sınırı',
      'time3m': '3 dk süre sınırı',
      'timeNone': 'Süre Sınırsız',
      'timeUp': 'Süren doldu. Sıra Rakibinde!',
    },
  };

  String get appTitle => _get('appTitle');
  String get newGame => _get('newGame');
  String get language => _get('language');
  String get black => _get('black');
  String get white => _get('white');
  String get score => _get('score');
  String get invalidMove => _get('invalidMove');
  String get gameOver => _get('gameOver');
  String get draw => _get('draw');
  String get validMoveHint => _get('validMoveHint');
  String get lastMoveHint => _get('lastMoveHint');
  String get restartTitle => _get('restartTitle');
  String get restartBody => _get('restartBody');
  String get cancel => _get('cancel');
  String get restart => _get('restart');
  String get onePlayer => _get('onePlayer');
  String get twoPlayer => _get('twoPlayer');
  String get chooseDifficulty => _get('chooseDifficulty');
  String get easy => _get('easy');
  String get normal => _get('normal');
  String get hard => _get('hard');
  String get back => _get('back');
  String get startGame => _get('startGame');
  String get modeTwoPlayer => _get('modeTwoPlayer');
  String get aiThinking => _get('aiThinking');
  String get leaveTitle => _get('leaveTitle');
  String get leaveBody => _get('leaveBody');
  String get leave => _get('leave');
  String get continueGame => _get('continueGame');
  String get playerYou => _get('playerYou');
  String get playerAi => _get('playerAi');
  String get yourMove => _get('yourMove');
  String get toMove => _get('toMove');
  String get newGameTitle => _get('newGameTitle');
  String get gameMode => _get('gameMode');
  String get settings => _get('settings');
  String get boardColor => _get('boardColor');
  String get coinColor => _get('coinColor');
  String get yourCoin => _get('yourCoin');
  String get opponentCoin => _get('opponentCoin');
  String get youWon => _get('youWon');
  String get drawTitle => _get('drawTitle');
  String get aiLuckyMessage => _get('aiLuckyMessage');
  String get playAgain => _get('playAgain');
  String get mainMenu => _get('mainMenu');
  String get chooseTimeLimit => _get('chooseTimeLimit');
  String get timeUp => _get('timeUp');

  String timeLimitLabel(TimeLimit limit) {
    switch (limit) {
      case TimeLimit.thirtySeconds: return _get('time30s');
      case TimeLimit.oneMinute: return _get('time1m');
      case TimeLimit.threeMinutes: return _get('time3m');
      case TimeLimit.none: return _get('timeNone');
    }
  }

  String winnerTitle(String name) =>
      _get('winnerTitle').replaceAll('{name}', name);

  String boardThemeLabel(BoardTheme theme) {
    switch (theme) {
      case BoardTheme.wood: return _get('themeWood');
      case BoardTheme.turkuaz: return _get('themeTurkuaz');
      case BoardTheme.gece: return _get('themeGece');
      case BoardTheme.antrasit: return _get('themeAntrasit');
      case BoardTheme.petrol: return _get('themePetrol');
    }
  }

  String coinColorLabel(CoinColor color) {
    switch (color) {
      case CoinColor.black: return _get('coinBlack');
      case CoinColor.white: return _get('coinWhite');
      case CoinColor.turquoise: return _get('coinTurquoise');
      case CoinColor.orange: return _get('coinOrange');
    }
  }

  String playerName(String player) => player == 'black' ? black : white;

  String turn(String player) =>
      _get('turn').replaceAll('{player}', playerName(player));

  String forcedPass(String player) =>
      _get('forcedPass').replaceAll('{player}', playerName(player));

  String winner(String player) =>
      _get('winner').replaceAll('{player}', playerName(player));

  String winnerNamed(String name) =>
      _get('winner').replaceAll('{player}', name);

  String modeSinglePlayer(String difficulty) =>
      _get('modeSinglePlayer').replaceAll('{difficulty}', difficulty);

  String difficultyLabel(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy: return easy;
      case Difficulty.normal: return normal;
      case Difficulty.hard: return hard;
    }
  }

  String _get(String key) {
    final lang = _values.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';
    return _values[lang]![key]!;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales
      .any((s) => s.languageCode == locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppStrings> old) => false;
}
