import 'local_db_models.dart';
import 'local_db_store.dart';

class MemoryLocalDbStore implements LocalDbStore {
  final Map<String, LocalDbRecord> _records = <String, LocalDbRecord>{};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> upsert({
    required LocalDbBucket bucket,
    required String id,
    required Map<String, dynamic> payload,
    DateTime? expiresAt,
  }) async {
    _ensureInitialized();
    final now = DateTime.now().toUtc();
    final key = _composeKey(bucket, id);
    _records[key] = LocalDbRecord(
      bucket: bucket,
      id: id,
      payload: Map<String, dynamic>.from(payload),
      updatedAt: now,
      expiresAt: expiresAt?.toUtc(),
    );
  }

  @override
  Future<LocalDbRecord?> read(
    LocalDbBucket bucket,
    String id, {
    bool allowExpired = false,
  }) async {
    _ensureInitialized();
    final key = _composeKey(bucket, id);
    final record = _records[key];
    if (record == null) return null;
    if (!allowExpired && record.isExpired(DateTime.now().toUtc())) return null;
    return record;
  }

  @override
  Future<List<LocalDbRecord>> list(
    LocalDbBucket bucket, {
    int limit = 100,
    bool allowExpired = false,
  }) async {
    _ensureInitialized();
    final now = DateTime.now().toUtc();
    final filtered =
        _records.values
            .where((record) => record.bucket == bucket)
            .where((record) => allowExpired || !record.isExpired(now))
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (filtered.length <= limit) return filtered;
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<void> remove(LocalDbBucket bucket, String id) async {
    _ensureInitialized();
    _records.remove(_composeKey(bucket, id));
  }

  @override
  Future<int> pruneExpired({DateTime? now, LocalDbBucket? bucket}) async {
    _ensureInitialized();
    final pivot = (now ?? DateTime.now()).toUtc();
    final keys = _records.entries
        .where((entry) => bucket == null || entry.value.bucket == bucket)
        .where((entry) => entry.value.isExpired(pivot))
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in keys) {
      _records.remove(key);
    }
    return keys.length;
  }

  @override
  Future<void> clearBucket(LocalDbBucket bucket) async {
    _ensureInitialized();
    final keys = _records.keys
        .where((key) => key.startsWith('${bucket.key}|'))
        .toList(growable: false);
    for (final key in keys) {
      _records.remove(key);
    }
  }

  @override
  Future<void> clearAll() async {
    _ensureInitialized();
    _records.clear();
  }

  String _composeKey(LocalDbBucket bucket, String id) {
    final normalized = id.trim();
    return '${bucket.key}|$normalized';
  }

  void _ensureInitialized() {
    if (_initialized) return;
    throw StateError('local_db_not_initialized');
  }
}
