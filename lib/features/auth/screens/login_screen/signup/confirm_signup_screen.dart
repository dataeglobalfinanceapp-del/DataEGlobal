import 'package:flutter/material.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_flow_arguments.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_models.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/repositories/auth_repository.dart';
import 'package:savetep/features/auth/widgets/auth_widgets.dart';

import 'controllers/confirm_signup_controller.dart';

class ConfirmSignUpScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final AuthCodeDeliveryInfo? codeDelivery;

  const ConfirmSignUpScreen({
    super.key,
    required this.email,
    this.fullName = '',
    this.codeDelivery,
  });

  @override
  State<ConfirmSignUpScreen> createState() => _ConfirmSignUpScreenState();
}

class _ConfirmSignUpScreenState extends State<ConfirmSignUpScreen> {
  static const AuthRepository _authRepository = ServiceAuthRepository();

  late final ConfirmSignUpController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfirmSignUpController(
      email: widget.email,
      confirmSignUp: _authRepository.confirmSignUp,
      resendSignUpCode: _authRepository.resendSignUpCode,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final bool complete = await _controller.confirm();
    if (!mounted) return;

    if (complete) {
      Navigator.pushReplacementNamed(
        context,
        '/business-name-onboarding',
        arguments: BusinessNameOnboardingArguments(
          email: widget.email,
          fullName: widget.fullName,
        ),
      );
      return;
    }

    _showControllerError();
  }

  Future<void> _resendCode() async {
    final String? message = await _controller.resendCode();
    if (!mounted) return;

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    _showControllerError();
  }

  void _showControllerError() {
    final String? error = _controller.state.errorMessage;
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final ConfirmSignUpState state = _controller.state;
        return Scaffold(
          appBar: AppBar(title: const Text('Verify email')),
          body: AuthFocusTraversal(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('A verification code was sent to ${widget.email}'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller.codeController,
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isConfirming ? null : _confirm,
                      child: state.isConfirming
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify'),
                    ),
                  ),
                  TextButton(
                    onPressed: state.isResending ? null : _resendCode,
                    child: Text(
                      state.isResending ? 'Resending...' : 'Resend code',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
