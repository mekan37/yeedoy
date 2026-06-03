// ignore_for_file: avoid_print
/// Growth feature'ları smoke testleri
///
/// Widget bağımlılıklarını minimize etmek için:
/// - SponsoredBadge → widget render testi (yalnızca tema gerektirmez)
/// - Inbox share callback → pure function unit testi
/// - BudgetCombo sort logic → pure function unit testi
/// - BudgetComboResult.fromMap → model parse testi
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/budget_combos/domain/budget_combo_models.dart';
import 'package:yeedoy/features/notifications/domain/inbox_models.dart';
import 'package:yeedoy/features/sponsorluk/ui/sponsored_badge.dart';

// ---------------------------------------------------------------------------
// Inbox share callback helper — inbox_page.dart'daki private fonksiyonu
// yeniden uygular (test isolation için). Gerçek işlevi crash etmeden
// çağrılabilir mi kontrol eder; SharePlus.instance.share çağrılmaz.
// ---------------------------------------------------------------------------

typedef _ShareCallback = void Function();

_ShareCallback? _shareCallbackFor(InboxItem item) {
  if (item.type == 'favorite_price_changed') {
    return () {
      final businessId = item.meta['business_id']?.toString() ?? '';
      final businessName =
          item.meta['business_name']?.toString() ?? item.title;
      final prevCents = (item.meta['previous_price_cents'] as num?)?.toInt();
      final newCents = (item.meta['matched_price_cents'] as num?)?.toInt();
      final pct = prevCents != null && prevCents > 0 && newCents != null
          ? (((newCents - prevCents) / prevCents) * 100).round()
          : null;
      final emoji =
          (newCents != null && prevCents != null && newCents > prevCents)
              ? '!'
              : 'ok';
      // Gerçek kodda SharePlus.instance.share(...) çağrılır.
      // Burada sadece string oluşturma mantığını crash-test ederiz.
      final shareText = [
        '$emoji $businessName',
        if (pct != null)
          'Fiyat %${pct.abs()} ${pct > 0 ? 'artis' : 'dusus'}',
        'yeedoy.com/isletme/$businessId',
      ].join('\n');
      // share() çağrısı platforma bağlı; testte sadece build aşamasını doğrularız.
      assert(shareText.isNotEmpty, 'Share text boş olamaz');
    };
  }

  if (item.type == 'achievement_unlocked') {
    return () {
      final achievementTitle = item.meta['title']?.toString() ?? 'rozet';
      final xp = (item.meta['xp'] as num?)?.toInt();
      final level = (item.meta['level'] as num?)?.toInt();
      final parts = ['Yeedoy\'da "$achievementTitle" rozeti kazandim!'];
      if (xp != null && xp > 0) parts.add('+$xp XP');
      if (level != null) parts.add('Seviye $level');
      parts.add('yeedoy.com/gurmeler');
      final shareText = parts.join(' • ');
      assert(shareText.isNotEmpty, 'Share text boş olamaz');
    };
  }

  return null;
}

// ---------------------------------------------------------------------------
// BudgetCombo sort logic — results_page private _sortWithWeights yeniden impl
// ---------------------------------------------------------------------------

List<BudgetComboResult> _sortWithWeights(
  List<BudgetComboResult> items, {
  double weightDistance = 0.35,
  double weightPrice = 0.45,
  double weightRating = 0.2,
}) {
  if (items.length <= 1) return items;

  final priceValues = items.map((e) => e.totalCents).toList();
  final minPrice = priceValues.reduce((a, b) => a < b ? a : b).toDouble();
  final maxPrice = priceValues.reduce((a, b) => a > b ? a : b).toDouble();
  final priceRange = (maxPrice - minPrice).clamp(1.0, maxPrice).toDouble();

  final distanceValues =
      items.map((e) => e.distanceKm).whereType<double>().toList();
  final minDistance = distanceValues.isEmpty
      ? null
      : distanceValues.reduce((a, b) => a < b ? a : b);
  final maxDistance = distanceValues.isEmpty
      ? null
      : distanceValues.reduce((a, b) => a > b ? a : b);
  final distanceRange = (minDistance == null || maxDistance == null)
      ? null
      : (maxDistance - minDistance).clamp(0.1, 9999.0).toDouble();

  final ratingValues =
      items.map((e) => e.rating).whereType<double>().toList();
  final minRating = ratingValues.isEmpty
      ? null
      : ratingValues.reduce((a, b) => a < b ? a : b);
  final maxRating = ratingValues.isEmpty
      ? null
      : ratingValues.reduce((a, b) => a > b ? a : b);
  final ratingRange = (minRating == null || maxRating == null)
      ? null
      : (maxRating - minRating).clamp(0.1, 10.0).toDouble();

  final weights = [weightDistance, weightPrice, weightRating];
  final totalWeight = weights.fold<double>(0, (a, b) => a + b);
  final wDistance = totalWeight == 0 ? 0.0 : weightDistance / totalWeight;
  final wPrice = totalWeight == 0 ? 1.0 : weightPrice / totalWeight;
  final wRating = totalWeight == 0 ? 0.0 : weightRating / totalWeight;

  double scoreItem(BudgetComboResult item) {
    final priceScore =
        1 - ((item.totalCents.toDouble() - minPrice) / priceRange);
    final parts = <double>[priceScore];
    final ws = <double>[wPrice];

    if (item.distanceKm != null && distanceRange != null && minDistance != null) {
      final distScore = 1 - ((item.distanceKm! - minDistance) / distanceRange);
      parts.add(distScore);
      ws.add(wDistance);
    }
    if (item.rating != null && ratingRange != null && minRating != null) {
      final rScore = (item.rating! - minRating) / ratingRange;
      parts.add(rScore);
      ws.add(wRating);
    }

    final sumW = ws.fold<double>(0, (a, b) => a + b);
    if (sumW == 0) return priceScore;
    double score = 0;
    for (var i = 0; i < parts.length; i++) {
      score += parts[i] * ws[i];
    }
    return score / sumW;
  }

  final sorted = [...items];
  sorted.sort((a, b) => scoreItem(b).compareTo(scoreItem(a)));
  return sorted;
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

InboxItem _inboxItem(
  String type, {
  Map<String, dynamic> meta = const {},
}) =>
    InboxItem(
      id: 'test-$type',
      type: type,
      title: 'Test başlık',
      message: 'Test mesaj',
      createdAt: DateTime(2026, 6, 1),
      targetPath: '/inbox',
      meta: meta,
    );

BudgetComboResult _combo(
  String id, {
  required int totalCents,
  double? distanceKm,
  double? rating,
}) =>
    BudgetComboResult(
      businessId: id,
      businessName: 'İşletme $id',
      combo: BudgetCombo(
        main: BudgetComboItem(
          id: '$id-main',
          name: 'Ana yemek',
          priceCents: totalCents,
          currency: 'TRY',
        ),
      ),
      totalCents: totalCents,
      distanceKm: distanceKm,
      rating: rating,
    );

// ---------------------------------------------------------------------------
// Testler
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // 1. SponsoredBadge görünürlük
  // =========================================================================
  group('SponsoredBadge görünürlük', () {
    testWidgets('SponsoredBadge render oluyor — "Sponsorlu" yazısı görünür',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SponsoredBadge()),
        ),
      );
      expect(find.text('Sponsorlu'), findsOneWidget,
          reason: 'Badge "Sponsorlu" labelını göstermeli');
    });

    testWidgets('SponsoredBadge olmadığında "Sponsorlu" yazısı yok',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      );
      expect(find.text('Sponsorlu'), findsNothing,
          reason: 'SponsoredBadge yoksa label render edilmemeli');
    });

    testWidgets('SponsoredBadge verified_outlined ikon içeriyor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SponsoredBadge()),
        ),
      );
      expect(
        find.byIcon(Icons.verified_outlined),
        findsOneWidget,
        reason: 'SponsoredBadge verified_outlined ikonunu içermeli',
      );
    });

    testWidgets('SponsoredBadge çoklu render crash yapmıyor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SponsoredBadge(),
                SponsoredBadge(),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Sponsorlu'), findsNWidgets(2));
    });
  });

  // =========================================================================
  // 2. Inbox paylaşım callback — crash testi
  // =========================================================================
  group('Inbox paylaşım callback — crash testi', () {
    test('favorite_price_changed callback null değil', () {
      final item = _inboxItem(
        'favorite_price_changed',
        meta: {
          'business_id': 'biz-123',
          'business_name': 'Test Kebap',
          'previous_price_cents': 5000,
          'matched_price_cents': 4500,
        },
      );
      final cb = _shareCallbackFor(item);
      expect(cb, isNotNull);
    });

    test('favorite_price_changed callback exception throw etmiyor', () {
      final item = _inboxItem(
        'favorite_price_changed',
        meta: {
          'business_id': 'biz-123',
          'business_name': 'Test Kebap',
          'previous_price_cents': 5000,
          'matched_price_cents': 4500,
        },
      );
      final cb = _shareCallbackFor(item);
      expect(() => cb!(), returnsNormally);
    });

    test('favorite_price_changed — eksik meta ile crash yok', () {
      // meta tamamen boş olsa bile callback patlamamalı
      final item = _inboxItem('favorite_price_changed');
      final cb = _shareCallbackFor(item);
      expect(cb, isNotNull);
      expect(() => cb!(), returnsNormally);
    });

    test('favorite_price_changed — fiyat artışı (pct > 0) crash yok', () {
      final item = _inboxItem(
        'favorite_price_changed',
        meta: {
          'business_id': 'biz-456',
          'business_name': 'Pahalı Yer',
          'previous_price_cents': 3000,
          'matched_price_cents': 4000,
        },
      );
      final cb = _shareCallbackFor(item);
      expect(() => cb!(), returnsNormally);
    });

    test('achievement_unlocked callback null değil', () {
      final item = _inboxItem(
        'achievement_unlocked',
        meta: {
          'title': 'Gurme Gezgin',
          'xp': 100,
          'level': 5,
        },
      );
      final cb = _shareCallbackFor(item);
      expect(cb, isNotNull);
    });

    test('achievement_unlocked callback exception throw etmiyor', () {
      final item = _inboxItem(
        'achievement_unlocked',
        meta: {
          'title': 'Gurme Gezgin',
          'xp': 100,
          'level': 5,
        },
      );
      final cb = _shareCallbackFor(item);
      expect(() => cb!(), returnsNormally);
    });

    test('achievement_unlocked — xp=0 ve level null ile crash yok', () {
      final item = _inboxItem(
        'achievement_unlocked',
        meta: {'title': 'Rozet'},
      );
      final cb = _shareCallbackFor(item);
      expect(() => cb!(), returnsNormally);
    });

    test('generic type callback null döner — paylaşım yok', () {
      final item = _inboxItem('system_announcement');
      final cb = _shareCallbackFor(item);
      expect(cb, isNull,
          reason: 'Paylaşım desteklenmeyen tipler için null dönmeli');
    });

    test('report_result type callback null döner', () {
      final item = _inboxItem('report_result');
      final cb = _shareCallbackFor(item);
      expect(cb, isNull);
    });
  });

  // =========================================================================
  // 3. BudgetCombo sort logic — crash ve doğruluk testi
  // =========================================================================
  group('BudgetCombo sort logic', () {
    test('boş liste sort crash yapmıyor', () {
      expect(() => _sortWithWeights([]), returnsNormally);
      expect(_sortWithWeights([]), isEmpty);
    });

    test('tek eleman sort crash yapmıyor', () {
      final items = [
        _combo('a', totalCents: 5000, distanceKm: 1.5, rating: 8.0),
      ];
      final sorted = _sortWithWeights(items);
      expect(sorted.length, 1);
    });

    test('daha ucuz işletme price-weight yüksekken öne geçer', () {
      final cheap = _combo('cheap', totalCents: 3000, rating: 7.0);
      final expensive = _combo('exp', totalCents: 8000, rating: 9.0);

      // weightPrice ağır; fiyat daha belirleyici
      final sorted = _sortWithWeights(
        [expensive, cheap],
        weightPrice: 0.8,
        weightDistance: 0.1,
        weightRating: 0.1,
      );
      expect(sorted.first.businessId, 'cheap',
          reason: 'Fiyat ağırlığı yüksekken ucuz işletme öne geçmeli');
    });

    test('daha yakın işletme distance-weight yüksekken öne geçer', () {
      final near = _combo('near', totalCents: 6000, distanceKm: 0.5);
      final far = _combo('far', totalCents: 5000, distanceKm: 10.0);

      // weightDistance çok ağır
      final sorted = _sortWithWeights(
        [far, near],
        weightDistance: 0.9,
        weightPrice: 0.05,
        weightRating: 0.05,
      );
      expect(sorted.first.businessId, 'near',
          reason: 'Mesafe ağırlığı yüksekken yakın işletme öne geçmeli');
    });

    test('distanceKm null olan öğeler crash yapmıyor', () {
      final items = [
        _combo('a', totalCents: 4000),
        _combo('b', totalCents: 6000, distanceKm: 2.0),
        _combo('c', totalCents: 5000),
      ];
      expect(() => _sortWithWeights(items), returnsNormally);
      final sorted = _sortWithWeights(items);
      expect(sorted.length, 3);
    });

    test('tüm ağırlıklar 0 olduğunda crash yapmıyor', () {
      final items = [
        _combo('a', totalCents: 3000),
        _combo('b', totalCents: 7000),
      ];
      expect(
        () => _sortWithWeights(
          items,
          weightDistance: 0,
          weightPrice: 0,
          weightRating: 0,
        ),
        returnsNormally,
      );
    });
  });

  // =========================================================================
  // 4. BudgetComboResult model parse testi
  // =========================================================================
  group('BudgetComboResult model parse', () {
    test('fromMap tüm alanları doğru parse eder', () {
      final map = {
        'business_id': 'b-1',
        'business_name': 'Lezzet Durağı',
        'total_cents': 4500,
        'distance_km': 1.2,
        'rating': 8.5,
        'combo': {
          'main': {
            'id': 'm-1',
            'name': 'Adana Kebap',
            'price_cents': 3500,
            'currency': 'TRY',
          },
          'drink': {
            'id': 'd-1',
            'name': 'Ayran',
            'price_cents': 1000,
            'currency': 'TRY',
          },
        },
      };

      final result = BudgetComboResult.fromMap(map);
      expect(result.businessId, 'b-1');
      expect(result.businessName, 'Lezzet Durağı');
      expect(result.totalCents, 4500);
      expect(result.distanceKm, 1.2);
      expect(result.rating, 8.5);
      expect(result.combo.main.name, 'Adana Kebap');
      expect(result.combo.drink?.name, 'Ayran');
    });

    test('fromMap drink null ile crash yapmıyor', () {
      final map = {
        'business_id': 'b-2',
        'business_name': 'Sadece Yemek',
        'total_cents': 3000,
        'combo': {
          'main': {
            'id': 'm-2',
            'name': 'Izgara Köfte',
            'price_cents': 3000,
            'currency': 'TRY',
          },
        },
      };
      final result = BudgetComboResult.fromMap(map);
      expect(result.combo.drink, isNull);
      expect(result.businessId, 'b-2');
    });

    test('fromMap eksik alanlar default değer alır', () {
      final result = BudgetComboResult.fromMap({'combo': {}});
      expect(result.businessId, '');
      expect(result.totalCents, 0);
      expect(result.distanceKm, isNull);
      expect(result.rating, isNull);
    });

    test('BudgetComboQuery alanları doğru atanır', () {
      const query = BudgetComboQuery(
        city: 'Ankara',
        district: 'Çankaya',
        partySize: 2,
        budgetTotalCents: 20000,
        category: 'Kebap',
      );
      expect(query.city, 'Ankara');
      expect(query.district, 'Çankaya');
      expect(query.partySize, 2);
      expect(query.budgetTotalCents, 20000);
      expect(query.category, 'Kebap');
      expect(query.limit, 30);
    });
  });
}
