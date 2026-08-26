import 'package:flutter/widgets.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_models.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/validators/auth_form_validators.dart';

import '../models/signup_flow_result.dart';

typedef SignUpRequest =
    Future<AuthSignUpAttempt> Function({
      required String email,
      required String password,
      required String fullName,
    });
typedef StageNewAccount =
    Future<void> Function({required String email, required String fullName});

class SignUpFormState {
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool agreedToTerms;
  final String countryCode;
  final List<String> errors;
  final bool nameInvalid;
  final bool emailInvalid;
  final bool phoneInvalid;
  final bool passwordInvalid;
  final bool confirmInvalid;

  const SignUpFormState({
    required this.isLoading,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.agreedToTerms,
    required this.countryCode,
    required this.errors,
    required this.nameInvalid,
    required this.emailInvalid,
    required this.phoneInvalid,
    required this.passwordInvalid,
    required this.confirmInvalid,
  });

  const SignUpFormState.initial()
    : isLoading = false,
      obscurePassword = true,
      obscureConfirm = true,
      agreedToTerms = false,
      countryCode = '+1',
      errors = const <String>[],
      nameInvalid = false,
      emailInvalid = false,
      phoneInvalid = false,
      passwordInvalid = false,
      confirmInvalid = false;

  SignUpFormState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    bool? obscureConfirm,
    bool? agreedToTerms,
    String? countryCode,
    List<String>? errors,
    bool? nameInvalid,
    bool? emailInvalid,
    bool? phoneInvalid,
    bool? passwordInvalid,
    bool? confirmInvalid,
  }) {
    return SignUpFormState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      countryCode: countryCode ?? this.countryCode,
      errors: errors ?? this.errors,
      nameInvalid: nameInvalid ?? this.nameInvalid,
      emailInvalid: emailInvalid ?? this.emailInvalid,
      phoneInvalid: phoneInvalid ?? this.phoneInvalid,
      passwordInvalid: passwordInvalid ?? this.passwordInvalid,
      confirmInvalid: confirmInvalid ?? this.confirmInvalid,
    );
  }
}

class SignUpController extends ChangeNotifier {
  static const List<String> countryCodes = <String>[
    '+1',
    '+7',
    '+20',
    '+27',
    '+30',
    '+31',
    '+32',
    '+33',
    '+34',
    '+36',
    '+39',
    '+40',
    '+41',
    '+44',
    '+45',
    '+46',
    '+47',
    '+48',
    '+49',
    '+51',
    '+52',
    '+54',
    '+55',
    '+56',
    '+57',
    '+60',
    '+61',
    '+62',
    '+63',
    '+64',
    '+65',
    '+66',
    '+81',
    '+82',
    '+84',
    '+86',
    '+90',
    '+91',
    '+92',
    '+94',
    '+95',
    '+98',
  ];

  final SignUpRequest _signUp;
  final StageNewAccount? _stageNewAccount;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  SignUpFormState _state = const SignUpFormState.initial();
  bool _isDisposed = false;

  SignUpController({
    required SignUpRequest signUp,
    StageNewAccount? stageNewAccount,
  }) : _signUp = signUp,
       _stageNewAccount = stageNewAccount;

  SignUpFormState get state => _state;

  String get email => emailController.text.trim();
  String get fullName => nameController.text.trim();

  bool validate() {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String phone = phoneController.text.trim();
    final String password = passwordController.text;
    final String confirm = confirmController.text;

    final bool nameOk = name.isNotEmpty;
    final bool emailOk = AuthFormValidators.isValidEmail(email);
    final bool phoneOk = AuthFormValidators.isValidPhoneNumber(phone);
    final PasswordValidation passwordValidation =
        AuthFormValidators.validatePassword(password);
    final bool confirmOk = confirm == password;
    final List<String> errors = <String>[
      if (!nameOk) 'Username is required',
      if (!emailOk) 'A valid email is required',
      if (!phoneOk) 'A valid phone number is required',
      ...passwordValidation.errors,
      if (password.isNotEmpty && !confirmOk) 'Passwords do not match',
      if (!_state.agreedToTerms) 'Please accept the terms and conditions',
    ];

    _setState(
      _state.copyWith(
        errors: errors,
        nameInvalid: !nameOk,
        emailInvalid: !emailOk,
        phoneInvalid: !phoneOk,
        passwordInvalid: !passwordValidation.isValid,
        confirmInvalid: password.isNotEmpty && !confirmOk,
      ),
    );

    return errors.isEmpty;
  }

  void togglePasswordVisibility() {
    _setState(_state.copyWith(obscurePassword: !_state.obscurePassword));
  }

  void toggleConfirmVisibility() {
    _setState(_state.copyWith(obscureConfirm: !_state.obscureConfirm));
  }

  void setAgreedToTerms(bool value) {
    _setState(_state.copyWith(agreedToTerms: value));
  }

  void setCountryCode(String value) {
    if (!countryCodes.contains(value)) return;
    _setState(_state.copyWith(countryCode: value));
  }

  Future<AuthSignUpAttempt?> submit() async {
    if (!validate()) return null;

    _setState(_state.copyWith(isLoading: true, errors: const <String>[]));
    try {
      return await _signUp(
        email: email,
        password: passwordController.text,
        fullName: fullName,
      );
    } on Object catch (error) {
      _setState(_state.copyWith(errors: <String>[error.toString()]));
      return null;
    } finally {
      _setState(_state.copyWith(isLoading: false));
    }
  }

  Future<SignUpFlowResult?> submitFlow() async {
    final AuthSignUpAttempt? attempt = await submit();
    if (_isDisposed || attempt == null) return null;

    String? profileWarning;
    final StageNewAccount? stageNewAccount = _stageNewAccount;
    if (stageNewAccount != null) {
      _setState(_state.copyWith(isLoading: true));
      try {
        await stageNewAccount(email: email, fullName: fullName);
      } on Object catch (error) {
        profileWarning =
            'Account created, but profile setup could not be prepared: $error';
      } finally {
        _setState(_state.copyWith(isLoading: false));
      }
    }

    return SignUpFlowResult(
      nextStep: attempt.needsConfirmation
          ? SignUpNextStep.confirmEmail
          : SignUpNextStep.businessNameOnboarding,
      email: email,
      fullName: fullName,
      codeDelivery: attempt.codeDelivery,
      profileWarning: profileWarning,
    );
  }

  void _setState(SignUpFormState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}
