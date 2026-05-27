import 'dart:convert';
import 'dart:typed_data';

import 'yearly_pdf_report.dart';

class ExcelTransactionReport {
  static Uint8List build({
    required String reportTitle,
    required String periodLabel,
    required String transactionType,
    required List<TransactionReportRow> rows,
    required double total,
  }) {
    final buffer = StringBuffer()
      ..writeln('<html>')
      ..writeln('<head><meta charset="UTF-8"></head>')
      ..writeln('<body>')
      ..writeln('<h2>${_escape(reportTitle)}</h2>')
      ..writeln('<p><b>Period:</b> ${_escape(periodLabel)}</p>')
      ..writeln('<p><b>Type:</b> ${_escape(transactionType)}</p>')
      ..writeln('<table border="1">')
      ..writeln(
        '<tr>'
        '<th>Date</th>'
        '<th>Description</th>'
        '<th>Category</th>'
        '<th>Detail</th>'
        '<th>Amount</th>'
        '</tr>',
      );

    for (final row in rows..sort((a, b) => a.date.compareTo(b.date))) {
      buffer.writeln(
        '<tr>'
        '<td>${_escape(_fmtDate(row.date))}</td>'
        '<td>${_escape(row.title)}</td>'
        '<td>${_escape(row.category)}</td>'
        '<td>${_escape(row.detail)}</td>'
        '<td>${row.amount.toStringAsFixed(2)}</td>'
        '</tr>',
      );
    }

    buffer
      ..writeln(
        '<tr>'
        '<td colspan="4"><b>Total</b></td>'
        '<td><b>${total.toStringAsFixed(2)}</b></td>'
        '</tr>',
      )
      ..writeln('</table>')
      ..writeln('</body>')
      ..writeln('</html>');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static String _fmtDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';

  static String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
