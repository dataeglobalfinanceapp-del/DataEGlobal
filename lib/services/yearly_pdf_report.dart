import 'dart:convert';
import 'dart:typed_data';

class TransactionReportRow {
  final DateTime date;
  final String title;
  final String category;
  final double amount;
  final String detail;

  const TransactionReportRow({
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
    required this.detail,
  });
}

class YearlyTransactionPdfReport {
  static Uint8List build({
    required String reportTitle,
    required String periodLabel,
    required List<TransactionReportRow> rows,
    required double total,
  }) {
    final pages = _buildPages(
      reportTitle: reportTitle,
      periodLabel: periodLabel,
      rows: rows,
      total: total,
    );
    return _PdfDocument(pages).build();
  }

  static List<List<String>> _buildPages({
    required String reportTitle,
    required String periodLabel,
    required List<TransactionReportRow> rows,
    required double total,
  }) {
    final lines = <String>[
      reportTitle,
      'Period: $periodLabel',
      'Generated: ${_fmtDate(DateTime.now())}',
      'Total: ${_fmtMoney(total)}',
      '',
    ];

    if (rows.isEmpty) {
      lines.add('No transactions found for this period.');
    } else {
      final byMonth = <int, List<TransactionReportRow>>{};
      for (final row in rows) {
        byMonth.putIfAbsent(row.date.month, () => []).add(row);
      }

      for (var month = 1; month <= 12; month++) {
        final monthRows = byMonth[month] ?? [];
        if (monthRows.isEmpty) continue;
        final monthTotal = monthRows.fold<double>(
          0,
          (sum, row) => sum + row.amount,
        );
        lines
          ..add('${_monthNames[month]} - ${_fmtMoney(monthTotal)}')
          ..add(
            'Date       Description                 Category              Amount',
          );
        for (final row in monthRows..sort((a, b) => a.date.compareTo(b.date))) {
          lines.add(
            '${_fmtShortDate(row.date).padRight(10)} '
            '${_clip(row.title, 27).padRight(28)} '
            '${_clip(row.category, 20).padRight(21)} '
            '${_fmtMoney(row.amount).padLeft(10)}',
          );
          if (row.detail.isNotEmpty) {
            lines.add('           ${_clip(row.detail, 68)}');
          }
        }
        lines.add('');
      }
    }

    const linesPerPage = 42;
    final pages = <List<String>>[];
    for (var index = 0; index < lines.length; index += linesPerPage) {
      pages.add(lines.skip(index).take(linesPerPage).toList());
    }
    return pages.isEmpty ? [[]] : pages;
  }

  static String _fmtMoney(double value) => '\$${value.toStringAsFixed(2)}';

  static String _fmtDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';

  static String _fmtShortDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';

  static String _clip(String value, int max) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max - 3)}...';
  }
}

class _PdfDocument {
  final List<List<String>> pages;

  const _PdfDocument(this.pages);

  Uint8List build() {
    final objects = <String>[];
    final pageObjectIds = <int>[];

    objects.add('<< /Type /Catalog /Pages 2 0 R >>');
    objects.add('');
    objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>');

    for (final page in pages) {
      final contentObjectId = objects.length + 1;
      final content = _contentStream(page);
      objects.add(
        '<< /Length ${latin1.encode(content).length} >>\nstream\n$content\nendstream',
      );

      final pageObjectId = objects.length + 1;
      pageObjectIds.add(pageObjectId);
      objects.add(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Resources << /Font << /F1 3 0 R >> >> '
        '/Contents $contentObjectId 0 R >>',
      );
    }

    objects[1] =
        '<< /Type /Pages /Kids [${pageObjectIds.map((id) => '$id 0 R').join(' ')}] /Count ${pageObjectIds.length} >>';

    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (var index = 0; index < objects.length; index++) {
      offsets.add(latin1.encode(buffer.toString()).length);
      buffer
        ..write('${index + 1} 0 obj\n')
        ..write(objects[index])
        ..write('\nendobj\n');
    }

    final xrefOffset = latin1.encode(buffer.toString()).length;
    buffer
      ..write('xref\n')
      ..write('0 ${objects.length + 1}\n')
      ..write('0000000000 65535 f \n');
    for (final offset in offsets.skip(1)) {
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
    final buffer = StringBuffer();
    var y = 790;
    for (var index = 0; index < lines.length; index++) {
      final isTitle = index == 0;
      final size = isTitle ? 16 : 10;
      buffer.write(
        'BT /F1 $size Tf 50 $y Td (${_escape(lines[index])}) Tj ET\n',
      );
      y -= isTitle ? 24 : 16;
    }
    return buffer.toString();
  }

  String _escape(String value) {
    final clean = value.runes.map((rune) {
      if (rune < 32 || rune > 126) return '?';
      return String.fromCharCode(rune);
    }).join();

    return clean
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }
}

const _monthNames = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
