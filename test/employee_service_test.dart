import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/local/local_employee_repository.dart';
import 'package:savetep/domain/services/employee_service.dart';
import 'package:savetep/services/app_clock.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
  });

  tearDown(AppClock.reset);

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
}
