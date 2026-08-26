import 'package:flutter/widgets.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_models.dart';

typedef ConfirmSignUpRequest = Future<bool> Function(String email, String code);
typedef ResendSignUpCodeRequest =
    Future<AuthCodeDeliveryInfo?> Function(String email);

class ConfirmSignUpState {
  final bool isConfirming;
  final bool isResending;
  final String? errorMessage;

  const ConfirmSignUpState({
    required this.isConfirming,
    required this.isResending,
    required this.errorMessage,
  });

  const ConfirmSignUpState.initial()
    : isConfirming = false,
      isResending = false,
      errorMessage = null;

  ConfirmSignUpState copyWith({
    bool? isConfirming,
    bool? isResending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConfirmSignUpState(
      isConfirming: isConfirming ?? this.isConfirming,
      isResending: isResending ?? this.isResending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ConfirmSignUpController extends ChangeNotifier {
  final String email;
  final ConfirmSignUpRequest _confirmSignUp;
  final ResendSignUpCodeRequest _resendSignUpCode;

  final TextEditingController codeController = TextEditingController();

  ConfirmSignUpState _state = const ConfirmSignUpState.initial();
  bool _isDisposed = false;

  ConfirmSignUpController({
    required this.email,
    required ConfirmSignUpRequest confirmSignUp,
    required ResendSignUpCodeRequest resendSignUpCode,
  }) : _confirmSignUp = confirmSignUp,
       _resendSignUpCode = resendSignUpCode;

  ConfirmSignUpState get state => _state;

  Future<bool> confirm() async {
    _setState(_state.copyWith(isConfirming: true, clearError: true));
    try {
      return await _confirmSignUp(email, codeController.text.trim());
    } on Object catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
      return false;
    } finally {
      _setState(_state.copyWith(isConfirming: false));
    }
  }

  Future<String?> resendCode() async {
    _setState(_state.copyWith(isResending: true, clearError: true));
    try {
      final AuthCodeDeliveryInfo? delivery = await _resendSignUpCode(email);
      return delivery?.message ?? 'Code resent - check your email';
    } on Object catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
      return null;
    } finally {
      _setState(_state.copyWith(isResending: false));
    }
  }

  void _setState(ConfirmSignUpState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    codeController.dispose();
    super.dispose();
  }
}
