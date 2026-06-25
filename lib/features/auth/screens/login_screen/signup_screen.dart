import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'confirm_signup_screen.dart';
import 'signup_controller.dart';

class SignUpScreen extends StatefulWidget {
  final SignUpController? controller;

  const SignUpScreen({super.key, this.controller});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late SignUpController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant SignUpScreen oldWidget) {
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
        widget.controller ?? SignUpController(signUp: AuthService.signUp);
  }

  Future<void> _submit() async {
    final SignUpAttempt? signUp = await _controller.submit();
    if (!mounted || signUp == null || !signUp.needsConfirmation) return;

    Navigator.pushNamed(
      context,
      '/confirm-signup',
      arguments: ConfirmSignUpArguments(
        email: _controller.email,
        codeDelivery: signUp.codeDelivery,
      ),
    );
  }

  Future<void> _pickCountryCode() async {
    final String? selectedCode = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: SignUpController.countryCodes.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select country code',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            }

            final String code = SignUpController.countryCodes[index - 1];
            return ListTile(
              title: Text(code),
              trailing: code == _controller.state.countryCode
                  ? const Icon(Icons.check, color: AuthTokens.primary)
                  : null,
              onTap: () => Navigator.pop(context, code),
            );
          },
        );
      },
    );

    if (selectedCode != null) {
      _controller.setCountryCode(selectedCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final SignUpFormState state = _controller.state;

        return AuthFocusTraversal(
          child: AuthScreenScaffold(
            title: 'Save Tep',
            subtitle: 'Create your executive account',
            activeTab: AuthTab.signup,
            onLoginTap: () => Navigator.pushReplacementNamed(context, '/login'),
            children: <Widget>[
              _SignUpForm(
                controller: _controller,
                state: state,
                onSubmit: _submit,
                onLogin: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                onPickCountryCode: _pickCountryCode,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SignUpForm extends StatelessWidget {
  final SignUpController controller;
  final SignUpFormState state;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;
  final VoidCallback onPickCountryCode;

  const _SignUpForm({
    required this.controller,
    required this.state,
    required this.onSubmit,
    required this.onLogin,
    required this.onPickCountryCode,
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
          const AuthFieldLabel(text: 'FULL NAME', required: true),
          const SizedBox(height: 6),
          AuthTextInput(
            controller: controller.nameController,
            hint: 'e.g: Sunny',
            invalid: state.nameInvalid,
            textCapitalization: TextCapitalization.words,
            autofillHints: const <String>[AutofillHints.name],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
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
          const AuthFieldLabel(text: 'PHONE', required: true),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              AuthCountryCodeButton(
                countryCode: state.countryCode,
                invalid: state.phoneInvalid,
                onPressed: onPickCountryCode,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AuthTextInput(
                  controller: controller.phoneController,
                  hint: '23456788889',
                  invalid: state.phoneInvalid,
                  keyboardType: TextInputType.phone,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  autofillHints: const <String>[
                    AutofillHints.telephoneNumberNational,
                  ],
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AuthFieldLabel(text: 'PASSWORD', required: true),
          const SizedBox(height: 6),
          AuthPasswordField(
            controller: controller.passwordController,
            obscureText: state.obscurePassword,
            invalid: state.passwordInvalid,
            onToggleVisibility: controller.togglePasswordVisibility,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const AuthFieldLabel(text: 'CONFIRM PASSWORD', required: true),
          const SizedBox(height: 6),
          AuthPasswordField(
            controller: controller.confirmController,
            obscureText: state.obscureConfirm,
            invalid: state.confirmInvalid,
            onToggleVisibility: controller.toggleConfirmVisibility,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 16),
          _TermsCheckbox(
            value: state.agreedToTerms,
            onChanged: controller.setAgreedToTerms,
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'Sign Up',
            isLoading: state.isLoading,
            onPressed: onSubmit,
          ),
          const SizedBox(height: 16),
          AuthAccountSwitchLink(
            text: 'Already have an account. ',
            actionLabel: 'Log in',
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Checkbox(
          value: value,
          onChanged: (bool? checked) => onChanged(checked ?? false),
          activeColor: AuthTokens.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'I have read and agree to the terms and conditions',
              style: AuthTokens.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
