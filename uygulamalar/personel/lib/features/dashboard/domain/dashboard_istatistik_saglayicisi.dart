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
      final bugun = DateTime.now();
      final yediGunOnce = DateTime(bugun.year, bugun.month, bugun.day - 6)
          .toUtc()
          .toIso8601String();

      final siparisRows = await supabase
          .from('table_orders')
          .select('created_at, status')
          .eq('business_id', isletmeId)
          .gte('created_at', yediGunOnce) as List<dynamic>;

      final gelirRows = await supabase
          .from('table_order_items')
          .select('created_at, price, quantity')
          .eq('business_id', isletmeId)
          .gte('created_at', yediGunOnce) as List<dynamic>;

      final Map<String, int> gunlukSiparis = {};
      final Map<String, double> gunlukGelir = {};

      for (final s in siparisRows) {
        final tarih = DateTime.tryParse(s['created_at'] as String? ?? '');
        if (tarih == null) continue;
        final gun = '${tarih.toLocal().year}-${tarih.toLocal().month.toString().padLeft(2, '0')}-${tarih.toLocal().day.toString().padLeft(2, '0')}';
        gunlukSiparis[gun] = (gunlukSiparis[gun] ?? 0) + 1;
      }

      for (final g in gelirRows) {
        final tarih = DateTime.tryParse(g['created_at'] as String? ?? '');
        if (tarih == null) continue;
        final gun = '${tarih.toLocal().year}-${tarih.toLocal().month.toString().padLeft(2, '0')}-${tarih.toLocal().day.toString().padLeft(2, '0')}';
        final fiyat = (g['price'] as num?)?.toDouble() ?? 0;
        final adet = (g['quantity'] as num?)?.toInt() ?? 1;
        gunlukGelir[gun] = (gunlukGelir[gun] ?? 0) + fiyat * adet;
      }

      final sonuc = <GunlukVeri>[];
      for (var i = 6; i >= 0; i--) {
        final gun = DateTime(bugun.year, bugun.month, bugun.day - i);
        final anahtarStr =
            '${gun.year}-${gun.month.toString().padLeft(2, '0')}-${gun.day.toString().padLeft(2, '0')}';
        sonuc.add(GunlukVeri(
          gun: gun,
          siparisSayisi: gunlukSiparis[anahtarStr] ?? 0,
          gelir: gunlukGelir[anahtarStr] ?? 0,
        ));
      }
      return sonuc;
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

// P-14: Saatlik sipariş verisi
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
      final bugun = DateTime.now();
      final bugunBaslangic =
          DateTime(bugun.year, bugun.month, bugun.day).toUtc().toIso8601String();
      final siparisler = await supabase
          .from('table_orders')
          .select('created_at')
          .eq('business_id', isletmeId)
          .gte('created_at', bugunBaslangic) as List<dynamic>;

      final Map<int, int> saatlikSayac = {};
      for (final s in siparisler) {
        final tarih = DateTime.tryParse(s['created_at'] as String? ?? '');
        if (tarih == null) continue;
        final saat = tarih.toLocal().hour;
        saatlikSayac[saat] = (saatlikSayac[saat] ?? 0) + 1;
      }

      final simdi = DateTime.now().hour;
      return List.generate(simdi + 1, (i) => SaatlikVeri(
        saat: i,
        siparisSayisi: saatlikSayac[i] ?? 0,
      ));
    } catch (e) {
      debugPrint('SaatlikVeri yükleme hatası: $e');
      return [];
    }
  }
}

// P-16: Personel performans verisi
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
      final rows = await ref.read(supabaseProvider).rpc(
        'get_staff_performance_today_v1',
        params: {'p_business_id': kimlik.isletmeId},
      ) as List<dynamic>;
      return rows.map((r) => PersonelPerformans(
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
      // Sipariş istatistiklerini tek RPC ile çek (MED-009: N+1 sorgu önleme)
      final rpcSonuc = await supabase.rpc(
        'get_dashboard_stats_today_v1',
        params: {'p_business_id': isletmeId},
      );

      final data = (rpcSonuc as Map<String, dynamic>?) ?? const {};
      final bekleyen = (data['bugun_bekleyen'] as num?)?.toInt() ?? 0;
      final hazirlaniyor = (data['bugun_hazirlaniyor'] as num?)?.toInt() ?? 0;
      final tamamlanan = (data['bugun_tamamlanan'] as num?)?.toInt() ?? 0;
      final toplam = (data['toplam_bugun'] as num?)?.toInt() ?? 0;

      // Menü kalem sayıları RPC kapsamı dışında — ayrı sorgu
      final menuKalemleri = await supabase
          .from('menu_items')
          .select('is_available')
          .eq('business_id', isletmeId) as List<dynamic>;

      int aktif = 0, pasif = 0;
      for (final m in menuKalemleri) {
        final mevcut = m['is_available'] as bool? ?? true;
        if (mevcut) {
          aktif++;
        } else {
          pasif++;
        }
      }

      return DashboardIstatistik(
        bugunBekleyen: bekleyen,
        bugunHazirlaniyor: hazirlaniyor,
        bugunTamamlanan: tamamlanan,
        toplamBugun: toplam,
        aktifMenuKalemi: aktif,
        pasifMenuKalemi: pasif,
        bugunMusteriSayisi: toplam,
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
