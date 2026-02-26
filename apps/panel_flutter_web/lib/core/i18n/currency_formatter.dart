String formatCurrencyFromCents(
  int? cents, {
  String currency = 'TRY',
  String languageCode = 'tr',
}) {
  if (cents == null) return '—';
  return formatCurrency(
    cents / 100.0,
    currency: currency,
    languageCode: languageCode,
  );
}

String formatCurrency(
  double? amount, {
  String currency = 'TRY',
  String languageCode = 'tr',
}) {
  if (amount == null) return '—';
  final fixed = amount.toStringAsFixed(
    amount.truncateToDouble() == amount ? 0 : 2,
  );
  final localized = languageCode.toLowerCase().startsWith('tr')
      ? fixed.replaceAll('.', ',')
      : fixed;

  final symbol = switch (currency.toUpperCase()) {
    'TRY' => 'â‚º',
    'USD' => '\$',
    'EUR' => 'â‚¬',
    _ => '${currency.toUpperCase()} ',
  };

  if (currency.toUpperCase() == 'TRY' ||
      currency.toUpperCase() == 'USD' ||
      currency.toUpperCase() == 'EUR') {
    return '$symbol$localized';
  }
  return '$localized $symbol';
}

