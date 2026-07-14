import 'dart:convert';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/services/liability_service.dart';

import 'payroll_models.dart';
import 'payroll_pay_date_validator.dart';

class PayrollService {
  static const String _storageKey = 'savetep_payroll_data_v1';
  static const String _employeeDataMigrationStorageKey =
      'savetep_payroll_employee_data_cleanup_version';
  static const int _employeeDataSeedVersion = 1;

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

    return _latestPayrollRecord();
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
    saved = saved.copyWith(syncedExpenseId: syncedExpenseId ?? '');

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
    if (_isSameDate(payroll.payDate, validPayDate)) {
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
      await _clearSeedEmployeeDataIfNeeded();
      _loaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await _clearSeedEmployeeDataIfNeeded();
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

    await _clearSeedEmployeeDataIfNeeded();
    _loaded = true;
  }

  static Future<void> _clearSeedEmployeeDataIfNeeded() async {
    if (_disablePersistenceForTesting) return;

    final String? version = await LocalStore.read(
      _employeeDataMigrationStorageKey,
    );
    if (version == _employeeDataSeedVersion.toString()) return;

    final bool changed = _clearEmployeeDataFromRecords();
    if (changed) await _persist();

    await LocalStore.write(
      _employeeDataMigrationStorageKey,
      _employeeDataSeedVersion.toString(),
    );
  }

  static bool _clearEmployeeDataFromRecords() {
    var changed = false;

    for (var index = 0; index < _records.length; index += 1) {
      final PayrollRecord payroll = _records[index];
      final bool hasEmployeeData =
          payroll.employees.isNotEmpty ||
          payroll.syncedExpenseId.trim().isNotEmpty;
      if (!hasEmployeeData) continue;

      _records[index] = payroll.copyWith(
        employees: const <PayrollEmployee>[],
        syncedExpenseId: '',
      );
      changed = true;
    }

    return changed;
  }

  static Future<void> _persist() async {
    if (_disablePersistenceForTesting) return;

    await LocalStore.write(
      _storageKey,
      jsonEncode(PayrollSnapshot(records: _records).toJson()),
    );
  }

  static String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
  }
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
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
