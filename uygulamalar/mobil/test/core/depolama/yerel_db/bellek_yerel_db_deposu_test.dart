import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/core/storage/local_db/local_db_models.dart';
import 'package:yeedoy/core/storage/local_db/memory_local_db_store.dart';

void main() {
  group('MemoryLocalDbStore', () {
    test('requires initialization', () async {
      final store = MemoryLocalDbStore();
      expect(
        () => store.read(LocalDbBucket.discoveryFeed, 'x'),
        throwsA(isA<StateError>()),
      );
    });

    test('upsert and read record', () async {
      final store = MemoryLocalDbStore();
      await store.initialize();
      await store.upsert(
        bucket: LocalDbBucket.businessSnapshot,
        id: 'b1',
        payload: {'name': 'Cafe A'},
      );

      final record = await store.read(LocalDbBucket.businessSnapshot, 'b1');
      expect(record, isNotNull);
      expect(record!.payload['name'], 'Cafe A');
    });

    test('list ordered by updated desc', () async {
      final store = MemoryLocalDbStore();
      await store.initialize();
      await store.upsert(
        bucket: LocalDbBucket.discoveryFeed,
        id: '1',
        payload: {'v': 1},
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await store.upsert(
        bucket: LocalDbBucket.discoveryFeed,
        id: '2',
        payload: {'v': 2},
      );

      final list = await store.list(LocalDbBucket.discoveryFeed);
      expect(list.length, 2);
      expect(list.first.id, '2');
      expect(list.last.id, '1');
    });

    test('expired records are hidden and prune removes them', () async {
      final store = MemoryLocalDbStore();
      await store.initialize();
      final now = DateTime.now().toUtc();
      await store.upsert(
        bucket: LocalDbBucket.offlineMutationQueue,
        id: 'old',
        payload: {'x': 1},
        expiresAt: now.subtract(const Duration(seconds: 1)),
      );
      await store.upsert(
        bucket: LocalDbBucket.offlineMutationQueue,
        id: 'new',
        payload: {'x': 2},
        expiresAt: now.add(const Duration(minutes: 5)),
      );

      final hidden = await store.read(
        LocalDbBucket.offlineMutationQueue,
        'old',
      );
      expect(hidden, isNull);

      final removed = await store.pruneExpired(now: now);
      expect(removed, 1);
      final remaining = await store.list(LocalDbBucket.offlineMutationQueue);
      expect(remaining.map((e) => e.id).toList(), ['new']);
    });
  });
}
