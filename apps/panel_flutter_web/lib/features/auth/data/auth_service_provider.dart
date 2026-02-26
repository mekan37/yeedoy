import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_provider.dart';
import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseProvider);
  return AuthService(client);
});
