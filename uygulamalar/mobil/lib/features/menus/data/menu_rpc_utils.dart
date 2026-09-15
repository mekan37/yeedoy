// MenuRepository'nin bölünmesiyle (B42) menu_price_repository.dart ve
// menu_item_photo_repository.dart arasında paylaşılan, durumsuz RPC
// yardımcıları.

bool isLikelyOfflineError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection closed before full header was received') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('timed out') ||
      text.contains('timeout');
}

void ensureOkResponse(dynamic res, {required String fallbackError}) {
  if (res is Map) {
    final data = res.cast<String, dynamic>();
    if (data['ok'] == true) return;
    final error = (data['error'] ?? '').toString().trim();
    throw Exception(error.isEmpty ? fallbackError : error);
  }
  if (res is List && res.isNotEmpty && res.first is Map) {
    ensureOkResponse(
      (res.first as Map).cast<String, dynamic>(),
      fallbackError: fallbackError,
    );
    return;
  }
  throw Exception(fallbackError);
}

bool isMissingRpcError(Object error, String rpcName) {
  final text = error.toString().toLowerCase();
  final normalized = rpcName.toLowerCase();
  return text.contains(normalized) &&
      (text.contains('could not find') ||
          text.contains('does not exist') ||
          text.contains('not found') ||
          text.contains('undefined function') ||
          text.contains('pgrst202'));
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}
