import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/core/analytics/analytics_repository.dart';
import 'package:yeedoy/core/cache/request_cache.dart';
import 'package:yeedoy/core/monitoring/app_telemetry.dart';
import 'package:yeedoy/features/business/data/meal_card_providers_repository.dart';
import 'package:yeedoy/features/discovery/data/search_repository.dart';
import 'package:yeedoy/features/discovery/domain/business_card.dart';
import 'package:yeedoy/features/discovery/domain/discovery_search_notifier.dart';

// B43 (mimari denetim): en karmaşık, hiç test edilmemiş controller.
// SearchRepository somut bir sınıf (arayüz değil) ve gerçek bir
// SupabaseClient/AppTelemetry/RequestCache/MealCardProvidersRepository
// bekliyor — testte gerçek ağa hiç dokunmayan bir alt sınıf ile
// searchBusinesses/searchNearby/enrichBusinessCards override ediliyor,
// super() zincirindeki bağımlılıklar asla çağrılmadığı için zararsız
// (dummy) değerlerle kuruluyor.
//
// NOT: build() kendi içinde bir Future.microtask ile loadInitial()'ı
// otomatik tetikliyor (gerçek uygulamadaki ilk ekran açılışı davranışı).
// Testler bunu manuel bir loadInitial() çağrısıyla İKİNCİ kez tetiklemek
// yerine (ki bu, _requestId yarışına ve çift fetch'e yol açar) bu otomatik
// yüklemenin bitmesini bekleyip oradan devam ediyor.
class _FakeSearchRepository extends SearchRepository {
  _FakeSearchRepository({
    required this.pages,
    this.throwOnFetch,
  }) : super(
          SupabaseClient('https://example.invalid', 'anon-key'),
          AppTelemetry(AnalyticsRepository.forTest(rpc: (_, {params}) async => {'ok': true})),
          RequestCache(),
          MealCardProvidersRepository(SupabaseClient('https://example.invalid', 'anon-key')),
        );

  /// offset -> dönecek sayfa. Bulunamayan offset boş liste döner (hasMore=false).
  final Map<int, List<BusinessCardModel>> pages;
  final Object? throwOnFetch;
  int searchCallCount = 0;
  int enrichCallCount = 0;
  List<int> requestedOffsets = [];

  @override
  void clearCache() {}

  @override
  Future<List<BusinessCardModel>> searchBusinesses({
    required String query,
    String? city,
    String? district,
    List<String> mealCardKeys = const [],
    int limit = 20,
    int offset = 0,
  }) async {
    searchCallCount++;
    requestedOffsets.add(offset);
    if (throwOnFetch != null) throw throwOnFetch!;
    return pages[offset] ?? const [];
  }

  @override
  Future<List<BusinessCardModel>> searchNearby({
    required double userLat,
    required double userLng,
    double radiusKm = 5,
    String? query,
    String? city,
    String? district,
    List<String> mealCardKeys = const [],
    int limit = 50,
    int offset = 0,
  }) async {
    searchCallCount++;
    requestedOffsets.add(offset);
    if (throwOnFetch != null) throw throwOnFetch!;
    return pages[offset] ?? const [];
  }

  @override
  Future<List<BusinessCardModel>> enrichBusinessCards(
    List<BusinessCardModel> input,
  ) async {
    enrichCallCount++;
    return input;
  }
}

BusinessCardModel _card(
  String id, {
  String category = 'Restoran',
  double? avgRating,
  double? distanceKm,
}) {
  return BusinessCardModel(
    id: id,
    name: 'Business $id',
    category: category,
    avgRating: avgRating,
    distanceKm: distanceKm,
  );
}

Future<void> _pumpUntilLoaded(
  ProviderContainer container, {
  int maxTicks = 50,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (!container.read(discoverySearchProvider).loading) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('discoverySearchProvider hâlâ loading, initial load hiç bitmedi');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Container'ı kurar, notifier'ı okuyup build()'ın otomatik tetiklediği
  /// ilk loadInitial()'ın bitmesini bekler. Testler buradan devam eder.
  Future<(ProviderContainer, DiscoverySearchNotifier)> setup(
    _FakeSearchRepository fake,
  ) async {
    final container = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(fake),
        // loadInitial() ilk başarılı yüklemede appTelemetryProvider'ı
        // ref.read ile OKUYOR (override edilmezse gerçek Supabase.instance'a
        // zincirlenip "not initialized" fırlatıyor ve bu, catch bloğunda
        // state.error'ı kirletip testin gerçek fetch-hatası senaryosuyla
        // karışmasına yol açıyor).
        appTelemetryProvider.overrideWithValue(
          AppTelemetry(AnalyticsRepository.forTest(rpc: (_, {params}) async => {'ok': true})),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(discoverySearchProvider.notifier);
    await _pumpUntilLoaded(container);
    return (container, notifier);
  }

  group('DiscoverySearchNotifier initial load (via build())', () {
    test('populates items from page 0 and sets hasMore based on page size', () async {
      final fake = _FakeSearchRepository(pages: {
        0: [_card('a'), _card('b')],
      });
      final (container, _) = await setup(fake);
      final state = container.read(discoverySearchProvider);

      expect(state.items.map((b) => b.id), containsAll(['a', 'b']));
      // pageSize=20, döndürülen 2 satır < pageSize -> hasMore=false
      expect(state.hasMore, isFalse);
    });

    test('surfaces fetch errors without crashing', () async {
      final fake = _FakeSearchRepository(
        pages: const {},
        throwOnFetch: Exception('network_down'),
      );
      final (container, _) = await setup(fake);
      final state = container.read(discoverySearchProvider);

      expect(state.loading, isFalse);
      expect(state.error, isA<Exception>());
      expect(state.error.toString(), contains('network_down'));
      expect(state.items, isEmpty);
    });
  });

  group('DiscoverySearchNotifier.loadMore (B14/B56 offset & O(n^2) fix)', () {
    test('uses raw (pre-filter) offset for the next page, not the filtered item count', () async {
      // Sayfa 0'da 20 satır (pageSize) dönüyor ki hasMore=true olsun ve
      // loadMore tetiklenebilsin; sayfa "offset=20"de yeni satırlar var.
      final page0 = List.generate(20, (i) => _card('p0-$i'));
      final page1 = [_card('p1-0'), _card('p1-1')];
      final fake = _FakeSearchRepository(pages: {0: page0, 20: page1});
      final (container, notifier) = await setup(fake);
      expect(container.read(discoverySearchProvider).hasMore, isTrue);
      expect(fake.requestedOffsets, [0]);

      await notifier.loadMore();
      final state = container.read(discoverySearchProvider);

      // loadMore ikinci _fetchPage çağrısını HAM offset (20) ile yapmalı,
      // filtrelenmiş öğe sayısıyla değil.
      expect(fake.requestedOffsets, [0, 20]);
      expect(state.items.length, 22);
      expect(state.hasMore, isFalse); // page1.length(2) < pageSize(20)
    });

    test('enriches only the new page, not the whole accumulated list (B14)', () async {
      final page0 = List.generate(20, (i) => _card('p0-$i'));
      final page1 = [_card('p1-0')];
      final fake = _FakeSearchRepository(pages: {0: page0, 20: page1});
      final (_, notifier) = await setup(fake);
      final enrichCallsAfterInitial = fake.enrichCallCount;

      await notifier.loadMore();

      // loadMore, enrichBusinessCards'ı yalnızca YENİ sayfa (1 öğe) için bir
      // kez daha çağırmalı — tüm birikmiş listeyi (21 öğe) değil.
      expect(fake.enrichCallCount, enrichCallsAfterInitial + 1);
    });

    test('does not duplicate items already present (dedupe by id)', () async {
      final page0 = List.generate(20, (i) => _card('p0-$i'));
      // Sunucu aynı id'yi tekrar döndürürse (ör. sıralama kayması) client
      // dedupe etmeli.
      final page1 = [_card('p0-0'), _card('new-1')];
      final fake = _FakeSearchRepository(pages: {0: page0, 20: page1});
      final (container, notifier) = await setup(fake);

      await notifier.loadMore();
      final state = container.read(discoverySearchProvider);

      expect(state.items.where((b) => b.id == 'p0-0').length, 1);
      expect(state.items.any((b) => b.id == 'new-1'), isTrue);
    });

    test('is a no-op once hasMore is false', () async {
      final fake = _FakeSearchRepository(pages: {
        0: [_card('a')],
      });
      final (container, notifier) = await setup(fake);
      expect(container.read(discoverySearchProvider).hasMore, isFalse);

      final callsBefore = fake.searchCallCount;
      await notifier.loadMore();
      expect(fake.searchCallCount, callsBefore); // hasMore=false -> hiç fetch yok
    });
  });

  group('DiscoverySearchNotifier filtering', () {
    test('setFilters(minRating) drops businesses below the threshold and reloads', () async {
      final fake = _FakeSearchRepository(pages: {
        0: [
          _card('low', avgRating: 2.0),
          _card('high', avgRating: 4.5),
        ],
      });
      final (container, notifier) = await setup(fake);

      await notifier.setFilters(minRating: 4.0);
      final state = container.read(discoverySearchProvider);

      expect(state.items.map((b) => b.id), ['high']);
    });

    test('setQuery with empty string reloads the unfiltered base list (B54)', () async {
      final fake = _FakeSearchRepository(pages: {
        0: [_card('a'), _card('b')],
      });
      final (container, notifier) = await setup(fake);

      notifier.setQuery('', withDebounce: false);
      // withDebounce:false dalı loadInitial()'ı unawaited çağırır — bitmesini bekle.
      await _pumpUntilLoaded(container);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(discoverySearchProvider);
      expect(state.items.length, 2);
    });
  });
}
