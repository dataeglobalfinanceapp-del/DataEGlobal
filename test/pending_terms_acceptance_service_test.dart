import 'package:flutter_test/flutter_test.dart';
import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/services/pending_terms_acceptance_service.dart';

void main() {
  final values = <String, String>{};

  setUp(() {
    values.clear();
    LocalStore.setOverridesForTesting(
      read: (String key) async => values[key],
      write: (String key, String value) async => values[key] = value,
    );
  });

  tearDown(LocalStore.resetOverridesForTesting);

  test('stages by normalized email and clears only after submission', () async {
    const service = PendingTermsAcceptanceService(
      identitySource: _FakeTermsIdentitySource('Owner@Example.com'),
    );

    await PendingTermsAcceptanceService.stage(
      email: ' owner@example.COM ',
      termsVersion: ' 2026-09-01 ',
    );

    expect(await service.loadForCurrentUser(), '2026-09-01');
    await service.markSubmittedForCurrentUser();
    expect(await service.loadForCurrentUser(), isNull);
  });

  test('rejects empty and oversized terms versions', () {
    expect(
      () => PendingTermsAcceptanceService.stage(
        email: 'owner@example.com',
        termsVersion: ' ',
      ),
      throwsArgumentError,
    );
    expect(
      () => PendingTermsAcceptanceService.stage(
        email: 'owner@example.com',
        termsVersion: 'x'.padRight(65, 'x'),
      ),
      throwsArgumentError,
    );
  });
}

class _FakeTermsIdentitySource implements TermsAcceptanceIdentitySource {
  final String email;

  const _FakeTermsIdentitySource(this.email);

  @override
  Future<String> loadEmail() async => email;
}
