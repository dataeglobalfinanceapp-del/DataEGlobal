import 'package:savetep/features/auth/screens/home_screen/models/home_budget_chart_models.dart';

class HomeBudgetChartCalculator {
  const HomeBudgetChartCalculator._();

  static String periodKey({
    required String selectedPeriod,
    required String dataPeriod,
  }) {
    final selectedKey = selectedPeriod.trim();
    final rawKey = selectedKey.isNotEmpty
        ? selectedKey
        : dataPeriod.trim().isEmpty
        ? 'Week'
        : dataPeriod;
    return rawKey == 'Year' ? 'Month' : rawKey;
  }

  static double? targetPercentageFrom(String value) {
    final target = double.tryParse(value.trim());
    return target?.clamp(0, 100).toDouble();
  }

  static List<HomeBudgetSegment> budgetSegments(HomeBudgetData data) {
    final categories =
        data.categories.where((category) => category.percentage > 0).toList()
          ..sort((a, b) => b.percentage.compareTo(a.percentage));

    if (categories.isEmpty) {
      if (data.expense > 0) {
        return [
          HomeBudgetSegment(
            label: 'Expenses',
            amount: data.expense,
            percentage: 100,
          ),
        ];
      }
      return const [
        HomeBudgetSegment(
          label: 'No activity',
          amount: 0,
          percentage: 100,
          isPlaceholder: true,
        ),
      ];
    }

    final visibleCategories = categories.length <= 8
        ? categories
        : categories.take(7).toList(growable: true);
    if (categories.length > 8) {
      final otherPercentage = categories
          .skip(7)
          .fold<double>(0, (total, category) => total + category.percentage);
      final segments = [
        for (final category in visibleCategories)
          HomeBudgetSegment(
            label: category.label,
            amount: data.expense * category.percentage / 100,
            percentage: category.percentage,
          ),
        HomeBudgetSegment(
          label: 'Others',
          amount: data.expense * otherPercentage / 100,
          percentage: otherPercentage,
        ),
      ];
      return segments
          .where((segment) => segment.amount > 0)
          .toList(growable: false);
    }

    return [
      for (final category in visibleCategories)
        if (data.expense * category.percentage / 100 > 0)
          HomeBudgetSegment(
            label: category.label,
            amount: data.expense * category.percentage / 100,
            percentage: category.percentage,
          ),
    ];
  }

  static List<HomeBudgetSegment> legendSegments(HomeBudgetData data) {
    final categories = data.categories.toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final segments = [
      for (final category in categories.take(8))
        HomeBudgetSegment(
          label: category.label,
          amount: data.expense * category.percentage / 100,
          percentage: category.percentage,
        ),
    ];

    if (segments.isNotEmpty) return segments;
    return const [
      HomeBudgetSegment(
        label: 'No activity',
        amount: 0,
        percentage: 0,
        isPlaceholder: true,
      ),
    ];
  }

  static int surplusPercent(HomeBudgetData data) {
    return data.deposit > 0
        ? ((data.available / data.deposit) * 100).round()
        : 0;
  }
}
