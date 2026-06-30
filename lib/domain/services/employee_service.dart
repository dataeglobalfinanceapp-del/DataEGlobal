import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/local/local_employee_repository.dart';
import 'package:savetep/data/repositories/employee_repository.dart';

class EmployeeService {
  static EmployeeRepository _defaultRepository = LocalEmployeeRepository();

  final EmployeeRepository _repository;

  EmployeeService({EmployeeRepository? repository})
    : _repository = repository ?? _defaultRepository;

  static void configureRepository(EmployeeRepository repository) {
    _defaultRepository = repository;
  }

  static void resetForTesting({bool disablePersistence = true}) {
    _defaultRepository = LocalEmployeeRepository(
      disablePersistenceForTesting: disablePersistence,
    );
  }

  Future<List<EmployeeRecord>> loadEmployees() {
    return _repository.loadEmployees();
  }

  Future<EmployeeRecord> saveEmployee(SaveEmployeeRequest request) {
    return _repository.saveEmployee(request);
  }

  Future<bool> deleteEmployee(String id) {
    return _repository.deleteEmployee(id);
  }
}
