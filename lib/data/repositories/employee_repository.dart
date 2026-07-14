import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/domain/models/employee_payroll_setting.dart';

class EmployeeRecord {
  final String id;
  final String fullName;
  final String birthday;
  final String phone;
  final String address;
  final String dateHire;
  final String jobType;
  final double rate;
  final String payMethod;
  final String linkW4;
  final EmployeePayrollSetting? payrollSetting;

  const EmployeeRecord({
    required this.id,
    required this.fullName,
    required this.birthday,
    required this.phone,
    required this.address,
    required this.dateHire,
    required this.jobType,
    required this.rate,
    this.payMethod = '',
    this.linkW4 = '',
    this.payrollSetting,
  });

  factory EmployeeRecord.fromJson(Map<dynamic, dynamic> json) {
    return EmployeeRecord(
      id: _asString(json['id']),
      fullName: _asString(json['fullName']),
      birthday: _asString(json['birthday']),
      phone: _asString(json['phone']),
      address: _asString(json['address']),
      dateHire: _asString(json['dateHire']),
      jobType: _asString(json['jobType']),
      rate: _asDouble(json['rate']),
      payMethod: _asString(json['payMethod']),
      linkW4: _asString(json['linkW4']),
      payrollSetting: employeePayrollSettingFromJson(json['payrollSetting']),
    );
  }

  factory EmployeeRecord.fromRequest({
    required String id,
    required SaveEmployeeRequest request,
  }) {
    return EmployeeRecord(
      id: id,
      fullName: request.fullName,
      birthday: request.birthday,
      phone: request.phone,
      address: request.address,
      dateHire: request.dateHire,
      jobType: request.jobType,
      rate: request.rate,
      payMethod: request.payMethod,
      linkW4: request.linkW4,
      payrollSetting: request.payrollSetting,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'fullName': fullName,
    'birthday': birthday,
    'phone': phone,
    'address': address,
    'dateHire': dateHire,
    'jobType': jobType,
    'rate': rate,
    'payMethod': payMethod,
    'linkW4': linkW4,
    if (payrollSetting != null) 'payrollSetting': payrollSetting!.toJson(),
  };
}

abstract class EmployeeRepository {
  Future<List<EmployeeRecord>> loadEmployees();

  Future<EmployeeRecord> saveEmployee(SaveEmployeeRequest request);

  Future<bool> deleteEmployee(String id);
}

String _asString(Object? value) => value?.toString() ?? '';

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
