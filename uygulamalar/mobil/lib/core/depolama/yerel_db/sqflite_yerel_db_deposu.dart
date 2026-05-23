import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'yerel_db_modelleri.dart';
import 'yerel_db_deposu.dart';
import 'paylasilan_tercihler_yerel_db_deposu.dart';

class SqfliteLocalDbStore implements LocalDbStore {
  SqfliteLocalDbStore({LocalDbStore? fallbackStore})
    : _fallbackStore = fallbackStore ?? SharedPrefsLocalDbStore();

  static const _databaseName = 'yeedoy_local.db';
  static const _databaseVersion = 1;
  static const _metaTable = 'local_db_meta';
  static const _sharedPrefsMigratedKey = 'shared_prefs_migrated_v1';

  final LocalDbStore _fallbackStore;

  Database? _database;
  Future<void>? _initFuture;
  Object? _initError;

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
    await _run(
      onDatabase: (database) async {
        final schema = _schemaFor(bucket);
        final now = DateTime.now().toUtc();
        await database.insert(
          schema.tableName,
          <String, Object?>{
            schema.idColumn: id.trim(),
            'record_type': _recordType(payload),
            'payload_json': jsonEncode(payload),
            'updated_at_ms': now.millisecondsSinceEpoch,
            'expires_at_ms': expiresAt?.toUtc().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
      onFallback: (store) => store.upsert(
        bucket: bucket,
        id: id,
        payload: payload,
        expiresAt: expiresAt,
      ),
    );
  }

  @override
  Future<LocalDbRecord?> read(
    LocalDbBucket bucket,
    String id, {
    bool allowExpired = false,
  }) async {
    return _run(
      onDatabase: (database) async {
        final schema = _schemaFor(bucket);
        final rows = await database.query(
          schema.tableName,
          where: '${schema.idColumn} = ?',
          whereArgs: <Object?>[id.trim()],
          limit: 1,
        );
        if (rows.isEmpty) return null;
        final record = _decodeRecord(bucket, rows.first);
        if (!allowExpired && record.isExpired(DateTime.now().toUtc())) {
          return null;
        }
        return record;
      },
      onFallback: (store) => store.read(bucket, id, allowExpired: allowExpired),
    );
  }

  @override
  Future<List<LocalDbRecord>> list(
    LocalDbBucket bucket, {
    int limit = 100,
    bool allowExpired = false,
  }) async {
    return _run(
      onDatabase: (database) async {
        final schema = _schemaFor(bucket);
        final rows = await database.query(
          schema.tableName,
          orderBy: 'updated_at_ms DESC',
          limit: limit,
        );
        final now = DateTime.now().toUtc();
        final records = rows
            .map((row) => _decodeRecord(bucket, row))
            .where((record) => allowExpired || !record.isExpired(now))
            .toList(growable: false);
        return records;
      },
      onFallback: (store) => store.list(
        bucket,
        limit: limit,
        allowExpired: allowExpired,
      ),
    );
  }

  @override
  Future<void> remove(LocalDbBucket bucket, String id) async {
    await _run(
      onDatabase: (database) async {
        final schema = _schemaFor(bucket);
        await database.delete(
          schema.tableName,
          where: '${schema.idColumn} = ?',
          whereArgs: <Object?>[id.trim()],
        );
      },
      onFallback: (store) => store.remove(bucket, id),
    );
  }

  @override
  Future<int> pruneExpired({DateTime? now, LocalDbBucket? bucket}) async {
    return _run(
      onDatabase: (database) async {
        final pivot = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
        final buckets = bucket == null ? LocalDbBucket.values : <LocalDbBucket>[bucket];
        var removed = 0;
        for (final current in buckets) {
          final schema = _schemaFor(current);
          removed += await database.delete(
            schema.tableName,
            where: 'expires_at_ms IS NOT NULL AND expires_at_ms <= ?',
            whereArgs: <Object?>[pivot],
          );
        }
        return removed;
      },
      onFallback: (store) => store.pruneExpired(now: now, bucket: bucket),
    );
  }

  @override
  Future<void> clearBucket(LocalDbBucket bucket) async {
    await _run(
      onDatabase: (database) async {
        await database.delete(_schemaFor(bucket).tableName);
      },
      onFallback: (store) => store.clearBucket(bucket),
    );
  }

  @override
  Future<void> clearAll() async {
    await _run(
      onDatabase: (database) async {
        final batch = database.batch();
        for (final bucket in LocalDbBucket.values) {
          batch.delete(_schemaFor(bucket).tableName);
        }
        await batch.commit(noResult: true);
      },
      onFallback: (store) => store.clearAll(),
    );
  }

  Future<void> _ensureInitialized() async {
    if (_database != null || _initError != null) return;
    _initFuture ??= _openDatabase();
    await _initFuture;
  }

  Future<void> _openDatabase() async {
    try {
      final basePath = await getDatabasesPath();
      final path = '$basePath/$_databaseName';
      final database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
      _database = database;
      await _migrateFromSharedPrefs(database);
    } catch (error) {
      _initError = error;
      await _fallbackStore.initialize();
    }
  }

  Future<void> _onCreate(Database database, int version) async {
    final batch = database.batch();
    batch.execute('''
      CREATE TABLE $_metaTable (
        meta_key TEXT PRIMARY KEY,
        meta_value TEXT NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');

    for (final schema in _schemas) {
      batch.execute('''
        CREATE TABLE ${schema.tableName} (
          ${schema.idColumn} TEXT PRIMARY KEY,
          record_type TEXT,
          payload_json TEXT NOT NULL,
          updated_at_ms INTEGER NOT NULL,
          expires_at_ms INTEGER
        )
      ''');
      batch.execute(
        'CREATE INDEX idx_${schema.tableName}_expires_at ON ${schema.tableName}(expires_at_ms)',
      );
      batch.execute(
        'CREATE INDEX idx_${schema.tableName}_record_type ON ${schema.tableName}(record_type)',
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> _migrateFromSharedPrefs(Database database) async {
    final migrated = await database.query(
      _metaTable,
      columns: <String>['meta_value'],
      where: 'meta_key = ?',
      whereArgs: <Object?>[_sharedPrefsMigratedKey],
      limit: 1,
    );
    if (migrated.isNotEmpty) return;

    await _fallbackStore.initialize();
    final batch = database.batch();

    for (final bucket in LocalDbBucket.values) {
      final schema = _schemaFor(bucket);
      final records = await _fallbackStore.list(
        bucket,
        limit: 5000,
        allowExpired: true,
      );
      for (final record in records) {
        batch.insert(
          schema.tableName,
          <String, Object?>{
            schema.idColumn: record.id.trim(),
            'record_type': _recordType(record.payload),
            'payload_json': jsonEncode(record.payload),
            'updated_at_ms': record.updatedAt.toUtc().millisecondsSinceEpoch,
            'expires_at_ms': record.expiresAt?.toUtc().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    batch.insert(
      _metaTable,
      <String, Object?>{
        'meta_key': _sharedPrefsMigratedKey,
        'meta_value': '1',
        'updated_at_ms': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await batch.commit(noResult: true);
  }

  Future<T> _run<T>({
    required Future<T> Function(Database database) onDatabase,
    required Future<T> Function(LocalDbStore fallbackStore) onFallback,
  }) async {
    await _ensureInitialized();
    final database = _database;
    if (database != null) {
      return onDatabase(database);
    }
    return onFallback(_fallbackStore);
  }

  LocalDbRecord _decodeRecord(
    LocalDbBucket bucket,
    Map<String, Object?> row,
  ) {
    final payloadJson = (row['payload_json'] ?? '{}').toString();
    Map<String, dynamic> payload = <String, dynamic>{};
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map) {
        payload = decoded.cast<String, dynamic>();
      }
    } catch (_) {
      payload = <String, dynamic>{};
    }
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      (row['updated_at_ms'] as int?) ?? 0,
      isUtc: true,
    );
    final expiresAtMs = row['expires_at_ms'] as int?;
    return LocalDbRecord(
      bucket: bucket,
      id: (row[_schemaFor(bucket).idColumn] ?? '').toString(),
      payload: payload,
      updatedAt: updatedAt,
      expiresAt: expiresAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresAtMs, isUtc: true),
    );
  }

  _LocalDbSchema _schemaFor(LocalDbBucket bucket) {
    return _schemas.firstWhere((schema) => schema.bucket == bucket);
  }

  String? _recordType(Map<String, dynamic> payload) {
    final value = payload['type'];
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  static const List<_LocalDbSchema> _schemas = <_LocalDbSchema>[
    _LocalDbSchema(
      bucket: LocalDbBucket.discoveryFeed,
      tableName: 'local_discovery_feed',
      idColumn: 'cache_key',
    ),
    _LocalDbSchema(
      bucket: LocalDbBucket.businessSnapshot,
      tableName: 'local_business_snapshot',
      idColumn: 'snapshot_key',
    ),
    _LocalDbSchema(
      bucket: LocalDbBucket.menuSnapshot,
      tableName: 'local_menu_snapshot',
      idColumn: 'snapshot_key',
    ),
    _LocalDbSchema(
      bucket: LocalDbBucket.offlineMutationQueue,
      tableName: 'local_offline_mutation_queue',
      idColumn: 'queue_key',
    ),
    _LocalDbSchema(
      bucket: LocalDbBucket.telemetrySnapshot,
      tableName: 'local_telemetry_snapshot',
      idColumn: 'snapshot_key',
    ),
  ];
}

class _LocalDbSchema {
  const _LocalDbSchema({
    required this.bucket,
    required this.tableName,
    required this.idColumn,
  });

  final LocalDbBucket bucket;
  final String tableName;
  final String idColumn;
}
