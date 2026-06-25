import 'package:flutter/material.dart';

class ExpenseCategoryLink extends StatelessWidget {
  final String category;
  final VoidCallback onTap;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  const ExpenseCategoryLink({
    super.key,
    required this.category,
    required this.onTap,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle =
        style ?? DefaultTextStyle.of(context).style;

    return Semantics(
      button: true,
      link: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            category,
            maxLines: maxLines,
            overflow: overflow,
            style: effectiveStyle.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
