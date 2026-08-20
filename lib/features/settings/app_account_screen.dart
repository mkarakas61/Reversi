import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/legal/legal_links.dart';
import '../../core/profile/profile_scope.dart';
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
                            child: MenuButton(
                              label: strings.deleteAccount,
                              icon: Icons.person_remove_outlined,
                              onTap: () =>
                                  _confirmDelete(context, strings, lang),
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

  /// Deletion is irreversible, so it asks first and says exactly what goes.
  /// The request itself goes by e-mail from the account's own address — that
  /// address is how the request is verified.
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
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.deleteAccountSend),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final subject = Uri.encodeComponent('Reversi — ${strings.deleteAccount}');
    await _openUrl(
      context,
      'mailto:${LegalLinks.supportEmail}?subject=$subject',
    );
  }
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
