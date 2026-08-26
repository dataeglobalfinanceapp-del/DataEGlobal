import 'package:flutter/material.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/repositories/auth_repository.dart';
import 'package:savetep/features/auth/widgets/auth_widgets.dart';

import 'controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const AuthRepository _authRepository = ServiceAuthRepository();

  late final ForgotPasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ForgotPasswordController(
      sendResetCode: _authRepository.sendResetCode,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final String? email = await _controller.sendCode();
    if (!mounted) return;

    if (email != null) {
      Navigator.pushNamed(context, '/confirm-reset', arguments: email);
      return;
    }

    final String? error = _controller.state.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final ForgotPasswordState state = _controller.state;
        return Scaffold(
          appBar: AppBar(title: const Text('Forgot password')),
          body: AuthFocusTraversal(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Enter your email address and we\'ll send you a code to reset your password.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller.emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _sendCode,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send reset code'),
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
