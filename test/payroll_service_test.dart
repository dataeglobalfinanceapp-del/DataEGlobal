import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_models.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_service.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
    PayrollService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LocalStore.resetOverridesForTesting();
    LiabilityService.resetForTesting(disablePersistence: false);
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
    'saving payroll persists without syncing an aggregate expense',
    () async {
      final saved = await PayrollService.savePayroll(
        PayrollRecord(
          id: 'payroll-test',
          payDate: DateTime(2026, 6, 20),
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

      expect(saved.syncedExpenseId, isEmpty);

      final expenses = await LiabilityService.loadExpenses();
      final payrollExpenses = expenses
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);

      expect(payrollExpenses, isEmpty);

      final updated = await PayrollService.savePayroll(
        saved.copyWith(
          payDate: DateTime(2026, 6, 21),
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
      final payrollExpensesAfterUpdate = updatedExpenses
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(updated.syncedExpenseId, isEmpty);
      expect(payrollExpensesAfterUpdate, isEmpty);
    },
  );

  test('saving a draft normalizes invalid pay dates before storage', () async {
    final saved = await PayrollService.savePayrollDraft(
      PayrollRecord(
        id: 'payroll-invalid-date',
        payDate: DateTime(2026, 6, 15),
        employees: const <PayrollEmployee>[],
      ),
    );
    final payrolls = await PayrollService.loadPayrolls();

    expect(saved.payDate, DateTime(2026, 6, 16));
    expect(payrolls.single.payDate, DateTime(2026, 6, 16));
  });

  test(
    'local migration strips persisted employee rows from payroll snapshots once',
    () async {
      final Map<String, String> storage = <String, String>{
        'savetep_payroll_data_v1': jsonEncode(<String, Object?>{
          'records': <Map<String, Object?>>[
            <String, Object?>{
              'id': 'payroll-with-seed-employees',
              'payDate': '2026-06-30T00:00:00.000',
              'syncedExpenseId': 'expense-payroll-old',
              'employees': <Map<String, Object?>>[
                <String, Object?>{
                  'id': 'employee-jack-nicholson',
                  'name': 'Jack Nicholson',
                  'rate': 20,
                  'regularHours': 40,
                  'isPayrollConfirmed': true,
                },
              ],
            },
          ],
        }),
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
      expect(storedSnapshot.records.single.employees, isEmpty);
      expect(storedSnapshot.records.single.syncedExpenseId, isEmpty);
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
