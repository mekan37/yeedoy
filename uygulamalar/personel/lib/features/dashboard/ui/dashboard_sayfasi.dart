import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hata_esleyici.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import '../../shared/ui/p_iskelet.dart';
import '../domain/dashboard_istatistik_saglayicisi.dart';

class DashboardSayfasi extends ConsumerWidget {
  const DashboardSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    final isletmeAdi = kimlik is KimlikGirilmis ? kimlik.isletmeAdi : '';
    final istatistikState = ref.watch(dashboardIstatistikProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isletmeAdi.isEmpty ? 'Dashboard' : isletmeAdi),
        actions: [
          IconButton(
            icon: const Icon(Icons.reviews_outlined),
            tooltip: 'Yorumlar',
            onPressed: () => context.push('/yorumlar'),
          ),
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Kampanya Gönder',
            onPressed: () => context.push('/kampanya'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                ref.read(dashboardIstatistikProvider.notifier).yenile(),
          ),
        ],
      ),
      body: istatistikState.when(
        loading: () => const PersonelDashboardIskeleti(),
        error: (e, _) => Center(child: Text(HataEsleyici.mesaj(e), style: const TextStyle(color: PColors.danger))),
        data: (ist) => ist == null
            ? const Center(child: Text('Veri yok'))
            : _DashboardIcerik(ist: ist),
      ),
    );
  }
}

class _DashboardIcerik extends StatelessWidget {
  final DashboardIstatistik ist;
  const _DashboardIcerik({required this.ist});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _baslik(context, "Bugünün Siparişleri"),
          const SizedBox(height: 12),
          _SiparisKartlari(ist: ist),
          const SizedBox(height: 24),
          _baslik(context, 'Menü Durumu'),
          const SizedBox(height: 12),
          _MenuKartlari(ist: ist),
          const SizedBox(height: 24),
          _baslik(context, 'Hızlı Özet'),
          const SizedBox(height: 12),
          _OzetKarti(ist: ist),
          const SizedBox(height: 24),
          _baslik(context, 'Son 7 Gün'),
          const SizedBox(height: 12),
          const _HaftalikGrafik(),
        ],
      ),
    );
  }

  Widget _baslik(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: PColors.muted,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    ),
  );
}

class _SiparisKartlari extends StatelessWidget {
  final DashboardIstatistik ist;
  const _SiparisKartlari({required this.ist});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatKarti(
            sayi: ist.bugunBekleyen,
            etiket: 'Bekliyor',
            renk: PColors.orderPending,
            ikon: Icons.hourglass_top_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatKarti(
            sayi: ist.bugunHazirlaniyor,
            etiket: 'Hazırlanıyor',
            renk: PColors.orderSeen,
            ikon: Icons.restaurant_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatKarti(
            sayi: ist.bugunTamamlanan,
            etiket: 'Tamamlandı',
            renk: PColors.orderDone,
            ikon: Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _MenuKartlari extends StatelessWidget {
  final DashboardIstatistik ist;
  const _MenuKartlari({required this.ist});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatKarti(
            sayi: ist.aktifMenuKalemi,
            etiket: 'Aktif Ürün',
            renk: PColors.success,
            ikon: Icons.check_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatKarti(
            sayi: ist.pasifMenuKalemi,
            etiket: 'Pasif Ürün',
            renk: PColors.muted,
            ikon: Icons.block_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatKarti(
            sayi: ist.toplamMenu,
            etiket: 'Toplam',
            renk: PColors.info,
            ikon: Icons.menu_book_outlined,
          ),
        ),
      ],
    );
  }
}

class _OzetKarti extends ConsumerWidget {
  final DashboardIstatistik ist;
  const _OzetKarti({required this.ist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tamamlanmaOrani = ist.toplamBugun > 0
        ? (ist.bugunTamamlanan / ist.toplamBugun * 100).round()
        : 0;

    final gelirStr = ist.bugunGelir > 0
        ? '₺${ist.bugunGelir.toStringAsFixed(2)}'
        : '—';

    // P-26: Haftalık veriden ortalama sipariş hesapla (bugün hariç 6 gün)
    final haftalikState = ref.watch(haftalikVeriProvider);
    final kiyasStr = haftalikState.maybeWhen(
      data: (veriler) {
        if (veriler.length < 7) return null;
        // Son 7 günün ilk 6 günü (bugün hariç)
        final gecmisToplam = veriler
            .take(6)
            .fold(0, (sum, v) => sum + v.siparisSayisi);
        if (gecmisToplam == 0) return null;
        final gunlukOrtalama = gecmisToplam / 6;
        if (gunlukOrtalama == 0) return null;
        final fark = ist.toplamBugun - gunlukOrtalama;
        final yuzde = ((fark / gunlukOrtalama) * 100).round();
        return yuzde >= 0 ? '+$yuzde%' : '$yuzde%';
      },
      orElse: () => null,
    );

    final kiyasRenk = kiyasStr == null
        ? null
        : kiyasStr.startsWith('+')
            ? PColors.success
            : PColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _OzetSatir(
              ikon: Icons.receipt_long_outlined,
              etiket: 'Toplam sipariş (bugün)',
              deger: '${ist.toplamBugun}',
              badge: kiyasStr,
              badgeRengi: kiyasRenk,
            ),
            const Divider(height: 20),
            _OzetSatir(
              ikon: Icons.percent_outlined,
              etiket: 'Tamamlanma oranı',
              deger: '%$tamamlanmaOrani',
              degerRengi: tamamlanmaOrani > 70
                  ? PColors.orderDone
                  : tamamlanmaOrani > 40
                  ? PColors.orderPending
                  : PColors.danger,
            ),
            const Divider(height: 20),
            _OzetSatir(
              ikon: Icons.attach_money_outlined,
              etiket: 'Bugün ciro',
              deger: gelirStr,
              degerRengi: ist.bugunGelir > 0 ? PColors.success : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OzetSatir extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final String deger;
  final Color? degerRengi;
  final String? badge;
  final Color? badgeRengi;

  const _OzetSatir({
    required this.ikon,
    required this.etiket,
    required this.deger,
    this.degerRengi,
    this.badge,
    this.badgeRengi,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 18, color: PColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(etiket, style: const TextStyle(color: PColors.text)),
        ),
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeRengi ?? PColors.muted).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: badgeRengi ?? PColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          deger,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: degerRengi ?? PColors.textStrong,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _StatKarti extends StatelessWidget {
  final int sayi;
  final String etiket;
  final Color renk;
  final IconData ikon;

  const _StatKarti({
    required this.sayi,
    required this.etiket,
    required this.renk,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(ikon, color: renk, size: 22),
          const SizedBox(height: 8),
          Text(
            '$sayi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: renk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiket,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Haftalık Grafik ──────────────────────────────────────────────────────────

class _HaftalikGrafik extends ConsumerStatefulWidget {
  const _HaftalikGrafik();

  @override
  ConsumerState<_HaftalikGrafik> createState() => _HaftalikGrafikState();
}

class _HaftalikGrafikState extends ConsumerState<_HaftalikGrafik> {
  bool _gelirModu = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(haftalikVeriProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _gelirModu ? 'Haftalık Gelir (₺)' : 'Haftalık Sipariş',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: PColors.textStrong,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _gelirModu = !_gelirModu),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _gelirModu ? '₺' : '#',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: PColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            state.when(
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Grafik yüklenemedi',
                    style: TextStyle(color: PColors.muted, fontSize: 12),
                  ),
                ),
              ),
              data: (veriler) => veriler.isEmpty
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Veri yok',
                          style: TextStyle(color: PColors.muted),
                        ),
                      ),
                    )
                  : _BarGrafik(veriler: veriler, gelirModu: _gelirModu),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarGrafik extends StatelessWidget {
  final List<GunlukVeri> veriler;
  final bool gelirModu;
  static const double _yukseklik = 120;
  static const double _etiketGenislik = 32;
  static const List<String> _gunKisaltma = [
    'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz',
  ];

  const _BarGrafik({required this.veriler, required this.gelirModu});

  static double _niceMax(double val) {
    if (val <= 0) return 10;
    final adim = val <= 10 ? 2.0 : val <= 50 ? 10.0 : val <= 200 ? 50.0 : 100.0;
    return (val / adim).ceil() * adim;
  }

  static String _yEtiket(double val, bool gelir) {
    if (gelir) {
      return val >= 1000
          ? '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}K'
          : val.toStringAsFixed(0);
    }
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final degerler = veriler
        .map((v) => gelirModu ? v.gelir : v.siparisSayisi.toDouble())
        .toList();
    final rawMax = degerler.fold(0.0, math.max);
    final yMax = _niceMax(rawMax);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y ekseni etiketleri
        SizedBox(
          width: _etiketGenislik,
          height: _yukseklik + 26,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 2,
                child: Text(
                  _yEtiket(yMax, gelirModu),
                  style: const TextStyle(fontSize: 9, color: PColors.muted),
                ),
              ),
              Positioned(
                top: _yukseklik / 2 - 6,
                right: 2,
                child: Text(
                  _yEtiket(yMax / 2, gelirModu),
                  style: const TextStyle(fontSize: 9, color: PColors.muted),
                ),
              ),
              const Positioned(
                top: _yukseklik - 6,
                right: 2,
                child: Text('0', style: TextStyle(fontSize: 9, color: PColors.muted)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        // Grafik alanı
        Expanded(
          child: SizedBox(
            height: _yukseklik + 26,
            child: Stack(
              children: [
                // Grid çizgileri
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Divider(height: 1, color: PColors.muted.withValues(alpha: 0.2)),
                ),
                Positioned(
                  top: _yukseklik / 2, left: 0, right: 0,
                  child: Divider(height: 1, color: PColors.muted.withValues(alpha: 0.15)),
                ),
                Positioned(
                  top: _yukseklik, left: 0, right: 0,
                  child: Divider(height: 1, color: PColors.muted.withValues(alpha: 0.2)),
                ),
                // Çubuklar
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(veriler.length, (i) {
                      final veri = veriler[i];
                      final deger = degerler[i];
                      final oran = yMax > 0 ? deger / yMax : 0.0;
                      final bugun = i == veriler.length - 1;
                      final gunAdi = _gunKisaltma[veri.gun.weekday - 1];

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (bugun && deger > 0)
                                Text(
                                  gelirModu ? '₺${deger.toStringAsFixed(0)}' : '$deger',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: PColors.primary,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                height: math.max(4, oran * _yukseklik),
                                decoration: BoxDecoration(
                                  color: bugun
                                      ? PColors.primary
                                      : PColors.primary.withValues(alpha: 0.35),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gunAdi,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: bugun ? FontWeight.w900 : FontWeight.normal,
                                  color: bugun ? PColors.primary : PColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
