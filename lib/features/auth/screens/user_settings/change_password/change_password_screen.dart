import 'package:flutter/material.dart';

import 'change_password_controller.dart';
import 'widgets/change_password_form_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final ChangePasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChangePasswordController()
      ..addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _submit() async {
    final saved = await _controller.submit();
    if (!mounted) return;

    final message = saved
        ? 'Password saved successfully.'
        : _controller.state.submitError ?? 'Check the highlighted fields.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      backgroundColor: ChangePasswordTokens.background,
      appBar: AppBar(
        backgroundColor: ChangePasswordTokens.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ChangePasswordTokens.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change password',
          style: TextStyle(
            color: ChangePasswordTokens.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(15, 24, 15, 24),
          children: [
            const PasswordFieldLabel(label: 'NEW PASSWORD'),
            const SizedBox(height: 16),
            PasswordInput(
              key: const Key('new-password-field'),
              controller: _controller.newPasswordController,
              obscureText: state.obscureNewPassword,
              textInputAction: TextInputAction.next,
              errorText: state.newPasswordError,
              toggleTooltip: state.obscureNewPassword
                  ? 'Show new password'
                  : 'Hide new password',
              onToggleVisibility: _controller.toggleNewPasswordVisibility,
            ),
            const SizedBox(height: 17),
            ComplexityRequirementsCard(state: state),
            const SizedBox(height: 17),
            const PasswordFieldLabel(label: 'CONFIRM NEW PASSWORD'),
            const SizedBox(height: 16),
            PasswordInput(
              key: const Key('confirm-new-password-field'),
              controller: _controller.confirmPasswordController,
              obscureText: state.obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              errorText: state.confirmPasswordError,
              toggleTooltip: state.obscureConfirmPassword
                  ? 'Show confirm password'
                  : 'Hide confirm password',
              onToggleVisibility: _controller.toggleConfirmPasswordVisibility,
              onSubmitted: (_) => state.canSubmit ? _submit() : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(15, 8, 15, 16),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.canSubmit ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ChangePasswordTokens.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD9DDE6),
              disabledForegroundColor: const Color(0xFF7A8497),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
