class AppFormat {
  AppFormat._();

  static int decimalPlaces = 2;

  static String number(double value, {int? decimals}) {
    String s = value.toStringAsFixed(decimals ?? decimalPlaces);
    if (!s.contains('.')) return s;
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  static String percent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  static String percentOf(double part, double total, {int decimals = 1}) {
    if (total == 0) return '0%';
    return '${((part / total) * 100).toStringAsFixed(decimals)}%';
  }

  static String compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(decimalPlaces);
  }
}
