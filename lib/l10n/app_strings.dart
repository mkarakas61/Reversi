import 'package:flutter/widgets.dart';

import '../game/app_settings.dart';
import '../game/game_settings.dart';
import '../models/game_stats.dart';

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
      'appSubtitle': 'The classic game of strategy',
      'newGame': 'New game',
      'language': 'Language',
      'black': 'Black',
      'white': 'White',
      'turn': '{player} to move',
      'score': 'Score',
      'invalidMove':
          'Choose a highlighted square to capture at least one disc.',
      'passSkippedYou':
          'You have no legal move — your turn passes to your opponent.',
      'passSkippedOpponent':
          "Your opponent has no legal move — it's your turn again!",
      'passSkippedTwoPlayer':
          '{coin} has no legal move — the turn passes to the other player.',
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
      'sound': 'Sound',
      'soundEffects': 'Sound effects',
      'music': 'Music',
      'undo': 'Undo',
      'gameSpeed': 'Game speed',
      'speedFast': 'Fast',
      'speedNormal': 'Normal',
      'speedSlow': 'Slow',
      'signIn': 'Sign in',
      'signOut': 'Sign out',
      'signInError': 'Sign-in failed, please try again.',
      'profile': 'Profile',
      'level': 'Level',
      'onlinePlay': 'Play Online',
      'searchingOpponent': 'Finding an opponent…',
      'opponentFound': 'Opponent found!',
      'onlineComingSoon': 'Online play is coming very soon!',
      'opponentTurn': "Opponent's turn",
      'youLost': 'You Lost',
      'leaveOnlineBody': "If you leave, you'll forfeit this match.",
      'statistics': 'Statistics',
      'singlePlayerStatistics': 'Single Player Statistics',
      'statsTotalGames': 'Total games',
      'statsWins': 'Wins',
      'statsLosses': 'Losses',
      'statsDraws': 'Draws',
      'statsWinRate': 'Win rate',
      'statsCurrentStreak': 'Current win streak',
      'statsBestStreak': 'Best win streak',
      'statsBestScoreDiff': 'Best score gap',
      'statsTotalFlipped': 'Total discs flipped',
      'statsTotalPlayTime': 'Total play time',
      'statsResultDistribution': 'Result distribution',
      'statsByMode': 'By game mode',
      'statsEmpty':
          "You haven't finished a game yet. Play one to see your stats here!",
      'statsReset': 'Reset statistics',
      'statsResetTitle': 'Reset statistics?',
      'statsResetBody':
          'All statistics will be permanently deleted. This cannot be undone.',
      'statsModeSinglePlayerEasy': '1 Player · Easy',
      'statsModeSinglePlayerNormal': '1 Player · Normal',
      'statsModeSinglePlayerHard': '1 Player · Hard',
      'durationHoursMinutes': '{h}h {m}m',
      'durationMinutes': '{m}m',
      'durationSeconds': '{s}s',
      'onlineStatistics': 'Online Statistics',
      'statsOnlineEmpty':
          "You haven't played any online games yet. Play a ranked match to see your stats here!",
      'statsTotalFlippedOnline': 'Total discs flipped',
      'statsBestScoreDiffOnline': 'Best score gap',
      'viewAll': 'View all',
    },
    'tr': {
      'appTitle': 'Reversi',
      'appSubtitle': 'Klasik strateji oyunu',
      'newGame': 'Yeni oyun',
      'language': 'Dil',
      'black': 'Siyah',
      'white': 'Beyaz',
      'turn': 'Sıra {player}',
      'score': 'Skor',
      'invalidMove':
          'En az bir taşı çevirmek için işaretli karelerden birini seçin.',
      'passSkippedYou': 'Hamle hakkın yok, sıra rakibine geçti.',
      'passSkippedOpponent': 'Rakibinin hamle hakkı yok, sıra sende!',
      'passSkippedTwoPlayer':
          '{coin} için geçerli hamle yok, sıra diğer oyuncuya geçti.',
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
      'sound': 'Ses',
      'soundEffects': 'Ses efektleri',
      'music': 'Müzik',
      'undo': 'Geri Al',
      'gameSpeed': 'Oyun hızı',
      'speedFast': 'Hızlı',
      'speedNormal': 'Normal',
      'speedSlow': 'Yavaş',
      'signIn': 'Giriş yap',
      'signOut': 'Çıkış yap',
      'signInError': 'Giriş yapılamadı, lütfen tekrar deneyin.',
      'profile': 'Profil',
      'level': 'Seviye',
      'onlinePlay': 'Online Oyna',
      'searchingOpponent': 'Rakip aranıyor…',
      'opponentFound': 'Rakip bulundu!',
      'onlineComingSoon': 'Online oyun çok yakında!',
      'opponentTurn': 'Rakibin sırası',
      'youLost': 'Kaybettin',
      'leaveOnlineBody': 'Çıkarsan bu maçı kaybedersin.',
      'statistics': 'İstatistikler',
      'singlePlayerStatistics': 'Tek Oyuncu İstatistikleri',
      'statsTotalGames': 'Toplam oyun',
      'statsWins': 'Galibiyet',
      'statsLosses': 'Mağlubiyet',
      'statsDraws': 'Beraberlik',
      'statsWinRate': 'Galibiyet oranı',
      'statsCurrentStreak': 'Mevcut galibiyet serisi',
      'statsBestStreak': 'En uzun galibiyet serisi',
      'statsBestScoreDiff': 'En yüksek skor farkı',
      'statsTotalFlipped': 'Toplam çevrilen taş',
      'statsTotalPlayTime': 'Toplam oynama süresi',
      'statsResultDistribution': 'Sonuç dağılımı',
      'statsByMode': 'Oyun moduna göre',
      'statsEmpty':
          'Henüz tamamlanmış bir oyun yok. İstatistiklerini görmek için bir oyun oyna!',
      'statsReset': 'İstatistikleri sıfırla',
      'statsResetTitle': 'İstatistikler sıfırlansın mı?',
      'statsResetBody':
          'Tüm istatistik verileri kalıcı olarak silinecek. Bu işlem geri alınamaz.',
      'statsModeSinglePlayerEasy': '1 Oyuncu · Kolay',
      'statsModeSinglePlayerNormal': '1 Oyuncu · Normal',
      'statsModeSinglePlayerHard': '1 Oyuncu · Zor',
      'durationHoursMinutes': '{h} sa {m} dk',
      'durationMinutes': '{m} dk',
      'durationSeconds': '{s} sn',
      'onlineStatistics': 'Online İstatistikler',
      'statsOnlineEmpty':
          'Henüz çevrimiçi oyun oynamadın. Sıralama maçı oynayınca istatistiklerin burada görünecek!',
      'statsTotalFlippedOnline': 'Toplam çevrilen taş',
      'statsBestScoreDiffOnline': 'En yüksek skor farkı',
      'viewAll': 'Tümünü gör',
    },
  };

  String get appTitle => _get('appTitle');
  String get appSubtitle => _get('appSubtitle');
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
  String get sound => _get('sound');
  String get soundEffects => _get('soundEffects');
  String get music => _get('music');
  String get undo => _get('undo');
  String get signIn => _get('signIn');
  String get signOut => _get('signOut');
  String get signInError => _get('signInError');
  String get profile => _get('profile');
  String get level => _get('level');
  String get onlinePlay => _get('onlinePlay');
  String get searchingOpponent => _get('searchingOpponent');
  String get opponentFound => _get('opponentFound');
  String get onlineComingSoon => _get('onlineComingSoon');
  String get opponentTurn => _get('opponentTurn');
  String get youLost => _get('youLost');
  String get leaveOnlineBody => _get('leaveOnlineBody');
  String get statistics => _get('statistics');
  String get singlePlayerStatistics => _get('singlePlayerStatistics');
  String get statsTotalGames => _get('statsTotalGames');
  String get statsWins => _get('statsWins');
  String get statsLosses => _get('statsLosses');
  String get statsDraws => _get('statsDraws');
  String get statsWinRate => _get('statsWinRate');
  String get statsCurrentStreak => _get('statsCurrentStreak');
  String get statsBestStreak => _get('statsBestStreak');
  String get statsBestScoreDiff => _get('statsBestScoreDiff');
  String get statsTotalFlipped => _get('statsTotalFlipped');
  String get statsTotalPlayTime => _get('statsTotalPlayTime');
  String get statsResultDistribution => _get('statsResultDistribution');
  String get statsByMode => _get('statsByMode');
  String get statsEmpty => _get('statsEmpty');
  String get statsReset => _get('statsReset');
  String get statsResetTitle => _get('statsResetTitle');
  String get statsResetBody => _get('statsResetBody');
  String get onlineStatistics => _get('onlineStatistics');
  String get statsOnlineEmpty => _get('statsOnlineEmpty');
  String get viewAll => _get('viewAll');

  String timeLimitLabel(TimeLimit limit) {
    switch (limit) {
      case TimeLimit.thirtySeconds:
        return _get('time30s');
      case TimeLimit.oneMinute:
        return _get('time1m');
      case TimeLimit.threeMinutes:
        return _get('time3m');
      case TimeLimit.none:
        return _get('timeNone');
    }
  }

  String winnerTitle(String name) {
    return _get('winnerTitle').replaceAll('{name}', name);
  }

  String boardThemeLabel(BoardTheme theme) {
    switch (theme) {
      case BoardTheme.wood:
        return _get('themeWood');
      case BoardTheme.turkuaz:
        return _get('themeTurkuaz');
      case BoardTheme.gece:
        return _get('themeGece');
      case BoardTheme.antrasit:
        return _get('themeAntrasit');
      case BoardTheme.petrol:
        return _get('themePetrol');
    }
  }

  String coinColorLabel(CoinColor color) {
    switch (color) {
      case CoinColor.black:
        return _get('coinBlack');
      case CoinColor.white:
        return _get('coinWhite');
      case CoinColor.turquoise:
        return _get('coinTurquoise');
      case CoinColor.orange:
        return _get('coinOrange');
    }
  }

  String playerName(String player) => player == 'black' ? black : white;

  String turn(String player) {
    return _get('turn').replaceAll('{player}', playerName(player));
  }

  String get passSkippedYou => _get('passSkippedYou');
  String get passSkippedOpponent => _get('passSkippedOpponent');

  String passSkippedTwoPlayer(String coin) {
    return _get('passSkippedTwoPlayer').replaceAll('{coin}', coin);
  }

  String winner(String player) {
    return _get('winner').replaceAll('{player}', playerName(player));
  }

  /// Like [winner] but takes an already-resolved display name.
  String winnerNamed(String name) {
    return _get('winner').replaceAll('{player}', name);
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

  String get gameSpeed => _get('gameSpeed');

  String gameSpeedLabel(GameSpeed speed) {
    switch (speed) {
      case GameSpeed.fast:
        return _get('speedFast');
      case GameSpeed.normal:
        return _get('speedNormal');
      case GameSpeed.slow:
        return _get('speedSlow');
    }
  }

  String statsModeLabel(StatsMode mode) {
    switch (mode) {
      case StatsMode.singlePlayerEasy:
        return _get('statsModeSinglePlayerEasy');
      case StatsMode.singlePlayerNormal:
        return _get('statsModeSinglePlayerNormal');
      case StatsMode.singlePlayerHard:
        return _get('statsModeSinglePlayerHard');
    }
  }

  /// Formats a duration as "{h}h {m}m", "{m}m" or "{s}s" depending on size.
  String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return _get('durationHoursMinutes')
          .replaceAll('{h}', '$hours')
          .replaceAll('{m}', '$minutes');
    }
    if (minutes > 0) {
      return _get('durationMinutes').replaceAll('{m}', '$minutes');
    }
    return _get('durationSeconds').replaceAll('{s}', '$totalSeconds');
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
