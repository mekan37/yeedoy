import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/features/reviews/data/reviews_repository.dart';
import 'package:yeedoy/features/reviews/domain/business_reviews_controller.dart';
import 'package:yeedoy/features/reviews/domain/review.dart';

// B43 (mimari denetim): pagination + B47 (ref.mounted guard'ları) regresyon
// kilidi. ReviewsRepository somut bir sınıf — diğer testlerdeki aynı
// "override + zararsız dummy SupabaseClient" deseni kullanılıyor.
class _FakeReviewsRepository extends ReviewsRepository {
  _FakeReviewsRepository({
    required this.pages,
    this.onFetch,
  }) : super(SupabaseClient('https://example.invalid', 'anon-key'));

  final Map<int, List<Review>> pages;
  final Future<void> Function()? onFetch;
  final List<int> requestedOffsets = [];

  @override
  Future<List<Review>> fetchBusinessReviews({
    required String businessId,
    required String sort,
    int limit = 20,
    int offset = 0,
  }) async {
    requestedOffsets.add(offset);
    if (onFetch != null) await onFetch!();
    return pages[offset] ?? const [];
  }
}

Review _review(String id) => Review(
      id: id,
      businessId: 'biz-1',
      rating: 5,
      content: 'Great food',
      helpfulCount: 0,
      createdAt: DateTime(2026, 1, 1),
      status: 'approved',
    );

Future<void> _settle() => pumpEventQueue(times: 20);

void main() {
  // businessReviewsProvider .autoDispose — container.read() tek başına
  // dinleyici sayılmaz, okur okumaz dispose edilir. container.listen ile
  // kalıcı bir dinleyici tutmak, testin kendi container'ı yaşadığı sürece
  // provider'ı canlı tutar (widget testlerinde ProviderScope'un yaptığının
  // aynısı).
  ProviderContainer buildContainer(_FakeReviewsRepository fake) {
    final container = ProviderContainer(
      overrides: [reviewsRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    container.listen(businessReviewsProvider('biz-1'), (_, _) {});
    return container;
  }

  group('BusinessReviewsController.loadInitial', () {
    test('loads the first page and sets hasMore based on page size', () async {
      final fake = _FakeReviewsRepository(pages: {
        0: [_review('r1'), _review('r2')],
      });
      final container = buildContainer(fake);
      container.read(businessReviewsProvider('biz-1').notifier);
      await _settle();

      final state = container.read(businessReviewsProvider('biz-1'));
      expect(state.items.map((r) => r.id), ['r1', 'r2']);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isFalse); // 2 < pageSize(20)
    });
  });

  group('BusinessReviewsController.loadMore', () {
    test('appends the next page using the accumulated item count as offset', () async {
      final page0 = List.generate(20, (i) => _review('p0-$i'));
      final page1 = [_review('p1-0')];
      final fake = _FakeReviewsRepository(pages: {0: page0, 20: page1});
      final container = buildContainer(fake);
      final notifier = container.read(businessReviewsProvider('biz-1').notifier);
      await _settle();
      expect(container.read(businessReviewsProvider('biz-1')).hasMore, isTrue);

      await notifier.loadMore();
      final state = container.read(businessReviewsProvider('biz-1'));

      expect(fake.requestedOffsets, [0, 20]);
      expect(state.items.length, 21);
      expect(state.hasMore, isFalse);
    });

    test('is a no-op once hasMore is false', () async {
      final fake = _FakeReviewsRepository(pages: {
        0: [_review('r1')],
      });
      final container = buildContainer(fake);
      final notifier = container.read(businessReviewsProvider('biz-1').notifier);
      await _settle();
      expect(container.read(businessReviewsProvider('biz-1')).hasMore, isFalse);

      final before = fake.requestedOffsets.length;
      await notifier.loadMore();
      expect(fake.requestedOffsets.length, before);
    });
  });

  group('BusinessReviewsController.setSort', () {
    test('reloads from scratch when the sort changes', () async {
      final fake = _FakeReviewsRepository(pages: {
        0: [_review('newest-1')],
      });
      final container = buildContainer(fake);
      final notifier = container.read(businessReviewsProvider('biz-1').notifier);
      await _settle();

      await notifier.setSort('helpful');
      final state = container.read(businessReviewsProvider('biz-1'));

      expect(state.sort, 'helpful');
      expect(fake.requestedOffsets, [0, 0]); // her ikisi de offset 0'dan başlar
    });

    test('is a no-op when the sort does not actually change', () async {
      final fake = _FakeReviewsRepository(pages: {
        0: [_review('r1')],
      });
      final container = buildContainer(fake);
      final notifier = container.read(businessReviewsProvider('biz-1').notifier);
      await _settle();
      final callsBefore = fake.requestedOffsets.length;

      await notifier.setSort('newest'); // build()'daki varsayılan zaten 'newest'
      expect(fake.requestedOffsets.length, callsBefore);
    });
  });

  group('BusinessReviewsController ref.mounted guard (B47 regression)', () {
    test('a fetch that resolves after the provider is disposed does not throw', () async {
      // B47: loadInitial/loadMore await'ten sonra hiç ref.mounted kontrolü
      // yapmıyordu — provider (autoDispose) ekran kapanınca dispose olduğunda
      // pending future tamamlanınca "used after dispose" hatası fırlatıyordu.
      final fetchStarted = Completer<void>();
      final fetchCanFinish = Completer<void>();
      final fake = _FakeReviewsRepository(
        pages: {0: [_review('r1')]},
        onFetch: () async {
          fetchStarted.complete();
          await fetchCanFinish.future;
        },
      );
      final container = buildContainer(fake);
      container.read(businessReviewsProvider('biz-1').notifier);

      await fetchStarted.future; // fetch tam ortasında, henüz dönmedi
      container.dispose(); // ekran kapandı: provider disposed oluyor
      fetchCanFinish.complete(); // ŞİMDİ ağ cevabı geliyor — provider artık yok

      // ref.mounted guard'ı olmasaydı burada bir exception (zone error)
      // fırlardı; pumpEventQueue bunu tüketip test'i patlatırdı.
      await pumpEventQueue(times: 20);
    });
  });
}
