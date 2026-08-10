import 'package:flutter/material.dart';

import '../settings/app_settings.dart';
import 'game_colors.dart';

/// Whether the warm wood/parchment app theme is currently active.
bool isWoodTheme(BuildContext context) =>
    SettingsScope.of(context).settings.appTheme == AppThemeId.wood;

// Theme-aware page chrome (REV-79): every screen uses these so the Güzelsi
// (wood) ↔ Orijinal (cream/teal) app theme applies app-wide, not just on the
// menu/settings. Güzelsi → parchment body + dark-wood header; Orijinal →
// cream body + teal banner.

/// Surface colour behind the page body gradient.
Color pageSurfaceColor(BuildContext context) =>
    isWoodTheme(context) ? WoodTheme.surface : GameColors.creamTop;

/// Page body (content area) gradient.
Gradient pageBackgroundGradient(BuildContext context) =>
    isWoodTheme(context) ? WoodTheme.pageBackground : creamShellGradient;

/// Header / immersive full-bleed banner gradient (white text sits on top in
/// both themes).
Gradient headerGradient(BuildContext context) =>
    isWoodTheme(context) ? WoodTheme.buttonGradient : bannerGradient;

/// Shared tokens for the "Ahşap" (wood) app theme — the warm handcrafted wood +
/// cream parchment look from the Online Oyna screen, reused across all screens.
class WoodTheme {
  WoodTheme._();

  // Fonts
  static const String displayFont = 'Marcellus';
  static const String bodyFont = 'Lora';

  // Wood disc images (walnut = black/you, maple = white/opponent)
  static const String discWalnut = 'assets/wood/disc-walnut.png';
  static const String discMaple = 'assets/wood/disc-maple.png';

  // Surfaces
  static const Color surface = Color(0xFFEFE5D5);
  static const Color cardTop = Color(0xFFF5EAD4);
  static const Color cardBottom = Color(0xFFEBDBBE);
  static const Color cardIdleBorder = Color(0x4D7A5634);

  // Accents / text
  static const Color gold = Color(0xFFB8860B);
  static const Color goldText = Color(0xFF9A6B2F);
  static const Color inkTitle = Color(0xFF2E1B0E);
  static const Color inkName = Color(0xFF2E1F14);
  static const Color inkScore = Color(0xFF3E2A1E);

  // Buttons
  static const Color buttonTop = Color(0xFF56391F);
  static const Color buttonBottom = Color(0xFF3E2A1E);
  static const Color buttonText = Color(0xFFF4E9D2);

  /// Page background — cream parchment with a soft top highlight.
  static const Gradient pageBackground = RadialGradient(
    center: Alignment(0, -1.1),
    radius: 1.1,
    colors: [Color(0xFFFBF6EC), surface],
    stops: [0.0, 0.6],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cardTop, cardBottom],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [buttonTop, buttonBottom],
  );
}
