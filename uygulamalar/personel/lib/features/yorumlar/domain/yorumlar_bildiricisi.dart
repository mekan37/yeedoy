import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import 'yorum_modeli.dart';

final yorumlarProvider =
    AsyncNotifierProvider<YorumlarBildiricisi, List<IsletmeYorum>>(
  YorumlarBildiricisi.new,
);

class YorumlarBildiricisi extends AsyncNotifier<List<IsletmeYorum>> {
  @override
  Future<List<IsletmeYorum>> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return [];
    return _yukle(ref.read(supabaseProvider), kimlik.isletmeId);
  }

  Future<List<IsletmeYorum>> _yukle(
      SupabaseClient supabase, String isletmeId) async {
    final rows = await supabase
        .from('business_reviews')
        .select(
            'id, rating, content, created_at, owner_reply, owner_replied_at, profiles(display_name)')
        .eq('business_id', isletmeId)
        .eq('status', 'approved')
        .order('created_at', ascending: false)
        .limit(50) as List<dynamic>;

    return rows
        .map((r) => IsletmeYorum.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> yanitGonder(String yorumId, String yanit) async {
    state = AsyncData(
      state.valueOrNull
              ?.map((y) => y.id == yorumId ? y.withYanit(yanit) : y)
              .toList() ??
          [],
    );
    try {
      final result = await ref.read(supabaseProvider).rpc(
        'submit_owner_review_reply_v1',
        params: {'p_review_id': yorumId, 'p_reply_text': yanit},
      ) as Map<String, dynamic>;
      if (result['ok'] != true) {
        ref.invalidateSelf();
      }
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> yanitSil(String yorumId) async {
    state = AsyncData(
      state.valueOrNull
              ?.map((y) => y.id == yorumId ? y.withoutYanit() : y)
              .toList() ??
          [],
    );
    try {
      await ref.read(supabaseProvider).rpc(
        'delete_owner_review_reply_v1',
        params: {'p_review_id': yorumId},
      );
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> sikayet(String yorumId) async {
    try {
      await ref.read(supabaseProvider).from('review_flags').insert({
        'review_id': yorumId,
        'reason': 'inappropriate',
        'flagged_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Tablo yoksa sessizce geç
    }
  }

  Future<void> yenile() async {
    final kimlik = ref.read(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return;
    state = const AsyncLoading();
    state = AsyncData(
        await _yukle(ref.read(supabaseProvider), kimlik.isletmeId));
  }
}
