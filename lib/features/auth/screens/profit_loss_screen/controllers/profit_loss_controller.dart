import 'package:flutter/material.dart';

import 'package:savetep/services/app_clock.dart';

import '../models/profit_loss_models.dart';
import '../models/profit_loss_state.dart';
import '../repositories/profit_loss_repository.dart';
import '../services/profit_loss_report_service.dart';

class ProfitLossController extends ChangeNotifier {
  final ProfitLossRepository _repository;
  final ProfitLossReportService _reportService;

  ProfitLossState _state;
  bool _isDisposed = false;

  ProfitLossController({
    DateTimeRange? initialDateRange,
    ProfitLossRepository repository = const LiabilityProfitLossRepository(),
    ProfitLossReportService reportService = const ProfitLossReportService(),
  }) : _repository = repository,
       _reportService = reportService,
       _state = _initialState(initialDateRange);

  ProfitLossState get state => _state;

  ProfitLossReport get report => _reportService.buildReport(
    data: _state.data,
    year: _state.year,
    periodStart: _state.dateRange.start,
    periodEnd: _state.dateRange.end,
    currentDate: AppClock.now,
  );

  Future<void> load() async {
    _setState(_state.copyWith(isLoading: true, clearError: true));
    try {
      final ProfitLossData data = await _repository.load();
      _setState(_state.copyWith(isLoading: false, data: data));
    } on Object catch (error) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load Profit and Loss data: $error',
        ),
      );
    }
  }

  void changeYear(int delta) {
    final int year = _state.year + delta;
    _setState(_state.copyWith(year: year, dateRange: _yearRange(year)));
  }

  void setDateRange(DateTimeRange range) {
    final DateTimeRange normalizedRange = _normalizedRange(range);
    _setState(
      _state.copyWith(
        year: normalizedRange.start.year,
        dateRange: normalizedRange,
      ),
    );
  }

  static ProfitLossState _initialState(DateTimeRange? initialDateRange) {
    final int year = AppClock.now.year;
    final DateTimeRange range = _normalizedRange(
      initialDateRange ?? _yearRange(year),
    );
    return ProfitLossState(
      isLoading: true,
      year: range.start.year,
      dateRange: range,
      data: const ProfitLossData(),
      errorMessage: null,
    );
  }

  static DateTimeRange _yearRange(int year) {
    return DateTimeRange(start: DateTime(year), end: DateTime(year, 12, 31));
  }

  static DateTimeRange _normalizedRange(DateTimeRange range) {
    final DateTime start = _dateOnly(range.start);
    final DateTime end = _dateOnly(range.end);
    return end.isBefore(start)
        ? DateTimeRange(start: end, end: start)
        : DateTimeRange(start: start, end: end);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  void _setState(ProfitLossState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
