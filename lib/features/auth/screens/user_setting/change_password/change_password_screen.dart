import 'package:flutter/material.dart';

import 'change_password_controller.dart';

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
      backgroundColor: _ChangePasswordTokens.background,
      appBar: AppBar(
        backgroundColor: _ChangePasswordTokens.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _ChangePasswordTokens.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change password',
          style: TextStyle(
            color: _ChangePasswordTokens.text,
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
            const _PasswordFieldLabel(label: 'NEW PASSWORD'),
            const SizedBox(height: 16),
            _PasswordInput(
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
            _ComplexityRequirementsCard(state: state),
            const SizedBox(height: 17),
            const _PasswordFieldLabel(label: 'CONFIRM NEW PASSWORD'),
            const SizedBox(height: 16),
            _PasswordInput(
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
              backgroundColor: _ChangePasswordTokens.green,
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

class _ComplexityRequirementsCard extends StatelessWidget {
  final ChangePasswordState state;

  const _ComplexityRequirementsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final rules = state.rules;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFE),
        border: Border.all(color: const Color(0xFFCED5E3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMPLEXITY REQUIREMENTS',
            style: TextStyle(
              color: _ChangePasswordTokens.muted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 22),
          _RequirementRow(
            isComplete: rules.hasMinimumLength,
            label: '12+ characters minimum',
          ),
          const SizedBox(height: 22),
          _RequirementRow(
            isComplete: rules.hasMixedCase,
            label: 'Uppercase & lowercase mix',
          ),
          const SizedBox(height: 22),
          _RequirementRow(
            isComplete: rules.hasDigitAndSpecialCharacter,
            label: 'Special character & digit included',
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.strengthProgress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE8EAEE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _ChangePasswordTokens.green,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Security Strength: ${state.strengthLabel}',
              style: const TextStyle(
                color: _ChangePasswordTokens.muted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final bool isComplete;
  final String label;

  const _RequirementRow({required this.isComplete, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isComplete
              ? _ChangePasswordTokens.green
              : const Color(0xFFD6DAE2),
          size: 20,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _ChangePasswordTokens.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordFieldLabel extends StatelessWidget {
  final String label;

  const _PasswordFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: _ChangePasswordTokens.muted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Color(0xFFE11D48), letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final TextInputAction textInputAction;
  final String? errorText;
  final String toggleTooltip;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onSubmitted;

  const _PasswordInput({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.textInputAction,
    required this.errorText,
    required this.toggleTooltip,
    required this.onToggleVisibility,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            obscuringCharacter: '*',
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              color: _ChangePasswordTokens.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              hintText: '************',
              hintStyle: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 15,
                letterSpacing: 0,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 18, 8, 18),
              suffixIcon: IconButton(
                tooltip: toggleTooltip,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _ChangePasswordTokens.text,
                  size: 24,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChangePasswordTokens {
  static const Color background = Color(0xFFF4F4F5);
  static const Color text = Color(0xFF202124);
  static const Color muted = Color(0xFF4A5670);
  static const Color green = Color(0xFF08A64B);

  const _ChangePasswordTokens._();
}
