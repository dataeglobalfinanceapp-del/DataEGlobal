import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/services/business_profile_service.dart';
import 'package:savetep/features/auth/services/expense_category_service.dart';

abstract interface class BusinessCategoryOnboardingRepository {
  Future<Set<String>?> loadSelectedCategoryIds();

  Future<void> completeOnboarding({
    required BusinessProfile businessProfile,
    required Set<String> selectedCategoryIds,
  });
}

class ServiceBusinessCategoryOnboardingRepository
    implements BusinessCategoryOnboardingRepository {
  final ExpenseCategoryRepository _expenseCategoryRepository;
  final BusinessProfileRepository _businessProfileRepository;

  const ServiceBusinessCategoryOnboardingRepository({
    required ExpenseCategoryRepository expenseCategoryRepository,
    required BusinessProfileRepository businessProfileRepository,
  }) : _expenseCategoryRepository = expenseCategoryRepository,
       _businessProfileRepository = businessProfileRepository;

  @override
  Future<Set<String>?> loadSelectedCategoryIds() {
    return _expenseCategoryRepository.loadSelectedCategoryIds();
  }

  @override
  Future<void> completeOnboarding({
    required BusinessProfile businessProfile,
    required Set<String> selectedCategoryIds,
  }) async {
    await _expenseCategoryRepository.saveSelectedCategoryIds(
      selectedCategoryIds,
    );
    await _businessProfileRepository.save(businessProfile);
  }
}
