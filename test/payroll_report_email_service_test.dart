import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_models.dart';
import 'package:savetep/features/auth/screens/payroll_screen/payroll_report_email_service.dart';
import 'package:savetep/services/app_clock.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 7, 20));
  });

  tearDown(AppClock.reset);

  test(
    'mock sender receives a PDF with only eligible payroll employees',
    () async {
      final sender = _RecordingPayrollEmailSender();
      final service = PayrollReportEmailService(sender: sender);

      final result = await service.sendConfirmedPayroll(
        recipientEmail: ' manager@example.com ',
        employees: <PayrollEmployee>[
          PayrollEmployee(
            id: 'employee-maya',
            name: 'Maya Rodriguez',
            rate: 20,
            regularHours: 40,
            overtimeHours: 2,
            commission: 50,
            tips: 25,
            dateHire: '07/13/26',
            payrollAction: PayrollAction.change,
            isPayrollConfirmed: true,
            payrollSetting: EmployeePayrollSetting(
              schedule: EmployeePayrollSchedule.biWeekly,
              endingDay: EmployeePayrollEndingDay.sunday,
              firstPeriodEndDate: DateTime(2026, 7, 19),
            ),
          ),
          PayrollEmployee(
            id: 'employee-noah',
            name: 'Noah Bennett',
            dateHire: '07/13/26',
            isPayrollConfirmed: false,
            payrollSetting: EmployeePayrollSetting(
              schedule: EmployeePayrollSchedule.biWeekly,
              endingDay: EmployeePayrollEndingDay.sunday,
              firstPeriodEndDate: DateTime(2026, 7, 19),
            ),
          ),
          const PayrollEmployee(
            id: 'employee-empty',
            name: 'Missing Setup',
            isPayrollConfirmed: true,
          ),
        ],
        asOf: DateTime(2026, 7, 20),
      );

      expect(result.recipientEmail, 'manager@example.com');
      expect(result.fileName, 'payroll-report-20260720.pdf');
      expect(result.employeeCount, 1);
      expect(sender.requests, hasLength(1));

      final PayrollReport report = sender.requests.single.report;
      expect(report.rows, hasLength(1));
      expect(report.rows.single.employee.name, 'Maya Rodriguez');
      expect(report.rows.single.period.displayText, '07/20/26 - 08/02/26');

      final String pdfText = latin1.decode(report.pdfBytes);
      expect(pdfText, startsWith('%PDF-1.4'));
      expect(pdfText, contains('SAVE TEP'));
      expect(pdfText, contains('Employee name: Maya Rodriguez'));
      expect(pdfText, contains('Payroll Period: 07/20/26 - 08/02/26'));
      expect(pdfText, contains('Status: Change'));
      expect(pdfText, isNot(contains('Noah Bennett')));
      expect(pdfText, isNot(contains('Missing Setup')));
    },
  );

  test('throws when no employees can be included in the payroll report', () {
    const service = PayrollReportEmailService();

    expect(
      service.sendConfirmedPayroll(
        recipientEmail: 'manager@example.com',
        employees: const <PayrollEmployee>[
          PayrollEmployee(id: 'employee-nope', name: 'No Setup'),
        ],
      ),
      throwsA(isA<PayrollReportEmailException>()),
    );
  });
}

class _RecordingPayrollEmailSender implements PayrollEmailSender {
  final List<PayrollEmailRequest> requests = <PayrollEmailRequest>[];

  @override
  Future<PayrollEmailResult> sendPayrollReport(
    PayrollEmailRequest request,
  ) async {
    requests.add(request);
    return PayrollEmailResult(
      recipientEmail: request.normalizedRecipientEmail,
      fileName: request.report.fileName,
      employeeCount: request.report.employeeCount,
    );
  }
}
