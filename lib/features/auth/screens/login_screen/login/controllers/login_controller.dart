import 'package:flutter/widgets.dart';

import 'package:savetep/core/api/access_token_provider.dart';
import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/features/auth/models/auth_sign_in_challenge.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_flow_destination.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/validators/auth_form_validators.dart';

typedef LoginRequest =
    Future<bool> Function(String usernameOrEmail, String password);
typedef ConfirmLoginChallenge = Future<bool> Function(String response);
typedef BusinessSetupStatusLoader = Future<bool> Function();

class LoginFormState {
  final bool isLoading;
  final bool isRoutingProfile;
  final bool authenticationComplete;
  final bool obscurePassword;
  final List<String> errors;
  final String? profileError;
  final AuthSignInChallengeRequired? challenge;
  final bool identifierInvalid;
  final bool challengeInvalid;
  final bool passwordInvalid;

  const LoginFormState({
    required this.isLoading,
    required this.isRoutingProfile,
    required this.authenticationComplete,
    required this.obscurePassword,
    required this.errors,
    required this.profileError,
    required this.challenge,
    required this.identifierInvalid,
    required this.challengeInvalid,
    required this.passwordInvalid,
  });

  const LoginFormState.initial()
    : isLoading = false,
      isRoutingProfile = false,
      authenticationComplete = false,
      obscurePassword = true,
      errors = const <String>[],
      profileError = null,
      challenge = null,
      identifierInvalid = false,
      challengeInvalid = false,
      passwordInvalid = false;

  LoginFormState copyWith({
    bool? isLoading,
    bool? isRoutingProfile,
    bool? authenticationComplete,
    bool? obscurePassword,
    List<String>? errors,
    String? profileError,
    bool clearProfileError = false,
    AuthSignInChallengeRequired? challenge,
    bool clearChallenge = false,
    bool? identifierInvalid,
    bool? challengeInvalid,
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
      challenge: clearChallenge ? null : challenge ?? this.challenge,
      identifierInvalid: identifierInvalid ?? this.identifierInvalid,
      challengeInvalid: challengeInvalid ?? this.challengeInvalid,
      passwordInvalid: passwordInvalid ?? this.passwordInvalid,
    );
  }
}

class LoginController extends ChangeNotifier {
  final LoginRequest _signIn;
  final ConfirmLoginChallenge? _confirmSignIn;
  final BusinessSetupStatusLoader? _loadBusinessSetupCompleted;

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController challengeController = TextEditingController();

  LoginFormState _state = const LoginFormState.initial();
  bool _isDisposed = false;

  LoginController({
    required LoginRequest signIn,
    ConfirmLoginChallenge? confirmSignIn,
    BusinessSetupStatusLoader? loadBusinessSetupCompleted,
  }) : _signIn = signIn,
       _confirmSignIn = confirmSignIn,
       _loadBusinessSetupCompleted = loadBusinessSetupCompleted;

  LoginFormState get state => _state;

  bool validate() {
    final AuthSignInChallengeRequired? challenge = _state.challenge;
    if (challenge != null) {
      final bool challengeOk =
          challenge.canRespond && challengeController.text.trim().isNotEmpty;
      final List<String> errors = <String>[
        if (!challenge.canRespond) challenge.prompt,
        if (challenge.canRespond && !challengeOk)
          '${challenge.inputLabel.toLowerCase()} is required',
      ];
      _setState(
        _state.copyWith(errors: errors, challengeInvalid: !challengeOk),
      );
      return errors.isEmpty;
    }

    final String usernameOrEmail = identifierController.text.trim();
    final String password = passwordController.text;
    final bool identifierOk = AuthFormValidators.isValidUsernameOrEmail(
      usernameOrEmail,
    );
    final bool passwordOk = AuthFormValidators.isValidLoginPassword(password);
    final List<String> errors = <String>[
      if (!identifierOk) 'Username or email is required',
      if (!passwordOk) 'Password must be at least 8 characters',
    ];

    _setState(
      _state.copyWith(
        errors: errors,
        identifierInvalid: !identifierOk,
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
      if (_state.challenge != null) {
        final ConfirmLoginChallenge? confirmSignIn = _confirmSignIn;
        if (confirmSignIn == null) {
          _setState(
            _state.copyWith(
              errors: const <String>[
                'This sign-in challenge cannot be completed in this flow.',
              ],
            ),
          );
          return false;
        }
        final AuthSignInChallengeRequired challenge = _state.challenge!;
        final String response = challengeController.text.trim();
        final bool complete = await confirmSignIn(
          challenge.type == AuthSignInChallengeType.mfaSelection
              ? response.toUpperCase()
              : response,
        );
        if (complete) {
          challengeController.clear();
          _setState(
            _state.copyWith(clearChallenge: true, challengeInvalid: false),
          );
        }
        return complete;
      }
      return await _signIn(
        identifierController.text.trim(),
        passwordController.text,
      );
    } on AuthSignInChallengeRequired catch (challenge) {
      challengeController.clear();
      if (challenge.canRespond) {
        _setState(
          _state.copyWith(
            challenge: challenge,
            errors: const <String>[],
            challengeInvalid: false,
          ),
        );
      } else {
        _setState(
          _state.copyWith(
            errors: <String>[challenge.prompt],
            clearChallenge: true,
          ),
        );
      }
      return false;
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
      final bool authenticationFailed =
          error is ApiAccessTokenException ||
          (error is ApiHttpException &&
              error.kind == ApiFailureKind.unauthenticated);
      _setState(
        _state.copyWith(
          authenticationComplete: authenticationFailed ? false : null,
          profileError: authenticationFailed
              ? 'Your session expired. Sign in again.'
              : 'Could not load business setup: $error',
        ),
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
    identifierController.dispose();
    passwordController.dispose();
    challengeController.dispose();
    super.dispose();
  }
}
