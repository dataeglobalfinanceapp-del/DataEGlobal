import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/local/default_employee_seed_data.dart';
import 'package:savetep/data/local/local_employee_repository.dart';
import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/domain/services/employee_service.dart';
import 'package:savetep/services/app_clock.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
  });

  tearDown(() {
    AppClock.reset();
    LocalStore.resetOverridesForTesting();
  });

  test(
    'saves, updates, loads, and removes employees through the service',
    () async {
      final EmployeeService service = EmployeeService(
        repository: LocalEmployeeRepository(disablePersistenceForTesting: true),
      );

      final saved = await service.saveEmployee(
        const SaveEmployeeRequest(
          fullName: 'Taylor Reed',
          birthday: '06/15/1990',
          phone: '555-3399',
          address: '500 Market Street, San Francisco, CA 94105',
          dateHire: '06/15/2026',
          jobType: 'Hourly',
          rate: 24.5,
          payMethod: 'Direct Deposit',
          linkW4: 'https://example.com/taylor-w4.pdf',
        ),
      );

      expect(saved.id, isNotEmpty);
      expect(await service.loadEmployees(), hasLength(1));

      final updated = await service.saveEmployee(
        SaveEmployeeRequest(
          id: saved.id,
          fullName: saved.fullName,
          birthday: saved.birthday,
          phone: '555-4400',
          address: saved.address,
          dateHire: saved.dateHire,
          jobType: saved.jobType,
          rate: saved.rate,
          payMethod: saved.payMethod,
          linkW4: saved.linkW4,
          payrollSetting: EmployeePayrollSetting(
            schedule: EmployeePayrollSchedule.biWeekly,
            endingDay: EmployeePayrollEndingDay.sunday,
            firstPeriodEndDate: DateTime(2026, 6, 21),
            paidAfterPeriodEndDays: 3,
            remindAfterPeriodEndDays: 2,
          ),
        ),
      );

      expect(updated.phone, '555-4400');
      expect(updated.payrollSetting?.firstPeriodEndDate, DateTime(2026, 6, 21));
      expect(updated.payrollSetting?.paidAfterPeriodEndDays, 3);
      expect(updated.payrollSetting?.remindAfterPeriodEndDays, 2);
      expect((await service.loadEmployees()).single.phone, '555-4400');
      expect(
        (await service.loadEmployees()).single.payrollSetting?.schedule,
        EmployeePayrollSchedule.biWeekly,
      );
      expect(
        (await service.loadEmployees())
            .single
            .payrollSetting
            ?.paidAfterPeriodEndDays,
        3,
      );
      expect(
        (await service.loadEmployees())
            .single
            .payrollSetting
            ?.remindAfterPeriodEndDays,
        2,
      );

      expect(await service.deleteEmployee(saved.id), isTrue);
      expect(await service.loadEmployees(), isEmpty);
    },
  );

  test(
    'local repository seeds default employees when storage is empty',
    () async {
      final Map<String, String> storage = <String, String>{};
      LocalStore.setOverridesForTesting(
        read: (String key) async => storage[key],
        write: (String key, String value) async => storage[key] = value,
      );

      final EmployeeService service = EmployeeService(
        repository: LocalEmployeeRepository(),
      );

      final employees = await service.loadEmployees();

      expect(employees, hasLength(DefaultEmployeeSeedData.employees.length));
      expect(
        employees.map((employee) => employee.fullName),
        DefaultEmployeeSeedData.employees.map((employee) => employee.fullName),
      );
      expect(employees.map((employee) => employee.rate), <double>[
        20,
        16.9,
        20,
        17.5,
        18.5,
        25,
      ]);

      final Map<String, dynamic> stored =
          jsonDecode(storage['savetep_employee_data_v1']!)
              as Map<String, dynamic>;
      expect(
        stored['defaultEmployeeSeedVersion'],
        DefaultEmployeeSeedData.version,
      );
      expect(
        stored['employees'],
        hasLength(DefaultEmployeeSeedData.employees.length),
      );

      final EmployeeService reloadedService = EmployeeService(
        repository: LocalEmployeeRepository(),
      );

      expect(
        await reloadedService.loadEmployees(),
        hasLength(DefaultEmployeeSeedData.employees.length),
      );
    },
  );

  test('local repository leaves non-empty employee storage unseeded', () async {
    final Map<String, String> storage = <String, String>{
      'savetep_employee_data_v1': jsonEncode(<String, dynamic>{
        'employees': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'employee-existing',
            'fullName': 'Existing Employee',
            'birthday': '08/12/1993',
            'phone': '555-2200',
            'address': '123 Existing Avenue',
            'dateHire': '02/03/2025',
            'jobType': 'Hourly',
            'rate': 22,
          },
        ],
      }),
    };
    LocalStore.setOverridesForTesting(
      read: (String key) async => storage[key],
      write: (String key, String value) async => storage[key] = value,
    );

    final EmployeeService service = EmployeeService(
      repository: LocalEmployeeRepository(),
    );

    final employees = await service.loadEmployees();

    expect(employees, hasLength(1));
    expect(employees.single.fullName, 'Existing Employee');
    expect(employees.single.rate, 22);
  });

  test('local migration replaces legacy seed data only once', () async {
    final Map<String, String> storage = <String, String>{
      'savetep_employee_data_v1': jsonEncode(<String, dynamic>{
        'employees': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'employee-jack-nicholson',
            'fullName': 'Jack Nicholson',
            'birthday': '04/22/1988',
            'phone': '555-2601',
            'address': '195 Spruce Ave',
            'dateHire': '',
            'jobType': 'Hourly',
            'rate': 20,
          },
        ],
      }),
    };
    LocalStore.setOverridesForTesting(
      read: (String key) async => storage[key],
      write: (String key, String value) async => storage[key] = value,
    );

    final EmployeeService service = EmployeeService(
      repository: LocalEmployeeRepository(),
    );

    expect(
      await service.loadEmployees(),
      hasLength(DefaultEmployeeSeedData.employees.length),
    );
    expect(
      storage[EmployeeDataMigration.migrationStorageKey],
      EmployeeDataMigration.employeeDataSeedVersion.toString(),
    );
    expect(
      (await service.loadEmployees()).map((employee) => employee.fullName),
      DefaultEmployeeSeedData.employees.map((employee) => employee.fullName),
    );

    await service.saveEmployee(
      const SaveEmployeeRequest(
        fullName: 'New Employee',
        birthday: '',
        phone: '',
        address: '100 Pine Street',
        dateHire: '',
        jobType: 'Hourly',
        rate: 18,
      ),
    );

    final EmployeeService reloadedService = EmployeeService(
      repository: LocalEmployeeRepository(),
    );

    expect(
      await reloadedService.loadEmployees(),
      hasLength(DefaultEmployeeSeedData.employees.length + 1),
    );
    expect(
      (await reloadedService.loadEmployees()).last.fullName,
      'New Employee',
    );
  });
}
