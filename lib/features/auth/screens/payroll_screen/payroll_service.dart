import 'dart:convert';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/recurrence_schedule.dart';
import 'package:savetep/services/reminder_service.dart';

import 'payroll_models.dart';
import 'payroll_pay_date_validator.dart';
import 'payroll_schedule_calculator.dart';

class PayrollService {
  static const String _storageKey = 'savetep_payroll_data_v1';

  static final List<PayrollRecord> _records = <PayrollRecord>[];
  static bool _loaded = false;
  static bool _disablePersistenceForTesting = false;
  static int _idCounter = 0;

  PayrollService._();

  static Future<PayrollRecord> loadCurrentPayroll() async {
    await _ensureLoaded();
    if (_records.isEmpty) {
      return PayrollRecord.draft(id: _newId('payroll'));
    }

    return _rollCurrentPayrollForwardIfNeeded();
  }

  static Future<PayrollRecord> _rollCurrentPayrollForwardIfNeeded() async {
    var current = _latestPayrollRecord();
    var changed = false;
    final DateTime today = RecurrenceSchedule.dateOnly(AppClock.now);

    while (today.isAfter(current.processDate)) {
      final bool missedConfirmation = !current.allEmployeesConfirmed;
      if (missedConfirmation) {
        current = await _saveMissedPayrollAsZero(current);
      } else {
        current = await savePayroll(current);
      }

      final nextPayroll = _nextPayrollFrom(
        current,
        forceClearedPayroll: missedConfirmation,
      );
      _upsertPayroll(nextPayroll);
      current = nextPayroll;
      changed = true;
    }

    if (changed) await _persist();
    return current;
  }

  static PayrollRecord _latestPayrollRecord() {
    final records = List<PayrollRecord>.from(_records)
      ..sort((PayrollRecord a, PayrollRecord b) {
        final dateCompare = b.payDate.compareTo(a.payDate);
        if (dateCompare != 0) return dateCompare;
        return b.id.compareTo(a.id);
      });
    return records.first;
  }

  static Future<List<PayrollRecord>> loadPayrolls() async {
    await _ensureLoaded();
    final records = List<PayrollRecord>.from(_records)
      ..sort(
        (PayrollRecord a, PayrollRecord b) => b.payDate.compareTo(a.payDate),
      );
    return List<PayrollRecord>.unmodifiable(records);
  }

  static Future<PayrollRecord> savePayroll(PayrollRecord payroll) async {
    await _ensureLoaded();

    PayrollRecord saved = payroll.id.trim().isEmpty
        ? payroll.copyWith(id: _newId('payroll'))
        : payroll;
    saved = _withValidPayDate(saved);

    final String? syncedExpenseId = await LiabilityService.syncPayrollExpense(
      payrollId: saved.id,
      existingExpenseId: saved.syncedExpenseId,
      totalAmount: saved.totalPay,
      payDate: saved.payDate,
    );
    final String reminderSeriesId = saved.reminderSeriesId.trim().isEmpty
        ? _newId('payroll-reminder')
        : saved.reminderSeriesId;

    await ReminderService.syncRecurringReminderSeries(
      seriesId: reminderSeriesId,
      startDate: saved.processDate,
      category: 'Payroll',
      amount: saved.totalPay,
      reminderCount: saved.schedule.reminderFrequency,
      payee: 'Payroll',
    );

    saved = saved.copyWith(
      syncedExpenseId: syncedExpenseId ?? '',
      reminderSeriesId: reminderSeriesId,
    );

    _upsertPayroll(saved);

    await _persist();
    return saved;
  }

  static Future<PayrollRecord> savePayrollDraft(
    PayrollRecord payroll, {
    bool clearPayrollExpense = false,
  }) async {
    await _ensureLoaded();

    PayrollRecord saved = payroll.id.trim().isEmpty
        ? payroll.copyWith(id: _newId('payroll'))
        : payroll;
    saved = _withValidPayDate(saved);

    if (clearPayrollExpense && saved.syncedExpenseId.trim().isNotEmpty) {
      await LiabilityService.syncPayrollExpense(
        payrollId: saved.id,
        existingExpenseId: saved.syncedExpenseId,
        totalAmount: 0,
        payDate: saved.payDate,
      );
      saved = saved.copyWith(syncedExpenseId: '');
    }

    _upsertPayroll(saved);
    await _persist();
    return saved;
  }

  static Future<PayrollRecord> _saveMissedPayrollAsZero(
    PayrollRecord payroll,
  ) async {
    final PayrollRecord clearedPayroll = payroll.copyWith(
      employees: payroll.employees
          .map(
            (PayrollEmployee employee) =>
                employee.withClearedPayroll.copyWith(isPayrollConfirmed: false),
          )
          .toList(growable: false),
    );

    return savePayrollDraft(clearedPayroll, clearPayrollExpense: true);
  }

  static PayrollRecord _nextPayrollFrom(
    PayrollRecord payroll, {
    required bool forceClearedPayroll,
  }) {
    final employees = payroll.employees
        .map((PayrollEmployee employee) {
          final PayrollAction nextAction = employee.payrollAction.nextDefault;
          final PayrollEmployee nextEmployee = employee.copyWith(
            payrollAction: nextAction,
            isPayrollConfirmed: false,
          );
          if (forceClearedPayroll || nextAction.clearsPayroll) {
            return nextEmployee.withClearedPayroll;
          }
          return nextEmployee;
        })
        .toList(growable: false);

    return PayrollRecord(
      id: _newId('payroll'),
      payDate: _nextPayDate(payroll),
      biweeklyPeriodBeginDate: _nextBiweeklyPeriodBeginDate(payroll),
      schedule: payroll.schedule,
      processDaysBefore: payroll.processDaysBefore,
      employees: employees,
    );
  }

  static DateTime _nextPayDate(PayrollRecord payroll) {
    final payDate = RecurrenceSchedule.dateOnly(payroll.payDate);
    return switch (payroll.schedule) {
      PayrollSchedule.biWeekly => payDate.add(const Duration(days: 14)),
      PayrollSchedule.monthly => _addMonthsClamped(payDate, 1),
    };
  }

  static DateTime _nextBiweeklyPeriodBeginDate(PayrollRecord payroll) {
    if (payroll.schedule != PayrollSchedule.biWeekly) {
      return payroll.biweeklyPeriodBeginDate;
    }

    return payroll.biweeklyPeriodBeginDate.add(
      const Duration(days: PayrollScheduleCalculator.biweeklyPeriodDays),
    );
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = _minInt(date.day, DateTime(year, month + 1, 0).day);
    return DateTime(year, month, day);
  }

  static void _upsertPayroll(PayrollRecord payroll) {
    final PayrollRecord validPayroll = _withValidPayDate(payroll);
    final int index = _records.indexWhere(
      (PayrollRecord record) => record.id == validPayroll.id,
    );
    if (index == -1) {
      _records.add(validPayroll);
    } else {
      _records[index] = validPayroll;
    }
  }

  static PayrollRecord _withValidPayDate(PayrollRecord payroll) {
    final DateTime validPayDate = PayrollPayDateValidator.normalizePayDate(
      payroll.payDate,
    );
    if (RecurrenceSchedule.isSameDate(payroll.payDate, validPayDate)) {
      return payroll;
    }

    return payroll.copyWith(payDate: validPayDate);
  }

  static void resetForTesting({bool disablePersistence = true}) {
    _records.clear();
    _idCounter = 0;
    _loaded = disablePersistence;
    _disablePersistenceForTesting = disablePersistence;
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;

    final String? raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _loaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _loaded = true;
        return;
      }

      final snapshot = PayrollSnapshot.fromJson(decoded);
      _records
        ..clear()
        ..addAll(snapshot.records);
    } catch (_) {
      _records.clear();
    }

    _loaded = true;
  }

  static Future<void> _persist() async {
    if (_disablePersistenceForTesting) return;

    await LocalStore.write(
      _storageKey,
      jsonEncode(PayrollSnapshot(records: _records).toJson()),
    );
  }

  static String _newId(String prefix) {
    return '$prefix-${AppClock.now.microsecondsSinceEpoch}-${_idCounter++}';
  }

  static int _minInt(int a, int b) => a < b ? a : b;
}

class PayrollSnapshot {
  final List<PayrollRecord> records;

  const PayrollSnapshot({required this.records});

  factory PayrollSnapshot.fromJson(Map<dynamic, dynamic> json) {
    final recordsJson = json['records'];
    final records = recordsJson is List
        ? recordsJson
              .whereType<Map>()
              .map(PayrollRecord.fromJson)
              .toList(growable: false)
        : const <PayrollRecord>[];
    return PayrollSnapshot(records: List<PayrollRecord>.unmodifiable(records));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'records': records
        .map((PayrollRecord record) => record.toJson())
        .toList(growable: false),
  };
}
