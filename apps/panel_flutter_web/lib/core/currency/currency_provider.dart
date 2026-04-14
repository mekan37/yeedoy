import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/supabase_provider.dart';
import 'currency_models.dart';

// ─── Exchange rates ───────────────────────────────────────────────────────────

/// Fetches current USD/EUR rates from the `get-exchange-rates` edge function.
/// Riverpod caches the result for the session; call ref.invalidate to force refresh.
final exchangeRatesProvider = FutureProvider<ExchangeRates>((ref) async {
  final client = ref.watch(supabaseProvider);
  try {
    final res = await client.functions.invoke('get-exchange-rates');
    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['ok'] != true) return ExchangeRates.fallback;
    final rates = data['rates'] as Map<String, dynamic>? ?? {};
    return ExchangeRates.fromMap(rates);
  } catch (_) {
    return ExchangeRates.fallback;
  }
});

// ─── Selected currency (persisted) ───────────────────────────────────────────

const _kCurrencyPrefKey = 'yeedoy_selected_currency';

class _CurrencyNotifier extends Notifier<AppCurrency> {
  @override
  AppCurrency build() {
    _loadFromPrefs();
    return AppCurrency.trl;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kCurrencyPrefKey);
    if (saved != null) {
      state = AppCurrency.fromCode(saved);
    }
  }

  Future<void> select(AppCurrency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyPrefKey, currency.code);
  }
}

final selectedCurrencyProvider =
    NotifierProvider<_CurrencyNotifier, AppCurrency>(_CurrencyNotifier.new);
