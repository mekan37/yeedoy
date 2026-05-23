import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import 'sadakat_modeli.dart';

final sadakatProvider =
    AsyncNotifierProvider<SadakatBildiricisi, List<LoyaltyKart>>(
      SadakatBildiricisi.new,
    );

class SadakatBildiricisi extends AsyncNotifier<List<LoyaltyKart>> {
  @override
  Future<List<LoyaltyKart>> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return [];
    return _yukle(ref.read(supabaseProvider), kimlik.isletmeId);
  }

  Future<List<LoyaltyKart>> _yukle(
    SupabaseClient supabase,
    String isletmeId,
  ) async {
    try {
      final rows =
          await supabase
                  .from('loyalty_cards')
                  .select(
                    'id, user_id, stamp_count, total_stamps, loyalty_programs(required_stamps), profiles(full_name, phone)',
                  )
                  .eq('business_id', isletmeId)
                  .order('updated_at', ascending: false)
                  .limit(50)
              as List<dynamic>;

      return rows.map((r) {
        final prog = r['loyalty_programs'] as Map<String, dynamic>?;
        final profile = r['profiles'] as Map<String, dynamic>?;
        return LoyaltyKart(
          id: r['id'] as String,
          kullaniciId: r['user_id'] as String,
          kullaniciAdi: profile?['full_name'] as String?,
          telefon: profile?['phone'] as String?,
          stampSayisi: (r['stamp_count'] as num?)?.toInt() ?? 0,
          hedef: (prog?['required_stamps'] as num?)?.toInt() ?? 10,
          toplamStamp: (r['total_stamps'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> stampEkle(String kartId) async {
    try {
      final supabase = ref.read(supabaseProvider);
      final kimlik = ref.read(kimlikProvider).valueOrNull;
      if (kimlik is! KimlikGirilmis) return 'Kimlik hatası';

      // Mevcut kart durumunu al — tamamlanıp tamamlanmadığını anlamak için
      final onceki = state.valueOrNull
          ?.where((k) => k.id == kartId)
          .firstOrNull;

      await supabase.rpc(
        'add_loyalty_stamp_v1',
        params: {'p_card_id': kartId, 'p_business_id': kimlik.isletmeId},
      );

      // Kart tamamlandıysa müşteriye push bildirimi gönder
      if (onceki != null &&
          !onceki.tamamlandi &&
          onceki.stampSayisi + 1 >= onceki.hedef) {
        await _tamamlanmaPushu(
          supabase: supabase,
          kullaniciId: onceki.kullaniciId,
          kullaniciAdi: onceki.kullaniciAdi ?? 'Müşteri',
          isletmeId: kimlik.isletmeId,
        );
      }

      ref.invalidateSelf();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _tamamlanmaPushu({
    required SupabaseClient supabase,
    required String kullaniciId,
    required String kullaniciAdi,
    required String isletmeId,
  }) async {
    try {
      // Kullanıcının FCM token'ını al
      final tokenRow = await supabase
          .from('push_tokens')
          .select('token')
          .eq('user_id', kullaniciId)
          .maybeSingle();

      final token = tokenRow?['token'] as String?;
      if (token == null) return;

      // İşletme adını al
      final bizRow = await supabase
          .from('businesses')
          .select('name')
          .eq('id', isletmeId)
          .maybeSingle();
      final isletmeAdi = bizRow?['name'] as String? ?? 'Yeedoy';

      // FCM aracılığıyla gönder (server-side, Supabase Edge Function çağrısı)
      await supabase.functions.invoke(
        'send-push-notification',
        body: {
          'token': token,
          'title': '🎉 Kart Tamamlandı!',
          'body':
              '$isletmeAdi kartını tamamladın! Ödülünü almak için ziyaret et.',
          'data': {'type': 'loyalty_complete', 'business_id': isletmeId},
        },
      );
    } catch (_) {
      // Push bildirimi başarısız olursa sessizce geç
    }
  }

  /// Belirtilen kullanıcıya manuel puan ekler.
  /// Başarıysa null, hata varsa hata mesajı döner.
  Future<String?> puanEkle({
    required String kullaniciId,
    required int puan,
  }) async {
    try {
      final supabase = ref.read(supabaseProvider);
      final kimlik = ref.read(kimlikProvider).valueOrNull;
      if (kimlik is! KimlikGirilmis) return 'Kimlik hatası';

      await supabase.rpc(
        'award_loyalty_points_v1',
        params: {
          'p_user_id': kullaniciId,
          'p_business_id': kimlik.isletmeId,
          'p_points': puan,
          'p_source': 'manual',
        },
      );
      ref.invalidateSelf();
      return null;
    } catch (e) {
      final mesaj = e.toString();
      // RPC mevcut değil ya da yapılandırılmamışsa kullanıcı dostu mesaj
      if (mesaj.contains('does not exist') ||
          mesaj.contains('function') ||
          mesaj.contains('42883')) {
        return 'Puan ekleme sistemi yapılandırılıyor. Lütfen daha sonra tekrar deneyin.';
      }
      return mesaj;
    }
  }

  Future<void> yenile() async {
    final kimlik = ref.read(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return;
    state = const AsyncLoading();
    state = AsyncData(
      await _yukle(ref.read(supabaseProvider), kimlik.isletmeId),
    );
  }
}
