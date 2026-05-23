import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../analitik/analitik_istemcisi.dart';

class OfflineMutationIdempotencyToken {
  const OfflineMutationIdempotencyToken({
    required this.action,
    required this.clientId,
    required this.payloadHash,
    required this.idempotencyKey,
  });

  final String action;
  final String clientId;
  final String payloadHash;
  final String idempotencyKey;
}

Future<OfflineMutationIdempotencyToken> createOfflineMutationIdempotencyToken({
  required String action,
  required Map<String, dynamic> payload,
  String? clientId,
}) async {
  final resolvedClientId =
      (clientId ?? await getAnalyticsClientId()).trim();
  final normalizedPayload = _normalizePayload(payload);
  final digest = sha256
      .convert(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'action': action.trim(),
            'client_id': resolvedClientId,
            'payload': normalizedPayload,
          }),
        ),
      )
      .toString();
  final prefix = action.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
  return OfflineMutationIdempotencyToken(
    action: action,
    clientId: resolvedClientId,
    payloadHash: digest,
    idempotencyKey: '$prefix:${digest.substring(0, 24)}',
  );
}

Future<Map<String, dynamic>> attachOfflineMutationIdempotency({
  required String action,
  required Map<String, dynamic> payload,
  String? clientId,
}) async {
  final token = await createOfflineMutationIdempotencyToken(
    action: action,
    payload: payload,
    clientId: clientId,
  );
  return <String, dynamic>{
    ...payload,
    'client_id': token.clientId,
    'payload_hash': token.payloadHash,
    'idempotency_key': token.idempotencyKey,
    'idempotency_action': token.action,
  };
}

Map<String, Object?> _normalizePayload(Map<String, dynamic> payload) {
  final cleaned = Map<String, dynamic>.from(payload)
    ..remove('client_id')
    ..remove('payload_hash')
    ..remove('idempotency_key')
    ..remove('idempotency_action');
  return _canonicalize(cleaned) as Map<String, Object?>;
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return <String, Object?>{
      for (final entry in entries)
        entry.key.toString(): _canonicalize(entry.value),
    };
  }
  if (value is List) {
    return value.map(_canonicalize).toList(growable: false);
  }
  if (value is num || value is bool || value == null) {
    return value;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
