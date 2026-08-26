import 'package:flutter/widgets.dart';

typedef ConfirmResetRequest =
    Future<void> Function({
      required String email,
      required String code,
      required String newPassword,
    });

class ConfirmResetState {
  final bool isLoading;
  final bool obscurePassword;
  final String? errorMessage;

  const ConfirmResetState({
    required this.isLoading,
    required this.obscurePassword,
    required this.errorMessage,
  });

  const ConfirmResetState.initial()
    : isLoading = false,
      obscurePassword = true,
      errorMessage = null;

  ConfirmResetState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConfirmResetState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ConfirmResetController extends ChangeNotifier {
  final String email;
  final ConfirmResetRequest _confirmReset;

  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  ConfirmResetState _state = const ConfirmResetState.initial();
  bool _isDisposed = false;

  ConfirmResetController({
    required this.email,
    required ConfirmResetRequest confirmReset,
  }) : _confirmReset = confirmReset;

  ConfirmResetState get state => _state;

  void togglePasswordVisibility() {
    _setState(_state.copyWith(obscurePassword: !_state.obscurePassword));
  }

  Future<bool> confirm() async {
    final String code = codeController.text.trim();
    final String newPassword = passwordController.text;
    if (code.isEmpty || newPassword.isEmpty) {
      _setState(_state.copyWith(errorMessage: 'Please fill in all fields'));
      return false;
    }

    _setState(_state.copyWith(isLoading: true, clearError: true));
    try {
      await _confirmReset(email: email, code: code, newPassword: newPassword);
      return true;
    } on Object catch (error) {
      _setState(_state.copyWith(errorMessage: error.toString()));
      return false;
    } finally {
      _setState(_state.copyWith(isLoading: false));
    }
  }

  void _setState(ConfirmResetState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    codeController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
