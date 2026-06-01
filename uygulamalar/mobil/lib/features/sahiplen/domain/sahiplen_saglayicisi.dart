import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';
import '../../auth/domain/auth_providers.dart';

final sahiplenBasvuruProvider =
    AsyncNotifierProvider.autoDispose<SahiplenBildiricisi, void>(SahiplenBildiricisi.new);

class SahiplenBildiricisi extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> gonder({
    String? isletmeId,
    required String isletmeAdi,
    required String telefon,
    required String email,
    required String belgeBilgi,
  }) async {
    final user = ref.read(userProvider);
    final supabase = ref.read(supabaseProvider);

    await supabase.from('business_ownership_claims').insert({
      'user_id': user?.id,
      'business_id': isletmeId,
      'business_name_claimed': isletmeAdi,
      'phone': telefon,
      'email': email.isEmpty ? null : email,
      'document_info': belgeBilgi.isEmpty ? null : belgeBilgi,
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
