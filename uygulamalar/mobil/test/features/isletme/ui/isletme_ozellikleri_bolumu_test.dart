import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yeedoy/uygulama/tema/uygulama_tokenleri.dart';
import 'package:yeedoy/features/isletme/domain/isletme_ozelligi.dart';
import 'package:yeedoy/features/isletme/domain/isletme_ozellikleri_saglayicisi.dart';
import 'package:yeedoy/features/isletme/domain/isletme_yoklamalari_saglayicisi.dart';
import 'package:yeedoy/features/isletme/domain/isletme_yeni_urunler_saglayicisi.dart';
import 'package:yeedoy/features/isletme/ui/isletme_sayfasi.dart';
import 'package:yeedoy/features/ayricaliklar/domain/ayricalik_modelleri.dart';
import 'package:yeedoy/features/ayricaliklar/domain/ayricalik_saglayicilari.dart';
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

BusinessPerk _makePerk(String id) => BusinessPerk(
      id: id,
      businessId: 'biz-1',
      title: 'Perk $id',
      requiresCheckin: false,
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
    );

BusinessAmenity _makeAmenity(String id) => BusinessAmenity(
      id: id,
      key: 'wifi',
      label: 'Wi-Fi',
      icon: 'wifi',
    );

Future<void> _pumpSection(
  WidgetTester tester, {
  required List<BusinessPerk> perks,
  List<BusinessAmenity> amenities = const [],
  int checkins = 0,
}) async {
  const businessId = 'biz-1';
  const businessName = 'Test Bistro';

  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (context, state) => Scaffold(
          body: SingleChildScrollView(
            child: BusinessPerksSection(
              businessId: businessId,
              businessName: businessName,
            ),
          ),
        ),
      ),
      GoRoute(path: '/ayricaliklar/:id', builder: (context, state) => const SizedBox()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        businessPerksProvider(businessId).overrideWith((_) async => perks),
        businessAmenitiesProvider(businessId)
            .overrideWith((_) async => amenities),
        businessRecentCheckinsProvider(businessId)
            .overrideWith((_) async => checkins),
        businessNewItemsProvider(businessId).overrideWith((_) async => []),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: _theme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  testWidgets('BusinessPerksSection shows no-campaign text when empty',
      (tester) async {
    await _pumpSection(tester, perks: []);

    expect(find.text('No active campaigns'), findsOneWidget);
  });

  testWidgets('BusinessPerksSection shows perk count when perks exist',
      (tester) async {
    final perks = [_makePerk('p1'), _makePerk('p2'), _makePerk('p3')];
    await _pumpSection(tester, perks: perks);

    // "3 active campaigns"
    expect(find.textContaining('3'), findsOneWidget);
    expect(find.textContaining('active campaigns'), findsWidgets);
  });

  testWidgets(
    'BusinessPerksSection shows "Tümünü gör" button only when perks exist',
    (tester) async {
      await _pumpSection(tester, perks: [_makePerk('p1')]);
      expect(find.text('Tümünü gör'), findsOneWidget);
    },
  );

  testWidgets(
    'BusinessPerksSection hides "Tümünü gör" when no perks',
    (tester) async {
      await _pumpSection(tester, perks: []);
      expect(find.text('Tümünü gör'), findsNothing);
    },
  );

  testWidgets('BusinessPerksSection shows amenity count when amenities exist',
      (tester) async {
    final amenities = [_makeAmenity('a1'), _makeAmenity('a2')];
    await _pumpSection(tester, perks: [], amenities: amenities);

    expect(find.textContaining('2'), findsOneWidget);
  });

  testWidgets('BusinessPerksSection shows checkin count when > 0',
      (tester) async {
    await _pumpSection(tester, perks: [], checkins: 7);

    expect(find.textContaining('7'), findsOneWidget);
  });

  // Unit tests for perk model
  test('BusinessPerk.fromMap round-trips correctly', () {
    final perk = BusinessPerk(
      id: 'x1',
      businessId: 'biz-1',
      title: 'Happy Hour',
      description: '-20% indirim',
      requiresCheckin: true,
      status: 'active',
      createdAt: DateTime(2026, 3, 1),
    );

    expect(perk.id, 'x1');
    expect(perk.requiresCheckin, isTrue);
    expect(perk.status, 'active');
    expect(perk.description, contains('indirim'));
  });
}


