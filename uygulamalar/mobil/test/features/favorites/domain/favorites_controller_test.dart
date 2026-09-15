import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/features/auth/domain/auth_providers.dart';
import 'package:yeedoy/features/discovery/domain/business_card.dart';
import 'package:yeedoy/features/favorites/data/favorites_repository.dart';
import 'package:yeedoy/features/favorites/domain/favorite_status_provider.dart';
import 'package:yeedoy/features/favorites/domain/favorites_controller.dart';

// B43 (mimari denetim): iyimser toggle+rollback + B03/B52 regresyonlarını
// kilitleyen ilk test seti. FavoritesRepository somut bir sınıf (arayüz
// değil, forTest yok) — searchRepositoryProvider testinde kurulan aynı
// "alt sınıf + zararsız dummy SupabaseClient" deseni burada da kullanılıyor.
class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository({
    this.pages = const {},
    this.setFavoriteImpl,
  }) : super(SupabaseClient('https://example.invalid', 'anon-key'));

  // cursorKey (afterBusinessId ?? 'first') -> sayfa
  final Map<String, PaginatedFavorites> pages;
  Future<bool> Function(String businessId, bool isFavorited)? setFavoriteImpl;

  final List<String?> requestedCursors = [];

  @override
  Future<PaginatedFavorites?> getCachedFavorites() async => null;

  @override
  Future<PaginatedFavorites> fetchMyFavoritesWithBusinesses({
    int limit = 50,
    DateTime? afterFavoritedAt,
    String? afterBusinessId,
  }) async {
    final key = afterBusinessId ?? 'first';
    requestedCursors.add(afterBusinessId);
    return pages[key] ?? const PaginatedFavorites(ids: [], items: []);
  }

  @override
  Future<bool> isFavorited(String businessId) async => false;

  @override
  Future<bool> setFavorite(String businessId, {required bool isFavorited}) {
    if (setFavoriteImpl != null) return setFavoriteImpl!(businessId, isFavorited);
    return Future.value(isFavorited);
  }

  @override
  Future<BusinessCardModel?> fetchBusinessById(String businessId) {
    return Future.value(_card(businessId));
  }
}

BusinessCardModel _card(String id) =>
    BusinessCardModel(id: id, name: 'Business $id', category: 'Restoran');

User _stubUser({String id = 'user-1'}) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

// FavoritesPagingState.initial()'ın isLoading'i (discovery'nin loading:true
// varsayılanının aksine) false — yani build()'ın Future.microtask ile
// tetiklediği ilk loadInitial() henüz başlamadan "loading değil" görünüyor.
// pumpEventQueue tüm bekleyen microtask/Future zincirini (gerçek ağ
// gecikmesi olmadığından) güvenle tüketir; isLoading'e bakan bir polling
// yerine bunu kullanmak premature-assert riskini ortadan kaldırıyor.
Future<void> _settle() => pumpEventQueue(times: 20);

void main() {
  ProviderContainer buildContainer(
    _FakeFavoritesRepository fake, {
    bool anonymous = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(fake),
        userProvider.overrideWithValue(anonymous ? null : _stubUser()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('FavoritesController.loadInitial', () {
    test('loads first page and marks hasMore when a full page returns', () async {
      final fake = _FakeFavoritesRepository(pages: {
        'first': PaginatedFavorites(
          ids: List.generate(20, (i) => 'b$i'),
          items: List.generate(20, (i) => _card('b$i')),
          cursorFavoritedAt: DateTime(2026, 1, 1),
          cursorBusinessId: 'b19',
        ),
      });
      final container = buildContainer(fake);
      container.read(favoritesControllerProvider.notifier);
      await _settle();

      final state = container.read(favoritesControllerProvider);
      expect(state.items.length, 20);
      expect(state.hasMore, isTrue);
    });

    test('does nothing when there is no logged-in user', () async {
      final fake = _FakeFavoritesRepository();
      final container = buildContainer(fake, anonymous: true);
      final notifier = container.read(favoritesControllerProvider.notifier);
      await notifier.loadInitial();

      final state = container.read(favoritesControllerProvider);
      expect(state.hasMore, isFalse);
      expect(state.items, isEmpty);
      expect(fake.requestedCursors, isEmpty);
    });
  });

  group('FavoritesController.refresh (B03 regression)', () {
    test('refresh() does not set isLoading before calling loadInitial, so it never self-locks', () async {
      // B03: refresh() eskiden isLoading:true set edip loadInitial()'ı
      // çağırıyordu; loadInitial()'ın kendi `if (state.isLoading) return;`
      // guard'ı bu yüzden anında devreye girip fonksiyonu hiçbir şey
      // yapmadan bitiriyordu — liste kalıcı olarak sonsuz spinner'da kalıyordu.
      final fake = _FakeFavoritesRepository(pages: {
        'first': PaginatedFavorites(
          ids: ['b1'],
          items: [_card('b1')],
        ),
      });
      final container = buildContainer(fake);
      final notifier = container.read(favoritesControllerProvider.notifier);
      await _settle();

      await notifier.refresh();
      final state = container.read(favoritesControllerProvider);

      // Regresyon olsaydı: items boş kalır, isLoading sonsuza kadar true kalırdı.
      expect(state.isLoading, isFalse);
      expect(state.items, isNotEmpty);
    });
  });

  group('FavoritesController.loadMore (B52 cursor regression)', () {
    test('paginates using the keyset cursor, not an offset, and appends without duplicates', () async {
      final page1Ids = List.generate(20, (i) => 'b$i');
      final fake = _FakeFavoritesRepository(pages: {
        'first': PaginatedFavorites(
          ids: page1Ids,
          items: page1Ids.map(_card).toList(),
          cursorFavoritedAt: DateTime(2026, 1, 1),
          cursorBusinessId: 'b19',
        ),
        'b19': PaginatedFavorites(
          ids: ['b19', 'b20'], // sunucu son satırı (b19) tekrar döndürebilir
          items: [_card('b19'), _card('b20')],
        ),
      });
      final container = buildContainer(fake);
      final notifier = container.read(favoritesControllerProvider.notifier);
      await _settle();
      expect(container.read(favoritesControllerProvider).hasMore, isTrue);

      await notifier.loadMore();
      final state = container.read(favoritesControllerProvider);

      // loadMore ikinci çağrıyı b19 cursor'ıyla yapmalı (offset değil).
      expect(fake.requestedCursors, [null, 'b19']);
      // b19 zaten listede vardı — tekrar eklenmemeli (stale-id/duplicate fix).
      expect(state.items.where((b) => b.id == 'b19').length, 1);
      expect(state.items.any((b) => b.id == 'b20'), isTrue);
      expect(state.hasMore, isFalse); // page2.length(2) < pageSize(20)
    });
  });

  group('FavoritesController.toggleFavorite', () {
    test('optimistically removes an already-favorited item, keeps it removed on success', () async {
      final fake = _FakeFavoritesRepository(
        pages: {
          'first': PaginatedFavorites(ids: ['b1'], items: [_card('b1')]),
        },
        setFavoriteImpl: (id, isFav) async => isFav,
      );
      final container = buildContainer(fake);
      final notifier = container.read(favoritesControllerProvider.notifier);
      await _settle();
      container.read(favoriteIdsProvider.notifier).add('b1');
      container.read(favoriteStatusCacheProvider.notifier).set('b1', true);

      final result = await notifier.toggleFavorite('b1');

      expect(result, isFalse);
      expect(container.read(favoritesControllerProvider).items.any((b) => b.id == 'b1'), isFalse);
      expect(container.read(favoriteIdsProvider).contains('b1'), isFalse);
    });

    test('rolls back the optimistic removal when the server call fails', () async {
      final fake = _FakeFavoritesRepository(
        pages: {
          'first': PaginatedFavorites(ids: ['b1'], items: [_card('b1')]),
        },
        setFavoriteImpl: (id, isFav) async => throw Exception('network_error'),
      );
      final container = buildContainer(fake);
      final notifier = container.read(favoritesControllerProvider.notifier);
      await _settle();
      container.read(favoriteIdsProvider.notifier).add('b1');
      container.read(favoriteStatusCacheProvider.notifier).set('b1', true);

      await expectLater(() => notifier.toggleFavorite('b1'), throwsException);
      // Rollback: loadInitial() tekrar çağrılır, b1 tekrar listede olmalı;
      // favoriteIdsProvider'a da geri eklenmeli.
      await _settle();
      expect(container.read(favoritesControllerProvider).items.any((b) => b.id == 'b1'), isTrue);
      expect(container.read(favoriteIdsProvider).contains('b1'), isTrue);
    });
  });
}
