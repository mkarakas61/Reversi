import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/game_colors.dart';

/// Shown wherever a guest hits a feature that needs a signed-in account
/// (profile stats, progress charts, the leaderboard): explains that guest
/// progress isn't tracked and offers a straight path to sign in with Google.
class GuestUpsellCard extends StatefulWidget {
  const GuestUpsellCard({super.key});

  @override
  State<GuestUpsellCard> createState() => _GuestUpsellCardState();
}

class _GuestUpsellCardState extends State<GuestUpsellCard> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.signInError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 36, color: GameColors.accent),
          const SizedBox(height: 12),
          Text(
            strings.guestUpsellTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: GameColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.guestUpsellBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: GameColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: GameColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _busy ? null : _signIn,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                strings.continueWithGoogle,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
