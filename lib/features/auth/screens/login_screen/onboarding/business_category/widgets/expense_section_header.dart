import 'package:flutter/material.dart';

class ExpenseSectionHeader extends StatelessWidget {
  final String label;

  const ExpenseSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
