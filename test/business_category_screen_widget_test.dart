import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/features/auth/screens/login_screen/onboarding/business_category/business_category_screen.dart';
import 'package:savetep/features/auth/screens/login_screen/onboarding/business_category/controllers/business_category_controller.dart';
import 'package:savetep/features/auth/screens/login_screen/onboarding/business_category/repositories/business_category_onboarding_repository.dart';

void main() {
  testWidgets('moves a category between unchecked and checked columns', (
    WidgetTester tester,
  ) async {
    final BusinessCategoryController controller = BusinessCategoryController(
      businessProfile: const BusinessProfile(businessName: 'Sunny Nails'),
      repository: _FakeOnboardingRepository(),
    );
    addTearDown(controller.dispose);

    await _pumpScreen(tester, controller);

    expect(find.text('Unchecked'), findsOneWidget);
    expect(find.text('Checked'), findsOneWidget);
    expect(find.text('FIXED EXPENSE'), findsNWidgets(2));
    expect(
      find.byKey(
        ValueKey<String>('category.unchecked.${ExpenseCategory.rents.id}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('category.checked.${ExpenseCategory.rents.id}'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        ValueKey<String>('category.unchecked.${ExpenseCategory.rents.id}'),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        ValueKey<String>('category.unchecked.${ExpenseCategory.rents.id}'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey<String>('category.checked.${ExpenseCategory.rents.id}'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        ValueKey<String>('category.checked.${ExpenseCategory.rents.id}'),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        ValueKey<String>('category.unchecked.${ExpenseCategory.rents.id}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('headers are not selectable and Continue saves selection', (
    WidgetTester tester,
  ) async {
    final _FakeOnboardingRepository repository = _FakeOnboardingRepository();
    final BusinessCategoryController controller = BusinessCategoryController(
      businessProfile: const BusinessProfile(businessName: 'Sunny Nails'),
      repository: repository,
    );
    addTearDown(controller.dispose);

    await _pumpScreen(tester, controller);

    expect(
      find.ancestor(
        of: find.text('FIXED EXPENSE').first,
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('VARIABLE EXPENSE').first,
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        ValueKey<String>('category.unchecked.${ExpenseCategory.rents.id}'),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('businessCategories.continue')),
    );
    await tester.pumpAndSettle();

    expect(repository.savedIds, <String>{ExpenseCategory.rents.id});
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  BusinessCategoryController controller,
) async {
  tester.view.physicalSize = const Size(390, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: BusinessCategoryScreen(
          businessProfile: const BusinessProfile(businessName: 'Sunny Nails'),
          controller: controller,
        ),
        routes: <String, WidgetBuilder>{
          '/home': (_) => const Scaffold(body: Center(child: Text('Home'))),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeOnboardingRepository
    implements BusinessCategoryOnboardingRepository {
  Set<String>? savedIds;

  @override
  Future<Set<String>?> loadSelectedCategoryIds() async => null;

  @override
  Future<void> completeOnboarding({
    required BusinessProfile businessProfile,
    required Set<String> selectedCategoryIds,
  }) async {
    savedIds = Set<String>.of(selectedCategoryIds);
  }
}
