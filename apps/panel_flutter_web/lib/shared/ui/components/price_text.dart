import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/currency/currency_models.dart';
import '../../../core/currency/currency_provider.dart';

/// Displays a TRY price converted to the user's selected currency.
/// Automatically updates when the user switches currency.
///
/// Usage:
///   PriceText(priceTry: item.price)
///   PriceText(priceTry: item.price, style: TextStyle(...), showOriginal: true)
class PriceText extends ConsumerWidget {
  const PriceText({
    super.key,
    required this.priceTry,
    this.style,
    this.showOriginal = false,
  });

  /// The price in Turkish Lira (base currency stored in DB).
  final double priceTry;

  final TextStyle? style;

  /// If true and currency ≠ TRY, also shows the original TRY in smaller text.
  final bool showOriginal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCurrencyProvider);
    final ratesAsync = ref.watch(exchangeRatesProvider);

    final rates = ratesAsync.when(
      data: (r) => r,
      loading: () => ExchangeRates.fallback,
      error: (err, st) => ExchangeRates.fallback,
    );
    final formatted = rates.format(priceTry, selected);

    if (!showOriginal || selected == AppCurrency.trl) {
      return Text(formatted, style: style);
    }

    // Show converted price + original TRY below
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formatted, style: style),
        Text(
          '₺${priceTry.toStringAsFixed(2)}',
          style: (style ?? const TextStyle()).copyWith(
            fontSize: ((style?.fontSize ?? 14) * 0.75),
            color: Colors.black38,
          ),
        ),
      ],
    );
  }
}

/// Convenience: format a price string outside widget tree.
String formatPriceWith(
  double priceTry,
  AppCurrency currency,
  ExchangeRates rates,
) =>
    rates.format(priceTry, currency);
