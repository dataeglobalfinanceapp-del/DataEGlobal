import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/expense_category.dart';

import 'category_item.dart';
import 'expense_section_header.dart';

class CategoryColumn extends StatelessWidget {
  final bool selected;
  final List<ExpenseCategory> fixedCategories;
  final List<ExpenseCategory> variableCategories;
  final ValueChanged<String> onCategoryTap;

  const CategoryColumn({
    super.key,
    required this.selected,
    required this.fixedCategories,
    required this.variableCategories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = selected
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.error;
    final String statusLabel = selected ? 'Checked' : 'Unchecked';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Semantics(
              label: '$statusLabel expense categories',
              header: true,
              child: Column(
                children: <Widget>[
                  Icon(
                    selected ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 34,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CustomScrollView(
              key: PageStorageKey<String>('categoryColumn.$statusLabel'),
              slivers: <Widget>[
                const SliverToBoxAdapter(
                  child: ExpenseSectionHeader(label: 'FIXED EXPENSE'),
                ),
                SliverList.builder(
                  itemCount: fixedCategories.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ExpenseCategory category = fixedCategories[index];
                    return CategoryItem(
                      category: category,
                      selected: selected,
                      onTap: () => onCategoryTap(category.id),
                    );
                  },
                ),
                const SliverToBoxAdapter(
                  child: ExpenseSectionHeader(label: 'VARIABLE EXPENSE'),
                ),
                SliverList.builder(
                  itemCount: variableCategories.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ExpenseCategory category = variableCategories[index];
                    return CategoryItem(
                      category: category,
                      selected: selected,
                      onTap: () => onCategoryTap(category.id),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
