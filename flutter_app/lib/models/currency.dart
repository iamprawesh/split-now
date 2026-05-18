import '../services/app_constants.dart';

class Currency {
  final String code;
  final String name;
  final String symbol;
  final int decimalDigits;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalDigits = 2,
  });

  String format(double amount) {
    return '$symbol\u2009${AppFormat.number(amount)}';
  }

  String formatWithCode(double amount) {
    return '$code\u2009${AppFormat.number(amount)}';
  }

  Map<String, dynamic> toJson() => {
    'code': code,
  };

  static const List<Currency> all = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', decimalDigits: 0),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    Currency(code: 'NPR', name: 'Nepalese Rupee', symbol: 'रू'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
    Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩', decimalDigits: 0),
    Currency(code: 'MXN', name: 'Mexican Peso', symbol: 'Mex\$'),
    Currency(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$'),
    Currency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
    Currency(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr'),
    Currency(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
    Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
    Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
    Currency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$'),
  ];

  static Currency fromCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => all.first,
    );
  }
}
