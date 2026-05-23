import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import 'kimlik_servisi.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseProvider);
  return AuthService(client);
});

