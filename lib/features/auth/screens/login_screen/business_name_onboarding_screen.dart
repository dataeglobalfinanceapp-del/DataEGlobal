import 'package:flutter/material.dart';

import 'package:savetep/features/auth/services/account_profile_service.dart';
import 'package:savetep/features/auth/widgets/business_name_prompt_dialog.dart';

class BusinessNameOnboardingArguments {
  final String email;
  final String fullName;

  const BusinessNameOnboardingArguments({
    required this.email,
    required this.fullName,
  });
}

class BusinessNameOnboardingScreen extends StatefulWidget {
  final String email;
  final String fullName;

  const BusinessNameOnboardingScreen({
    super.key,
    required this.email,
    required this.fullName,
  });

  @override
  State<BusinessNameOnboardingScreen> createState() =>
      _BusinessNameOnboardingScreenState();
}

class _BusinessNameOnboardingScreenState
    extends State<BusinessNameOnboardingScreen> {
  bool _promptStarted = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptStarted) return;
    _promptStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPrompt());
  }

  Future<void> _showPrompt() async {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    final businessName = await showBusinessNamePromptDialog(context);
    if (!mounted) return;

    try {
      await AccountProfileService.completePendingOnboarding(
        email: widget.email,
        fullName: widget.fullName,
        businessName: businessName,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not save the account profile: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    return Scaffold(
      body: Center(
        child: errorMessage == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _showPrompt,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
