import 'package:savetep/domain/services/employee_document_email_service.dart';

EmployeeDocumentEmailService createEmployeeDocumentEmailService() {
  return const UnsupportedEmployeeDocumentEmailService();
}

class UnsupportedEmployeeDocumentEmailService
    implements EmployeeDocumentEmailService {
  const UnsupportedEmployeeDocumentEmailService();

  @override
  Future<void> sendW4Email(W4EmailRequest request) {
    throw const EmployeeDocumentEmailException(
      'Email sending is not available on this platform.',
    );
  }
}
