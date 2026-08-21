import 'package:flutter/widgets.dart';

import '../settings/app_settings.dart';
import '../game/game_settings.dart';
import '../models/game_stats.dart';
import '../models/rank.dart';

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
      'coinWalnut': 'Walnut',
      'coinMaple': 'Maple',
      'coinMarbleBlack': 'Marble Black',
      'coinMarbleWhite': 'Marble White',
      'coinFlowerPurple': 'Flower Purple',
      'coinFlowerPink': 'Flower Pink',
      'youWon': 'You Won!',
      'winnerTitle': '{name} Wins!',
      'drawTitle': "It's a Draw!",
      'aiLuckyMessage': 'Sorry, I just got lucky. Shall we play again?',
      'playAgain': 'Play Again',
      // Rematch (REV-98).
      'rematchOffer': 'Rematch',
      'rematchWaiting': 'Waiting for your opponent…',
      'rematchWithdraw': 'Never mind',
      'rematchIncoming': 'Your opponent wants a rematch',
      'rematchAccept': 'Accept',
      'rematchDeclineAction': 'No thanks',
      'rematchDeclined': 'Your opponent declined the rematch.',
      'rematchExpired': 'The rematch offer timed out.',
      'newOpponent': 'Find a New Opponent',
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
      'leaderboard': 'Leaderboard',
      'leaderboardAllTime': 'All-Time',
      'leaderboardEmpty': 'No one has played a ranked match yet.',
      'leaderboardUnitTrophies': 'trophies',
      'leaderboardUnitWins': 'wins',
      'leaderboardWeekly': 'Weekly',
      'leaderboardYourRank': 'Your rank',
      'leaveOnlineBody': "If you leave, you'll forfeit this match.",
      'level': 'Level',
      'music': 'Music',
      'onlineComingSoon': 'Online play is coming very soon!',
      'onlinePlay': 'Play Online',
      'onlineSignInChoiceTitle': 'How do you want to play online?',
      'onlineStatistics': 'Online Statistics',
      'opponentFound': 'Opponent found!',
      'opponentTurn': "Opponent's turn",
      'opponentReconnecting': 'Opponent is reconnecting…',
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
      'statsActivity': 'Activity',
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
      'statsWinRateTrend': 'Win rate trend',
      'statsWins': 'Wins',
      'viewAll': 'View all',
      'youLost': 'You Lost',
      'rankCaylak': 'Rookie',
      'rankAcemi': 'Novice',
      'rankKalfa': 'Journeyman',
      'rankUsta': 'Master',
      'rankBuyukusta': 'Grandmaster',
      'rankEfsane': 'Legend',
      'rankLabel': 'Rank',
      'trophies': 'Trophies',
      'rankUp': 'Rank up!',
      'topRank': 'Top rank',
      'trophyRoad': 'Trophy Road',
      'youAreHere': 'You are here',
      'matchFlipped': 'Flipped',
      'matchMargin': 'Margin',
      'matchStreak': 'Streak',
      // App & Account: legal, support, licences, version (REV-91).
      'appAndAccount': 'App & Account',
      'appAccountHint': 'Privacy, terms, version',
      'legalSection': 'Legal',
      'supportSection': 'Support',
      'accountSection': 'Account',
      'privacyPolicy': 'Privacy Policy',
      'termsOfUse': 'Terms of Use',
      'openSourceLicenses': 'Open-source licences',
      'supportContact': 'Support & feedback',
      'supportContactHint': '{email}',
      'deleteAccount': 'Delete my account',
      'marketingConsentTitle': 'Hear about our new games?',
      'marketingConsentBody':
          'We would send an e-mail when we release a new game or a big '
              'update — rarely, and never for anything else. You can turn it '
              'off any time from App & Account.',
      'marketingConsentAccept': 'Yes, e-mail me',
      'marketingConsentDecline': 'No thanks',
      'marketingConsentToggle': 'News about new games',
      'marketingConsentToggleHint': 'E-mail, rarely. Off by default.',
      'deleteAccountTitle': 'Delete your account?',
      'deleteAccountBody':
          'Your account, profile, trophies, coins and match history are '
              'permanently deleted. This cannot be undone.\n\nFinished matches '
              'stay as a record for your opponents, with your name and photo '
              'removed, for at most 12 months.',
      'deleteAccountSend': 'Delete permanently',
      'deleteAccountDetails': 'What gets deleted',
      'deleteAccountWorking': 'Deleting your account…',
      'deleteAccountDone': 'Your account has been deleted.',
      'deleteAccountFailed':
          'Your account could not be deleted, nothing was changed. '
              'Please try again.',
      'version': 'Version',
      'linkFailed': 'Could not open the link.',
      // Coin wallet (REV-102). The balance is server-written; these strings
      // only name it and say where it comes from.
      'coins': 'Coins',
      'happyHourWindow': 'Happy hour {start}–{end} · double coins',
      'happyHourNow': 'Happy hour is on · double coins',
      'happyHourTag': '×{multiplier} happy hour',
      'waitBonusNote':
          'Time spent waiting is added as a bonus when the match ends '
              '(up to +{cap}).',
      'waitBonusLine': 'Waiting bonus +{amount}',
      'wallet': 'Wallet',
      'walletRates': 'Win {win} · Draw {draw} · Loss {loss}',
      'walletSpendSoon': 'You will be able to spend these in the store.',
      'walletGuest': 'Sign in to earn coins.',
      // How to Play + first-launch tour (REV-103).
      'help': 'Help',
      'howToPlay': 'How to Play',
      'htpGoalTitle': 'The goal',
      'htpGoalBody':
          'When the board can take no more moves, whoever has more discs on it wins.',
      'htpMoveTitle': 'Making a move',
      'htpMoveBody':
          'Place a disc so that one or more of your opponent\'s discs are trapped in a straight line between the disc you just placed and another disc of yours. Every trapped disc turns over and becomes yours.',
      'htpBefore': 'Before',
      'htpAfter': 'After',
      'htpHintsTitle': 'The marked squares',
      'htpHintsBody':
          'Rings on the board mark every square you may play right now. A square with no ring would capture nothing, so it is not a legal move.',
      'htpPassTitle': 'Passing',
      'htpPassBody':
          'If no square would capture anything, your turn passes to your opponent automatically. You do not lose anything by passing.',
      'htpEndTitle': 'How a game ends',
      'htpEndBody':
          'The game ends when neither player has a legal move — usually when the board is full. Discs are counted, and the larger pile wins.',
      'htpCustomizeTitle': 'Make it yours',
      'htpCustomizeBody':
          'The board and both sets of discs are yours to choose — wood, marble, floral and plain colours, in any combination. Sound, music and language live in Settings too.',
      'htpOpenSettings': 'Open Settings',
      'htpOnlineTitle': 'Playing online',
      'htpOnlineBody':
          'Sign in and you can be matched with a real opponent, earn trophies, climb the ranks and appear on the leaderboard. You can also play as a guest.',
      'tourWelcomeTitle': 'Welcome to Reversi',
      'tourWelcomeBody':
          'A game of turning discs over. When no more moves are left, whoever has more discs on the board wins.',
      'tourCaptureTitle': 'Trap discs to turn them',
      'tourCaptureBody':
          'Close off a line of your opponent\'s discs at both ends and every disc in between becomes yours. The marked squares show where you may play.',
      'tourCustomizeTitle': 'Make it look how you like',
      'tourCustomizeBody':
          'Pick your board and your discs in Settings — wood, marble, floral or plain. You can change them any time, mid-game too.',
      'tourOnlineTitle': 'Play the world',
      'tourOnlineBody':
          'Play offline against the computer or a friend on one device, or go online for real opponents, trophies and the leaderboard.',
      'tourSkip': 'Skip',
      'tourNext': 'Next',
      'tourStart': 'Let\'s play',
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
      'coinWalnut': 'Ceviz',
      'coinMaple': 'Akçaağaç',
      'coinMarbleBlack': 'Mermer Siyah',
      'coinMarbleWhite': 'Mermer Beyaz',
      'coinFlowerPurple': 'Çiçek Mor',
      'coinFlowerPink': 'Çiçek Pembe',
      'youWon': 'Sen Kazandın!',
      'winnerTitle': '{name} Kazandı!',
      'drawTitle': 'Berabere!',
      'aiLuckyMessage': 'Üzgünüm, sadece şanslıydım. Tekrar oynayalım mı?',
      'playAgain': 'Tekrar Oyna',
      // Rövanş (REV-98).
      'rematchOffer': 'Rövanş',
      'rematchWaiting': 'Rakibin bekleniyor…',
      'rematchWithdraw': 'Vazgeç',
      'rematchIncoming': 'Rakibin rövanş istiyor',
      'rematchAccept': 'Kabul et',
      'rematchDeclineAction': 'İstemiyorum',
      'rematchDeclined': 'Rakibin rövanşı kabul etmedi.',
      'rematchExpired': 'Rövanş teklifi zaman aşımına uğradı.',
      'newOpponent': 'Yeni Rakip Bul',
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
      'leaderboard': 'Lider Tablosu',
      'leaderboardAllTime': 'Tüm Zamanlar',
      'leaderboardEmpty': 'Henüz kimse sıralı maç oynamadı.',
      'leaderboardUnitTrophies': 'kupa',
      'leaderboardUnitWins': 'galibiyet',
      'leaderboardWeekly': 'Haftalık',
      'leaderboardYourRank': 'Sıralaman',
      'leaveOnlineBody': 'Çıkarsan bu maçı kaybedersin.',
      'level': 'Seviye',
      'music': 'Müzik',
      'onlineComingSoon': 'Online oyun çok yakında!',
      'onlinePlay': 'Online Oyna',
      'onlineSignInChoiceTitle': 'Online nasıl oynamak istersin?',
      'onlineStatistics': 'Online İstatistikler',
      'opponentFound': 'Rakip bulundu!',
      'opponentTurn': 'Rakibin sırası',
      'opponentReconnecting': 'Rakip bağlanmaya çalışıyor…',
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
      'statsActivity': 'Aktivite',
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
      'statsWinRateTrend': 'Galibiyet oranı trendi',
      'statsWins': 'Galibiyet',
      'viewAll': 'Tümünü gör',
      'youLost': 'Kaybettin',
      'rankCaylak': 'Çaylak',
      'rankAcemi': 'Acemi',
      'rankKalfa': 'Kalfa',
      'rankUsta': 'Usta',
      'rankBuyukusta': 'Büyük Usta',
      'rankEfsane': 'Efsane',
      'rankLabel': 'Rütbe',
      'trophies': 'Kupa',
      'rankUp': 'Rütbe atladın!',
      'topRank': 'En yüksek rütbe',
      'trophyRoad': 'Kupa Yolu',
      'youAreHere': 'Buradasın',
      'matchFlipped': 'Çevrilen',
      'matchMargin': 'Fark',
      'matchStreak': 'Seri',
      // Uygulama & Hesap: yasal, destek, lisanslar, sürüm (REV-91).
      'appAndAccount': 'Uygulama & Hesap',
      'appAccountHint': 'Gizlilik, koşullar, sürüm',
      'legalSection': 'Yasal',
      'supportSection': 'Destek',
      'accountSection': 'Hesap',
      'privacyPolicy': 'Gizlilik Politikası',
      'termsOfUse': 'Kullanım Koşulları',
      'openSourceLicenses': 'Açık kaynak lisansları',
      'supportContact': 'Destek & geri bildirim',
      'supportContactHint': '{email}',
      'deleteAccount': 'Hesabımı sil',
      'marketingConsentTitle': 'Yeni oyunlarımızdan haberdar ol',
      'marketingConsentBody':
          'Yeni bir oyun ya da büyük bir güncelleme çıkardığımızda sana '
              'e-posta göndeririz — çok seyrek, başka hiçbir şey için değil. '
              'İstediğin an Uygulama & Hesap\'tan kapatabilirsin.',
      'marketingConsentAccept': 'Evet, haber ver',
      'marketingConsentDecline': 'Hayır, teşekkürler',
      'marketingConsentToggle': 'Yeni oyun haberleri',
      'marketingConsentToggleHint': 'E-posta, çok seyrek. Varsayılan kapalı.',
      'deleteAccountTitle': 'Hesabın silinsin mi?',
      'deleteAccountBody':
          'Hesabın, profilin, kupaların, coinlerin ve maç geçmişin kalıcı '
              'olarak silinir. Bu işlem geri alınamaz.\n\nTamamlanmış maçlar '
              'rakiplerin için kayıt olarak kalır; adın ve fotoğrafın '
              'çıkarılır, kayıtlar en fazla 12 ay tutulur.',
      'deleteAccountSend': 'Kalıcı olarak sil',
      'deleteAccountDetails': 'Neler siliniyor',
      'deleteAccountWorking': 'Hesabın siliniyor…',
      'deleteAccountDone': 'Hesabın silindi.',
      'deleteAccountFailed':
          'Hesabın silinemedi, hiçbir şey değişmedi. Lütfen tekrar dene.',
      'version': 'Sürüm',
      'linkFailed': 'Bağlantı açılamadı.',
      // Coin cüzdanı (REV-102). Bakiyeyi sunucu yazar; bu metinler yalnız adını
      // ve nereden geldiğini söyler.
      'coins': 'Coin',
      'happyHourWindow': 'Buluşma saati {start}–{end} · coin ×2',
      'happyHourNow': 'Buluşma saati başladı · coin ×2',
      'happyHourTag': '×{multiplier} buluşma saati',
      'waitBonusNote':
          'Beklediğin süre maç sonunda ikramiye olarak eklenecek '
              '(en fazla +{cap}).',
      'waitBonusLine': 'Bekleme ikramiyesi +{amount}',
      'wallet': 'Cüzdan',
      'walletRates': 'Galibiyet {win} · Beraberlik {draw} · Mağlubiyet {loss}',
      'walletSpendSoon': 'Mağaza açıldığında burada harcayabileceksin.',
      'walletGuest': 'Coin kazanmak için giriş yap.',
      // Nasıl Oynanır + ilk açılış turu (REV-103).
      'help': 'Yardım',
      'howToPlay': 'Nasıl Oynanır',
      'htpGoalTitle': 'Amaç',
      'htpGoalBody':
          'Tahtada oynanacak hamle kalmadığında, tahtada daha çok taşı olan kazanır.',
      'htpMoveTitle': 'Hamle nasıl yapılır',
      'htpMoveBody':
          'Taşını öyle bir kareye koy ki, yeni koyduğun taşla senin başka bir taşın arasında rakibin taşları düz bir hat üzerinde kapana kısılsın. Arada kalan taşların hepsi dönüp senin olur.',
      'htpBefore': 'Önce',
      'htpAfter': 'Sonra',
      'htpHintsTitle': 'İşaretli kareler',
      'htpHintsBody':
          'Tahtadaki halkalar, şu anda oynayabileceğin bütün kareleri gösterir. Halkası olmayan bir kare hiçbir taşı çeviremeyeceği için geçerli hamle değildir.',
      'htpPassTitle': 'Pas geçmek',
      'htpPassBody':
          'Hiçbir kare taş çeviremiyorsa sıra kendiliğinden rakibine geçer. Pas geçmek sana bir şey kaybettirmez.',
      'htpEndTitle': 'Oyun nasıl biter',
      'htpEndBody':
          'İki oyuncunun da geçerli hamlesi kalmadığında oyun biter — çoğu zaman tahta dolduğunda. Taşlar sayılır, çok olan kazanır.',
      'htpCustomizeTitle': 'Kendine göre ayarla',
      'htpCustomizeBody':
          'Tahta da, iki tarafın taşları da senin seçimin — ahşap, mermer, çiçekli ve düz renkler, istediğin bileşimde. Ses, müzik ve dil de Ayarlar\'da.',
      'htpOpenSettings': 'Ayarları aç',
      'htpOnlineTitle': 'Online oynamak',
      'htpOnlineBody':
          'Giriş yaptığında gerçek bir rakiple eşleşir, kupa kazanır, rütbe atlar ve lider tablosunda yer alırsın. İstersen misafir olarak da oynayabilirsin.',
      'tourWelcomeTitle': 'Reversi\'ye hoş geldin',
      'tourWelcomeBody':
          'Taş çevirme oyunu. Oynanacak hamle kalmadığında tahtada daha çok taşı olan kazanır.',
      'tourCaptureTitle': 'Taşları kıstır, dönsünler',
      'tourCaptureBody':
          'Rakibinin taş dizisini iki ucundan kapat, aradaki bütün taşlar senin olsun. İşaretli kareler nereye oynayabileceğini gösterir.',
      'tourCustomizeTitle': 'Görünüşü sana kalmış',
      'tourCustomizeBody':
          'Tahtanı ve taşlarını Ayarlar\'dan seç — ahşap, mermer, çiçekli ya da düz. İstediğin zaman, oyunun ortasında bile değiştirebilirsin.',
      'tourOnlineTitle': 'Herkesle oyna',
      'tourOnlineBody':
          'Bilgisayara karşı ya da tek cihazda arkadaşınla oynayabilir, online\'a geçip gerçek rakiplerle kupa ve lider tablosu için yarışabilirsin.',
      'tourSkip': 'Atla',
      'tourNext': 'Devam',
      'tourStart': 'Hadi oynayalım',
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

  // Rematch (REV-98).
  String get rematchOffer => _get('rematchOffer');
  String get rematchWaiting => _get('rematchWaiting');
  String get rematchWithdraw => _get('rematchWithdraw');
  String get rematchIncoming => _get('rematchIncoming');
  String get rematchAccept => _get('rematchAccept');
  String get rematchDeclineAction => _get('rematchDeclineAction');
  String get rematchDeclined => _get('rematchDeclined');
  String get rematchExpired => _get('rematchExpired');
  String get newOpponent => _get('newOpponent');
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

  String rankTitle(RankId rank) {
    switch (rank) {
      case RankId.caylak: return _get('rankCaylak');
      case RankId.acemi: return _get('rankAcemi');
      case RankId.kalfa: return _get('rankKalfa');
      case RankId.usta: return _get('rankUsta');
      case RankId.buyukusta: return _get('rankBuyukusta');
      case RankId.efsane: return _get('rankEfsane');
    }
  }

  String get rankLabel => _get('rankLabel');
  String get trophies => _get('trophies');
  String get rankUp => _get('rankUp');
  String get topRank => _get('topRank');
  String get trophyRoad => _get('trophyRoad');
  String get youAreHere => _get('youAreHere');
  String get matchFlipped => _get('matchFlipped');
  String get matchMargin => _get('matchMargin');
  String get matchStreak => _get('matchStreak');

  // Uygulama & Hesap (REV-91).
  String get appAndAccount => _get('appAndAccount');
  String get appAccountHint => _get('appAccountHint');
  String get legalSection => _get('legalSection');
  String get supportSection => _get('supportSection');
  String get accountSection => _get('accountSection');
  String get privacyPolicy => _get('privacyPolicy');
  String get termsOfUse => _get('termsOfUse');
  String get openSourceLicenses => _get('openSourceLicenses');
  String get supportContact => _get('supportContact');
  String supportContactHint(String email) =>
      _get('supportContactHint').replaceAll('{email}', email);
  String get deleteAccount => _get('deleteAccount');
  String get deleteAccountTitle => _get('deleteAccountTitle');
  String get deleteAccountBody => _get('deleteAccountBody');
  String get deleteAccountSend => _get('deleteAccountSend');
  String get deleteAccountDetails => _get('deleteAccountDetails');
  String get deleteAccountWorking => _get('deleteAccountWorking');
  String get deleteAccountDone => _get('deleteAccountDone');
  String get deleteAccountFailed => _get('deleteAccountFailed');

  // Marketing consent (REV-117).
  String get marketingConsentTitle => _get('marketingConsentTitle');
  String get marketingConsentBody => _get('marketingConsentBody');
  String get marketingConsentAccept => _get('marketingConsentAccept');
  String get marketingConsentDecline => _get('marketingConsentDecline');
  String get marketingConsentToggle => _get('marketingConsentToggle');
  String get marketingConsentToggleHint => _get('marketingConsentToggleHint');
  String get version => _get('version');
  String get linkFailed => _get('linkFailed');

  // Coin wallet (REV-102).
  String get coins => _get('coins');
  String get wallet => _get('wallet');
  String walletRates(int win, int draw, int loss) => _get('walletRates')
      .replaceAll('{win}', '$win')
      .replaceAll('{draw}', '$draw')
      .replaceAll('{loss}', '$loss');
  String get walletSpendSoon => _get('walletSpendSoon');
  String get walletGuest => _get('walletGuest');

  // Happy hour + waiting bonus (REV-109/110).
  String happyHourWindow(String start, String end) => _get('happyHourWindow')
      .replaceAll('{start}', start)
      .replaceAll('{end}', end);
  String get happyHourNow => _get('happyHourNow');
  String happyHourTag(int multiplier) =>
      _get('happyHourTag').replaceAll('{multiplier}', '$multiplier');
  String waitBonusNote(int cap) =>
      _get('waitBonusNote').replaceAll('{cap}', '$cap');
  String waitBonusLine(int amount) =>
      _get('waitBonusLine').replaceAll('{amount}', '$amount');

  // How to Play + first-launch tour (REV-103).
  String get help => _get('help');
  String get howToPlay => _get('howToPlay');
  String get htpGoalTitle => _get('htpGoalTitle');
  String get htpGoalBody => _get('htpGoalBody');
  String get htpMoveTitle => _get('htpMoveTitle');
  String get htpMoveBody => _get('htpMoveBody');
  String get htpBefore => _get('htpBefore');
  String get htpAfter => _get('htpAfter');
  String get htpHintsTitle => _get('htpHintsTitle');
  String get htpHintsBody => _get('htpHintsBody');
  String get htpPassTitle => _get('htpPassTitle');
  String get htpPassBody => _get('htpPassBody');
  String get htpEndTitle => _get('htpEndTitle');
  String get htpEndBody => _get('htpEndBody');
  String get htpCustomizeTitle => _get('htpCustomizeTitle');
  String get htpCustomizeBody => _get('htpCustomizeBody');
  String get htpOpenSettings => _get('htpOpenSettings');
  String get htpOnlineTitle => _get('htpOnlineTitle');
  String get htpOnlineBody => _get('htpOnlineBody');
  String get tourWelcomeTitle => _get('tourWelcomeTitle');
  String get tourWelcomeBody => _get('tourWelcomeBody');
  String get tourCaptureTitle => _get('tourCaptureTitle');
  String get tourCaptureBody => _get('tourCaptureBody');
  String get tourCustomizeTitle => _get('tourCustomizeTitle');
  String get tourCustomizeBody => _get('tourCustomizeBody');
  String get tourOnlineTitle => _get('tourOnlineTitle');
  String get tourOnlineBody => _get('tourOnlineBody');
  String get tourSkip => _get('tourSkip');
  String get tourNext => _get('tourNext');
  String get tourStart => _get('tourStart');

  String coinColorLabel(CoinColor color) {
    switch (color) {
      case CoinColor.black: return _get('coinBlack');
      case CoinColor.white: return _get('coinWhite');
      case CoinColor.turquoise: return _get('coinTurquoise');
      case CoinColor.orange: return _get('coinOrange');
      case CoinColor.walnut: return _get('coinWalnut');
      case CoinColor.maple: return _get('coinMaple');
      case CoinColor.marbleBlack: return _get('coinMarbleBlack');
      case CoinColor.marbleWhite: return _get('coinMarbleWhite');
      case CoinColor.flowerPurple: return _get('coinFlowerPurple');
      case CoinColor.flowerPink: return _get('coinFlowerPink');
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
  String get leaderboard => _get('leaderboard');
  String get leaderboardAllTime => _get('leaderboardAllTime');
  String get leaderboardEmpty => _get('leaderboardEmpty');
  String get leaderboardUnitTrophies => _get('leaderboardUnitTrophies');
  String get leaderboardUnitWins => _get('leaderboardUnitWins');
  String get leaderboardWeekly => _get('leaderboardWeekly');
  String get leaderboardYourRank => _get('leaderboardYourRank');
  String get leaveOnlineBody => _get('leaveOnlineBody');
  String get level => _get('level');
  String get music => _get('music');
  String get onlineComingSoon => _get('onlineComingSoon');
  String get onlinePlay => _get('onlinePlay');
  String get onlineSignInChoiceTitle => _get('onlineSignInChoiceTitle');
  String get onlineStatistics => _get('onlineStatistics');
  String get opponentFound => _get('opponentFound');
  String get opponentTurn => _get('opponentTurn');
  String get opponentReconnecting => _get('opponentReconnecting');
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
  String get statsActivity => _get('statsActivity');
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
  String get statsWinRateTrend => _get('statsWinRateTrend');
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
