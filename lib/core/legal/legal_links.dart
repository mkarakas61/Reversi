/// Where the published legal pages and the support address live (REV-91).
///
/// Play requires the privacy policy to be reachable both from the Play listing
/// and from inside the app, and requires a web page where a user can request
/// account deletion. Both are served from the project's GitHub Pages site, so
/// the text can be corrected with a commit instead of an app release.
///
/// The pages exist in Turkish and English; the app opens whichever matches the
/// language the player is reading the app in, falling back to English.
class LegalLinks {
  const LegalLinks._();

  static const String _base = 'https://mkarakas61.github.io/Reversi';

  /// Public support address. Also the channel for data requests (access,
  /// correction, deletion) named in the privacy policy.
  static const String supportEmail = 'reversi.destek@gmail.com';

  /// The published date of the privacy policy the player is agreeing to.
  /// Stamped onto every consent record (REV-117) so consent given under this
  /// text can be told apart from consent given under a later one. Bump it in
  /// the same commit that changes the policy pages, never on its own.
  static const String policyVersion = '2026-08-20';

  static String privacy(String languageCode) =>
      languageCode == 'tr' ? '$_base/gizlilik.html' : '$_base/privacy.html';

  static String terms(String languageCode) =>
      languageCode == 'tr' ? '$_base/kosullar.html' : '$_base/terms.html';

  static String deleteAccount(String languageCode) => languageCode == 'tr'
      ? '$_base/hesap-silme.html'
      : '$_base/delete-account.html';
}
