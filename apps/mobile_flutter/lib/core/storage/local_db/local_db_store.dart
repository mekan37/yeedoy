import 'local_db_models.dart';

abstract class LocalDbStore {
  Future<void> initialize();

  Future<void> upsert({
    required LocalDbBucket bucket,
    required String id,
    required Map<String, dynamic> payload,
    DateTime? expiresAt,
  });

  Future<LocalDbRecord?> read(
    LocalDbBucket bucket,
    String id, {
    bool allowExpired = false,
  });

  Future<List<LocalDbRecord>> list(
    LocalDbBucket bucket, {
    int limit = 100,
    bool allowExpired = false,
  });

  Future<void> remove(LocalDbBucket bucket, String id);

  Future<int> pruneExpired({DateTime? now, LocalDbBucket? bucket});

  Future<void> clearBucket(LocalDbBucket bucket);

  Future<void> clearAll();
}
