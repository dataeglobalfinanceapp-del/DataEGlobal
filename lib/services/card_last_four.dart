String normalizeCardLastFour(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 4) return digits;
  return digits.substring(digits.length - 4);
}

bool isValidCardLastFour(String value) {
  return normalizeCardLastFour(value).length == 4;
}
