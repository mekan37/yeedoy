import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../../../core/hata_esleyici.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../masa_siparisleri/domain/masa_siparisi_modeli.dart';
import '../../shared/ui/p_iskelet.dart';
import '../domain/kds_bildiricisi.dart';
import 'kds_yazici_ayarlari.dart';
import 'kds_siparis_karti.dart';

class KdsSayfasi extends ConsumerStatefulWidget {
  const KdsSayfasi({super.key});

  @override
  ConsumerState<KdsSayfasi> createState() => _KdsSayfasiState();
}

class _KdsSayfasiState extends ConsumerState<KdsSayfasi> {
  DateTime _sonYenilenme = DateTime.now();

  int _oncekiSiparisSayisi = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kdsProvider);

    // Son yenilenme zamanını güncelle + yeni sipariş titreşimi
    ref.listen<AsyncValue<List<MasaSiparisi>>>(kdsProvider, (onceki, sonraki) {
      if (sonraki is AsyncData) {
        final yeniSayi =
            sonraki.value?.where((s) => s.durum == 'pending').length ?? 0;
        if (yeniSayi > _oncekiSiparisSayisi) {
          Vibration.vibrate(pattern: [0, 200, 100, 200]);
        }
        _oncekiSiparisSayisi = yeniSayi;
        setState(() => _sonYenilenme = DateTime.now());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutfak Ekranı'),
        actions: [
          KdsSonYenilenme(zaman: _sonYenilenme),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Yazıcı Ayarları',
            onPressed: () => _showYaziciAyarlari(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Yenile',
            onPressed: () => ref.read(kdsProvider.notifier).yenile(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const PersonelListIskeleti(satirSayisi: 4),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(HataEsleyici.mesaj(e), style: const TextStyle(color: PColors.danger)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(kdsProvider.notifier).yenile(),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (siparisler) {
          final bekleyen = siparisler
              .where((s) => s.durum == 'pending')
              .toList();
          final hazirlaniyor = siparisler
              .where((s) => s.durum == 'seen')
              .toList();

          if (siparisler.isEmpty) {
            return const _MutfakTemizMesaji();
          }

          final eni = MediaQuery.sizeOf(context).width;
          if (eni >= 600) {
            return Column(
              children: [
                // Stats bar
                _KdsStatsBar(
                  bekleyen: bekleyen.length,
                  hazirlaniyor: hazirlaniyor.length,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _KdsSutun(
                          baslik: 'Yeni Siparişler',
                          renk: PColors.orderPending,
                          siparisler: bekleyen,
                          aksiyonEtiketi: 'Kabul Et',
                          onAksiyon: (id) =>
                              ref.read(kdsProvider.notifier).siparisKabulEt(id),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _KdsSutun(
                          baslik: 'Hazırlanıyor',
                          renk: PColors.orderSeen,
                          siparisler: hazirlaniyor,
                          aksiyonEtiketi: 'Hazır',
                          onAksiyon: (id) =>
                              ref.read(kdsProvider.notifier).siparisHazir(id),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Dar ekran: tab view
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KdsSayiBadge(bekleyen.length, PColors.orderPending),
                          const SizedBox(width: 6),
                          const Text('Yeni'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KdsSayiBadge(hazirlaniyor.length, PColors.orderSeen),
                          const SizedBox(width: 6),
                          const Text('Hazırlanıyor'),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _KdsSutun(
                        baslik: 'Yeni Siparişler',
                        renk: PColors.orderPending,
                        siparisler: bekleyen,
                        aksiyonEtiketi: 'Kabul Et',
                        onAksiyon: (id) =>
                            ref.read(kdsProvider.notifier).siparisKabulEt(id),
                      ),
                      _KdsSutun(
                        baslik: 'Hazırlanıyor',
                        renk: PColors.orderSeen,
                        siparisler: hazirlaniyor,
                        aksiyonEtiketi: 'Hazır',
                        onAksiyon: (id) =>
                            ref.read(kdsProvider.notifier).siparisHazir(id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showYaziciAyarlari(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const YaziciAyarlariSheet(),
    );
  }
}

class _KdsStatsBar extends StatelessWidget {
  final int bekleyen;
  final int hazirlaniyor;
  const _KdsStatsBar({required this.bekleyen, required this.hazirlaniyor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: PColors.surface,
      child: Row(
        children: [
          _StatChip(
            label: 'Bekleyen',
            sayi: bekleyen,
            renk: PColors.orderPending,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Hazırlanıyor',
            sayi: hazirlaniyor,
            renk: PColors.orderSeen,
          ),
          const Spacer(),
          if (bekleyen == 0 && hazirlaniyor == 0)
            const Text(
              '✓ Mutfak temiz',
              style: TextStyle(
                color: PColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int sayi;
  final Color renk;
  const _StatChip({
    required this.label,
    required this.sayi,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sayi',
            style: TextStyle(
              color: renk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: renk,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Yazıcı Ayarları Bottom Sheet
class _MutfakTemizMesaji extends StatelessWidget {
  const _MutfakTemizMesaji();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✓', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'Mutfak temiz',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: PColors.muted),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bekleyen sipariş yok',
            style: TextStyle(color: PColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _KdsSutun extends StatelessWidget {
  final String baslik;
  final Color renk;
  final List<MasaSiparisi> siparisler;
  final String aksiyonEtiketi;
  final void Function(String id) onAksiyon;

  const _KdsSutun({
    required this.baslik,
    required this.renk,
    required this.siparisler,
    required this.aksiyonEtiketi,
    required this.onAksiyon,
  });

  @override
  Widget build(BuildContext context) {
    if (siparisler.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Boş',
            style: TextStyle(
              color: renk.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: renk.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            baslik,
            style: TextStyle(
              color: renk,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: siparisler.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => RepaintBoundary(
              child: KdsSiparisKarti(
                siparis: siparisler[i],
                durumRengi: renk,
                aksiyonEtiketi: aksiyonEtiketi,
                onAksiyon: () => onAksiyon(siparisler[i].id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
