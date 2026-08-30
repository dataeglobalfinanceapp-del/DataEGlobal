import 'package:flutter/material.dart';

import 'profit_loss_models.dart';

class ProfitLossState {
  final bool isLoading;
  final int year;
  final DateTimeRange dateRange;
  final ProfitLossData data;
  final String? errorMessage;

  const ProfitLossState({
    required this.isLoading,
    required this.year,
    required this.dateRange,
    required this.data,
    required this.errorMessage,
  });

  ProfitLossState copyWith({
    bool? isLoading,
    int? year,
    DateTimeRange? dateRange,
    ProfitLossData? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfitLossState(
      isLoading: isLoading ?? this.isLoading,
      year: year ?? this.year,
      dateRange: dateRange ?? this.dateRange,
      data: data ?? this.data,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
