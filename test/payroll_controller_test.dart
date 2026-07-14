import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/local/default_employee_seed_data.dart';
import 'package:savetep/data/local/local_employee_repository.dart';
import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/data/repositories/employee_repository.dart';
import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/domain/services/employee_service.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_controller.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_models.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_service.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
    PayrollService.resetForTesting();
    EmployeeService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
    PayrollService.resetForTesting(disablePersistence: false);
    EmployeeService.resetForTesting(disablePersistence: false);
    LocalStore.resetOverridesForTesting();
  });

  test('pay date updates normalize today and past dates to tomorrow', () async {
    final PayrollController controller = PayrollController();
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 16));

    controller.setPayDate(DateTime(2026, 6, 15));
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 16));

    controller.setPayDate(DateTime(2026, 6, 1));
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 16));

    controller.setPayDate(DateTime(2026, 6, 17));
    expect(controller.state.payroll.payDate, DateTime(2026, 6, 17));
  });

  test(
    'loads default local employees when employee storage is empty',
    () async {
      final Map<String, String> storage = <String, String>{};
      LocalStore.setOverridesForTesting(
        read: (String key) async => storage[key],
        write: (String key, String value) async => storage[key] = value,
      );
      EmployeeService.configureRepository(LocalEmployeeRepository());

      final PayrollController controller = PayrollController();
      addTearDown(controller.dispose);

      await controller.load();

      expect(
        controller.state.payroll.employees,
        hasLength(DefaultEmployeeSeedData.employees.length),
      );
      expect(
        controller.state.payroll.employees.map((employee) => employee.name),
        DefaultEmployeeSeedData.employees.map((employee) => employee.fullName),
      );
      expect(
        controller.state.payroll.employees.map((employee) => employee.rate),
        <double>[20, 16.9, 20, 17.5, 18.5, 25],
      );
    },
  );

  test(
    'confirming all employee payrolls syncs expense and persists values',
    () async {
      final PayrollController controller = PayrollController();
      addTearDown(controller.dispose);

      await _seedPayrollEmployees();
      await controller.load();
      controller.setPayDate(DateTime(2026, 6, 29));
      final firstEmployee = controller.state.payroll.employees.first;

      await controller.updateEmployee(
        firstEmployee.id,
        rate: 20,
        regularHours: 40,
        overtimeHours: 10,
        commission: 5,
        tips: 2,
        confirmPayroll: true,
      );

      var payrollExpenses = (await LiabilityService.loadExpenses())
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, isEmpty);

      for (final employee in controller.state.payroll.employees.skip(1)) {
        await controller.updateEmployee(employee.id, confirmPayroll: true);
      }

      payrollExpenses = (await LiabilityService.loadExpenses())
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, hasLength(1));
      expect(payrollExpenses.single.totalAmount, 1107);
      expect(payrollExpenses.single.transactionDate, DateTime(2026, 6, 29));

      await controller.updateEmployee(
        firstEmployee.id,
        rate: 20,
        regularHours: 40,
        overtimeHours: 10,
        commission: 5,
        tips: 3,
        confirmPayroll: true,
      );

      payrollExpenses = (await LiabilityService.loadExpenses())
          .where((record) => record.category == 'Payroll')
          .toList(growable: false);
      expect(payrollExpenses, hasLength(1));
      expect(payrollExpenses.single.totalAmount, 1108);

      final PayrollController reloadedController = PayrollController();
      addTearDown(reloadedController.dispose);

      await reloadedController.load();
      final reloadedEmployee = reloadedController.state.payroll.employees.first;
      expect(reloadedEmployee.tips, 3);
      expect(reloadedEmployee.totalPay, 1108);
      expect(reloadedController.state.payroll.allEmployeesConfirmed, isTrue);
    },
  );

  test('confirming payroll updates one employee row only', () async {
    EmployeeService.configureRepository(
      _InMemoryEmployeeRepository(<EmployeeRecord>[
        const EmployeeRecord(
          id: 'employee-shared',
          fullName: 'Maya Rodriguez',
          birthday: '03/14/1992',
          phone: '555-0148',
          address: '214 Maple Avenue',
          dateHire: '01/08/2024',
          jobType: 'Hourly',
          rate: 20,
        ),
        const EmployeeRecord(
          id: 'employee-shared',
          fullName: 'Noah Bennett',
          birthday: '09/27/1998',
          phone: '555-0263',
          address: '87 Cedar Lane',
          dateHire: '03/18/2024',
          jobType: 'Part Time',
          rate: 16.9,
        ),
      ]),
    );
    final PayrollController controller = PayrollController();
    addTearDown(controller.dispose);

    await controller.load();
    controller.setPayDate(DateTime(2026, 6, 29));

    await controller.updateEmployee(
      'employee-shared',
      rate: 20,
      regularHours: 10,
      overtimeHours: 1,
      commission: 5,
      tips: 2,
      confirmPayroll: true,
    );

    final List<PayrollEmployee> employees = controller.state.payroll.employees;
    expect(employees, hasLength(2));
    expect(employees.first.name, 'Maya Rodriguez');
    expect(employees.first.regularHours, 10);
    expect(employees.first.overtimeHours, 1);
    expect(employees.first.commission, 5);
    expect(employees.first.tips, 2);
    expect(employees.first.isPayrollConfirmed, isTrue);
    expect(employees.first.totalPay, 237);

    expect(employees.last.name, 'Noah Bennett');
    expect(employees.last.rate, 16.9);
    expect(employees.last.regularHours, 0);
    expect(employees.last.overtimeHours, 0);
    expect(employees.last.commission, 0);
    expect(employees.last.tips, 0);
    expect(employees.last.isPayrollConfirmed, isFalse);
    expect(employees.last.totalPay, 0);
    expect(controller.state.payroll.totalPay, 237);
  });

  test('payroll setting updates and persists one employee only', () async {
    EmployeeService.configureRepository(
      _InMemoryEmployeeRepository(<EmployeeRecord>[
        const EmployeeRecord(
          id: 'employee-maya',
          fullName: 'Maya Rodriguez',
          birthday: '03/14/1992',
          phone: '555-0148',
          address: '214 Maple Avenue',
          dateHire: '07/13/2026',
          jobType: 'Hourly',
          rate: 20,
        ),
        const EmployeeRecord(
          id: 'employee-noah',
          fullName: 'Noah Bennett',
          birthday: '09/27/1998',
          phone: '555-0263',
          address: '87 Cedar Lane',
          dateHire: '03/18/2024',
          jobType: 'Part Time',
          rate: 16.9,
        ),
      ]),
    );
    final PayrollController controller = PayrollController();
    addTearDown(controller.dispose);

    await controller.load();

    final setting = EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.weekly,
      endingDay: EmployeePayrollEndingDay.friday,
      firstPeriodEndDate: DateTime(2026, 7, 17),
      payDateSetting: EmployeePayDateSetting.sameDay,
      processPayrollSetting: EmployeeProcessPayrollSetting.oneDayBeforePayDate,
    );
    await controller.updateEmployeePayrollSetting('employee-maya', setting);

    final List<PayrollEmployee> employees = controller.state.payroll.employees;
    expect(employees.first.payrollSetting, setting);
    expect(employees.last.payrollSetting, isNot(setting));
    expect(employees.first.isPayrollConfirmed, isFalse);
    expect(employees.first.totalPay, 0);

    final List<EmployeeRecord> savedEmployees = await EmployeeService()
        .loadEmployees();
    expect(savedEmployees.first.payrollSetting, setting);
    expect(savedEmployees.last.payrollSetting, isNull);

    final PayrollController reloadedController = PayrollController();
    addTearDown(reloadedController.dispose);
    await reloadedController.load();

    expect(
      reloadedController.state.payroll.employees.first.payrollSetting,
      setting,
    );
  });
}

class _InMemoryEmployeeRepository implements EmployeeRepository {
  final List<EmployeeRecord> _employees;

  _InMemoryEmployeeRepository(List<EmployeeRecord> employees)
    : _employees = List<EmployeeRecord>.of(employees);

  @override
  Future<List<EmployeeRecord>> loadEmployees() async {
    return List<EmployeeRecord>.unmodifiable(_employees);
  }

  @override
  Future<EmployeeRecord> saveEmployee(SaveEmployeeRequest request) async {
    final EmployeeRecord record = EmployeeRecord.fromRequest(
      id: request.id,
      request: request,
    );
    final int index = _employees.indexWhere(
      (EmployeeRecord employee) => employee.id == record.id,
    );
    if (index == -1) {
      _employees.add(record);
    } else {
      _employees[index] = record;
    }
    return record;
  }

  @override
  Future<bool> deleteEmployee(String id) async {
    final int index = _employees.indexWhere(
      (EmployeeRecord employee) => employee.id == id,
    );
    if (index == -1) return false;

    _employees.removeAt(index);
    return true;
  }
}

Future<void> _seedPayrollEmployees() async {
  final EmployeeService service = EmployeeService();
  await service.saveEmployee(
    const SaveEmployeeRequest(
      id: 'employee-alex',
      fullName: 'Alex Morgan',
      birthday: '04/22/1988',
      phone: '555-2601',
      address: '195 Spruce Ave',
      dateHire: '06/01/2025',
      jobType: 'Hourly',
      rate: 20,
    ),
  );
  await service.saveEmployee(
    const SaveEmployeeRequest(
      id: 'employee-jordan',
      fullName: 'Jordan Lee',
      birthday: '11/08/1991',
      phone: '555-7194',
      address: '84 Market Street',
      dateHire: '06/01/2025',
      jobType: 'Hourly',
      rate: 18,
    ),
  );
}
