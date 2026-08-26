import 'package:flutter/foundation.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_flow_destination.dart';

typedef CheckAuthSession = Future<bool> Function();
typedef LoadBusinessSetupCompleted = Future<bool> Function();

class SplashState {
  final bool isChecking;
  final String? errorMessage;

  const SplashState({required this.isChecking, required this.errorMessage});

  const SplashState.initial() : isChecking = false, errorMessage = null;

  SplashState copyWith({
    bool? isChecking,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SplashState(
      isChecking: isChecking ?? this.isChecking,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SplashController extends ChangeNotifier {
  final CheckAuthSession _checkAuthSession;
  final LoadBusinessSetupCompleted _loadBusinessSetupCompleted;

  SplashState _state = const SplashState.initial();
  bool _isDisposed = false;

  SplashController({
    required CheckAuthSession checkAuthSession,
    required LoadBusinessSetupCompleted loadBusinessSetupCompleted,
  }) : _checkAuthSession = checkAuthSession,
       _loadBusinessSetupCompleted = loadBusinessSetupCompleted;

  SplashState get state => _state;

  Future<AuthFlowDestination?> check() async {
    if (_state.isChecking) return null;
    _setState(_state.copyWith(isChecking: true, clearError: true));

    try {
      bool signedIn;
      try {
        signedIn = await _checkAuthSession();
      } on Object {
        signedIn = false;
      }

      if (!signedIn) return AuthFlowDestination.login;

      final bool setupCompleted = await _loadBusinessSetupCompleted();
      return setupCompleted
          ? AuthFlowDestination.home
          : AuthFlowDestination.businessSetup;
    } on Object catch (error) {
      _setState(
        _state.copyWith(errorMessage: 'Could not load business setup: $error'),
      );
      return null;
    } finally {
      _setState(_state.copyWith(isChecking: false));
    }
  }

  void _setState(SplashState nextState) {
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
