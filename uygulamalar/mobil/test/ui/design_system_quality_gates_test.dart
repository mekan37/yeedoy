import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/app/theme/app_tokens.dart';
import 'package:yeedoy/features/shared/ui/components/app_badge.dart';
import 'package:yeedoy/features/shared/ui/components/app_button.dart';
import 'package:yeedoy/features/shared/ui/components/app_chip.dart';
import 'package:yeedoy/features/shared/ui/components/app_empty_state.dart';

void main() {
  ThemeData testTheme() {
    return ThemeData(
      extensions: const <ThemeExtension<dynamic>>[
        AppTokens(
          space4: 4,
          space8: 8,
          space12: 12,
          space16: 16,
          space20: 20,
          space24: 24,
          radius12: 12,
          radius16: 16,
          radius20: 20,
          radius24: 24,
          elevation1: 1,
          elevation2: 6,
          elevation3: 12,
          minHitTarget: 44,
          fast: Duration(milliseconds: 150),
          medium: Duration(milliseconds: 180),
          slow: Duration(milliseconds: 220),
        ),
      ],
    );
  }

  testWidgets('components render with larger font scaling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: ListView(
              children: const [
                AppButton(label: 'Kaydet', onPressed: null),
                AppChip(label: 'Etiket'),
                AppBadge(label: 'Durum'),
                AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Kayit yok',
                  description: 'Ilk menuyu ekleyin.',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('primary button keeps min hit target >= 44', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        home: Scaffold(
          body: Center(
            child: AppButton(
              label: 'Onayla',
              semanticLabel: 'Onayla',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    final buttonFinder = find.byType(FilledButton);
    expect(buttonFinder, findsOneWidget);
    final size = tester.getSize(buttonFinder);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
  });
}

