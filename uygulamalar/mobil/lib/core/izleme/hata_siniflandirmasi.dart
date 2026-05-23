import 'package:supabase_flutter/supabase_flutter.dart';

enum ErrorTaxonomy {
  networkTimeout,
  authExpired,
  rlsDenied,
  decodeError,
  edgeRejectedRateLimit,
  unknown,
}

ErrorTaxonomy classifyError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('expired') || msg.contains('jwt')) {
      return ErrorTaxonomy.authExpired;
    }
  }

  if (error is PostgrestException) {
    final msg = '${error.code} ${error.message}'.toLowerCase();
    if (msg.contains('42501') ||
        msg.contains('rls') ||
        msg.contains('denied')) {
      return ErrorTaxonomy.rlsDenied;
    }
  }

  final text = error.toString().toLowerCase();
  if (text.contains('timeout') || text.contains('timed out')) {
    return ErrorTaxonomy.networkTimeout;
  }
  if (text.contains('429') || text.contains('rate_limit')) {
    return ErrorTaxonomy.edgeRejectedRateLimit;
  }
  if (text.contains('formatexception') ||
      text.contains('json') ||
      text.contains('decode')) {
    return ErrorTaxonomy.decodeError;
  }
  return ErrorTaxonomy.unknown;
}
