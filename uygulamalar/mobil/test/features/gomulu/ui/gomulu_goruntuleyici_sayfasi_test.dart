import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/i18n/app_localizations.dart';
import 'package:yeedoy/features/embed/ui/embed_viewer_page.dart';
import 'package:yeedoy/features/embed/ui/providers/embed_provider_youtube.dart';

void main() {
  Widget wrapWithApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('EmbedViewerPage shows fallback info for invalid url', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(const EmbedViewerPage(url: 'ftp://example.com/resource')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.open_in_browser), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('EmbedProviderYoutube shows fallback text for invalid source', (
    tester,
  ) async {
    const fallback = 'Embed yuklenemedi';
    await tester.pumpWidget(
      wrapWithApp(
        const Scaffold(
          body: EmbedProviderYoutube(
            sourceUrl: 'https://youtube.com/watch?v=',
            fallbackMessage: fallback,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(fallback), findsOneWidget);
  });
}


