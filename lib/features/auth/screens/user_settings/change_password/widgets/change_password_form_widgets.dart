import 'package:flutter/material.dart';

import '../models/change_password_state.dart';

class ComplexityRequirementsCard extends StatelessWidget {
  final ChangePasswordState state;

  const ComplexityRequirementsCard({super.key, required this.state});

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
              color: ChangePasswordTokens.muted,
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
                ChangePasswordTokens.green,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Security Strength: ${state.strengthLabel}',
              style: const TextStyle(
                color: ChangePasswordTokens.muted,
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
              ? ChangePasswordTokens.green
              : const Color(0xFFD6DAE2),
          size: 20,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: ChangePasswordTokens.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class PasswordFieldLabel extends StatelessWidget {
  final String label;

  const PasswordFieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: ChangePasswordTokens.muted,
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

class PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final TextInputAction textInputAction;
  final String? errorText;
  final String toggleTooltip;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onSubmitted;

  const PasswordInput({
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
              color: ChangePasswordTokens.text,
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
                  color: ChangePasswordTokens.text,
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

class ChangePasswordTokens {
  static const Color background = Color(0xFFF4F4F5);
  static const Color text = Color(0xFF202124);
  static const Color muted = Color(0xFF4A5670);
  static const Color green = Color(0xFF08A64B);

  const ChangePasswordTokens._();
}
