class W4EmailRequest {
  final String recipientEmail;
  final String employeeName;
  final String linkW4;

  const W4EmailRequest({
    required this.recipientEmail,
    required this.employeeName,
    required this.linkW4,
  });

  String get normalizedRecipientEmail => recipientEmail.trim();

  String get displayEmployeeName {
    final String trimmedName = employeeName.trim();
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
