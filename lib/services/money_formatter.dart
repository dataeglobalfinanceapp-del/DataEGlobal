String formatMoney(double value, {bool symbol = true}) {
  final sign = value < 0 ? '-' : '';
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final reversed = whole.split('').reversed.toList();
  final formatted = <String>[];

  for (var index = 0; index < reversed.length; index++) {
    if (index > 0 && index % 3 == 0) formatted.add(',');
    formatted.add(reversed[index]);
  }

  final amount = '${formatted.reversed.join()}.${parts.last}';
  return symbol ? '$sign\$$amount' : '$sign$amount';
}

double parseMoney(String value) {
  return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
}
