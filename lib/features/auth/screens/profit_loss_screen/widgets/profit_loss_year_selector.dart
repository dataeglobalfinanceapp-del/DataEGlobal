import 'package:flutter/material.dart';

class ProfitLossYearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const ProfitLossYearSelector({
    super.key,
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        Text(
          '$year',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}
