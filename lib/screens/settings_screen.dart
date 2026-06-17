import 'package:flutter/material.dart';

import '../game/app_settings.dart';
import '../game/reversi_game.dart';
import '../l10n/app_strings.dart';
import '../services/sound_service.dart';
import '../theme/game_theme.dart';

/// Settings sheet: language, board colour and coin colours. Changes apply live
/// (via [SettingsScope]) and are persisted immediately.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final controller = SettingsScope.of(context);
    final settings = controller.settings;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: GameColors.creamTop,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: creamShellGradient),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: bannerGradient),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    title: strings.settings,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        _Section(
                          title: strings.language,
                          child: _LanguageRow(
                            current: lang,
                            onSelect: (code) =>
                                controller.setLocale(Locale(code)),
                          ),
                        ),
                        _Section(
                          title: strings.boardColor,
                          child: _BoardGrid(
                            selected: settings.board,
                            onSelect: controller.setBoard,
                          ),
                        ),
                        _Section(
                          title: strings.coinColor,
                          child: Column(
                            children: [
                              _CoinRow(
                                label: strings.yourCoin,
                                selected: settings.yourCoin,
                                disabled: settings.opponentCoin,
                                onSelect: controller.setYourCoin,
                              ),
                              const SizedBox(height: 14),
                              _CoinRow(
                                label: strings.opponentCoin,
                                selected: settings.opponentCoin,
                                disabled: settings.yourCoin,
                                onSelect: controller.setOpponentCoin,
                              ),
                            ],
                          ),
                        ),
                        _Section(
                          title: strings.sound,
                          child: Column(
                            children: [
                              _ToggleRow(
                                label: strings.soundEffects,
                                value: settings.soundEnabled,
                                onChanged: controller.setSoundEnabled,
                              ),
                              const SizedBox(height: 6),
                              _ToggleRow(
                                label: strings.music,
                                value: settings.musicEnabled,
                                onChanged: controller.setMusicEnabled,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(0, size.height * 0.82)
      ..close();
  }

  @override
  bool shouldReclip(_HeaderClipper old) => false;
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 12),
          _RoundButton(icon: Icons.chevron_left, onTap: onBack),
          Expanded(
            child: Center(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 2.2,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0x1F000000), offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 54), // balances the back button
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), offset: Offset(0, 3)),
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            SoundService.instance.playSfx(Sfx.button);
            onTap();
          },
          child: SizedBox(
            width: 42,
            height: 38,
            child: Icon(icon, color: GameColors.onAccent, size: 24),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, 6)),
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: GameColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget seg(String code, String label) {
      final active = current == code;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? GameColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: active ? Colors.white : GameColors.inkSoft,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          seg('tr', 'Türkçe'),
          const SizedBox(width: 4),
          seg('en', 'English'),
        ],
      ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.selected, required this.onSelect});

  final BoardTheme selected;
  final ValueChanged<BoardTheme> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final theme in BoardTheme.values)
          _BoardTile(
            theme: theme,
            label: strings.boardThemeLabel(theme),
            active: theme == selected,
            onTap: () => onSelect(theme),
          ),
      ],
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({
    required this.theme,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final BoardTheme theme;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? GameColors.accent : Colors.transparent,
                width: 3,
              ),
            ),
            child: _BoardPreview(theme: theme),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 88,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: active ? GameColors.onAccent : GameColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniature of the board slab: frame border, felt surface and a faint grid.
class _BoardPreview extends StatelessWidget {
  const _BoardPreview({required this.theme});

  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    final palette = boardPalettes[theme];

    final BoxDecoration frame = palette == null
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            image: const DecorationImage(
              image: AssetImage('assets/wood/wood-frame.png'),
              fit: BoxFit.cover,
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: palette.frameGradient,
          );

    final BoxDecoration surface = palette == null
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            image: const DecorationImage(
              image: AssetImage('assets/wood/wood-surface.png'),
              fit: BoxFit.cover,
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: palette.surfaceGradient,
          );

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: frame,
      child: DecoratedBox(
        decoration: surface,
        child: SizedBox.expand(
          child: CustomPaint(painter: _MiniGridPainter(palette: palette)),
        ),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  _MiniGridPainter({required this.palette});

  final BoardPalette? palette;

  @override
  void paint(Canvas canvas, Size size) {
    final n = ReversiGame.size;
    final cell = size.width / n;
    final paint = Paint()
      ..color = palette == null
          ? GameColors.gridLine
          : palette!.line.withValues(alpha: 0.55)
      ..strokeWidth = 0.6;
    for (var i = 1; i < n; i++) {
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), paint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), paint);
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter old) => old.palette != palette;
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: GameColors.inkSoft,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: GameColors.accent,
        ),
      ],
    );
  }
}

class _CoinRow extends StatelessWidget {
  const _CoinRow({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onSelect,
  });

  final String label;
  final CoinColor selected;

  /// Colour in use by the other side — shown dimmed and not selectable so the
  /// two coins always stay distinct.
  final CoinColor disabled;
  final ValueChanged<CoinColor> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: GameColors.inkSoft,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final color in CoinColor.values)
                _CoinSwatch(
                  color: color,
                  active: color == selected,
                  disabled: color == disabled,
                  onTap: () => onSelect(color),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoinSwatch extends StatelessWidget {
  const _CoinSwatch({
    required this.color,
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  final CoinColor color;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = coinPalettes[color]!;
    final coin = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.24, -0.36),
          radius: 0.95,
          colors: [palette.faceTop, palette.faceMid, palette.faceBottom],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );

    return Opacity(
      opacity: disabled ? 0.28 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? GameColors.accent : Colors.transparent,
              width: 3,
            ),
          ),
          child: coin,
        ),
      ),
    );
  }
}
