import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/features/auth/services/expense_category_service.dart';

final expenseCategoryRepositoryProvider = Provider<ExpenseCategoryRepository>(
  (Ref ref) => const ExpenseCategoryService(),
);

final activeExpenseCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategory>>((Ref ref) {
      return ref
          .watch(expenseCategoryRepositoryProvider)
          .loadActiveCategories();
    });
