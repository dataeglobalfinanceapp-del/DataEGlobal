import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/expense_category.dart';

class CategoryItem extends StatelessWidget {
  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${selected ? 'Disable' : 'Enable'} ${category.name}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Material(
          color: selected
              ? const Color(0xFFEAF8EF)
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF16A34A)
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: InkWell(
            key: ValueKey<String>(
              'category.${selected ? 'checked' : 'unchecked'}.${category.id}',
            ),
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
