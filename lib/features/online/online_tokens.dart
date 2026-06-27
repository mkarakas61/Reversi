import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';

/// Design tokens for the "Online Oyna" match screen, taken verbatim from the
/// design handoff (warm handcrafted wood + cream parchment, serif type).
class OnlineTokens {
  OnlineTokens._();

  /// Disc asset matching the selected board theme. [isDark] true → black/you,
  /// false → white/opponent. Çiçek → flower coins, Mermer → marble, else wood.
  static String discFor(BoardTheme board, {required bool isDark}) {
    switch (board) {
      case BoardTheme.cicek:
        return isDark ? flowerDiscBlack : flowerDiscWhite;
      case BoardTheme.mermer:
        return isDark ? marbleDiscBlack : marbleDiscWhite;
      default:
        return isDark ? discWalnut : discMaple;
    }
  }

  // Backgrounds
  static const Color taupeBackground = Color(0xFFB7AB97);
  static const Color phoneSurface = Color(0xFFEFE5D5);

  // App bar
  static const Color appBarTop = Color(0xFF4A3220);
  static const Color appBarBottom = Color(0xFF38240F);
  static const Color gold = Color(0xFFB8860B);
  static const Color lightOnWood = Color(0xFFECD9BC);

  // Cards / pill
  static const Color cardTop = Color(0xFFF5EAD4);
  static const Color cardBottom = Color(0xFFEBDBBE);
  static const Color cardIdleBorder = Color(0x4D7A5634); // rgba(122,86,52,.30)
  static const Color pillBorder = Color(0x477A5634); // rgba(122,86,52,.28)

  // Result overlay
  static const Color overlayScrim = Color(0x8C2E1F14); // rgba(46,31,20,.55)
  static const Color overlayTop = Color(0xFFF7ECD7);
  static const Color overlayBottom = Color(0xFFEAD9BC);
  static const Color overlayBorder = Color(0xFFC9A66B);
  static const Color resultScore = Color(0xFF7A5224);
  static const Color buttonTop = Color(0xFF56391F);
  static const Color buttonBottom = Color(0xFF3E2A1E);
  static const Color buttonText = Color(0xFFF4E9D2);

  // Text
  static const Color inkTitle = Color(0xFF2E1B0E);
  static const Color inkName = Color(0xFF2E1F14);
  static const Color inkScore = Color(0xFF3E2A1E);
  static const Color goldText = Color(0xFF9A6B2F);
  static const Color pillText = Color(0xFF4A3220);

  // Board accents
  static const Color hintFill = Color(0x80C9A66B); // rgba(201,166,107,.5)
  static const Color hintRing = Color(0x8CFFF6E4); // rgba(255,246,228,.55)
  static const Color lastMoveRing = Color(0xE6C9A66B); // rgba(201,166,107,.9)

  // Board geometry (board-crop.png is 754 x 713). Grid fractions measured from
  // the baked-in checkerboard squares so discs center exactly in each square.
  static const double boardAspect = 754 / 713;
  static const double gridLeft = 0.0557;
  static const double gridTop = 0.0758;
  static const double gridRight = 0.0623;
  static const double gridBottom = 0.0575;

  // Assets
  static const String boardImage = 'assets/wood/board-crop.png';
  static const String discWalnut = 'assets/wood/disc-walnut.png'; // black / you
  static const String discMaple = 'assets/wood/disc-maple.png'; // white / opponent

  // ---- Marble board variant (Özel tema → Mermer) ----
  // marble-board.png is 431 x 433, cropped tight to the gray marble slab (all
  // wood removed), top-down with the 8x8 grid baked in; fractions measured.
  static const double marbleBoardAspect = 431 / 433;
  static const double marbleGridLeft = 0.0928;
  static const double marbleGridTop = 0.0947;
  static const double marbleGridRight = 0.0951;
  static const double marbleGridBottom = 0.0947;

  static const String marbleBoardImage = 'assets/marble/marble-board.png';
  static const String marbleDiscBlack =
      'assets/marble/disc-marble-black.png'; // black / you
  static const String marbleDiscWhite =
      'assets/marble/disc-marble-white.png'; // white / opponent

  // ---- Flower board variant (Özel tema → Çiçek) ----
  // flower-board.png: top-down, square, with the floral border + faded center
  // pattern + the rose-gold 8x8 grid baked in (NO discs). Discs are the
  // rose-gold-rimmed flower coins (mor/purple = black/you, pembe/pink =
  // white/opponent). Grid fractions are estimated from the reference art and
  // fine-tuned on-device so discs center exactly.
  // flower-board.png trimmed to 924x922 (flowers reach the edges, filling the
  // frame like the wood board). Grid lines measured on the trimmed art.
  static const double flowerBoardAspect = 924 / 922;
  static const double flowerGridLeft = 0.0823; // x=76 / 924
  static const double flowerGridTop = 0.0813; // y=75 / 922
  static const double flowerGridRight = 0.0855; // (924-845) / 924
  static const double flowerGridBottom = 0.0868; // (922-842) / 922

  static const String flowerBoardImage = 'assets/flower/flower-board.png';
  static const String flowerDiscBlack =
      'assets/flower/disc-flower-black.png'; // mor / purple — black / you
  static const String flowerDiscWhite =
      'assets/flower/disc-flower-white.png'; // pembe / pink — white / opponent
}
