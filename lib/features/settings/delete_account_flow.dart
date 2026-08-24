import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/legal/legal_links.dart';
import '../../core/services/account_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/game_colors.dart' show GameColors;

/// Deleting an account, from the first tap to the sign-out — shared by App &
/// Account and by the profile screen (Mustafa, 2026-08-24).
///
/// It lives in one place because it is one decision. The same action offered in
/// two rooms with two different amounts of friction would mean the safer path
/// is whichever door the player happened to walk through.
///
/// **Two steps, and the second one waits.** The first dialog says what goes and
/// offers the page that spells it out. The second exists only to cost time: its
/// delete button is dead for [_holdSeconds] seconds, so the gesture that
/// confirms cannot be the continuation of the gesture that opened the dialog.
/// Nobody deletes their account by double-tapping.
///
/// The delete itself runs server-side (REV-90); this file only asks, waits and
/// reports.
const int _holdSeconds = 5;

/// Runs the whole flow. Returns true when the account was actually deleted.
Future<bool> confirmAndDeleteAccount(BuildContext context) async {
  final strings = AppStrings.of(context);
  final lang = Localizations.localeOf(context).languageCode;

  SoundService.instance.playSfx(Sfx.button);

  final wantsTo = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.deleteAccountTitle),
      content: Text(strings.deleteAccountBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(false);
            _openUrl(context, LegalLinks.deleteAccount(lang));
          },
          child: Text(strings.deleteAccountDetails),
        ),
        // Destructive colour on the one button that cannot be undone; it is
        // also not the dialog's default action.
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE0312B),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(strings.deleteAccountSend),
        ),
      ],
    ),
  );
  if (wantsTo != true || !context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _FinalConfirmDialog(),
  );
  if (confirmed != true || !context.mounted) return false;

  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // Modal while the server works: the account must not be tapped twice, and
  // the call ends with a sign-out that rebuilds the screen underneath.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DeletingDialog(label: strings.deleteAccountWorking),
  );

  final ok = await AccountService.instance.deleteAccount();
  navigator.pop(); // the progress dialog

  messenger.showSnackBar(SnackBar(
    content: Text(ok ? strings.deleteAccountDone : strings.deleteAccountFailed),
  ));
  return ok;
}

Future<void> _openUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final strings = AppStrings.of(context);
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!ok) {
    messenger.showSnackBar(SnackBar(content: Text(strings.linkFailed)));
  }
}

/// The second ask: the same warning, but the way out is the easy button and the
/// way through has to be waited for.
///
/// The countdown is shown on the button itself rather than as a spinner
/// somewhere else — a player who means it watches a number reach zero, and one
/// who tapped by accident has five seconds to notice what they are looking at.
class _FinalConfirmDialog extends StatefulWidget {
  const _FinalConfirmDialog();

  @override
  State<_FinalConfirmDialog> createState() => _FinalConfirmDialogState();
}

class _FinalConfirmDialogState extends State<_FinalConfirmDialog> {
  int _remaining = _holdSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ready = _remaining <= 0;

    return PopScope(
      // Back would be an unanswered question here; "Keep my account" is the
      // answer, and it is the button under the thumb.
      canPop: false,
      child: AlertDialog(
        title: Text(strings.deleteAccountFinalTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.deleteAccountFinalBody),
            const SizedBox(height: 12),
            Text(
              strings.deleteAccountFinalHint,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: GameColors.inkSoft,
              ),
            ),
          ],
        ),
        // One Column instead of two loose actions, stretched to a fixed width.
        //
        // Found on the phone, 2026-08-24: while counting down, the delete
        // label is longer ("Kalıcı olarak sil (4)"), so the dialog's action bar
        // wrapped it onto its own row — and the moment the countdown ended and
        // the label shrank, both buttons snapped back onto one line and moved.
        // A dialog whose whole purpose is to stop a mistaken tap must not
        // rearrange itself under a thumb that is already moving. Stacked at a
        // fixed width, nothing shifts when the label changes.
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.deleteAccountKeep),
              ),
              const SizedBox(height: 4),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE0312B),
                ),
                onPressed: ready ? () => Navigator.of(context).pop(true) : null,
                child: Text(
                  ready
                      ? strings.deleteAccountSend
                      : strings.deleteAccountCountdown(_remaining),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeletingDialog extends StatelessWidget {
  const _DeletingDialog({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      );
}
