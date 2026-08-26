import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/models/expense_category.dart';

import '../models/business_category_state.dart';
import '../repositories/business_category_onboarding_repository.dart';

typedef BusinessCategoryOnboardingCompleted = FutureOr<void> Function();

class BusinessCategoryController extends ChangeNotifier {
  final BusinessProfile businessProfile;
  final Set<String>? _initialSelectedCategoryIds;
  final BusinessCategoryOnboardingRepository _repository;
  final BusinessCategoryOnboardingCompleted? _onCompleted;

  BusinessCategoryState _state = BusinessCategoryState.initial();
  bool _isDisposed = false;
  bool _hasLoaded = false;

  BusinessCategoryController({
    required this.businessProfile,
    required BusinessCategoryOnboardingRepository repository,
    Set<String>? initialSelectedCategoryIds,
    BusinessCategoryOnboardingCompleted? onCompleted,
  }) : _repository = repository,
       _initialSelectedCategoryIds = initialSelectedCategoryIds,
       _onCompleted = onCompleted;

  BusinessCategoryState get state => _state;

  Set<String> get selectedCategoryIds =>
      Set<String>.unmodifiable(_state.selectedCategoryIds);

  List<ExpenseCategory> categoriesFor(
    ExpenseType expenseType, {
    required bool selected,
  }) {
    return List<ExpenseCategory>.unmodifiable(
      _state.availableCategories.where(
        (ExpenseCategory category) =>
            category.expenseType == expenseType &&
            _state.selectedCategoryIds.contains(category.id) == selected,
      ),
    );
  }

  Future<void> load() async {
    if (_hasLoaded) return;
    _hasLoaded = true;
    try {
      final Set<String> selectedIds =
          _initialSelectedCategoryIds ??
          await _repository.loadSelectedCategoryIds() ??
          const <String>{};
      final Set<String> validIds = ExpenseCategory.onboardingById.keys.toSet();
      _setState(
        _state.copyWith(
          isLoading: false,
          selectedCategoryIds: Set<String>.unmodifiable(
            selectedIds.where(validIds.contains),
          ),
          clearError: true,
        ),
      );
    } on Object catch (error) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load expense categories: $error',
        ),
      );
    }
  }

  void toggleCategory(String categoryId) {
    if (!ExpenseCategory.onboardingById.containsKey(categoryId)) return;
    final Set<String> nextIds = Set<String>.of(_state.selectedCategoryIds);
    if (!nextIds.add(categoryId)) {
      nextIds.remove(categoryId);
    }
    _setState(
      _state.copyWith(
        selectedCategoryIds: Set<String>.unmodifiable(nextIds),
        clearValidation: true,
        clearError: true,
      ),
    );
  }

  Future<bool> save() async {
    if (_state.isSaving) return false;
    if (_state.selectedCategoryIds.isEmpty) {
      _setState(
        _state.copyWith(
          validationMessage: 'Select at least one expense category.',
        ),
      );
      return false;
    }

    _setState(
      _state.copyWith(isSaving: true, clearError: true, clearValidation: true),
    );
    try {
      await _repository.completeOnboarding(
        businessProfile: businessProfile,
        selectedCategoryIds: _state.selectedCategoryIds,
      );
      await _onCompleted?.call();
      return true;
    } on Object catch (error) {
      _setState(
        _state.copyWith(
          errorMessage: 'Could not save expense categories: $error',
        ),
      );
      return false;
    } finally {
      _setState(_state.copyWith(isSaving: false));
    }
  }

  void _setState(BusinessCategoryState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
