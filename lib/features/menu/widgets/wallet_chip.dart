import 'package:flutter/material.dart';

import '../../../core/profile/profile_scope.dart';
import '../../../core/services/sound_service.dart';
import '../../../shared/widgets/coin_amount.dart';
import '../../profile/profile_screen.dart';
import 'pill_button.dart';

/// Coin balance pill for the main menu, under the profile chip (REV-102).
///
/// Signed-in players only: guests earn nothing (REV-57) and a signed-out player
/// has no balance at all, so for both this renders nothing rather than a
/// misleading zero. A balance of 0 for a signed-in player IS shown — that is a
/// real balance, and hiding it would make the first coin look like a bug.
/// Tapping opens the profile, where the card says how coins are earned; once
/// the store lands (REV-69) this is its natural entry point.
/// Whether the menu shows a balance for [profile]. Signed out there is nothing
/// to show; a guest's balance is always 0 because guests earn nothing, and a
/// zero that can never move reads as a broken counter rather than a wallet.
bool showsWalletChip(Profile? profile) => profile != null && !profile.isGuest;

class WalletChip extends StatelessWidget {
  const WalletChip({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context).profile;
    if (!showsWalletChip(profile)) return const SizedBox.shrink();

    // The 8px gap belongs to the chip, not to the menu column: when there is no
    // balance to show the gap has to disappear with it.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PillButton(
        onTap: () {
          SoundService.instance.playSfx(Sfx.button);
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          );
        },
        child: CoinAmount(text: '${profile!.coins}', fontSize: 14),
      ),
    );
  }
}
