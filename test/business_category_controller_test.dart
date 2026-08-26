import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/features/auth/screens/login_screen/onboarding/business_category/controllers/business_category_controller.dart';
import 'package:savetep/features/auth/screens/login_screen/onboarding/business_category/repositories/business_category_onboarding_repository.dart';
import 'package:savetep/features/auth/services/expense_category_service.dart';

void main() {
  group('business category catalog', () {
    test(
      'every onboarding category has a unique stable ID and display name',
      () {
        final List<ExpenseCategory> categories =
            ExpenseCategory.onboardingCategories;

        expect(categories, hasLength(69));
        expect(
          categories.map((ExpenseCategory category) => category.id).toSet(),
          hasLength(categories.length),
        );
        expect(
          categories
              .map((ExpenseCategory category) => category.name.toLowerCase())
              .toSet(),
          hasLength(categories.length),
        );
        expect(
          categories.where(
            (ExpenseCategory category) =>
                category.expenseType == ExpenseType.fixed,
          ),
          hasLength(12),
        );
        expect(
          categories.where(
            (ExpenseCategory category) =>
                category.expenseType == ExpenseType.variable,
          ),
          hasLength(57),
        );
      },
    );
  });

  group('BusinessCategoryController', () {
    test('starts unchecked and moves categories in both directions', () async {
      final _FakeOnboardingRepository repository = _FakeOnboardingRepository();
      final BusinessCategoryController controller = BusinessCategoryController(
        businessProfile: const BusinessProfile(businessName: 'Sunny Nails'),
        repository: repository,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.selectedCategoryIds, isEmpty);
      expect(
        controller.categoriesFor(ExpenseType.fixed, selected: false),
        hasLength(12),
      );
      expect(
        controller.categoriesFor(ExpenseType.variable, selected: false),
        hasLength(57),
      );
      expect(
        controller.categoriesFor(ExpenseType.fixed, selected: true),
        isEmpty,
      );

      controller.toggleCategory(ExpenseCategory.rents.id);

      expect(controller.selectedCategoryIds, <String>{
        ExpenseCategory.rents.id,
      });
      expect(
        controller
            .categoriesFor(ExpenseType.fixed, selected: false)
            .map((ExpenseCategory category) => category.id),
        isNot(contains(ExpenseCategory.rents.id)),
      );
      expect(
        controller
            .categoriesFor(ExpenseType.fixed, selected: true)
            .map((ExpenseCategory category) => category.id),
        contains(ExpenseCategory.rents.id),
      );

      controller.toggleCategory(ExpenseCategory.rents.id);

      expect(controller.selectedCategoryIds, isEmpty);
      expect(
        controller
            .categoriesFor(ExpenseType.fixed, selected: false)
            .map((ExpenseCategory category) => category.id),
        contains(ExpenseCategory.rents.id),
      );
    });

    test('persists only selected IDs and completes business setup', () async {
      final _FakeOnboardingRepository repository = _FakeOnboardingRepository();
      const BusinessProfile profile = BusinessProfile(
        businessName: 'Sunny Nails',
      );
      final BusinessCategoryController controller = BusinessCategoryController(
        businessProfile: profile,
        repository: repository,
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller.toggleCategory(ExpenseCategory.rents.id);
      controller.toggleCategory(ExpenseCategory.travel.id);

      expect(await controller.save(), isTrue);
      expect(repository.savedProfile, same(profile));
      expect(repository.savedIds, <String>{
        ExpenseCategory.rents.id,
        ExpenseCategory.travel.id,
      });
      expect(
        repository.savedIds,
        isNot(contains(ExpenseCategory.accounting.id)),
      );
    });

    test('restores a category draft when returning to the step', () async {
      final BusinessCategoryController controller = BusinessCategoryController(
        businessProfile: const BusinessProfile(businessName: 'Sunny Nails'),
        repository: _FakeOnboardingRepository(),
        initialSelectedCategoryIds: <String>{ExpenseCategory.accounting.id},
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.selectedCategoryIds, <String>{
        ExpenseCategory.accounting.id,
      });
    });
  });

  group('ExpenseCategoryService', () {
    final Map<String, String> values = <String, String>{};

    setUp(() {
      values.clear();
      LocalStore.setOverridesForTesting(
        read: (String key) async => values[key],
        write: (String key, String value) async => values[key] = value,
      );
    });

    tearDown(LocalStore.resetOverridesForTesting);

    test('associates active categories with the current account', () async {
      final _FakeCategoryAccountSource source = _FakeCategoryAccountSource(
        'business-a',
      );
      final ExpenseCategoryService service = ExpenseCategoryService(
        accountSource: source,
      );

      await service.saveSelectedCategoryIds(<String>{
        ExpenseCategory.rents.id,
        ExpenseCategory.travel.id,
      });
      source.accountId = 'business-b';
      await service.saveSelectedCategoryIds(<String>{
        ExpenseCategory.payrollWages.id,
      });

      expect(
        (await service.loadActiveCategories()).map(
          (ExpenseCategory category) => category.id,
        ),
        <String>[ExpenseCategory.payrollWages.id],
      );

      source.accountId = 'business-a';
      expect(
        (await service.loadActiveCategories()).map(
          (ExpenseCategory category) => category.id,
        ),
        <String>[ExpenseCategory.rents.id, ExpenseCategory.travel.id],
      );
      expect(values, hasLength(2));
      expect(
        values.values
            .map((String value) => jsonDecode(value)['accountId'])
            .toSet(),
        <String>{'business-a', 'business-b'},
      );
    });
  });
}

class _FakeOnboardingRepository
    implements BusinessCategoryOnboardingRepository {
  Set<String>? existingIds;
  Set<String>? savedIds;
  BusinessProfile? savedProfile;

  @override
  Future<Set<String>?> loadSelectedCategoryIds() async => existingIds;

  @override
  Future<void> completeOnboarding({
    required BusinessProfile businessProfile,
    required Set<String> selectedCategoryIds,
  }) async {
    savedProfile = businessProfile;
    savedIds = Set<String>.of(selectedCategoryIds);
  }
}

class _FakeCategoryAccountSource implements ExpenseCategoryAccountSource {
  String accountId;

  _FakeCategoryAccountSource(this.accountId);

  @override
  Future<String> loadAccountId() async => accountId;
}
