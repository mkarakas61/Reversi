import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../online_tokens.dart';

/// Full-screen game-over overlay: blurred scrim + cream result card with the
/// two theme discs, a Marcellus title and score, and an "Ana Menü" button.
class OnlineResultOverlay extends StatelessWidget {
  const OnlineResultOverlay({
    super.key,
    required this.title,
    required this.blackScore,
    required this.whiteScore,
    required this.onMenu,
    required this.board,
  });

  final String title;
  final int blackScore;
  final int whiteScore;
  final VoidCallback onMenu;
  final BoardTheme board;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: OnlineTokens.overlayScrim,
          padding: const EdgeInsets.all(30),
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
            ),
            child: _card(),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [OnlineTokens.overlayTop, OnlineTokens.overlayBottom],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OnlineTokens.overlayBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73281A0E), // rgba(40,26,14,.45)
            offset: Offset(0, 20),
            blurRadius: 48,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _disc(OnlineTokens.discFor(board, isDark: true)),
              const SizedBox(width: 13),
              _disc(OnlineTokens.discFor(board, isDark: false)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Marcellus',
              fontSize: 28,
              color: OnlineTokens.inkScore,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$blackScore – $whiteScore',
            style: const TextStyle(
              fontFamily: 'Marcellus',
              fontSize: 42,
              color: OnlineTokens.resultScore,
            ),
          ),
          const SizedBox(height: 22),
          _menuButton(),
        ],
      ),
    );
  }

  Widget _disc(String asset) => SizedBox(
        width: 52,
        height: 52,
        child: Image.asset(asset, fit: BoxFit.contain),
      );

  Widget _menuButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onMenu,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [OnlineTokens.buttonTop, OnlineTokens.buttonBottom],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OnlineTokens.overlayBorder, width: 1.5),
          ),
          child: const Text(
            'Ana Menü',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Marcellus',
              fontSize: 18,
              color: OnlineTokens.buttonText,
            ),
          ),
        ),
      ),
    );
  }
}
