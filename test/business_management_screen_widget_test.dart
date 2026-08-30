import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_flow_arguments.dart';
import 'package:savetep/features/auth/screens/user_settings/business_management/business_management_screen.dart';
import 'package:savetep/features/auth/services/business_profile_service.dart';
import 'package:savetep/providers/business_profile_provider.dart';

void main() {
  testWidgets('setup Continue opens the category route without a type error', (
    WidgetTester tester,
  ) async {
    BusinessCategoryOnboardingArguments? receivedArguments;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessProfileRepositoryProvider.overrideWithValue(
            _FakeBusinessProfileRepository(),
          ),
        ],
        child: MaterialApp(
          home: const BusinessManagementScreen(isSetupFlow: true),
          routes: <String, WidgetBuilder>{
            '/business-categories-onboarding': (BuildContext context) {
              receivedArguments =
                  ModalRoute.of(context)!.settings.arguments
                      as BusinessCategoryOnboardingArguments;
              return const Scaffold(
                body: Center(child: Text('Business categories')),
              );
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder continueButton = find.byKey(
      const ValueKey<String>('businessManagement.saveButton'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Business categories'), findsOneWidget);
    expect(receivedArguments?.businessProfile.businessName, 'Sunny Nails');
    expect(tester.takeException(), isNull);
  });
}

class _FakeBusinessProfileRepository implements BusinessProfileRepository {
  static const BusinessProfile _profile = BusinessProfile(
    businessName: 'Sunny Nails',
    dba: 'Sunny Nails Spa',
    address: '123 Main Street',
    ein: '12-3456789',
    email: 'owner@example.com',
    phone: '714-555-0100',
  );

  @override
  Future<BusinessProfile> load() async => _profile;

  @override
  Future<BusinessProfile> save(BusinessProfile profile) async => profile;
}
