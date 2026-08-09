import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/profile/profile_scope.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/game_colors.dart';
import '../../profile/profile_screen.dart';
import 'pill_button.dart';

/// Sign-in / profile pill for the main menu. Shows a "Sign in" button when
/// signed out and the player's avatar + first name when signed in.
class ProfileChip extends StatefulWidget {
  const ProfileChip({super.key});

  @override
  State<ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<ProfileChip> {
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

  void _openProfile() {
    SoundService.instance.playSfx(Sfx.button);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final profile = ProfileScope.of(context).profile;

    if (profile == null) {
      return PillButton(
        onTap: _signIn,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.login_rounded, size: 18),
            const SizedBox(width: 6),
            Text(strings.signIn),
          ],
        ),
      );
    }

    if (profile.isGuest) {
      return PillButton(
        onTap: _openProfile,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded, size: 18),
            const SizedBox(width: 6),
            Text(strings.guestLabel),
          ],
        ),
      );
    }

    final name = profile.displayName ?? '';
    final firstName = name.isEmpty ? strings.signIn : name.split(' ').first;
    return PillButton(
      onTap: _openProfile,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileAvatar(
            photoUrl: profile.photoUrl,
            radius: 11,
            ringColor: profile.online.rank.color,
          ),
          const SizedBox(width: 7),
          Text(firstName),
        ],
      ),
    );
  }
}

/// Circular profile photo, falling back to a person icon when there is no URL.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.radius,
    this.ringColor,
  });

  final String? photoUrl;
  final double radius;

  /// Rank identity colour drawn as a thin ring around the photo (REV-61 §6.3).
  /// At chip size (∅22) the frame art's crowns and wings turn to mush, so the
  /// rank shows up as its colour alone; null draws no ring at all.
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasUrl = url != null && url.isNotEmpty;
    final photo = CircleAvatar(
      radius: radius,
      backgroundColor: GameColors.onAccent.withValues(alpha: 0.12),
      backgroundImage: hasUrl ? NetworkImage(url) : null,
      child: hasUrl
          ? null
          : Icon(Icons.person_rounded, size: radius, color: GameColors.onAccent),
    );

    final ring = ringColor;
    if (ring == null) return photo;

    // The ring sits outside the photo, so the widget grows by the stroke rather
    // than eating into the face.
    return Container(
      padding: const EdgeInsets.all(_ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: _ringWidth),
      ),
      child: photo,
    );
  }

  static const double _ringWidth = 2;
}
