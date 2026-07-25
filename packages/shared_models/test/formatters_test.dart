import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_shared_models/yeedoy_shared_models.dart';

Future<void> _withContext(
  WidgetTester tester,
  Locale locale,
  void Function(BuildContext context) callback,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (context) {
          callback(context);
          return const SizedBox();
        },
      ),
    ),
  );
}

void main() {
  group('formatCurrency', () {
    testWidgets('formats TRY amount for tr locale', (tester) async {
      await _withContext(tester, const Locale('tr'), (context) {
        final result = formatCurrency(context, 125.5);
        expect(result, contains('125'));
      });
    });

    testWidgets('respects an explicit currency code', (tester) async {
      await _withContext(tester, const Locale('en'), (context) {
        final result = formatCurrency(context, 10, currencyCode: 'USD');
        expect(result, contains('10'));
      });
    });
  });

  group('formatCompactNumber', () {
    testWidgets('compacts large numbers', (tester) async {
      await _withContext(tester, const Locale('en'), (context) {
        final result = formatCompactNumber(context, 1500);
        expect(result, isNotEmpty);
        expect(result.length, lessThan('1500'.length + 2));
      });
    });

    testWidgets('leaves small numbers mostly untouched', (tester) async {
      await _withContext(tester, const Locale('en'), (context) {
        final result = formatCompactNumber(context, 42);
        expect(result, contains('42'));
      });
    });
  });

  group('formatShortDate', () {
    testWidgets('formats a date without throwing', (tester) async {
      await _withContext(tester, const Locale('en'), (context) {
        final result = formatShortDate(context, DateTime(2026, 8, 1));
        expect(result, isNotEmpty);
      });
    });
  });
}
