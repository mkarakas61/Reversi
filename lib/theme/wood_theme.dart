import 'package:flutter/material.dart';

/// Walnut / maple wooden design system, ported pixel-for-pixel from the
/// Claude Design HTML/CSS handoff (Sidre design system).
///
/// Every constant here maps to a concrete value taken from the design
/// prototypes (`*.dc.html`). Screens compose these tokens and the shared
/// widgets below so the look stays consistent across the app.
class Wood {
  Wood._();

  // ── Surfaces / backgrounds ────────────────────────────────────────────
  /// Light cream "device" background (#EFE5D5).
  static const cream = Color(0xFFEFE5D5);

  /// Stone beige page backdrop behind the device (#B7AB97).
  static const stone = Color(0xFFB7AB97);

  /// Card gradient top / bottom (#F5EAD4 → #EBDBBE).
  static const cardTop = Color(0xFFF5EAD4);
  static const cardBottom = Color(0xFFEBDBBE);

  /// Secondary card (opponent / inset) (#EEE1C6 → #E0CFAE).
  static const card2Top = Color(0xFFEEE1C6);
  static const card2Bottom = Color(0xFFE0CFAE);

  /// Inset tile / muted surface (#EFE3CC).
  static const tile = Color(0xFFEFE3CC);

  // ── App bar (dark walnut) ─────────────────────────────────────────────
  static const barTop = Color(0xFF4A3220);
  static const barBottom = Color(0xFF38240F);

  /// Dark game/online background gradient (160deg).
  static const darkBgTop = Color(0xFF4A3220);
  static const darkBgMid = Color(0xFF3A2410);
  static const darkBgBottom = Color(0xFF2C1B0D);

  // ── Dark wood buttons ─────────────────────────────────────────────────
  static const btnDarkTop = Color(0xFF56391F);
  static const btnDarkBottom = Color(0xFF3E2A1E);

  /// Gold button (tertiary / "Online Oyna").
  static const btnGoldTop = Color(0xFFC9A05A);
  static const btnGoldBottom = Color(0xFFA87B33);
  static const btnGoldBorder = Color(0xFF8A5E22);

  // ── Accents ───────────────────────────────────────────────────────────
  /// Primary warm accent (active states, sliders, switches) (#9A6B2F).
  static const accent = Color(0xFF9A6B2F);

  /// Gold leaf used for borders / dividers (#B8860B).
  static const gold = Color(0xFFB8860B);

  /// Soft gold border (cards/modals) (#C9A66B).
  static const goldSoft = Color(0xFFC9A66B);

  /// Warm gold (chart slices / accents) (#D8B36A).
  static const warmGold = Color(0xFFD8B36A);

  /// Destructive (logout / reset) (#A8442A) + its 3D shadow (#7E3320).
  static const danger = Color(0xFFA8442A);
  static const dangerShadow = Color(0xFF7E3320);

  // ── Text ──────────────────────────────────────────────────────────────
  static const ink = Color(0xFF3E2A1E); // dark brown headings
  static const inkDeep = Color(0xFF2E1B0E); // deepest brown (REVERSI title)
  static const inkSoft = Color(0xFF6B5235); // secondary brown text
  static const inkSoft2 = Color(0xFF8A6A45); // muted captions
  static const cream2 = Color(0xFFF4E9D2); // light text on dark
  static const creamDim = Color(0xFFECD9BC); // dimmer light text

  // ── Disc asset paths ──────────────────────────────────────────────────
  static const discWalnut = 'assets/wood/disc-walnut.png';
  static const discMaple = 'assets/wood/disc-maple.png';
  static const boardCrop = 'assets/wood/board-crop.png';
  static const chessBoard = 'assets/wood/chess-board.png';
}

/// Typography helpers — Marcellus for headings, Lora for body.
class WoodText {
  WoodText._();

  /// Marcellus heading. [size]/[spacing]/[color] per design.
  static TextStyle heading(
    double size, {
    Color color = Wood.ink,
    double spacing = 0,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: 'Marcellus',
        fontSize: size,
        letterSpacing: spacing,
        color: color,
        fontWeight: weight,
        height: 1.05,
      );

  /// Lora body text.
  static TextStyle body(
    double size, {
    Color color = Wood.inkSoft,
    FontWeight weight = FontWeight.w400,
    bool italic = false,
  }) =>
      TextStyle(
        fontFamily: 'Lora',
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );
}

/// Decorations & gradients reused across screens.
class WoodDeco {
  WoodDeco._();

  /// Light cream page background (device shell) with the soft top light wash.
  static const Gradient pageWash = RadialGradient(
    center: Alignment(0.0, -1.16), // 50% -8%
    radius: 1.25,
    colors: [Color(0xCCFFFAF0), Color(0x00EFE5D5)],
    stops: [0.0, 0.62],
  );

  /// Dark walnut background for game / matchmaking screens (160deg).
  static const Gradient darkBackground = LinearGradient(
    begin: Alignment(-0.5, -1.0),
    end: Alignment(0.5, 1.0),
    colors: [Wood.darkBgTop, Wood.darkBgMid, Wood.darkBgBottom],
    stops: [0.0, 0.55, 1.0],
  );

  static const Gradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Wood.cardTop, Wood.cardBottom],
  );

  static const Gradient card2Gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Wood.card2Top, Wood.card2Bottom],
  );

  static const Gradient barGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Wood.barTop, Wood.barBottom],
  );

  static const Gradient btnDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Wood.btnDarkTop, Wood.btnDarkBottom],
  );

  static const Gradient btnGoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Wood.btnGoldTop, Wood.btnGoldBottom],
  );

  /// Standard cream card: gradient fill, 20px radius, soft shadow + hairline.
  static BoxDecoration card({double radius = 20}) => BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x2E7A5634)), // rgba(122,86,52,.18)
        boxShadow: const [
          BoxShadow(
            color: Color(0x213E2A1E), // rgba(62,42,30,.13)
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      );
}

/// Shared dark-walnut top bar (height 56 by default, 60 for some screens).
class WoodAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WoodAppBar({
    super.key,
    required this.title,
    this.height = 56,
    this.spacing = 2.2,
    this.onBack,
    this.actions = const [],
    this.titleColor = Colors.white,
  });

  final String title;
  final double height;
  final double spacing;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Color titleColor;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final back = onBack ?? () => Navigator.of(context).maybePop();
    return Container(
      height: height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        gradient: WoodDeco.barGradient,
        border: Border(bottom: BorderSide(color: Wood.gold, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D281A0E), // rgba(40,26,14,.3)
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          _BarIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: back,
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: WoodText.heading(22, color: titleColor, spacing: spacing),
              ),
            ),
          ),
          ...actions,
          SizedBox(width: actions.isEmpty ? 52 : 10),
        ],
      ),
    );
  }
}

/// Translucent cream icon button used inside the app bar (40–42px, radius 11).
class _BarIconButton extends StatelessWidget {
  const _BarIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0x29ECD9BB), // rgba(236,217,187,.16)
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: Wood.creamDim, size: 18),
      ),
    );
  }
}

/// App-bar action icon button (square, translucent cream).
class WoodBarAction extends StatelessWidget {
  const WoodBarAction({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0x29ECD9BB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Wood.creamDim, size: 19),
        ),
      ),
    );
  }
}

/// 3D pressable wooden button (dark / light / gold variants) with a hard
/// bottom shadow that collapses on press — matches the `0 3px 0` CSS look.
class WoodButton extends StatefulWidget {
  const WoodButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = WoodButtonVariant.dark,
    this.width,
    this.height = 56,
    this.fontSize = 18,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final WoodButtonVariant variant;
  final double? width;
  final double height;
  final double fontSize;
  final IconData? icon;

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

enum WoodButtonVariant { dark, light, gold, danger }

class _WoodButtonState extends State<WoodButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    late final Gradient gradient;
    late final Color textColor;
    late final Color borderColor;
    late final Color shadowColor;
    switch (widget.variant) {
      case WoodButtonVariant.dark:
        gradient = WoodDeco.btnDarkGradient;
        textColor = Wood.cream2;
        borderColor = Wood.goldSoft;
        shadowColor = const Color(0x4D281A0E);
        break;
      case WoodButtonVariant.light:
        gradient = WoodDeco.cardGradient;
        textColor = Wood.ink;
        borderColor = const Color(0x667A5634); // rgba(122,86,52,.40)
        shadowColor = const Color(0x1A3E2A1E);
        break;
      case WoodButtonVariant.gold:
        gradient = WoodDeco.btnGoldGradient;
        textColor = const Color(0xFF3E2A12);
        borderColor = Wood.btnGoldBorder;
        shadowColor = const Color(0x473C280E);
        break;
      case WoodButtonVariant.danger:
        gradient = const LinearGradient(colors: [Wood.danger, Wood.danger]);
        textColor = Colors.white;
        borderColor = Wood.danger;
        shadowColor = Wood.dangerShadow;
        break;
    }

    final double drop = widget.variant == WoodButtonVariant.danger ? 5 : 3;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, _down ? drop : 0, 0),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, _down ? 0 : drop),
            ),
          ],
        ),
        child: Center(
          // Shrink the label to fit a fixed-width button instead of
          // overflowing when the text is wider than the button.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: WoodText.heading(
                    widget.fontSize,
                    color: textColor,
                    spacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
