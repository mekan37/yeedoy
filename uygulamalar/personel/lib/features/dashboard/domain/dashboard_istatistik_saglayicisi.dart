import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';

class GunlukVeri {
  final DateTime gun;
  final int siparisSayisi;
  final double gelir;

  const GunlukVeri({
    required this.gun,
    required this.siparisSayisi,
    required this.gelir,
  });
}

final haftalikVeriProvider =
    AsyncNotifierProvider.autoDispose<HaftalikVeriBildiricisi, List<GunlukVeri>>(
  HaftalikVeriBildiricisi.new,
);

class HaftalikVeriBildiricisi extends AsyncNotifier<List<GunlukVeri>> {
  @override
  Future<List<GunlukVeri>> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return [];
    return _yukle(ref.read(supabaseProvider), kimlik.isletmeId);
  }

  Future<List<GunlukVeri>> _yukle(
      SupabaseClient supabase, String isletmeId) async {
    try {
      final rpcSonuc = await supabase.rpc(
        'get_dashboard_weekly_v1',
        params: {'p_business_id': isletmeId},
      ) as Map<String, dynamic>?;

      final gunlukRaw = (rpcSonuc?['gunluk'] as List?) ?? [];
      return gunlukRaw.map((g) {
        final tarihStr = g['gun'] as String? ?? '';
        final tarih = DateTime.tryParse(tarihStr) ?? DateTime.now();
        return GunlukVeri(
          gun: tarih,
          siparisSayisi: (g['siparis_sayisi'] as num?)?.toInt() ?? 0,
          gelir: (g['gelir'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      debugPrint('HaftalikVeri yükleme hatası: $e');
      return [];
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

// P-14: Saatlik sipariş verisi — get_dashboard_weekly_v1.saatlik alanından
class SaatlikVeri {
  final int saat;
  final int siparisSayisi;
  const SaatlikVeri({required this.saat, required this.siparisSayisi});
}

final saatlikVeriProvider =
    AsyncNotifierProvider.autoDispose<SaatlikVeriBildiricisi, List<SaatlikVeri>>(
  SaatlikVeriBildiricisi.new,
);

class SaatlikVeriBildiricisi extends AsyncNotifier<List<SaatlikVeri>> {
  @override
  Future<List<SaatlikVeri>> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return [];
    return _yukle(ref.read(supabaseProvider), kimlik.isletmeId);
  }

  Future<List<SaatlikVeri>> _yukle(
      SupabaseClient supabase, String isletmeId) async {
    try {
      final rpcSonuc = await supabase.rpc(
        'get_dashboard_weekly_v1',
        params: {'p_business_id': isletmeId, 'p_days': 1},
      ) as Map<String, dynamic>?;

      final saatlikRaw = (rpcSonuc?['saatlik'] as List?) ?? [];
      final simdi = DateTime.now().hour;
      return saatlikRaw
          .map((s) => SaatlikVeri(
                saat: (s['saat'] as num?)?.toInt() ?? 0,
                siparisSayisi: (s['siparis_sayisi'] as num?)?.toInt() ?? 0,
              ))
          .where((s) => s.saat <= simdi)
          .toList();
    } catch (e) {
      debugPrint('SaatlikVeri yükleme hatası: $e');
      return [];
    }
  }
}

// P-16: Personel performans verisi — get_dashboard_stats_today_v1.personel_performans
class PersonelPerformans {
  final String staffId;
  final int siparisSayisi;
  final int tamamlanan;
  const PersonelPerformans({required this.staffId, required this.siparisSayisi, required this.tamamlanan});
}

final personelPerformansProvider =
    AsyncNotifierProvider.autoDispose<PersonelPerformansiBildiricisi, List<PersonelPerformans>>(
  PersonelPerformansiBildiricisi.new,
);

class PersonelPerformansiBildiricisi extends AsyncNotifier<List<PersonelPerformans>> {
  @override
  Future<List<PersonelPerformans>> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return [];
    try {
      final rpcSonuc = await ref.read(supabaseProvider).rpc(
        'get_dashboard_stats_today_v1',
        params: {'p_business_id': kimlik.isletmeId},
      ) as Map<String, dynamic>?;

      final perfs = (rpcSonuc?['personel_performans'] as List?) ?? [];
      return perfs.map((r) => PersonelPerformans(
        staffId: r['staff_id'] as String? ?? '?',
        siparisSayisi: (r['siparis_sayisi'] as num?)?.toInt() ?? 0,
        tamamlanan: (r['tamamlanan'] as num?)?.toInt() ?? 0,
      )).toList();
    } catch (e) {
      debugPrint('PersonelPerformans yükleme hatası: $e');
      return [];
    }
  }
}

class DashboardIstatistik {
  final int bugunBekleyen;
  final int bugunHazirlaniyor;
  final int bugunTamamlanan;
  final int toplamBugun;
  final int aktifMenuKalemi;
  final int pasifMenuKalemi;
  final double bugunGelir;
  final int bugunMusteriSayisi;

  const DashboardIstatistik({
    required this.bugunBekleyen,
    required this.bugunHazirlaniyor,
    required this.bugunTamamlanan,
    required this.toplamBugun,
    required this.aktifMenuKalemi,
    required this.pasifMenuKalemi,
    this.bugunGelir = 0,
    this.bugunMusteriSayisi = 0,
  });

  int get toplamMenu => aktifMenuKalemi + pasifMenuKalemi;
}

final dashboardIstatistikProvider =
    AsyncNotifierProvider.autoDispose<DashboardIstatistikBildiricisi, DashboardIstatistik?>(
  DashboardIstatistikBildiricisi.new,
);

class DashboardIstatistikBildiricisi
    extends AsyncNotifier<DashboardIstatistik?> {
  @override
  Future<DashboardIstatistik?> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return null;
    return _yukle(ref.read(supabaseProvider), kimlik.isletmeId);
  }

  Future<DashboardIstatistik?> _yukle(
      SupabaseClient supabase, String isletmeId) async {
    try {
      final results = await Future.wait([
        supabase.rpc(
          'get_dashboard_stats_today_v1',
          params: {'p_business_id': isletmeId},
        ),
        supabase.rpc(
          'get_menu_item_counts_v1',
          params: {'p_business_id': isletmeId},
        ),
      ]);

      final data = (results[0] as Map<String, dynamic>?) ?? const {};
      final menuData = (results[1] as Map<String, dynamic>?) ?? const {};

      return DashboardIstatistik(
        bugunBekleyen: (data['bugun_bekleyen'] as num?)?.toInt() ?? 0,
        bugunHazirlaniyor: (data['bugun_hazirlaniyor'] as num?)?.toInt() ?? 0,
        bugunTamamlanan: (data['bugun_tamamlanan'] as num?)?.toInt() ?? 0,
        toplamBugun: (data['toplam_bugun'] as num?)?.toInt() ?? 0,
        aktifMenuKalemi: (menuData['aktif'] as num?)?.toInt() ?? 0,
        pasifMenuKalemi: (menuData['pasif'] as num?)?.toInt() ?? 0,
        bugunMusteriSayisi: (data['toplam_bugun'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('DashboardIstatistik yükleme hatası: $e');
      return null;
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
