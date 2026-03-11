import 'dart:math';

Map<String, String> traceHeaders(String requestId) {
  return {'x-request-id': requestId};
}

Map<String, Object?> withRequestTrace(
  Map<String, Object?> payload, {
  required String requestId,
}) {
  return <String, Object?>{
    ...payload,
    'request_id': requestId,
  };
}

String createRequestId({String prefix = 'req'}) {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rnd = Random().nextDouble().toString().split('.').last.padRight(8, '0');
  return '$prefix-$now-$rnd';
}
