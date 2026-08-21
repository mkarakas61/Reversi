import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/legal/legal_links.dart';
import '../../core/profile/profile_scope.dart';
import '../../core/services/account_service.dart';
import '../../core/services/consent_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/game_colors.dart'
    show GameColors, bannerGradient, creamShellGradient;
import '../../core/theme/wood_theme.dart';
import '../../shared/widgets/info_card.dart';
import '../menu/widgets/menu_button.dart';
import 'widgets/settings_header.dart';

/// Everything Play asks an app to expose about itself and the player's data
/// (REV-91): the privacy policy, the terms, the open-source licences, a support
/// address, the version, and a way to get the account deleted.
///
/// The policy and terms live on the web, not in the app: they have to be
/// reachable from the Play listing too, and a wording fix must not need a
/// release. The licence page is Flutter's own `showLicensePage`, which lists
/// every package actually linked into this build — hand-maintaining that list
/// would go stale on the next `pub add`.
class AppAccountScreen extends StatelessWidget {
  const AppAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wood = SettingsScope.of(context).settings.appTheme == AppThemeId.wood;
    final lang = Localizations.localeOf(context).languageCode;
    final signedIn = ProfileScope.of(context).profile != null;

    return Scaffold(
      backgroundColor: wood ? WoodTheme.surface : GameColors.creamTop,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: wood ? WoodTheme.pageBackground : creamShellGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: ClipPath(
                clipper: const HeaderClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: wood ? WoodTheme.buttonGradient : bannerGradient,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SettingsHeader(
                    title: strings.appAndAccount,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        InfoCard(
                          title: strings.legalSection,
                          child: Column(
                            children: [
                              MenuButton(
                                label: strings.privacyPolicy,
                                icon: Icons.privacy_tip_outlined,
                                onTap: () => _openUrl(
                                  context,
                                  LegalLinks.privacy(lang),
                                ),
                              ),
                              const SizedBox(height: 8),
                              MenuButton(
                                label: strings.termsOfUse,
                                icon: Icons.description_outlined,
                                onTap: () => _openUrl(
                                  context,
                                  LegalLinks.terms(lang),
                                ),
                              ),
                              const SizedBox(height: 8),
                              MenuButton(
                                label: strings.openSourceLicenses,
                                icon: Icons.article_outlined,
                                onTap: () => _openLicenses(context, strings),
                              ),
                            ],
                          ),
                        ),
                        InfoCard(
                          title: strings.supportSection,
                          child: MenuButton(
                            label: strings.supportContact,
                            subtitle: strings
                                .supportContactHint(LegalLinks.supportEmail),
                            icon: Icons.mail_outline_rounded,
                            onTap: () => _openUrl(
                              context,
                              _supportMailto(strings),
                            ),
                          ),
                        ),
                        // Deleting an account is only offered to someone who
                        // has one. A guest has no server-side record at all
                        // (REV-53/57), so there is nothing to delete.
                        if (signedIn)
                          InfoCard(
                            title: strings.accountSection,
                            child: Column(
                              children: [
                                // Consent is withdrawable at any time, so it
                                // sits with the account controls rather than
                                // being buried in a one-time prompt (REV-117).
                                const _MarketingConsentTile(),
                                const SizedBox(height: 12),
                                MenuButton(
                                  label: strings.deleteAccount,
                                  icon: Icons.person_remove_outlined,
                                  onTap: () =>
                                      _confirmDelete(context, strings, lang),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        const _VersionLine(),
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

  /// A support mail with the app version already in the subject — the first
  /// question on any bug report, and the one users are least able to answer.
  String _supportMailto(AppStrings strings) {
    final subject = Uri.encodeComponent('Reversi — ${strings.supportContact}');
    return 'mailto:${LegalLinks.supportEmail}?subject=$subject';
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    SoundService.instance.playSfx(Sfx.button);
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

  Future<void> _openLicenses(BuildContext context, AppStrings strings) async {
    SoundService.instance.playSfx(Sfx.button);
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: strings.appTitle,
      applicationVersion: '${info.version} (${info.buildNumber})',
      applicationLegalese: '© 2026 Mustafa Karakaş',
    );
  }

  /// Deletion is irreversible, so it asks first and says exactly what goes —
  /// including what does *not* go, since finished matches survive as the
  /// opponent's record. The delete itself runs server-side (REV-90); this
  /// screen only confirms, waits, and reports.
  Future<void> _confirmDelete(
    BuildContext context,
    AppStrings strings,
    String lang,
  ) async {
    SoundService.instance.playSfx(Sfx.button);
    final confirmed = await showDialog<bool>(
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
    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Modal while the server works: the account must not be tapped twice, and
    // the call ends with a sign-out that rebuilds this screen underneath.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeletingDialog(label: strings.deleteAccountWorking),
    );

    final ok = await AccountService.instance.deleteAccount();
    navigator.pop(); // the progress dialog

    messenger.showSnackBar(SnackBar(
      content: Text(
        ok ? strings.deleteAccountDone : strings.deleteAccountFailed,
      ),
    ));
    // Signed out now, so this screen's account section is gone: step back to
    // the menu rather than leave the player looking at a half-empty page.
    if (ok) navigator.maybePop();
  }
}

/// The e-mail consent switch (REV-117): the same answer the one-time prompt
/// records, reachable forever after. Loads the current value rather than
/// assuming one — a switch that shows "off" while the server says "on" would
/// be worse than no switch at all.
class _MarketingConsentTile extends StatefulWidget {
  const _MarketingConsentTile();

  @override
  State<_MarketingConsentTile> createState() => _MarketingConsentTileState();
}

class _MarketingConsentTileState extends State<_MarketingConsentTile> {
  bool? _granted;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_granted == null && !_busy) unawaited(_load());
  }

  Future<void> _load() async {
    final profile = ProfileScope.of(context).profile;
    if (profile == null) return;
    final value = await ConsentService.instance
        .current(profile.uid, ConsentService.marketingEmail);
    if (mounted) setState(() => _granted = value ?? false);
  }

  Future<void> _set(bool value) async {
    final profile = ProfileScope.of(context).profile;
    if (profile == null) return;
    final previous = _granted;
    setState(() {
      _granted = value;
      _busy = true;
    });
    final ok = await ConsentService.instance.record(
      uid: profile.uid,
      type: ConsentService.marketingEmail,
      granted: value,
      source: 'settings',
    );
    if (!mounted) return;
    // A failed write must not leave the switch claiming something the record
    // does not say.
    setState(() {
      _busy = false;
      if (!ok) _granted = previous;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: _granted ?? false,
      onChanged: _granted == null || _busy ? null : _set,
      title: Text(
        strings.marketingConsentToggle,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: GameColors.ink,
        ),
      ),
      subtitle: Text(
        strings.marketingConsentToggleHint,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          color: GameColors.inkSoft,
        ),
      ),
    );
  }
}

/// The blocking "deleting…" dialog. Deliberately without a cancel button:
/// once the server call is out there is nothing left to cancel.
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

/// Version and build number, read from the installed package rather than a
/// constant so it can never disagree with what the store shipped.
class _VersionLine extends StatelessWidget {
  const _VersionLine();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wood = isWoodTheme(context);
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final info = snap.data;
        final text = info == null
            ? ''
            : '${strings.version} ${info.version} (${info.buildNumber})';
        return Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: wood ? WoodTheme.goldText : GameColors.inkSoft,
            ),
          ),
        );
      },
    );
  }
}
