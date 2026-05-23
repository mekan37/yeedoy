import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_error_codes.dart';

void ensureCriticalActionAllowed(
  SupabaseClient client, {
  String action = 'critical',
}) {
  final user = client.auth.currentUser;
  if (user == null) {
    throw Exception('not_authenticated');
  }

  final emailVerified = user.emailConfirmedAt != null;
  final phoneVerified = user.phoneConfirmedAt != null;
  if (!emailVerified && !phoneVerified) {
    throw Exception('${AppErrorCodes.contactVerificationRequired}:$action');
  }
}
