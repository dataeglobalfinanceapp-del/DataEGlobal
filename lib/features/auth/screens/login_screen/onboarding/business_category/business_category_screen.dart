import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/models/expense_category.dart';
import 'package:savetep/providers/business_profile_provider.dart';
import 'package:savetep/providers/expense_category_provider.dart';

import 'controllers/business_category_controller.dart';
import 'repositories/business_category_onboarding_repository.dart';
import 'widgets/category_column.dart';

class BusinessCategoryScreen extends ConsumerStatefulWidget {
  final BusinessProfile businessProfile;
  final Set<String>? initialSelectedCategoryIds;
  final BusinessCategoryController? controller;

  const BusinessCategoryScreen({
    super.key,
    required this.businessProfile,
    this.initialSelectedCategoryIds,
    this.controller,
  });

  @override
  ConsumerState<BusinessCategoryScreen> createState() =>
      _BusinessCategoryScreenState();
}

class _BusinessCategoryScreenState
    extends ConsumerState<BusinessCategoryScreen> {
  late final BusinessCategoryController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        BusinessCategoryController(
          businessProfile: widget.businessProfile,
          initialSelectedCategoryIds: widget.initialSelectedCategoryIds,
          repository: ServiceBusinessCategoryOnboardingRepository(
            expenseCategoryRepository: ref.read(
              expenseCategoryRepositoryProvider,
            ),
            businessProfileRepository: ref.read(
              businessProfileRepositoryProvider,
            ),
          ),
          onCompleted: () {
            ref.invalidate(activeExpenseCategoriesProvider);
            ref.invalidate(businessProfileProvider);
          },
        );
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _continue() async {
    final bool complete = await _controller.save();
    if (!mounted || !complete) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (Route route) => false);
  }

  void _back() {
    Navigator.pop(context, _controller.selectedCategoryIds);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final state = _controller.state;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: state.isSaving ? null : _back,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to business setup',
            ),
            title: const Text('Choose Business Categories'),
          ),
          body: SafeArea(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Choose the expense categories available to your business. Tap a category to move it between columns.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (state.validationMessage case final message?) ...[
                          const SizedBox(height: 8),
                          Text(
                            message,
                            key: const ValueKey<String>(
                              'businessCategories.validationError',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (state.errorMessage case final message?) ...[
                          const SizedBox(height: 8),
                          Text(
                            message,
                            key: const ValueKey<String>(
                              'businessCategories.saveError',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: CategoryColumn(
                                  selected: false,
                                  fixedCategories: _controller.categoriesFor(
                                    ExpenseType.fixed,
                                    selected: false,
                                  ),
                                  variableCategories: _controller.categoriesFor(
                                    ExpenseType.variable,
                                    selected: false,
                                  ),
                                  onCategoryTap: _controller.toggleCategory,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CategoryColumn(
                                  selected: true,
                                  fixedCategories: _controller.categoriesFor(
                                    ExpenseType.fixed,
                                    selected: true,
                                  ),
                                  variableCategories: _controller.categoriesFor(
                                    ExpenseType.variable,
                                    selected: true,
                                  ),
                                  onCategoryTap: _controller.toggleCategory,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          key: const ValueKey<String>(
                            'businessCategories.continue',
                          ),
                          onPressed: state.isSaving ? null : _continue,
                          child: state.isSaving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Continue (${state.selectedCategoryIds.length} selected)',
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
