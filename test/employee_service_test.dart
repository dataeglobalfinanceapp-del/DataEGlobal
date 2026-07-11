import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/local/local_employee_repository.dart';
import 'package:savetep/data/local/local_store.dart';
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
        ),
      );

      expect(updated.phone, '555-4400');
      expect((await service.loadEmployees()).single.phone, '555-4400');

      expect(await service.deleteEmployee(saved.id), isTrue);
      expect(await service.loadEmployees(), isEmpty);
    },
  );

  test('local migration clears existing employee data only once', () async {
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

    expect(await service.loadEmployees(), isEmpty);
    expect(
      storage[EmployeeDataMigration.migrationStorageKey],
      EmployeeDataMigration.employeeDataSeedVersion.toString(),
    );
    expect(
      (jsonDecode(storage['savetep_employee_data_v1']!)
          as Map<String, dynamic>)['employees'],
      isEmpty,
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

    expect(await reloadedService.loadEmployees(), hasLength(1));
    expect(
      (await reloadedService.loadEmployees()).single.fullName,
      'New Employee',
    );
  });
}
