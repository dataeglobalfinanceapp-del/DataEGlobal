import 'package:flutter/material.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/repositories/pending_account_profile_repository.dart';
import 'package:savetep/features/auth/widgets/business_name_prompt_dialog.dart';

import 'controllers/business_name_onboarding_controller.dart';

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
  static const PendingAccountProfileRepository _profileRepository =
      ServicePendingAccountProfileRepository();

  late final BusinessNameOnboardingController _controller;
  bool _promptStarted = false;
  bool _promptVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = BusinessNameOnboardingController(
      email: widget.email,
      fullName: widget.fullName,
      completePendingOnboarding: _profileRepository.completeOnboarding,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptStarted) return;
    _promptStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPrompt());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showPrompt() async {
    _controller.beginPrompt();
    setState(() => _promptVisible = true);
    final String? businessName = await showBusinessNamePromptDialog(context);
    if (!mounted) return;
    setState(() => _promptVisible = false);

    final bool complete = await _controller.complete(businessName);
    if (!mounted || !complete) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final String? errorMessage = _controller.state.errorMessage;
        return Scaffold(
          body: Center(
            child: _promptVisible
                ? const SizedBox.shrink()
                : errorMessage == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
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
      },
    );
  }
}
