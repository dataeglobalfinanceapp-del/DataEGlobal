import 'package:savetep/features/auth/models/expense_category.dart';

class BusinessCategoryState {
  final bool isLoading;
  final bool isSaving;
  final List<ExpenseCategory> availableCategories;
  final Set<String> selectedCategoryIds;
  final String? errorMessage;
  final String? validationMessage;

  const BusinessCategoryState({
    required this.isLoading,
    required this.isSaving,
    required this.availableCategories,
    required this.selectedCategoryIds,
    required this.errorMessage,
    required this.validationMessage,
  });

  BusinessCategoryState.initial()
    : isLoading = true,
      isSaving = false,
      availableCategories = ExpenseCategory.onboardingCategories,
      selectedCategoryIds = const <String>{},
      errorMessage = null,
      validationMessage = null;

  BusinessCategoryState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<ExpenseCategory>? availableCategories,
    Set<String>? selectedCategoryIds,
    String? errorMessage,
    bool clearError = false,
    String? validationMessage,
    bool clearValidation = false,
  }) {
    return BusinessCategoryState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      availableCategories: availableCategories ?? this.availableCategories,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      validationMessage: clearValidation
          ? null
          : validationMessage ?? this.validationMessage,
    );
  }
}
