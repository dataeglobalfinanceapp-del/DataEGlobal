import 'package:flutter/material.dart';

import 'models/change_password_state.dart';

typedef ChangePasswordRequest = Future<void> Function(String newPassword);

class ChangePasswordController extends ChangeNotifier {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final ChangePasswordRequest _changePassword;

  ChangePasswordState _state = const ChangePasswordState();

  ChangePasswordController({ChangePasswordRequest? changePassword})
    : _changePassword = changePassword ?? _defaultChangePassword {
    newPasswordController.addListener(_syncStateFromFields);
    confirmPasswordController.addListener(_syncStateFromFields);
  }

  ChangePasswordState get state => _state;

  void toggleNewPasswordVisibility() {
    _setState(_state.copyWith(obscureNewPassword: !_state.obscureNewPassword));
  }

  void toggleConfirmPasswordVisibility() {
    _setState(
      _state.copyWith(obscureConfirmPassword: !_state.obscureConfirmPassword),
    );
  }

  Future<bool> submit() async {
    _syncStateFromFields(submitted: true);
    if (!_state.canSubmit) return false;

    _setState(_state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      await _changePassword(newPasswordController.text);
      _setState(_state.copyWith(isSubmitting: false));
      return true;
    } catch (error) {
      _setState(
        _state.copyWith(
          isSubmitting: false,
          submitError: 'Unable to save password. Please try again.',
        ),
      );
      return false;
    }
  }

  void _syncStateFromFields({bool? submitted}) {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;
    _setState(
      _state.copyWith(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        newPasswordTouched: _state.newPasswordTouched || newPassword.isNotEmpty,
        confirmPasswordTouched:
            _state.confirmPasswordTouched || confirmPassword.isNotEmpty,
        submitted: submitted ?? _state.submitted,
        clearSubmitError: true,
      ),
    );
  }

  void _setState(ChangePasswordState nextState) {
    if (_state == nextState) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    newPasswordController
      ..removeListener(_syncStateFromFields)
      ..dispose();
    confirmPasswordController
      ..removeListener(_syncStateFromFields)
      ..dispose();
    super.dispose();
  }

  static Future<void> _defaultChangePassword(String newPassword) async {}
}
