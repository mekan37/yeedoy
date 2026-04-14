enum AppCurrency {
  trl,
  usd,
  eur;

  String get code => switch (this) {
        trl => 'TRY',
        usd => 'USD',
        eur => 'EUR',
      };

  String get symbol => switch (this) {
        trl => '₺',
        usd => '\$',
        eur => '€',
      };

  String get label => switch (this) {
        trl => 'TL',
        usd => 'USD',
        eur => 'EUR',
      };

  static AppCurrency fromCode(String code) => switch (code) {
        'USD' => usd,
        'EUR' => eur,
        _ => trl,
      };
}

class ExchangeRates {
  const ExchangeRates({
    required this.usdToTry,
    required this.eurToTry,
    required this.fetchedAt,
    this.source = 'tcmb',
  });

  /// 1 USD = usdToTry TRY
  final double usdToTry;

  /// 1 EUR = eurToTry TRY
  final double eurToTry;

  final DateTime fetchedAt;
  final String source;

  /// Convert a TRY amount to the target currency.
  double convert(double priceTry, AppCurrency to) => switch (to) {
        AppCurrency.trl => priceTry,
        AppCurrency.usd => usdToTry > 0 ? priceTry / usdToTry : priceTry,
        AppCurrency.eur => eurToTry > 0 ? priceTry / eurToTry : priceTry,
      };

  /// Format a TRY price in the target currency with symbol.
  String format(double priceTry, AppCurrency to) {
    final amount = convert(priceTry, to);
    final decimals = to == AppCurrency.trl ? 2 : 2;
    return '${to.symbol}${amount.toStringAsFixed(decimals)}';
  }

  factory ExchangeRates.fromMap(Map<String, dynamic> rates) => ExchangeRates(
        usdToTry: (rates['USD'] as num? ?? 1).toDouble(),
        eurToTry: (rates['EUR'] as num? ?? 1).toDouble(),
        fetchedAt: DateTime.now(),
      );

  /// Fallback when rates are unavailable — identity (show TRY only).
  static ExchangeRates get fallback => ExchangeRates(
        usdToTry: 1,
        eurToTry: 1,
        fetchedAt: DateTime.utc(2000),
        source: 'fallback',
      );
}
