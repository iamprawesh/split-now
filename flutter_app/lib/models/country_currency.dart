import 'currency.dart';

class CountryCurrency {
  final String code;
  final String name;
  final String flagEmoji;
  final Currency currency;

  const CountryCurrency({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.currency,
  });

  static const List<CountryCurrency> all = [
    CountryCurrency(code: 'US', name: 'United States', flagEmoji: '\ud83c\uddfa\ud83c\uddf8', currency: Currency(code: 'USD', name: 'US Dollar', symbol: '\$')),
    CountryCurrency(code: 'NP', name: 'Nepal', flagEmoji: '\ud83c\uddf3\ud83c\uddf5', currency: Currency(code: 'NPR', name: 'Nepalese Rupee', symbol: '\u20a8')),
    CountryCurrency(code: 'IN', name: 'India', flagEmoji: '\ud83c\uddee\ud83c\uddf3', currency: Currency(code: 'INR', name: 'Indian Rupee', symbol: '\u20b9')),
    CountryCurrency(code: 'GB', name: 'United Kingdom', flagEmoji: '\ud83c\uddec\ud83c\udde7', currency: Currency(code: 'GBP', name: 'British Pound', symbol: '\u00a3')),
    CountryCurrency(code: 'EU', name: 'European Union', flagEmoji: '\ud83c\uddea\ud83c\uddfa', currency: Currency(code: 'EUR', name: 'Euro', symbol: '\u20ac')),
    CountryCurrency(code: 'JP', name: 'Japan', flagEmoji: '\ud83c\uddef\ud83c\uddf5', currency: Currency(code: 'JPY', name: 'Japanese Yen', symbol: '\u00a5', decimalDigits: 0)),
    CountryCurrency(code: 'AU', name: 'Australia', flagEmoji: '\ud83c\udde6\ud83c\uddfa', currency: Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$')),
    CountryCurrency(code: 'CA', name: 'Canada', flagEmoji: '\ud83c\udde8\ud83c\udde6', currency: Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'CA\$')),
    CountryCurrency(code: 'NZ', name: 'New Zealand', flagEmoji: '\ud83c\uddf3\ud83c\uddff', currency: Currency(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$')),
    CountryCurrency(code: 'SG', name: 'Singapore', flagEmoji: '\ud83c\uddf8\ud83c\uddec', currency: Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$')),
    CountryCurrency(code: 'HK', name: 'Hong Kong', flagEmoji: '\ud83c\udded\ud83c\uddf0', currency: Currency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$')),
    CountryCurrency(code: 'KR', name: 'South Korea', flagEmoji: '\ud83c\uddf0\ud83c\uddf7', currency: Currency(code: 'KRW', name: 'South Korean Won', symbol: '\u20a9', decimalDigits: 0)),
    CountryCurrency(code: 'CN', name: 'China', flagEmoji: '\ud83c\udde8\ud83c\uddf3', currency: Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '\u00a5')),
    CountryCurrency(code: 'MX', name: 'Mexico', flagEmoji: '\ud83c\uddf2\ud83c\uddfd', currency: Currency(code: 'MXN', name: 'Mexican Peso', symbol: 'Mex\$')),
    CountryCurrency(code: 'BR', name: 'Brazil', flagEmoji: '\ud83c\udde7\ud83c\uddf7', currency: Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$')),
    CountryCurrency(code: 'ZA', name: 'South Africa', flagEmoji: '\ud83c\uddff\ud83c\udde6', currency: Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R')),
    CountryCurrency(code: 'CH', name: 'Switzerland', flagEmoji: '\ud83c\udde8\ud83c\udded', currency: Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF')),
    CountryCurrency(code: 'SE', name: 'Sweden', flagEmoji: '\ud83c\uddf8\ud83c\uddea', currency: Currency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr')),
    CountryCurrency(code: 'NO', name: 'Norway', flagEmoji: '\ud83c\uddf3\ud83c\uddf4', currency: Currency(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr')),
    CountryCurrency(code: 'TR', name: 'Turkey', flagEmoji: '\ud83c\uddf9\ud83c\uddf7', currency: Currency(code: 'TRY', name: 'Turkish Lira', symbol: '\u20ba')),
    CountryCurrency(code: 'RU', name: 'Russia', flagEmoji: '\ud83c\uddf7\ud83c\uddfa', currency: Currency(code: 'RUB', name: 'Russian Ruble', symbol: '\u20bd')),
    CountryCurrency(code: 'AE', name: 'United Arab Emirates', flagEmoji: '\ud83c\udde6\ud83c\uddea', currency: Currency(code: 'AED', name: 'UAE Dirham', symbol: '\u062f.\u0625')),
    CountryCurrency(code: 'SA', name: 'Saudi Arabia', flagEmoji: '\ud83c\uddf8\ud83c\udde6', currency: Currency(code: 'SAR', name: 'Saudi Riyal', symbol: '\u0631.\u0633')),
    CountryCurrency(code: 'TH', name: 'Thailand', flagEmoji: '\ud83c\uddf9\ud83c\udded', currency: Currency(code: 'THB', name: 'Thai Baht', symbol: '\u0e3f')),
    CountryCurrency(code: 'PH', name: 'Philippines', flagEmoji: '\ud83c\uddf5\ud83c\udded', currency: Currency(code: 'PHP', name: 'Philippine Peso', symbol: '\u20b1')),
    CountryCurrency(code: 'ID', name: 'Indonesia', flagEmoji: '\ud83c\uddee\ud83c\udde9', currency: Currency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp')),
    CountryCurrency(code: 'MY', name: 'Malaysia', flagEmoji: '\ud83c\uddf2\ud83c\uddfe', currency: Currency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM')),
    CountryCurrency(code: 'BD', name: 'Bangladesh', flagEmoji: '\ud83c\udde7\ud83c\udde9', currency: Currency(code: 'BDT', name: 'Bangladeshi Taka', symbol: '\u09f3')),
    CountryCurrency(code: 'PK', name: 'Pakistan', flagEmoji: '\ud83c\uddf5\ud83c\uddf0', currency: Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: '\u20a8')),
    CountryCurrency(code: 'LK', name: 'Sri Lanka', flagEmoji: '\ud83c\uddf1\ud83c\uddf0', currency: Currency(code: 'LKR', name: 'Sri Lankan Rupee', symbol: 'Rs')),
    CountryCurrency(code: 'QA', name: 'Qatar', flagEmoji: '\ud83c\uddf6\ud83c\udde6', currency: Currency(code: 'QAR', name: 'Qatari Riyal', symbol: '\u0631.\u0642')),
    CountryCurrency(code: 'KW', name: 'Kuwait', flagEmoji: '\ud83c\uddf0\ud83c\uddfc', currency: Currency(code: 'KWD', name: 'Kuwaiti Dinar', symbol: '\u062f.\u0643')),
    CountryCurrency(code: 'BH', name: 'Bahrain', flagEmoji: '\ud83c\udde7\ud83c\udded', currency: Currency(code: 'BHD', name: 'Bahraini Dinar', symbol: '\u062f.\u0628')),
    CountryCurrency(code: 'OM', name: 'Oman', flagEmoji: '\ud83c\uddf4\ud83c\uddf2', currency: Currency(code: 'OMR', name: 'Omani Rial', symbol: '\u0631.\u0639.')),
    CountryCurrency(code: 'NG', name: 'Nigeria', flagEmoji: '\ud83c\uddf3\ud83c\uddec', currency: Currency(code: 'NGN', name: 'Nigerian Naira', symbol: '\u20a6')),
    CountryCurrency(code: 'KE', name: 'Kenya', flagEmoji: '\ud83c\uddf0\ud83c\uddea', currency: Currency(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh')),
    CountryCurrency(code: 'GH', name: 'Ghana', flagEmoji: '\ud83c\uddec\ud83c\udded', currency: Currency(code: 'GHS', name: 'Ghanaian Cedi', symbol: '\u20b5')),
    CountryCurrency(code: 'EG', name: 'Egypt', flagEmoji: '\ud83c\uddea\ud83c\uddec', currency: Currency(code: 'EGP', name: 'Egyptian Pound', symbol: 'E\u00a3')),
    CountryCurrency(code: 'AR', name: 'Argentina', flagEmoji: '\ud83c\udde6\ud83c\uddf7', currency: Currency(code: 'ARS', name: 'Argentine Peso', symbol: 'AR\$')),
    CountryCurrency(code: 'CO', name: 'Colombia', flagEmoji: '\ud83c\udde8\ud83c\uddf4', currency: Currency(code: 'COP', name: 'Colombian Peso', symbol: 'CO\$')),
    CountryCurrency(code: 'CL', name: 'Chile', flagEmoji: '\ud83c\udde8\ud83c\uddf1', currency: Currency(code: 'CLP', name: 'Chilean Peso', symbol: 'CL\$', decimalDigits: 0)),
    CountryCurrency(code: 'PE', name: 'Peru', flagEmoji: '\ud83c\uddf5\ud83c\uddea', currency: Currency(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/.')),
    CountryCurrency(code: 'VN', name: 'Vietnam', flagEmoji: '\ud83c\uddfb\ud83c\uddf3', currency: Currency(code: 'VND', name: 'Vietnamese Dong', symbol: '\u20ab', decimalDigits: 0)),
    CountryCurrency(code: 'CZ', name: 'Czech Republic', flagEmoji: '\ud83c\udde8\ud83c\uddff', currency: Currency(code: 'CZK', name: 'Czech Koruna', symbol: 'K\u010d')),
    CountryCurrency(code: 'PL', name: 'Poland', flagEmoji: '\ud83c\uddf5\ud83c\uddf1', currency: Currency(code: 'PLN', name: 'Polish Zloty', symbol: 'z\u0142')),
    CountryCurrency(code: 'HU', name: 'Hungary', flagEmoji: '\ud83c\udded\ud83c\uddfa', currency: Currency(code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft')),
    CountryCurrency(code: 'IL', name: 'Israel', flagEmoji: '\ud83c\uddee\ud83c\uddf1', currency: Currency(code: 'ILS', name: 'Israeli Shekel', symbol: '\u20aa')),
    CountryCurrency(code: 'DK', name: 'Denmark', flagEmoji: '\ud83c\udde9\ud83c\uddf0', currency: Currency(code: 'DKK', name: 'Danish Krone', symbol: 'kr.')),
  ];
}
