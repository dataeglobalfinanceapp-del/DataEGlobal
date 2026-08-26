import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/models/expense_category.dart';

abstract interface class ExpenseCategoryRepository {
  Future<Set<String>?> loadSelectedCategoryIds();

  Future<List<ExpenseCategory>> loadActiveCategories();

  Future<void> saveSelectedCategoryIds(Set<String> selectedCategoryIds);
}

class ExpenseCategoryService implements ExpenseCategoryRepository {
  static const String _keyPrefix = 'active_expense_categories_';

  final ExpenseCategoryAccountSource _accountSource;

  const ExpenseCategoryService({
    ExpenseCategoryAccountSource accountSource =
        const AmplifyExpenseCategoryAccountSource(),
  }) : _accountSource = accountSource;

  @override
  Future<Set<String>?> loadSelectedCategoryIds() async {
    final String accountId = await _accountSource.loadAccountId();
    final String? encoded = await LocalStore.read(_keyFor(accountId));
    if (encoded == null || encoded.isEmpty) return null;

    final Object? decoded = jsonDecode(encoded);
    if (decoded is! Map<String, Object?>) return null;
    if (decoded['accountId'] != accountId) return null;

    final Object? rawIds = decoded['selectedExpenseCategoryIds'];
    if (rawIds is! List<Object?>) return null;
    final Set<String> validIds = ExpenseCategory.onboardingById.keys.toSet();
    return Set<String>.unmodifiable(
      rawIds.whereType<String>().where(validIds.contains),
    );
  }

  @override
  Future<List<ExpenseCategory>> loadActiveCategories() async {
    final Set<String>? selectedIds = await loadSelectedCategoryIds();
    if (selectedIds == null) {
      return ExpenseCategory.values;
    }

    return List<ExpenseCategory>.unmodifiable(
      ExpenseCategory.onboardingCategories.where(
        (ExpenseCategory category) => selectedIds.contains(category.id),
      ),
    );
  }

  @override
  Future<void> saveSelectedCategoryIds(Set<String> selectedCategoryIds) async {
    if (selectedCategoryIds.isEmpty) {
      throw const FormatException('Select at least one expense category.');
    }

    final Set<String> validIds = ExpenseCategory.onboardingById.keys.toSet();
    if (!validIds.containsAll(selectedCategoryIds)) {
      throw const FormatException('Unknown expense category selection.');
    }

    final String accountId = await _accountSource.loadAccountId();
    final List<String> orderedIds = ExpenseCategory.onboardingCategories
        .where(
          (ExpenseCategory category) =>
              selectedCategoryIds.contains(category.id),
        )
        .map((ExpenseCategory category) => category.id)
        .toList(growable: false);
    await LocalStore.write(
      _keyFor(accountId),
      jsonEncode(<String, Object?>{
        'accountId': accountId,
        'selectedExpenseCategoryIds': orderedIds,
      }),
    );
  }

  static String _keyFor(String accountId) {
    final String encodedAccount = base64Url.encode(utf8.encode(accountId));
    return '$_keyPrefix$encodedAccount';
  }
}

abstract interface class ExpenseCategoryAccountSource {
  Future<String> loadAccountId();
}

class AmplifyExpenseCategoryAccountSource
    implements ExpenseCategoryAccountSource {
  const AmplifyExpenseCategoryAccountSource();

  @override
  Future<String> loadAccountId() async {
    final AuthUser user = await Amplify.Auth.getCurrentUser();
    return user.userId;
  }
}
