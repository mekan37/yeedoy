import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeedoy/core/storage/local_db/local_db_models.dart';
import 'package:yeedoy/core/storage/local_db/shared_prefs_local_db_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsLocalDbStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('upsert and read survive new store instance', () async {
      final first = SharedPrefsLocalDbStore();
      await first.initialize();
      await first.upsert(
        bucket: LocalDbBucket.discoveryFeed,
        id: 'feed|tr|istanbul',
        payload: {'rows': <Map<String, dynamic>>[{'id': 'b1'}]},
      );

      final second = SharedPrefsLocalDbStore();
      await second.initialize();
      final record = await second.read(
        LocalDbBucket.discoveryFeed,
        'feed|tr|istanbul',
      );

      expect(record, isNotNull);
      expect((record!.payload['rows'] as List).length, 1);
    });

    test('pruneExpired removes only expired records', () async {
      final store = SharedPrefsLocalDbStore();
      await store.initialize();
      final now = DateTime.utc(2026, 3, 6, 12);
      await store.upsert(
        bucket: LocalDbBucket.menuSnapshot,
        id: 'old',
        payload: {'items': <Map<String, dynamic>>[]},
        expiresAt: now.subtract(const Duration(minutes: 1)),
      );
      await store.upsert(
        bucket: LocalDbBucket.menuSnapshot,
        id: 'fresh',
        payload: {'items': <Map<String, dynamic>>[]},
        expiresAt: now.add(const Duration(minutes: 1)),
      );

      final removed = await store.pruneExpired(now: now);
      final records = await store.list(
        LocalDbBucket.menuSnapshot,
        allowExpired: true,
      );

      expect(removed, 1);
      expect(records.map((record) => record.id), <String>['fresh']);
    });
  });
}
