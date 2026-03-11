import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yeedoy/core/i18n/app_localizations.dart';
import 'package:yeedoy/features/embed/ui/embed_viewer_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('embed invalid url falls back without crash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EmbedViewerPage(url: 'ftp://example.com/resource'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.open_in_browser), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
