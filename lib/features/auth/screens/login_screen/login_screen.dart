import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'login_controller.dart';

class LoginScreen extends StatefulWidget {
  final LoginController? controller;

  const LoginScreen({super.key, this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late LoginController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    if (_ownsController) {
      _controller.dispose();
    }
    _bindController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _bindController() {
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? LoginController(signIn: AuthService.signIn);
  }

  Future<void> _submit() async {
    final bool signedIn = await _controller.submit();
    if (!mounted || !signedIn) return;

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final LoginFormState state = _controller.state;

        return AuthFocusTraversal(
          child: AuthScreenScaffold(
            title: 'Save Tep',
            subtitle: 'Executive Financial Portal',
            activeTab: AuthTab.login,
            onSignUpTap: () =>
                Navigator.pushReplacementNamed(context, '/signup'),
            children: <Widget>[
              _LoginForm(
                controller: _controller,
                state: state,
                onSubmit: _submit,
                onForgotPassword: () =>
                    Navigator.pushNamed(context, '/forgot-password'),
                onSignUp: () =>
                    Navigator.pushReplacementNamed(context, '/signup'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoginForm extends StatelessWidget {
  final LoginController controller;
  final LoginFormState state;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;

  const _LoginForm({
    required this.controller,
    required this.state,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        children: <Widget>[
          if (state.errors.isNotEmpty) ...<Widget>[
            AuthErrorBanner(errors: state.errors),
            const SizedBox(height: 16),
          ],
          const AuthFieldLabel(text: 'EMAIL', required: true),
          const SizedBox(height: 6),
          AuthTextInput(
            controller: controller.emailController,
            hint: 'e.g: sunny@gmail.com',
            invalid: state.emailInvalid,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const <String>[AutofillHints.email],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const AuthFieldLabel(text: 'PASSWORD', required: true),
          const SizedBox(height: 6),
          AuthPasswordField(
            controller: controller.passwordController,
            obscureText: state.obscurePassword,
            invalid: state.passwordInvalid,
            onToggleVisibility: controller.togglePasswordVisibility,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onForgotPassword,
            child: const Text('Forgot password?', style: AuthTokens.link),
          ),
          const SizedBox(height: 8),
          AuthPrimaryButton(
            label: 'Login',
            isLoading: state.isLoading,
            onPressed: onSubmit,
          ),
          const SizedBox(height: 20),
          const AuthOrDivider(),
          const SizedBox(height: 16),
          AuthSocialButton(
            onPressed: () {},
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AuthGoogleIcon(),
                SizedBox(width: 12),
                Text('Login with Google', style: AuthTokens.socialLabel),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AuthSocialButton(
            onPressed: () {},
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.apple, size: 22, color: AuthTokens.textStrong),
                SizedBox(width: 12),
                Text('Login with Apple', style: AuthTokens.socialLabel),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AuthAccountSwitchLink(
            text: "Don't have an account. ",
            actionLabel: 'Sign Up',
            onPressed: onSignUp,
          ),
        ],
      ),
    );
  }
}
