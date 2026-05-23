import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/shared/ui/components/community_score_explainer_sheet.dart';
import 'package:yeedoy/l10n/app_localizations.dart';

void main() {
  Future<void> pumpGuide(
    WidgetTester tester, {
    required CommunityScoreKind kind,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CommunityScoreGuideCard(
            kind: kind,
            margin: EdgeInsets.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders user trust guide copy', (tester) async {
    await pumpGuide(tester, kind: CommunityScoreKind.userTrust);

    expect(find.text('Kullanıcı güveni'), findsOneWidget);
    expect(find.text('Topluluk güveni'), findsOneWidget);
    expect(
      find.textContaining('Popülerlik değil, doğruluk ve onay kalitesi'),
      findsOneWidget,
    );
  });

  testWidgets('renders data trust guide copy', (tester) async {
    await pumpGuide(tester, kind: CommunityScoreKind.dataTrust);

    expect(find.text('Veri güveni'), findsWidgets);
    expect(
      find.textContaining(
        'Bir menü veya fiyat bilgisinin şu anda ne kadar güvenilir olduğunu gösterir.',
      ),
      findsOneWidget,
    );
  });
}
