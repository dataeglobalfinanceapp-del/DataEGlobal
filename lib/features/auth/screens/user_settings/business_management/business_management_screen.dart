import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_flow_arguments.dart';
import 'package:savetep/providers/business_profile_provider.dart';

import '../widgets/user_settings_detail_scaffold.dart';
import 'widgets/business_profile_form.dart';

class BusinessManagementScreen extends ConsumerStatefulWidget {
  final bool isSetupFlow;

  const BusinessManagementScreen({super.key, this.isSetupFlow = false});

  @override
  ConsumerState<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState
    extends ConsumerState<BusinessManagementScreen> {
  Set<String>? _categoryDraftIds;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(businessProfileProvider);

    return UserSettingsDetailScaffold(
      title: widget.isSetupFlow
          ? 'Business Management Setup'
          : 'Business Management',
      icon: Icons.business_outlined,
      accentColor: const Color(0xFF38A9E8),
      showBackButton: !widget.isSetupFlow,
      child: profile.when(
        data: (profile) => BusinessProfileForm(
          profile: profile,
          isSetupFlow: widget.isSetupFlow,
          onSave: (updatedProfile) async {
            if (widget.isSetupFlow) {
              final result = await Navigator.pushNamed(
                context,
                '/business-categories-onboarding',
                arguments: BusinessCategoryOnboardingArguments(
                  businessProfile: updatedProfile,
                  initialSelectedCategoryIds: _categoryDraftIds,
                ),
              );
              if (!mounted || result is! Set<String>) return;
              setState(() => _categoryDraftIds = Set<String>.of(result));
              return;
            }

            await ref
                .read(businessProfileProvider.notifier)
                .save(updatedProfile);
            if (!mounted) return;
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(content: Text('Business information saved.')),
            );
          },
        ),
        loading: () => const CircularProgressIndicator(),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load the business information: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(businessProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
