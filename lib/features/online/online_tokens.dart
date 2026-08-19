import 'package:flutter/material.dart';

/// Board geometry for the image boards: where the grid sits inside each
/// board asset, and the two colours drawn on top of it.
///
/// This started as the full design-token sheet for a mock "Online Oyna" screen.
/// That screen is gone (its palette lived on in [WoodTheme], which is what the
/// real screens use), so what is left is the part that could never move: the
/// grid fractions measured off each board image. [OnlineBoard] is the only
/// reader.
///
/// The fractions are measured from the baked-in grid of each asset and
/// fine-tuned on-device so a disc lands exactly in its square — change a board
/// image and these have to be re-measured with it.
class OnlineTokens {
  OnlineTokens._();

  // Board accents
  static const Color hintFill = Color(0x80C9A66B); // rgba(201,166,107,.5)
  static const Color hintRing = Color(0x8CFFF6E4); // rgba(255,246,228,.55)

  // ---- Wood board (board-crop.png is 754 x 713) ----
  static const double boardAspect = 754 / 713;
  static const double gridLeft = 0.0557;
  static const double gridTop = 0.0758;
  static const double gridRight = 0.0623;
  static const double gridBottom = 0.0575;

  static const String boardImage = 'assets/wood/board-crop.png';

  // ---- Marble board variant (Özel tema → Mermer) ----
  // marble-board.png is 431 x 433, cropped tight to the gray marble slab (all
  // wood removed), top-down with the 8x8 grid baked in; fractions measured.
  static const double marbleBoardAspect = 431 / 433;
  static const double marbleGridLeft = 0.0928;
  static const double marbleGridTop = 0.0947;
  static const double marbleGridRight = 0.0951;
  static const double marbleGridBottom = 0.0947;

  static const String marbleBoardImage = 'assets/marble/marble-board.png';

  // ---- Flower board variant (Özel tema → Çiçek) ----
  // flower-board.png: top-down, square, with the floral border + faded center
  // pattern + the rose-gold 8x8 grid baked in (NO discs). Trimmed to 924x922 so
  // the flowers reach the edges, filling the frame like the wood board. Grid
  // lines measured on the trimmed art.
  static const double flowerBoardAspect = 924 / 922;
  static const double flowerGridLeft = 0.0823; // x=76 / 924
  static const double flowerGridTop = 0.0813; // y=75 / 922
  static const double flowerGridRight = 0.0855; // (924-845) / 924
  static const double flowerGridBottom = 0.0868; // (922-842) / 922

  static const String flowerBoardImage = 'assets/flower/flower-board.png';
}
