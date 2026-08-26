import 'package:flutter/widgets.dart';

typedef SendResetCodeRequest = Future<void> Function(String email);

class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;

  const ForgotPasswordState({
    required this.isLoading,
    required this.errorMessage,
  });

  const ForgotPasswordState.initial() : isLoading = false, errorMessage = null;

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ForgotPasswordController extends ChangeNotifier {
  final SendResetCodeRequest _sendResetCode;

  final TextEditingController emailController = TextEditingController();

  ForgotPasswordState _state = const ForgotPasswordState.initial();
  bool _isDisposed = false;

  ForgotPasswordController({required SendResetCodeRequest sendResetCode})
    : _sendResetCode = sendResetCode;

  ForgotPasswordState get state => _state;

  Future<String?> sendCode() async {
    final String email = emailController.text.trim();
    if (email.isEmpty) {
      _setState(
        _state.copyWith(errorMessage: 'Please enter your email address'),
      );
      return null;
    }

    _setState(_state.copyWith(isLoading: true, clearError: true));
    try {
      await _sendResetCode(email);
      return email;
    } on Object catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
      return null;
    } finally {
      _setState(_state.copyWith(isLoading: false));
    }
  }

  void _setState(ForgotPasswordState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    emailController.dispose();
    super.dispose();
  }
}
