import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/legal/legal_links.dart';
import 'package:reversi/core/services/consent_service.dart';

/// Who gets asked for e-mail consent, and who never does (REV-117).
void main() {
  test('a signed-in player who has never answered is asked', () {
    expect(
      shouldAskConsent(signedIn: true, isGuest: false, currentAnswer: null),
      isTrue,
    );
  });

  test('an answer — either way — stops the asking', () {
    expect(
      shouldAskConsent(signedIn: true, isGuest: false, currentAnswer: true),
      isFalse,
    );
    expect(
      shouldAskConsent(signedIn: true, isGuest: false, currentAnswer: false),
      isFalse,
      reason: 'a recorded "no" must not be asked again every launch',
    );
  });

  test('guests are never asked: no address, no server record', () {
    expect(
      shouldAskConsent(signedIn: true, isGuest: true, currentAnswer: null),
      isFalse,
    );
  });

  test('a signed-out player is never asked', () {
    expect(
      shouldAskConsent(signedIn: false, isGuest: false, currentAnswer: null),
      isFalse,
    );
  });

  test('consent records carry a policy version to stamp them with', () {
    expect(LegalLinks.policyVersion, isNotEmpty);
    expect(ConsentService.marketingEmail, 'marketingEmail');
  });
}
