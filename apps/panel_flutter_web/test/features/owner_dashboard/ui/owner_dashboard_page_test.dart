import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/app/theme/app_tokens.dart';
import 'package:yeedoy/core/security/app_role_providers.dart';
import 'package:yeedoy/core/security/business_rbac.dart';
import 'package:yeedoy/features/owner_businesses/domain/owner_business_state.dart';
import 'package:yeedoy/features/owner_dashboard/domain/owner_growth_provider.dart';
import 'package:yeedoy/features/owner_dashboard/domain/owner_kpi_provider.dart';
import 'package:yeedoy/features/owner_dashboard/domain/owner_moat_provider.dart';
import 'package:yeedoy/features/owner_dashboard/domain/owner_quality_score_provider.dart';
import 'package:yeedoy/features/owner_dashboard/ui/owner_dashboard_page.dart';
import 'package:yeedoy/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
ThemeData _theme() => ThemeData(
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

OwnerKpiSummary _kpi() => const OwnerKpiSummary(
      businessViews: 120,
      outboundClicks: 30,
      directionsClicks: 12,
      searchImpressions: 450,
    );

OwnerGrowthSummary _growth() => const OwnerGrowthSummary(
      menuViews: 88,
      qrScans: 5,
      searchImpressions: 210,
      conversions: 14,
      outboundClicks: 9,
      reservationClicks: 3,
      orderClicks: 7,
      priceDropoffEstimate: 0,
      districtPriceGapPct: null,
      districtPricePosition: 'orta',
    );

OwnerQualityScore _quality() => const OwnerQualityScore(
      score: 74,
      tips: [],
      breakdown: {},
    );

OwnerMoatSummary _moat() => OwnerMoatSummary(
      businessTrustScore: 80,
      menuFreshnessScore: 65,
      priceAccuracyScore: 90,
      contributionTrustScore: 55,
      uniqueValidators: 3,
      lastPriceVerificationAt: DateTime(2026, 4, 1),
      evidenceRate: 0.7,
      contributionQualityRate: 0.6,
      menuViewsToday: 42,
      districtRank: 2,
    );

Future<void> _pumpDashboard(
  WidgetTester tester, {
  String? businessId,
  bool hasPermission = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        selectedOwnerBusinessIdProvider.overrideWith((_) => businessId),
        ownerKpiSummaryProvider(businessId).overrideWith((_) async => _kpi()),
        ownerGrowthSummaryProvider(businessId).overrideWith((_) async => _growth()),
        ownerQualityScoreProvider(businessId).overrideWith((_) async => _quality()),
        ownerMoatSummaryProvider(businessId).overrideWith((_) async => _moat()),
        if (businessId != null)
          hasBusinessPermissionProvider((businessId, BusinessPermission.businessRead))
              .overrideWith((_) async => hasPermission),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: _theme(),
        home: const Scaffold(
          body: OwnerDashboardPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  testWidgets('OwnerDashboardPage renders page header', (tester) async {
    await _pumpDashboard(tester);

    expect(find.text('Genel Bakış'), findsOneWidget);
  });

  testWidgets('OwnerDashboardPage shows section labels', (tester) async {
    await _pumpDashboard(tester);

    expect(find.text('PERFORMANS'), findsOneWidget);
    expect(find.text('İŞLETME SAĞLIĞI'), findsOneWidget);
  });

  testWidgets('OwnerDashboardPage shows no-permission message when denied',
      (tester) async {
    await _pumpDashboard(
      tester,
      businessId: 'biz-1',
      hasPermission: false,
    );

    expect(find.text('Genel Bakış'), findsNothing);
  });

  testWidgets(
    'OwnerDashboardPage refresh button is present',
    (tester) async {
      await _pumpDashboard(tester);

      expect(find.text('Yenile'), findsOneWidget);
    },
  );

  // Unit tests for KPI model
  test('OwnerKpiSummary.fromMap parses values correctly', () {
    final kpi = OwnerKpiSummary.fromMap({
      'business_views': 100,
      'outbound_clicks': 20,
      'directions_clicks': 5,
      'search_impressions': 300,
    });

    expect(kpi.businessViews, 100);
    expect(kpi.outboundClicks, 20);
    expect(kpi.directionsClicks, 5);
    expect(kpi.searchImpressions, 300);
  });

  test('OwnerKpiSummary.fromMap handles null values as 0', () {
    final kpi = OwnerKpiSummary.fromMap({});
    expect(kpi.businessViews, 0);
    expect(kpi.searchImpressions, 0);
  });

  test('OwnerQualityScore.fromMap parses score and tips', () {
    final q = OwnerQualityScore.fromMap({
      'score': 82,
      'tips': ['Menü güncelle', 'Fotoğraf ekle'],
      'breakdown': {'menu': 90, 'photos': 70},
    });

    expect(q.score, 82);
    expect(q.tips, hasLength(2));
    expect(q.tips.first, 'Menü güncelle');
  });
}
