import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AdminSavedViewRecord {
  const AdminSavedViewRecord({
    required this.id,
    required this.label,
    required this.payload,
    required this.updatedAt,
  });

  final String id;
  final String label;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;

  factory AdminSavedViewRecord.fromJson(Map<String, dynamic> json) {
    return AdminSavedViewRecord(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      payload:
          (json['payload'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      updatedAt:
          DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'payload': payload,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class AdminTableSavedViewsPrefs {
  const AdminTableSavedViewsPrefs._();

  static String _key(String scope) => 'admin_table_saved_views.$scope';

  static Future<List<AdminSavedViewRecord>> read(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(scope));
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => AdminSavedViewRecord.fromJson(item.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> upsert({
    required String scope,
    required String label,
    required Map<String, dynamic> payload,
    String? id,
  }) async {
    final current = await read(scope);
    final nextId =
        (id ?? '').trim().isNotEmpty ? id!.trim() : DateTime.now().microsecondsSinceEpoch.toString();
    final record = AdminSavedViewRecord(
      id: nextId,
      label: label.trim(),
      payload: payload,
      updatedAt: DateTime.now(),
    );
    final next = [
      record,
      ...current.where((item) => item.id != nextId),
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(scope),
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> delete({
    required String scope,
    required String id,
  }) async {
    final current = await read(scope);
    final next = current.where((item) => item.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(scope),
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }
}
