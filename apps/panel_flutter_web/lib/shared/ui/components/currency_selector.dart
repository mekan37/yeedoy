import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/currency/currency_models.dart';
import '../../../core/currency/currency_provider.dart';

/// Compact 3-button toggle: ₺ TL | $ USD | € EUR
/// Place anywhere in the UI — topbar, page header, settings panel.
class CurrencySelector extends ConsumerWidget {
  const CurrencySelector({super.key, this.compact = false});

  /// If true, shows only the symbol (₺ / $ / €) without the code label.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCurrencyProvider);
    final notifier = ref.read(selectedCurrencyProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AppCurrency.values.map((currency) {
        final isSelected = currency == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: _CurrencyButton(
            currency: currency,
            selected: isSelected,
            compact: compact,
            onTap: () => notifier.select(currency),
          ),
        );
      }).toList(),
    );
  }
}

class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({
    required this.currency,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final AppCurrency currency;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = compact ? currency.symbol : '${currency.symbol} ${currency.label}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? const Color(0xFF7F1D1D) : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Variant for light backgrounds (e.g. page body, dialogs).
class CurrencySelectorLight extends ConsumerWidget {
  const CurrencySelectorLight({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCurrencyProvider);
    final notifier = ref.read(selectedCurrencyProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AppCurrency.values.map((currency) {
        final isSelected = currency == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: GestureDetector(
            onTap: () => notifier.select(currency),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7F1D1D)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7F1D1D)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                '${currency.symbol} ${currency.label}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
