import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/payroll_screen/payroll_models.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_service.dart';
import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/reminder_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
    ReminderService.resetForTesting();
    PayrollService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LocalStore.resetOverridesForTesting();
    LiabilityService.resetForTesting(disablePersistence: false);
    ReminderService.resetForTesting(disablePersistence: false);
    PayrollService.resetForTesting(disablePersistence: false);
  });

  test(
    'employee payroll total includes regular, overtime, commission, and tips',
    () {
      const employee = PayrollEmployee(
        id: 'employee-1',
        name: 'Alex',
        rate: 20,
        regularHours: 40,
        overtimeHours: 10,
        commission: 50,
        tips: 25,
      );

      expect(employee.totalPay, 1175);
    },
  );

  test(
    'saving payroll syncs one payroll expense and a recurring reminder',
    () async {
      await LiabilityService.saveDeposit(
        orderNumber: 'DEP-1',
        totalAmount: 5000,
        creditDeposit: 5000,
        cash: 0,
        giftCard: 0,
        other: 0,
        transactionDate: DateTime(2026, 6, 1),
        isManual: true,
      );
      await LiabilityService.saveExpense(
        checkNumber: 'EXP-1',
        totalAmount: 500,
        transactionDate: DateTime(2026, 6, 10),
        category: 'Utilities',
        payee: 'Utilities',
        isManual: true,
      );

      final saved = await PayrollService.savePayroll(
        PayrollRecord(
          id: 'payroll-test',
          payDate: DateTime(2026, 6, 20),
          schedule: PayrollSchedule.biWeekly,
          processDaysBefore: 7,
          employees: const <PayrollEmployee>[
            PayrollEmployee(
              id: 'employee-1',
              name: 'Alex',
              rate: 20,
              regularHours: 40,
              overtimeHours: 10,
              commission: 50,
              tips: 25,
            ),
          ],
        ),
      );

      expect(saved.syncedExpenseId, isNotEmpty);
      expect(saved.reminderSeriesId, isNotEmpty);

      final expenses = await LiabilityService.loadExpenses();
      final payrollExpenses = expenses
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);

      expect(payrollExpenses, hasLength(1));
      expect(payrollExpenses.single.id, saved.syncedExpenseId);
      expect(payrollExpenses.single.checkNumber, 'PAYROLL-payroll-test');
      expect(payrollExpenses.single.totalAmount, 1175);
      expect(_dateKey(payrollExpenses.single.transactionDate), '2026-06-20');

      final reminders = await ReminderService.loadReminders();
      expect(
        reminders.any(
          (record) =>
              record.category == 'Payroll' &&
              record.amount == 1175 &&
              record.reminderCount == 'Biweekly' &&
              _dateKey(record.date) == '2026-06-13',
        ),
        true,
      );

      final updated = await PayrollService.savePayroll(
        saved.copyWith(
          payDate: DateTime(2026, 6, 21),
          schedule: PayrollSchedule.monthly,
          processDaysBefore: 5,
          employees: const <PayrollEmployee>[
            PayrollEmployee(
              id: 'employee-1',
              name: 'Alex',
              rate: 25,
              regularHours: 40,
            ),
          ],
        ),
      );

      final updatedExpenses = await LiabilityService.loadExpenses();
      final updatedPayrollExpenses = updatedExpenses
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(updatedPayrollExpenses, hasLength(1));
      expect(updatedPayrollExpenses.single.id, saved.syncedExpenseId);
      expect(updatedPayrollExpenses.single.id, updated.syncedExpenseId);
      expect(updatedPayrollExpenses.single.totalAmount, 1000);
      expect(
        _dateKey(updatedPayrollExpenses.single.transactionDate),
        '2026-06-21',
      );

      final updatedReminders = await ReminderService.loadReminders();
      expect(
        updatedReminders.where(
          (record) =>
              record.category == 'Payroll' &&
              _dateKey(record.date) == '2026-06-13',
        ),
        isEmpty,
      );
      expect(
        updatedReminders.any(
          (record) =>
              record.category == 'Payroll' &&
              record.amount == 1000 &&
              record.reminderCount == 'Monthly' &&
              _dateKey(record.date) == '2026-06-16',
        ),
        true,
      );
    },
  );

  test(
    'vacation action carries forward as a zeroed next payroll default',
    () async {
      AppClock.set(DateTime(2026, 6, 1));

      await PayrollService.savePayroll(
        PayrollRecord(
          id: 'payroll-vacation',
          payDate: DateTime(2026, 6, 20),
          schedule: PayrollSchedule.biWeekly,
          processDaysBefore: 7,
          employees: const <PayrollEmployee>[
            PayrollEmployee(
              id: 'employee-1',
              name: 'Alex',
              rate: 20,
              regularHours: 40,
              payrollAction: PayrollAction.vacation,
              isPayrollConfirmed: true,
            ),
          ],
        ),
      );

      AppClock.set(DateTime(2026, 6, 14));
      final currentPayroll = await PayrollService.loadCurrentPayroll();

      expect(currentPayroll.payDate, DateTime(2026, 7, 4));
      expect(currentPayroll.biweeklyPeriodBeginDate, DateTime(2026, 6, 1));
      expect(
        currentPayroll.employees.single.payrollAction,
        PayrollAction.vacation,
      );
      expect(currentPayroll.employees.single.isPayrollConfirmed, isFalse);
      expect(currentPayroll.employees.single.totalPay, 0);
    },
  );

  test('saving a draft normalizes invalid pay dates before storage', () async {
    final saved = await PayrollService.savePayrollDraft(
      PayrollRecord(
        id: 'payroll-invalid-date',
        payDate: DateTime(2026, 6, 15),
        biweeklyPeriodBeginDate: DateTime(2026, 4, 30),
        schedule: PayrollSchedule.biWeekly,
        processDaysBefore: 7,
        employees: const <PayrollEmployee>[],
      ),
    );
    final payrolls = await PayrollService.loadPayrolls();

    expect(saved.payDate, DateTime(2026, 6, 16));
    expect(saved.biweeklyPeriodBeginDate, DateTime(2026, 6, 1));
    expect(payrolls.single.payDate, DateTime(2026, 6, 16));
    expect(payrolls.single.biweeklyPeriodBeginDate, DateTime(2026, 6, 1));
  });

  test(
    'local migration strips persisted employee rows from payroll snapshots once',
    () async {
      final Map<String, String> storage = <String, String>{
        'savetep_payroll_data_v1': jsonEncode(
          PayrollSnapshot(
            records: <PayrollRecord>[
              PayrollRecord(
                id: 'payroll-with-seed-employees',
                payDate: DateTime(2026, 6, 30),
                schedule: PayrollSchedule.monthly,
                processDaysBefore: 5,
                syncedExpenseId: 'expense-payroll-old',
                reminderSeriesId: 'reminder-series-old',
                employees: const <PayrollEmployee>[
                  PayrollEmployee(
                    id: 'employee-jack-nicholson',
                    name: 'Jack Nicholson',
                    rate: 20,
                    regularHours: 40,
                    isPayrollConfirmed: true,
                  ),
                ],
              ),
            ],
          ).toJson(),
        ),
      };
      LocalStore.setOverridesForTesting(
        read: (String key) async => storage[key],
        write: (String key, String value) async => storage[key] = value,
      );
      PayrollService.resetForTesting(disablePersistence: false);

      final PayrollRecord migrated = await PayrollService.loadCurrentPayroll();
      final PayrollSnapshot storedSnapshot = PayrollSnapshot.fromJson(
        jsonDecode(storage['savetep_payroll_data_v1']!) as Map<String, dynamic>,
      );

      expect(migrated.employees, isEmpty);
      expect(migrated.syncedExpenseId, isEmpty);
      expect(migrated.reminderSeriesId, isEmpty);
      expect(migrated.schedule, PayrollSchedule.monthly);
      expect(migrated.processDaysBefore, 5);
      expect(storedSnapshot.records.single.employees, isEmpty);
      expect(storedSnapshot.records.single.syncedExpenseId, isEmpty);
      expect(storedSnapshot.records.single.reminderSeriesId, isEmpty);
      expect(storage['savetep_payroll_employee_data_cleanup_version'], '1');

      await PayrollService.savePayrollDraft(
        migrated.copyWith(
          employees: const <PayrollEmployee>[
            PayrollEmployee(id: 'employee-new', name: 'New Employee'),
          ],
        ),
      );
      PayrollService.resetForTesting(disablePersistence: false);

      final PayrollRecord reloaded = await PayrollService.loadCurrentPayroll();
      expect(reloaded.employees, hasLength(1));
      expect(reloaded.employees.single.name, 'New Employee');
    },
  );
}

String _dateKey(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
