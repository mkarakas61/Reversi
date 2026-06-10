import 'package:flutter/widgets.dart';

import '../game/game_settings.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('tr')];

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

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
      'invalidMove':
          'Choose a highlighted square to capture at least one disc.',
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
    },
    'tr': {
      'appTitle': 'Reversi',
      'newGame': 'Yeni oyun',
      'language': 'Dil',
      'black': 'Siyah',
      'white': 'Beyaz',
      'turn': 'Sıra {player}',
      'score': 'Skor',
      'invalidMove':
          'En az bir taşı çevirmek için işaretli karelerden birini seçin.',
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

  String playerName(String player) => player == 'black' ? black : white;

  String turn(String player) {
    return _get('turn').replaceAll('{player}', playerName(player));
  }

  String forcedPass(String player) {
    return _get('forcedPass').replaceAll('{player}', playerName(player));
  }

  String winner(String player) {
    return _get('winner').replaceAll('{player}', playerName(player));
  }

  String modeSinglePlayer(String difficulty) {
    return _get('modeSinglePlayer').replaceAll('{difficulty}', difficulty);
  }

  String difficultyLabel(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return easy;
      case Difficulty.normal:
        return normal;
      case Difficulty.hard:
        return hard;
    }
  }

  String _get(String key) {
    final language =
        _values.containsKey(locale.languageCode) ? locale.languageCode : 'en';
    return _values[language]![key]!;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppStrings.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppStrings> old) => false;
}
