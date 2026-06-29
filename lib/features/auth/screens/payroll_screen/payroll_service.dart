import 'dart:convert';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/reminder_service.dart';

import 'payroll_models.dart';

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

    final int index = _records.indexWhere(
      (PayrollRecord record) => record.id == saved.id,
    );
    if (index == -1) {
      _records.add(saved);
    } else {
      _records[index] = saved;
    }

    await _persist();
    return saved;
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
