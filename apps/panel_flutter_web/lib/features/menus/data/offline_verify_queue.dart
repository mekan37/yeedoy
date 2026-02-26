import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum OfflineVerifyActionType { votePrice, suggestPrice }

class OfflineVerifyQueueItem {
  const OfflineVerifyQueueItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.payload,
  });

  final String id;
  final OfflineVerifyActionType type;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      'payload': payload,
    };
  }

  factory OfflineVerifyQueueItem.fromMap(Map<String, dynamic> map) {
    final typeRaw = (map['type'] ?? '').toString();
    final type = OfflineVerifyActionType.values.firstWhere(
      (value) => value.name == typeRaw,
      orElse: () => OfflineVerifyActionType.votePrice,
    );
    final payloadRaw = map['payload'];
    final payload = payloadRaw is Map
        ? payloadRaw.cast<String, dynamic>()
        : <String, dynamic>{};
    final createdAtText = (map['created_at'] ?? '').toString();
    final createdAt =
        DateTime.tryParse(createdAtText)?.toLocal() ?? DateTime.now().toLocal();
    return OfflineVerifyQueueItem(
      id: (map['id'] ?? '').toString(),
      type: type,
      createdAt: createdAt,
      payload: payload,
    );
  }
}

class OfflineVerifyQueueStore {
  static const _queueKey = 'offline_verify_queue_v1';
  static const int _maxItems = 200;

  static Future<List<OfflineVerifyQueueItem>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List).whereType<Map>().map((e) {
        return OfflineVerifyQueueItem.fromMap(e.cast<String, dynamic>());
      }).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> enqueue(
    OfflineVerifyActionType type,
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await readAll();
    final now = DateTime.now().toLocal();
    final next = [
      ...existing,
      OfflineVerifyQueueItem(
        id: '${now.microsecondsSinceEpoch}_${type.name}',
        type: type,
        createdAt: now,
        payload: payload,
      ),
    ];
    final trimmed = next.length > _maxItems
        ? next.sublist(next.length - _maxItems)
        : next;
    await prefs.setString(
      _queueKey,
      jsonEncode(trimmed.map((e) => e.toMap()).toList()),
    );
  }

  static Future<void> replaceAll(List<OfflineVerifyQueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(_queueKey);
      return;
    }
    await prefs.setString(
      _queueKey,
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
  }
}

class OfflineQueuedException implements Exception {
  const OfflineQueuedException([this.code = 'offline_queued']);

  final String code;

  @override
  String toString() => 'Exception: $code';
}
