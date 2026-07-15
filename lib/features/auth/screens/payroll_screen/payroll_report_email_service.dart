import 'dart:convert';
import 'dart:typed_data';

import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/money_formatter.dart';

import 'payroll_models.dart';
import 'payroll_period_calculator.dart';

class PayrollReportEmployeeRow {
  final PayrollEmployee employee;
  final PayrollPayPeriod period;

  const PayrollReportEmployeeRow({
    required this.employee,
    required this.period,
  });
}

class PayrollReport {
  final String companyName;
  final List<PayrollReportEmployeeRow> rows;
  final Uint8List pdfBytes;
  final String fileName;

  const PayrollReport({
    required this.companyName,
    required this.rows,
    required this.pdfBytes,
    required this.fileName,
  });

  int get employeeCount => rows.length;

  bool get hasEmployees => rows.isNotEmpty;
}

class PayrollReportBuilder {
  const PayrollReportBuilder._();

  static PayrollReport build({
    required Iterable<PayrollEmployee> employees,
    DateTime? asOf,
    String companyName = 'SAVE TEP',
  }) {
    final DateTime reportDate = PayrollPeriodCalculator.dateOnly(
      asOf ?? AppClock.now,
    );
    final List<PayrollReportEmployeeRow> rows = eligibleEmployees(
      employees: employees,
      asOf: reportDate,
    ).toList(growable: false);

    return PayrollReport(
      companyName: companyName,
      rows: rows,
      pdfBytes: _PayrollPdfReport.build(companyName: companyName, rows: rows),
      fileName: 'payroll-report-${_dateKey(reportDate)}.pdf',
    );
  }

  static Iterable<PayrollReportEmployeeRow> eligibleEmployees({
    required Iterable<PayrollEmployee> employees,
    required DateTime asOf,
  }) sync* {
    final DateTime reportDate = PayrollPeriodCalculator.dateOnly(asOf);
    for (final PayrollEmployee employee in employees) {
      if (!employee.isPayrollConfirmed || !_hasSavedPayrollSetting(employee)) {
        continue;
      }

      final PayrollPayPeriod? period =
          PayrollPeriodCalculator.currentPeriodForEmployee(
            employee,
            asOf: reportDate,
          );
      if (period == null) continue;

      yield PayrollReportEmployeeRow(employee: employee, period: period);
    }
  }

  static bool _hasSavedPayrollSetting(PayrollEmployee employee) {
    final EmployeePayrollSetting? setting = employee.payrollSetting;
    return setting != null && setting.schedule != EmployeePayrollSchedule.none;
  }
}

class PayrollEmailRequest {
  final String recipientEmail;
  final PayrollReport report;

  const PayrollEmailRequest({
    required this.recipientEmail,
    required this.report,
  });

  String get normalizedRecipientEmail => recipientEmail.trim();
}

class PayrollEmailResult {
  final String recipientEmail;
  final String fileName;
  final int employeeCount;
  final bool mocked;

  const PayrollEmailResult({
    required this.recipientEmail,
    required this.fileName,
    required this.employeeCount,
    this.mocked = true,
  });
}

/// Replace this implementation with a Gmail API sender when real email is wired.
abstract class PayrollEmailSender {
  const PayrollEmailSender();

  Future<PayrollEmailResult> sendPayrollReport(PayrollEmailRequest request);
}

class MockPayrollEmailSender implements PayrollEmailSender {
  const MockPayrollEmailSender();

  @override
  Future<PayrollEmailResult> sendPayrollReport(
    PayrollEmailRequest request,
  ) async {
    return PayrollEmailResult(
      recipientEmail: request.normalizedRecipientEmail,
      fileName: request.report.fileName,
      employeeCount: request.report.employeeCount,
    );
  }
}

class PayrollReportEmailService {
  final PayrollEmailSender sender;

  const PayrollReportEmailService({
    this.sender = const MockPayrollEmailSender(),
  });

  Future<PayrollEmailResult> sendConfirmedPayroll({
    required String recipientEmail,
    required Iterable<PayrollEmployee> employees,
    DateTime? asOf,
    String companyName = 'SAVE TEP',
  }) async {
    final PayrollReport report = PayrollReportBuilder.build(
      employees: employees,
      asOf: asOf,
      companyName: companyName,
    );
    if (!report.hasEmployees) {
      throw const PayrollReportEmailException(
        'No eligible payroll records to send',
      );
    }

    return sender.sendPayrollReport(
      PayrollEmailRequest(recipientEmail: recipientEmail, report: report),
    );
  }
}

class PayrollReportEmailException implements Exception {
  final String message;

  const PayrollReportEmailException(this.message);

  @override
  String toString() => message;
}

class _PayrollPdfReport {
  const _PayrollPdfReport._();

  static Uint8List build({
    required String companyName,
    required List<PayrollReportEmployeeRow> rows,
  }) {
    final List<String> lines = <String>[companyName];
    for (final PayrollReportEmployeeRow row in rows) {
      final PayrollEmployee employee = row.employee;
      lines
        ..add('')
        ..add('Employee name: ${_clip(employee.name, 52)}')
        ..add('Payroll Period: ${row.period.displayText}')
        ..add('Status: ${employee.payrollAction.label}')
        ..add(
          'Rate: ${_amount(employee.rate)}    '
          'Reg Hours: ${_amount(employee.regularHours)}    '
          'OT: ${_amount(employee.overtimeHours)}',
        )
        ..add(
          'Commission: ${formatMoney(employee.commission)}    '
          'Tips: ${formatMoney(employee.tips)}',
        );
    }

    return _PayrollTextPdfDocument(_paginate(lines)).build();
  }

  static List<List<String>> _paginate(List<String> lines) {
    const int linesPerPage = 42;
    final List<List<String>> pages = <List<String>>[];
    for (int index = 0; index < lines.length; index += linesPerPage) {
      pages.add(lines.skip(index).take(linesPerPage).toList(growable: false));
    }
    return pages.isEmpty ? <List<String>>[<String>[]] : pages;
  }

  static String _amount(double value) {
    if (value == 0) return '0';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  static String _clip(String value, int max) {
    final String clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max - 3)}...';
  }
}

class _PayrollTextPdfDocument {
  final List<List<String>> pages;

  const _PayrollTextPdfDocument(this.pages);

  Uint8List build() {
    final List<String> objects = <String>[];
    final List<int> pageObjectIds = <int>[];

    objects.add('<< /Type /Catalog /Pages 2 0 R >>');
    objects.add('');
    objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>');

    for (final List<String> page in pages) {
      final int contentObjectId = objects.length + 1;
      final String content = _contentStream(page);
      objects.add(
        '<< /Length ${latin1.encode(content).length} >>\nstream\n$content\nendstream',
      );

      final int pageObjectId = objects.length + 1;
      pageObjectIds.add(pageObjectId);
      objects.add(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Resources << /Font << /F1 3 0 R >> >> '
        '/Contents $contentObjectId 0 R >>',
      );
    }

    objects[1] =
        '<< /Type /Pages /Kids [${pageObjectIds.map((int id) => '$id 0 R').join(' ')}] /Count ${pageObjectIds.length} >>';

    final StringBuffer buffer = StringBuffer('%PDF-1.4\n');
    final List<int> offsets = <int>[0];
    for (int index = 0; index < objects.length; index += 1) {
      offsets.add(latin1.encode(buffer.toString()).length);
      buffer
        ..write('${index + 1} 0 obj\n')
        ..write(objects[index])
        ..write('\nendobj\n');
    }

    final int xrefOffset = latin1.encode(buffer.toString()).length;
    buffer
      ..write('xref\n')
      ..write('0 ${objects.length + 1}\n')
      ..write('0000000000 65535 f \n');
    for (final int offset in offsets.skip(1)) {
      buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    buffer
      ..write('trailer\n')
      ..write('<< /Size ${objects.length + 1} /Root 1 0 R >>\n')
      ..write('startxref\n')
      ..write('$xrefOffset\n')
      ..write('%%EOF');

    return Uint8List.fromList(latin1.encode(buffer.toString()));
  }

  String _contentStream(List<String> lines) {
    final StringBuffer buffer = StringBuffer();
    int y = 790;
    for (int index = 0; index < lines.length; index += 1) {
      final bool isTitle = index == 0;
      final int size = isTitle ? 16 : 10;
      buffer.write(
        'BT /F1 $size Tf 50 $y Td (${_escape(lines[index])}) Tj ET\n',
      );
      y -= isTitle ? 24 : 16;
    }
    return buffer.toString();
  }

  String _escape(String value) {
    final String clean = value.runes.map((int rune) {
      if (rune < 32 || rune > 126) return '?';
      return String.fromCharCode(rune);
    }).join();

    return clean
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }
}

String _dateKey(DateTime date) {
  final DateTime value = PayrollPeriodCalculator.dateOnly(date);
  return '${value.year}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}';
}
