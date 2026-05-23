import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'yerel_db_modelleri.dart';
import 'yerel_db_deposu.dart';

class SharedPrefsLocalDbStore implements LocalDbStore {
  SharedPreferences? _prefs;
  Future<void>? _initFuture;

  @override
  Future<void> initialize() {
    return _ensureInitialized();
  }

  @override
  Future<void> upsert({
    required LocalDbBucket bucket,
    required String id,
    required Map<String, dynamic> payload,
    DateTime? expiresAt,
  }) async {
    final prefs = await _prefsInstance();
    final records = await _readBucket(bucket, prefs);
    final now = DateTime.now().toUtc();
    final normalizedId = id.trim();
    final nextRecord = LocalDbRecord(
      bucket: bucket,
      id: normalizedId,
      payload: Map<String, dynamic>.from(payload),
      updatedAt: now,
      expiresAt: expiresAt?.toUtc(),
    );

    final next = <LocalDbRecord>[
      for (final record in records)
        if (record.id != normalizedId) record,
      nextRecord,
    ];
    await _writeBucket(bucket, next, prefs);
  }

  @override
  Future<LocalDbRecord?> read(
    LocalDbBucket bucket,
    String id, {
    bool allowExpired = false,
  }) async {
    final prefs = await _prefsInstance();
    final now = DateTime.now().toUtc();
    final normalizedId = id.trim();
    final records = await _readBucket(bucket, prefs);
    for (final record in records) {
      if (record.id != normalizedId) continue;
      if (!allowExpired && record.isExpired(now)) return null;
      return record;
    }
    return null;
  }

  @override
  Future<List<LocalDbRecord>> list(
    LocalDbBucket bucket, {
    int limit = 100,
    bool allowExpired = false,
  }) async {
    final prefs = await _prefsInstance();
    final now = DateTime.now().toUtc();
    final records = await _readBucket(bucket, prefs);
    final filtered = records
        .where((record) => allowExpired || !record.isExpired(now))
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (filtered.length <= limit) return filtered;
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<void> remove(LocalDbBucket bucket, String id) async {
    final prefs = await _prefsInstance();
    final normalizedId = id.trim();
    final records = await _readBucket(bucket, prefs);
    final next = records
        .where((record) => record.id != normalizedId)
        .toList(growable: false);
    await _writeBucket(bucket, next, prefs);
  }

  @override
  Future<int> pruneExpired({DateTime? now, LocalDbBucket? bucket}) async {
    final prefs = await _prefsInstance();
    final pivot = (now ?? DateTime.now()).toUtc();
    final buckets = bucket == null ? LocalDbBucket.values : <LocalDbBucket>[bucket];
    var removed = 0;
    for (final current in buckets) {
      final records = await _readBucket(current, prefs);
      final next = records
          .where((record) => !record.isExpired(pivot))
          .toList(growable: false);
      removed += records.length - next.length;
      await _writeBucket(current, next, prefs);
    }
    return removed;
  }

  @override
  Future<void> clearBucket(LocalDbBucket bucket) async {
    final prefs = await _prefsInstance();
    await prefs.remove(_bucketKey(bucket));
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _prefsInstance();
    for (final bucket in LocalDbBucket.values) {
      await prefs.remove(_bucketKey(bucket));
    }
  }

  Future<void> _ensureInitialized() {
    return _initFuture ??= SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<SharedPreferences> _prefsInstance() async {
    await _ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('local_db_not_initialized');
    }
    return prefs;
  }

  Future<List<LocalDbRecord>> _readBucket(
    LocalDbBucket bucket,
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_bucketKey(bucket));
    if (raw == null || raw.trim().isEmpty) return const <LocalDbRecord>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <LocalDbRecord>[];
      return decoded
          .whereType<Map>()
          .map((entry) => _decodeRecord(bucket, entry.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const <LocalDbRecord>[];
    }
  }

  Future<void> _writeBucket(
    LocalDbBucket bucket,
    List<LocalDbRecord> records,
    SharedPreferences prefs,
  ) async {
    if (records.isEmpty) {
      await prefs.remove(_bucketKey(bucket));
      return;
    }
    final payload = jsonEncode(
      records.map((record) => _encodeRecord(record)).toList(growable: false),
    );
    await prefs.setString(_bucketKey(bucket), payload);
  }

  Map<String, dynamic> _encodeRecord(LocalDbRecord record) {
    return <String, dynamic>{
      'id': record.id,
      'payload': record.payload,
      'updated_at': record.updatedAt.toUtc().toIso8601String(),
      'expires_at': record.expiresAt?.toUtc().toIso8601String(),
    };
  }

  LocalDbRecord _decodeRecord(
    LocalDbBucket bucket,
    Map<String, dynamic> map,
  ) {
    final payloadRaw = map['payload'];
    final payload = payloadRaw is Map
        ? payloadRaw.cast<String, dynamic>()
        : <String, dynamic>{};
    final updatedAt =
        DateTime.tryParse((map['updated_at'] ?? '').toString())?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final expiresAt = DateTime.tryParse(
      (map['expires_at'] ?? '').toString(),
    )?.toUtc();
    return LocalDbRecord(
      bucket: bucket,
      id: (map['id'] ?? '').toString(),
      payload: payload,
      updatedAt: updatedAt,
      expiresAt: expiresAt,
    );
  }

  String _bucketKey(LocalDbBucket bucket) => 'local_db_bucket_${bucket.key}_v1';
}
