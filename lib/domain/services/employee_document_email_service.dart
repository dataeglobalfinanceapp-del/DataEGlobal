import 'package:savetep/domain/models/temporary_employee_document.dart';
import 'package:savetep/domain/models/temporary_employee_sensitive_data.dart';

class W4EmailEmployeeDetails {
  final String fullName;
  final String birthday;
  final String phone;
  final String address;
  final String dateHire;
  final String jobType;
  final double rate;
  final String payMethod;

  const W4EmailEmployeeDetails({
    required this.fullName,
    required this.birthday,
    required this.phone,
    required this.address,
    required this.dateHire,
    required this.jobType,
    required this.rate,
    required this.payMethod,
  });
}

class W4EmailRequest {
  final String recipientEmail;
  final W4EmailEmployeeDetails employeeDetails;
  final String linkW4;
  final TemporaryEmployeeSensitiveData sensitiveData;

  const W4EmailRequest({
    required this.recipientEmail,
    required this.employeeDetails,
    required this.linkW4,
    this.sensitiveData = const TemporaryEmployeeSensitiveData(),
  });

  String get normalizedRecipientEmail => recipientEmail.trim();

  String get employeeName => employeeDetails.fullName;

  String get socialSecurityNumber =>
      sensitiveData.formattedSocialSecurityNumber;

  bool get hasSocialSecurityNumber => sensitiveData.hasSocialSecurityNumber;

  TemporaryEmployeeDocument? get temporaryDocument => sensitiveData.w4Document;

  bool get hasTemporaryDocument => temporaryDocument != null;

  String get displayEmployeeName {
    final String trimmedName = employeeDetails.fullName.trim();
    return trimmedName.isEmpty ? 'Employee' : trimmedName;
  }
}

abstract class EmployeeDocumentEmailService {
  const EmployeeDocumentEmailService();

  Future<void> sendW4Email(W4EmailRequest request);
}

class EmployeeDocumentEmailException implements Exception {
  final String message;

  const EmployeeDocumentEmailException(this.message);

  @override
  String toString() => message;
}
