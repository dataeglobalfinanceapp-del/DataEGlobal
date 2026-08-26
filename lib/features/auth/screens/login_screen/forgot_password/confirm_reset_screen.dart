import 'package:flutter/material.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/repositories/auth_repository.dart';
import 'package:savetep/features/auth/widgets/auth_widgets.dart';

import 'controllers/confirm_reset_controller.dart';

class ConfirmResetScreen extends StatefulWidget {
  final String email;

  const ConfirmResetScreen({super.key, required this.email});

  @override
  State<ConfirmResetScreen> createState() => _ConfirmResetScreenState();
}

class _ConfirmResetScreenState extends State<ConfirmResetScreen> {
  static const AuthRepository _authRepository = ServiceAuthRepository();

  late final ConfirmResetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfirmResetController(
      email: widget.email,
      confirmReset: _authRepository.confirmReset,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final bool complete = await _controller.confirm();
    if (!mounted) return;

    if (!complete) {
      final String? error = _controller.state.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset successfully')),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final ConfirmResetState state = _controller.state;
        return Scaffold(
          appBar: AppBar(title: const Text('Reset password')),
          body: AuthFocusTraversal(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'A verification code was sent to ${widget.email}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller.codeController,
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller.passwordController,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          state.obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _controller.togglePasswordVisibility,
                      ),
                    ),
                    obscureText: state.obscurePassword,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _confirmReset,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Set new password'),
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
