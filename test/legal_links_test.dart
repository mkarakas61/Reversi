import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';
import 'package:reversi/core/legal/legal_links.dart';

// REV-91. Play blocks a release whose privacy policy is unreachable, and a
// half-translated legal page is worse than none: a missing map entry throws at
// lookup, so these tests are what keep the screen from crashing in one
// language and lying in the other.
void main() {
  final tr = AppStrings(const Locale('tr'));
  final en = AppStrings(const Locale('en'));

  group('legal links', () {
    test('every link is an absolute https URL', () {
      for (final lang in ['tr', 'en']) {
        for (final url in [
          LegalLinks.privacy(lang),
          LegalLinks.terms(lang),
          LegalLinks.deleteAccount(lang),
        ]) {
          final uri = Uri.parse(url);
          expect(uri.scheme, 'https', reason: url);
          expect(uri.host, isNotEmpty, reason: url);
        }
      }
    });

    test('the three pages are three different pages', () {
      final urls = {
        LegalLinks.privacy('tr'),
        LegalLinks.terms('tr'),
        LegalLinks.deleteAccount('tr'),
      };
      expect(urls.length, 3);
    });

    test('a Turkish reader gets the Turkish page', () {
      expect(LegalLinks.privacy('tr'), isNot(LegalLinks.privacy('en')));
      expect(LegalLinks.terms('tr'), isNot(LegalLinks.terms('en')));
      expect(
        LegalLinks.deleteAccount('tr'),
        isNot(LegalLinks.deleteAccount('en')),
      );
    });

    test('an unsupported language falls back to English, not to nothing', () {
      expect(LegalLinks.privacy('de'), LegalLinks.privacy('en'));
    });

    test('the support address is a plausible e-mail', () {
      expect(LegalLinks.supportEmail, contains('@'));
      expect(LegalLinks.supportEmail, isNot(contains(' ')));
    });
  });

  group('wording', () {
    test('the screen is fully translated in both languages', () {
      for (final s in [tr, en]) {
        for (final text in [
          s.appAndAccount,
          s.appAccountHint,
          s.legalSection,
          s.supportSection,
          s.accountSection,
          s.privacyPolicy,
          s.termsOfUse,
          s.openSourceLicenses,
          s.supportContact,
          s.deleteAccount,
          s.deleteAccountTitle,
          s.deleteAccountBody,
          s.deleteAccountSend,
          s.deleteAccountDetails,
          s.version,
          s.linkFailed,
        ]) {
          expect(text, isNotEmpty, reason: s.locale.languageCode);
        }
      }
    });

    test('the support hint carries the real address, substituted', () {
      for (final s in [tr, en]) {
        final hint = s.supportContactHint(LegalLinks.supportEmail);
        expect(hint, contains(LegalLinks.supportEmail));
        expect(hint, isNot(contains('{')));
      }
    });

    test('deletion is described as permanent before it is offered', () {
      // The dialog is the last thing a player reads before mailing the
      // request; if it ever loses the irreversibility, this fails.
      expect(tr.deleteAccountBody, contains('geri alınamaz'));
      expect(en.deleteAccountBody, contains('cannot be undone'));
    });
  });
}
