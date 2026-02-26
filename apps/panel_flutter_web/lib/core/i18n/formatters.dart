import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatCurrency(
  BuildContext context,
  num value, {
  String currencyCode = 'TRY',
}) {
  final localeName = Localizations.localeOf(context).toLanguageTag();
  final formatter = NumberFormat.simpleCurrency(
    locale: localeName,
    name: currencyCode,
  );
  return formatter.format(value);
}

String formatCompactNumber(BuildContext context, int n) {
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.compact(locale: localeName).format(n);
}

String formatShortDate(BuildContext context, DateTime dt) {
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(localeName).format(dt);
}
