import 'package:flutter/foundation.dart';

typedef CompletePendingOnboarding =
    Future<void> Function({
      required String email,
      required String fullName,
      String? businessName,
    });

class BusinessNameOnboardingState {
  final bool isSaving;
  final String? errorMessage;

  const BusinessNameOnboardingState({
    required this.isSaving,
    required this.errorMessage,
  });

  const BusinessNameOnboardingState.initial()
    : isSaving = false,
      errorMessage = null;

  BusinessNameOnboardingState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BusinessNameOnboardingState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class BusinessNameOnboardingController extends ChangeNotifier {
  final String email;
  final String fullName;
  final CompletePendingOnboarding _completePendingOnboarding;

  BusinessNameOnboardingState _state =
      const BusinessNameOnboardingState.initial();
  bool _isDisposed = false;

  BusinessNameOnboardingController({
    required this.email,
    required this.fullName,
    required CompletePendingOnboarding completePendingOnboarding,
  }) : _completePendingOnboarding = completePendingOnboarding;

  BusinessNameOnboardingState get state => _state;

  void beginPrompt() {
    if (_state.errorMessage == null) return;
    _setState(_state.copyWith(clearError: true));
  }

  Future<bool> complete(String? businessName) async {
    _setState(_state.copyWith(isSaving: true, clearError: true));
    try {
      await _completePendingOnboarding(
        email: email,
        fullName: fullName,
        businessName: businessName,
      );
      return true;
    } on Object catch (error) {
      _setState(
        _state.copyWith(
          errorMessage: 'Could not save the account profile: $error',
        ),
      );
      return false;
    } finally {
      _setState(_state.copyWith(isSaving: false));
    }
  }

  void _setState(BusinessNameOnboardingState nextState) {
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
