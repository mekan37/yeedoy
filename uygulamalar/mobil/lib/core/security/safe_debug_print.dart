import 'package:flutter/foundation.dart';

final RegExp _authHeaderPattern = RegExp(
  r'(Bearer\s+)[A-Za-z0-9\-._~+/]+=*',
  caseSensitive: false,
);
final RegExp _jwtPattern = RegExp(
  r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
);
final RegExp _uuidPattern = RegExp(
  r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\b',
);
final RegExp _emailPattern = RegExp(
  r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
);
final RegExp _phonePattern = RegExp(
  r'(?<!\d)(?:\+?90[\s-]?)?(?:0?5\d{2}[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2})(?!\d)',
);
final RegExp _coordPattern = RegExp(
  r'\b-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}\b',
);

String sanitizeDebugLog(String raw) {
  var out = raw;
  out = out.replaceAllMapped(_authHeaderPattern, (m) => '${m.group(1)}***');
  out = out.replaceAll(_jwtPattern, '***jwt***');
  out = out.replaceAll(_emailPattern, '***email***');
  out = out.replaceAll(_phonePattern, '***phone***');
  out = out.replaceAll(_coordPattern, '***coord***');
  out = out.replaceAllMapped(_uuidPattern, (m) {
    final v = m.group(0)!;
    return '${v.substring(0, 4)}...${v.substring(v.length - 4)}';
  });
  return out;
}

void installSafeDebugPrint() {
  final base = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null) {
      base(null, wrapWidth: wrapWidth);
      return;
    }
    base(sanitizeDebugLog(message), wrapWidth: wrapWidth);
  };
}
