import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/models/account_profile.dart';
import 'package:savetep/features/auth/services/account_profile_service.dart';

void main() {
  final values = <String, String>{};

  setUp(() {
    values.clear();
    LocalStore.setOverridesForTesting(
      read: (key) async => values[key],
      write: (key, value) async => values[key] = value,
    );
  });

  tearDown(LocalStore.resetOverridesForTesting);

  test('display name prioritizes business, full name, then SaveTep', () {
    expect(
      const AccountProfile(
        fullName: 'Sunny Nguyen',
        businessName: 'Sunny Nails',
        businessNameOnboardingCompleted: true,
      ).displayName,
      'Sunny Nails',
    );
    expect(
      const AccountProfile(
        fullName: 'Sunny Nguyen',
        businessNameOnboardingCompleted: true,
      ).displayName,
      'Sunny Nguyen',
    );
    expect(
      const AccountProfile(businessNameOnboardingCompleted: true).displayName,
      'SaveTep',
    );
  });

  test('SaveTep is only a fallback and is not stored as a business name', () {
    final profile = const AccountProfile(
      fullName: 'Sunny Nguyen',
      businessNameOnboardingCompleted: false,
    ).withBusinessName(' SaveTep ');

    expect(profile.businessName, isNull);
    expect(profile.displayName, 'Sunny Nguyen');
    expect(profile.businessNameOnboardingCompleted, isTrue);
  });

  test(
    'new-account profile preserves name and a skipped onboarding choice',
    () async {
      await AccountProfileService.stageNewAccount(
        email: 'sunny@example.com',
        fullName: 'Sunny Nguyen',
      );
      await AccountProfileService.completePendingOnboarding(
        email: 'sunny@example.com',
        fullName: 'Sunny Nguyen',
      );

      final service = AccountProfileService(
        identitySource: _FakeIdentitySource(
          const AccountIdentity(
            userId: 'user-1',
            email: 'sunny@example.com',
            fullName: 'Sunny Nguyen',
          ),
        ),
      );
      final profile = await service.load();

      expect(profile.fullName, 'Sunny Nguyen');
      expect(profile.businessName, isNull);
      expect(profile.businessNameOnboardingCompleted, isTrue);
      expect(profile.displayName, 'Sunny Nguyen');
    },
  );

  test(
    'existing account without profile works without an onboarding loop',
    () async {
      final service = AccountProfileService(
        identitySource: _FakeIdentitySource(
          const AccountIdentity(
            userId: 'existing-user',
            email: 'existing@example.com',
          ),
        ),
      );

      final profile = await service.load();

      expect(profile.displayName, 'SaveTep');
      expect(profile.businessNameOnboardingCompleted, isTrue);
    },
  );
}

class _FakeIdentitySource implements AccountIdentitySource {
  final AccountIdentity identity;

  const _FakeIdentitySource(this.identity);

  @override
  Future<AccountIdentity> load() async => identity;
}
