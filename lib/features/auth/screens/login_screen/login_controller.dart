import 'package:flutter/material.dart';

import 'auth_form_validators.dart';

typedef LoginRequest = Future<bool> Function(String email, String password);

class LoginFormState {
  final bool isLoading;
  final bool obscurePassword;
  final List<String> errors;
  final bool emailInvalid;
  final bool passwordInvalid;

  const LoginFormState({
    required this.isLoading,
    required this.obscurePassword,
    required this.errors,
    required this.emailInvalid,
    required this.passwordInvalid,
  });

  const LoginFormState.initial()
    : isLoading = false,
      obscurePassword = true,
      errors = const <String>[],
      emailInvalid = false,
      passwordInvalid = false;

  LoginFormState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    List<String>? errors,
    bool? emailInvalid,
    bool? passwordInvalid,
  }) {
    return LoginFormState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errors: errors ?? this.errors,
      emailInvalid: emailInvalid ?? this.emailInvalid,
      passwordInvalid: passwordInvalid ?? this.passwordInvalid,
    );
  }
}

class LoginController extends ChangeNotifier {
  final LoginRequest _signIn;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginFormState _state = const LoginFormState.initial();
  bool _isDisposed = false;

  LoginController({required LoginRequest signIn}) : _signIn = signIn;

  LoginFormState get state => _state;

  bool validate() {
    final String email = emailController.text.trim();
    final String password = passwordController.text;
    final bool emailOk = AuthFormValidators.isValidEmail(email);
    final bool passwordOk = AuthFormValidators.isValidLoginPassword(password);
    final List<String> errors = <String>[
      if (!emailOk) 'A valid email is required',
      if (!passwordOk) 'Password must be at least 8 characters',
    ];

    _setState(
      _state.copyWith(
        errors: errors,
        emailInvalid: !emailOk,
        passwordInvalid: !passwordOk,
      ),
    );

    return errors.isEmpty;
  }

  void togglePasswordVisibility() {
    _setState(_state.copyWith(obscurePassword: !_state.obscurePassword));
  }

  Future<bool> submit() async {
    if (!validate()) return false;

    _setState(_state.copyWith(isLoading: true, errors: const <String>[]));
    try {
      return await _signIn(
        emailController.text.trim(),
        passwordController.text,
      );
    } on Exception catch (error) {
      _setState(_state.copyWith(errors: <String>[error.toString()]));
      return false;
    } finally {
      _setState(_state.copyWith(isLoading: false));
    }
  }

  void _setState(LoginFormState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
