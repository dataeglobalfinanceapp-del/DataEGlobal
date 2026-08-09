import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/screens/login_screen/business_name_onboarding_screen.dart';
import 'package:savetep/features/auth/services/account_profile_service.dart';
import 'package:savetep/features/auth/widgets/business_name_prompt_dialog.dart';

void main() {
  final values = <String, String>{};

  tearDown(LocalStore.resetOverridesForTesting);

  testWidgets('post-signup onboarding can be skipped and preserves full name', (
    tester,
  ) async {
    LocalStore.setOverridesForTesting(
      read: (key) async => values[key],
      write: (key, value) async => values[key] = value,
    );

    await _pumpOnboarding(tester);
    expect(find.byType(BusinessNamePromptDialog), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);

    final profile = await AccountProfileService(
      identitySource: const _FakeIdentitySource(),
    ).load();
    expect(profile.fullName, 'Sunny Nguyen');
    expect(profile.businessName, isNull);
    expect(profile.businessNameOnboardingCompleted, isTrue);
  });

  testWidgets('onboarding save failure offers retry', (tester) async {
    var failNextWrite = true;
    LocalStore.setOverridesForTesting(
      read: (key) async => values[key],
      write: (key, value) async {
        if (failNextWrite) {
          failNextWrite = false;
          throw StateError('write failed');
        }
        values[key] = value;
      },
    );

    await _pumpOnboarding(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not save the account profile'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(BusinessNamePromptDialog), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}

Future<void> _pumpOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: const BusinessNameOnboardingScreen(
        email: 'sunny@example.com',
        fullName: 'Sunny Nguyen',
      ),
      routes: {
        '/login': (_) => const Scaffold(body: Center(child: Text('Login'))),
      },
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeIdentitySource implements AccountIdentitySource {
  const _FakeIdentitySource();

  @override
  Future<AccountIdentity> load() async => const AccountIdentity(
    userId: 'user-1',
    email: 'sunny@example.com',
    fullName: 'Sunny Nguyen',
  );
}
