import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/features/auth/services/expense_category_service.dart';
import 'package:savetep/services/liability_service.dart';

import '../models/profit_loss_models.dart';

abstract interface class ProfitLossRepository {
  Future<ProfitLossData> load();
}

class LiabilityProfitLossRepository implements ProfitLossRepository {
  final ExpenseCategoryRepository _expenseCategoryRepository;

  const LiabilityProfitLossRepository({
    ExpenseCategoryRepository expenseCategoryRepository =
        const ExpenseCategoryService(),
  }) : _expenseCategoryRepository = expenseCategoryRepository;

  @override
  Future<ProfitLossData> load() async {
    final Future<Set<String>?> selectedIdsFuture = _expenseCategoryRepository
        .loadSelectedCategoryIds();
    final Future<List<DepositRecord>> depositsFuture =
        LiabilityService.loadDeposits();
    final Future<List<ExpenseRecord>> expensesFuture =
        LiabilityService.loadExpenses();

    final Set<String> selectedIds = await selectedIdsFuture ?? const <String>{};
    final List<ExpenseCategory> selectedCategories = ExpenseCategory
        .onboardingCategories
        .where((ExpenseCategory category) => selectedIds.contains(category.id))
        .toList(growable: false);
    final List<DepositRecord> deposits = await depositsFuture;
    final List<ExpenseRecord> expenses = await expensesFuture;
    return ProfitLossData(
      deposits: deposits,
      expenses: expenses,
      selectedExpenseCategories: selectedCategories,
    );
  }
}
