import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/services/guest_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('generates a Misafir-XXXX name', () async {
    final name = await GuestIdentityService.instance.displayName();
    expect(name, matches(RegExp(r'^Misafir-\d{4}$')));
  });

  test('persists the same name across calls', () async {
    final first = await GuestIdentityService.instance.displayName();
    final second = await GuestIdentityService.instance.displayName();
    expect(second, first);
  });
}
