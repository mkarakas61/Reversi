import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/profile/profile_scope.dart';
import '../../core/services/consent_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/game_colors.dart';

/// The one-time ask for permission to e-mail the player about new games
/// (REV-117).
///
/// Shown once per account, after the player is signed in, and never to a
/// guest. Both answers are recorded — "no" is an answer, and storing it is
/// what keeps the sheet from asking again on every launch.
///
/// It is a sheet on top of the menu rather than a step in the sign-in flow so
/// that players who signed in on an earlier build are asked too; a checkbox on
/// the sign-in screen would silently skip every existing account.
class MarketingConsentPrompt extends StatelessWidget {
  const MarketingConsentPrompt._();

  /// Asks once, if this account has never answered. Safe to call on every
  /// launch: it returns immediately for guests, for signed-out players and for
  /// anyone who already answered.
  static Future<void> showIfNeeded(BuildContext context) async {
    final profile = ProfileScope.of(context).profile;
    if (profile == null) return;

    final answer = await ConsentService.instance
        .current(profile.uid, ConsentService.marketingEmail);
    if (!shouldAskConsent(
      signedIn: true,
      isGuest: profile.isGuest,
      currentAnswer: answer,
    )) {
      return;
    }
    if (!context.mounted) return;

    final granted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MarketingConsentPrompt._(),
    );
    // Dismissed by tapping outside: no answer given, so nothing is recorded
    // and the sheet may ask again next launch. Only a real tap is consent.
    if (granted == null) return;

    await ConsentService.instance.record(
      uid: profile.uid,
      type: ConsentService.marketingEmail,
      granted: granted,
      source: 'prompt',
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_unread_outlined,
                size: 40, color: GameColors.accent),
            const SizedBox(height: 14),
            Text(
              strings.marketingConsentTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: GameColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.marketingConsentBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.35,
                color: GameColors.inkSoft,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                SoundService.instance.playSfx(Sfx.button);
                Navigator.of(context).pop(true);
              },
              child: Text(strings.marketingConsentAccept),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                SoundService.instance.playSfx(Sfx.button);
                Navigator.of(context).pop(false);
              },
              child: Text(strings.marketingConsentDecline),
            ),
          ],
        ),
      ),
    );
  }
}
