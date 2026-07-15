import 'package:flutter/widgets.dart';

import '../settings/app_settings.dart';
import '../game/game_settings.dart';
import '../models/game_stats.dart';

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
      'undo': 'Undo',
      'gameSpeed': 'Game speed',
      'speedFast': 'Fast',
      'speedNormal': 'Normal',
      'speedSlow': 'Slow',
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
      'themeMermer': 'Marble',
      'themeCicek': 'Flower',
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
          'durationHoursMinutes': '{h}h {m}m',
      'durationMinutes': '{m}m',
      'durationSeconds': '{s}s',
      'continueWithGoogle': 'Continue with Google',
      'guestContinue': 'Continue as Guest',
      'guestLabel': 'Guest',
      'guestUpsellBody':
          "Guest progress isn't saved. Sign in with Google to track your stats, XP and the leaderboard.",
      'guestUpsellTitle': 'Sign in to unlock this',
      'leaveOnlineBody': "If you leave, you'll forfeit this match.",
      'level': 'Level',
      'music': 'Music',
      'onlineComingSoon': 'Online play is coming very soon!',
      'onlinePlay': 'Play Online',
      'onlineSignInChoiceTitle': 'How do you want to play online?',
      'onlineStatistics': 'Online Statistics',
      'opponentFound': 'Opponent found!',
      'opponentTurn': "Opponent's turn",
      'passSkippedOpponent':
          "Your opponent has no legal move — it's your turn again!",
      'passSkippedTwoPlayer':
          '{coin} has no legal move — the turn passes to the other player.',
      'passSkippedYou':
          'You have no legal move — your turn passes to your opponent.',
      'profile': 'Profile',
      'searchingOpponent': 'Finding an opponent…',
      'signIn': 'Sign in',
      'signInError': 'Sign-in failed, please try again.',
      'signOut': 'Sign out',
      'singlePlayerStatistics': 'Single Player Statistics',
      'sound': 'Sound',
      'soundEffects': 'Sound effects',
      'statistics': 'Statistics',
      'statsBestScoreDiff': 'Best score gap',
      'statsBestScoreDiffOnline': 'Best score gap',
      'statsBestStreak': 'Best win streak',
      'statsByMode': 'By game mode',
      'statsCurrentStreak': 'Current win streak',
      'statsDraws': 'Draws',
      'statsEmpty':
          "You haven't finished a game yet. Play one to see your stats here!",
      'statsLosses': 'Losses',
      'statsModeSinglePlayerEasy': '1 Player · Easy',
      'statsModeSinglePlayerHard': '1 Player · Hard',
      'statsModeSinglePlayerNormal': '1 Player · Normal',
      'statsOnlineEmpty':
          "You haven't played any online games yet. Play a ranked match to see your stats here!",
      'statsReset': 'Reset statistics',
      'statsResetBody':
          'All statistics will be permanently deleted. This cannot be undone.',
      'statsResetTitle': 'Reset statistics?',
      'statsResultDistribution': 'Result distribution',
      'statsTotalFlipped': 'Total discs flipped',
      'statsTotalFlippedOnline': 'Total discs flipped',
      'statsTotalGames': 'Total games',
      'statsTotalPlayTime': 'Total play time',
      'statsWinRate': 'Win rate',
      'statsWins': 'Wins',
      'viewAll': 'View all',
      'youLost': 'You Lost',
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
      'undo': 'Geri Al',
      'gameSpeed': 'Oyun hızı',
      'speedFast': 'Hızlı',
      'speedNormal': 'Normal',
      'speedSlow': 'Yavaş',
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
      'themeWood': 'Kahve rengi',
      'themeTurkuaz': 'Turkuaz',
      'themeGece': 'Gece Mavisi',
      'themeAntrasit': 'Antrasit',
      'themePetrol': 'Koyu Petrol',
      'themeMermer': 'Mermer',
      'themeCicek': 'Çiçek',
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
          'durationHoursMinutes': '{h} sa {m} dk',
      'durationMinutes': '{m} dk',
      'durationSeconds': '{s} sn',
      'continueWithGoogle': 'Google ile Devam Et',
      'guestContinue': 'Misafir Devam Et',
      'guestLabel': 'Misafir',
      'guestUpsellBody':
          'Misafir ilerlemesi kaydedilmez. İstatistiklerini, XP\'ni ve lider tablosunu takip etmek için Google ile giriş yap.',
      'guestUpsellTitle': 'Bunu açmak için giriş yap',
      'leaveOnlineBody': 'Çıkarsan bu maçı kaybedersin.',
      'level': 'Seviye',
      'music': 'Müzik',
      'onlineComingSoon': 'Online oyun çok yakında!',
      'onlinePlay': 'Online Oyna',
      'onlineSignInChoiceTitle': 'Online nasıl oynamak istersin?',
      'onlineStatistics': 'Online İstatistikler',
      'opponentFound': 'Rakip bulundu!',
      'opponentTurn': 'Rakibin sırası',
      'passSkippedOpponent': 'Rakibinin hamle hakkı yok, sıra sende!',
      'passSkippedTwoPlayer':
          '{coin} için geçerli hamle yok, sıra diğer oyuncuya geçti.',
      'passSkippedYou': 'Hamle hakkın yok, sıra rakibine geçti.',
      'profile': 'Profil',
      'searchingOpponent': 'Rakip aranıyor…',
      'signIn': 'Giriş yap',
      'signInError': 'Giriş yapılamadı, lütfen tekrar deneyin.',
      'signOut': 'Çıkış yap',
      'singlePlayerStatistics': 'Tek Oyuncu İstatistikleri',
      'sound': 'Ses',
      'soundEffects': 'Ses efektleri',
      'statistics': 'İstatistikler',
      'statsBestScoreDiff': 'En yüksek skor farkı',
      'statsBestScoreDiffOnline': 'En yüksek skor farkı',
      'statsBestStreak': 'En uzun galibiyet serisi',
      'statsByMode': 'Oyun moduna göre',
      'statsCurrentStreak': 'Mevcut galibiyet serisi',
      'statsDraws': 'Beraberlik',
      'statsEmpty':
          'Henüz tamamlanmış bir oyun yok. İstatistiklerini görmek için bir oyun oyna!',
      'statsLosses': 'Mağlubiyet',
      'statsModeSinglePlayerEasy': '1 Oyuncu · Kolay',
      'statsModeSinglePlayerHard': '1 Oyuncu · Zor',
      'statsModeSinglePlayerNormal': '1 Oyuncu · Normal',
      'statsOnlineEmpty':
          'Henüz çevrimiçi oyun oynamadın. Sıralama maçı oynayınca istatistiklerin burada görünecek!',
      'statsReset': 'İstatistikleri sıfırla',
      'statsResetBody':
          'Tüm istatistik verileri kalıcı olarak silinecek. Bu işlem geri alınamaz.',
      'statsResetTitle': 'İstatistikler sıfırlansın mı?',
      'statsResultDistribution': 'Sonuç dağılımı',
      'statsTotalFlipped': 'Toplam çevrilen taş',
      'statsTotalFlippedOnline': 'Toplam çevrilen taş',
      'statsTotalGames': 'Toplam oyun',
      'statsTotalPlayTime': 'Toplam oynama süresi',
      'statsWinRate': 'Galibiyet oranı',
      'statsWins': 'Galibiyet',
      'viewAll': 'Tümünü gör',
      'youLost': 'Kaybettin',
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
  String get undo => _get('undo');
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
      case BoardTheme.mermer: return _get('themeMermer');
      case BoardTheme.cicek: return _get('themeCicek');
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

  String get continueWithGoogle => _get('continueWithGoogle');
  String get guestContinue => _get('guestContinue');
  String get guestLabel => _get('guestLabel');
  String get guestUpsellBody => _get('guestUpsellBody');
  String get guestUpsellTitle => _get('guestUpsellTitle');
  String get leaveOnlineBody => _get('leaveOnlineBody');
  String get level => _get('level');
  String get music => _get('music');
  String get onlineComingSoon => _get('onlineComingSoon');
  String get onlinePlay => _get('onlinePlay');
  String get onlineSignInChoiceTitle => _get('onlineSignInChoiceTitle');
  String get onlineStatistics => _get('onlineStatistics');
  String get opponentFound => _get('opponentFound');
  String get opponentTurn => _get('opponentTurn');
  String get passSkippedOpponent => _get('passSkippedOpponent');
  String get passSkippedYou => _get('passSkippedYou');
  String get profile => _get('profile');
  String get searchingOpponent => _get('searchingOpponent');
  String get signIn => _get('signIn');
  String get signInError => _get('signInError');
  String get signOut => _get('signOut');
  String get singlePlayerStatistics => _get('singlePlayerStatistics');
  String get sound => _get('sound');
  String get soundEffects => _get('soundEffects');
  String get statistics => _get('statistics');
  String get statsBestScoreDiff => _get('statsBestScoreDiff');
  String get statsBestStreak => _get('statsBestStreak');
  String get statsByMode => _get('statsByMode');
  String get statsCurrentStreak => _get('statsCurrentStreak');
  String get statsDraws => _get('statsDraws');
  String get statsEmpty => _get('statsEmpty');
  String get statsLosses => _get('statsLosses');
  String get statsOnlineEmpty => _get('statsOnlineEmpty');
  String get statsReset => _get('statsReset');
  String get statsResetBody => _get('statsResetBody');
  String get statsResetTitle => _get('statsResetTitle');
  String get statsResultDistribution => _get('statsResultDistribution');
  String get statsTotalFlipped => _get('statsTotalFlipped');
  String get statsTotalGames => _get('statsTotalGames');
  String get statsTotalPlayTime => _get('statsTotalPlayTime');
  String get statsWinRate => _get('statsWinRate');
  String get statsWins => _get('statsWins');
  String get viewAll => _get('viewAll');
  String get youLost => _get('youLost');

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

  String passSkippedTwoPlayer(String coin) {
    return _get('passSkippedTwoPlayer').replaceAll('{coin}', coin);
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
