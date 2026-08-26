import 'package:flutter/widgets.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_flow_destination.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/validators/auth_form_validators.dart';

typedef LoginRequest = Future<bool> Function(String email, String password);
typedef BusinessSetupStatusLoader = Future<bool> Function();

class LoginFormState {
  final bool isLoading;
  final bool isRoutingProfile;
  final bool authenticationComplete;
  final bool obscurePassword;
  final List<String> errors;
  final String? profileError;
  final bool emailInvalid;
  final bool passwordInvalid;

  const LoginFormState({
    required this.isLoading,
    required this.isRoutingProfile,
    required this.authenticationComplete,
    required this.obscurePassword,
    required this.errors,
    required this.profileError,
    required this.emailInvalid,
    required this.passwordInvalid,
  });

  const LoginFormState.initial()
    : isLoading = false,
      isRoutingProfile = false,
      authenticationComplete = false,
      obscurePassword = true,
      errors = const <String>[],
      profileError = null,
      emailInvalid = false,
      passwordInvalid = false;

  LoginFormState copyWith({
    bool? isLoading,
    bool? isRoutingProfile,
    bool? authenticationComplete,
    bool? obscurePassword,
    List<String>? errors,
    String? profileError,
    bool clearProfileError = false,
    bool? emailInvalid,
    bool? passwordInvalid,
  }) {
    return LoginFormState(
      isLoading: isLoading ?? this.isLoading,
      isRoutingProfile: isRoutingProfile ?? this.isRoutingProfile,
      authenticationComplete:
          authenticationComplete ?? this.authenticationComplete,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errors: errors ?? this.errors,
      profileError: clearProfileError
          ? null
          : profileError ?? this.profileError,
      emailInvalid: emailInvalid ?? this.emailInvalid,
      passwordInvalid: passwordInvalid ?? this.passwordInvalid,
    );
  }
}

class LoginController extends ChangeNotifier {
  final LoginRequest _signIn;
  final BusinessSetupStatusLoader? _loadBusinessSetupCompleted;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginFormState _state = const LoginFormState.initial();
  bool _isDisposed = false;

  LoginController({
    required LoginRequest signIn,
    BusinessSetupStatusLoader? loadBusinessSetupCompleted,
  }) : _signIn = signIn,
       _loadBusinessSetupCompleted = loadBusinessSetupCompleted;

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
    } on Object catch (error) {
      _setState(_state.copyWith(errors: <String>[error.toString()]));
      return false;
    } finally {
      _setState(_state.copyWith(isLoading: false));
    }
  }

  Future<AuthFlowDestination?> submitForDestination() async {
    if (_state.isRoutingProfile) return null;

    if (!_state.authenticationComplete) {
      final bool signedIn = await submit();
      if (_isDisposed || !signedIn) return null;
      _setState(_state.copyWith(authenticationComplete: true));
    }

    _setState(_state.copyWith(isRoutingProfile: true, clearProfileError: true));
    try {
      final bool setupCompleted =
          await _loadBusinessSetupCompleted?.call() ?? true;
      return setupCompleted
          ? AuthFlowDestination.home
          : AuthFlowDestination.businessSetup;
    } on Object catch (error) {
      _setState(
        _state.copyWith(profileError: 'Could not load business setup: $error'),
      );
      return null;
    } finally {
      _setState(_state.copyWith(isRoutingProfile: false));
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
