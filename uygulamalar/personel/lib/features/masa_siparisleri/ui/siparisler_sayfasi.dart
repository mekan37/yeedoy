import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hata_esleyici.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import '../../shared/ui/p_iskelet.dart';
import '../domain/masa_siparisi_bildiricisi.dart';
import '../domain/masa_siparisi_modeli.dart';

class SiparislerSayfasi extends ConsumerWidget {
  const SiparislerSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siparisState = ref.watch(masaSiparisleriProvider);
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    final isletmeAdi =
        kimlik is KimlikGirilmis ? kimlik.isletmeAdi : 'İşletme';

    return Scaffold(
      appBar: AppBar(
        title: Text(isletmeAdi),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: 'Masa Tara',
            onPressed: () => context.push('/qr-tarayici'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Yenile',
            onPressed: () =>
                ref.read(masaSiparisleriProvider.notifier).yenile(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(masaSiparisleriProvider.notifier).yenile(),
        child: siparisState.when(
          loading: () => const PersonelListIskeleti(satirSayisi: 5),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(HataEsleyici.mesaj(e),
                        style: const TextStyle(color: PColors.danger)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.read(masaSiparisleriProvider.notifier).yenile(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (siparisler) => _SiparisListesi(siparisler: siparisler),
        ),
      ),
    );
  }
}

class _SiparisListesi extends ConsumerWidget {
  final List<MasaSiparisi> siparisler;
  const _SiparisListesi({required this.siparisler});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bekleyen =
        siparisler.where((s) => s.durum == 'pending').toList();
    // P-7: 'waiting' (bekletilmiş) siparişler de "Hazırlanıyor" sütununda gösterilir
    final hazirlaniyor =
        siparisler.where((s) => s.durum == 'seen' || s.durum == 'waiting').toList();

    if (siparisler.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: PColors.orderDone),
            const SizedBox(height: 12),
            Text(
              'Bekleyen sipariş yok',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: PColors.muted),
            ),
          ],
        ),
      );
    }

    final eni = MediaQuery.sizeOf(context).width;
    final ikisutun = eni >= 720;

    if (ikisutun) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _SiparisSutunu(
              baslik: 'Bekleyen',
              renk: PColors.orderPending,
              siparisler: bekleyen,
              aksiyon: 'Gördüm',
              aksiyonDurum: 'seen',
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _SiparisSutunu(
              baslik: 'Hazırlanıyor',
              renk: PColors.orderSeen,
              siparisler: hazirlaniyor,
              aksiyon: 'Teslim Edildi',
              aksiyonDurum: 'done',
            ),
          ),
        ],
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _Rozet(bekleyen.length, PColors.orderPending),
                  const SizedBox(width: 6),
                  const Text('Bekleyen'),
                ]),
              ),
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _Rozet(hazirlaniyor.length, PColors.orderSeen),
                  const SizedBox(width: 6),
                  const Text('Hazırlanıyor'),
                ]),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SiparisSutunu(
                  baslik: 'Bekleyen',
                  renk: PColors.orderPending,
                  siparisler: bekleyen,
                  aksiyon: 'Gördüm',
                  aksiyonDurum: 'seen',
                ),
                _SiparisSutunu(
                  baslik: 'Hazırlanıyor',
                  renk: PColors.orderSeen,
                  siparisler: hazirlaniyor,
                  aksiyon: 'Teslim Edildi',
                  aksiyonDurum: 'done',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SiparisSutunu extends ConsumerWidget {
  final String baslik;
  final Color renk;
  final List<MasaSiparisi> siparisler;
  final String aksiyon;
  final String aksiyonDurum;

  const _SiparisSutunu({
    required this.baslik,
    required this.renk,
    required this.siparisler,
    required this.aksiyon,
    required this.aksiyonDurum,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (siparisler.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Boş',
            style: TextStyle(color: PColors.muted, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: siparisler.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _SiparisKarti(
        siparis: siparisler[i],
        aksiyonEtiketi: aksiyon,
        aksiyonDurum: aksiyonDurum,
        durumRengi: renk,
      ),
    );
  }
}

class _SiparisKarti extends ConsumerStatefulWidget {
  final MasaSiparisi siparis;
  final String aksiyonEtiketi;
  final String aksiyonDurum;
  final Color durumRengi;

  const _SiparisKarti({
    required this.siparis,
    required this.aksiyonEtiketi,
    required this.aksiyonDurum,
    required this.durumRengi,
  });

  @override
  ConsumerState<_SiparisKarti> createState() => _SiparisKartiState();
}

class _SiparisKartiState extends ConsumerState<_SiparisKarti> {
  Timer? _timer;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // P-8: Her 30s'de bir timestamp güncellenir
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // P-6: Personel notu dialog
  Future<void> _personelNotuDialog() async {
    final ctrl = TextEditingController(text: widget.siparis.personelNotu ?? '');
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Masa ${widget.siparis.masaNo} — Personel Notu'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'İç not (müşteri görmez)...',
            prefixIcon: Icon(Icons.edit_note_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(masaSiparisleriProvider.notifier)
                  .personelNotuGuncelle(widget.siparis.id, ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _aksiyonTap() async {
    if (_isUpdating) return;
    HapticFeedback.mediumImpact();
    setState(() => _isUpdating = true);
    try {
      await ref.read(masaSiparisleriProvider.notifier)
          .durumGuncelle(widget.siparis.id, widget.aksiyonDurum);
      // P-12: Başarı toastı
      if (mounted) {
        final mesaj = widget.aksiyonDurum == 'seen'
            ? 'Masa ${widget.siparis.masaNo} — görüldü ✓'
            : 'Masa ${widget.siparis.masaNo} — teslim edildi ✓';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mesaj),
            duration: const Duration(seconds: 2),
            backgroundColor: PColors.orderDone,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(HataEsleyici.mesaj(e)),
            backgroundColor: PColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gecen = DateTime.now().difference(widget.siparis.olusturuldu);
    final dakika = gecen.inMinutes;

    // P-13: Aciliyet rengi — 30dk+ kırmızı, 15dk+ turuncu
    final Color zamanRengi = dakika >= 30
        ? PColors.danger
        : dakika >= 15
            ? const Color(0xFFF97316)
            : PColors.muted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.durumRengi.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Masa ${widget.siparis.masaNo}',
                    style: TextStyle(
                      color: widget.durumRengi,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                // P-8 + P-13: Gerçek zamanlı + aciliyet rengi
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dakika >= 15)
                      Icon(Icons.schedule_outlined, size: 13, color: zamanRengi),
                    if (dakika >= 15) const SizedBox(width: 3),
                    Text(
                      dakika == 0 ? 'Az önce' : '$dakika dk önce',
                      style: textTheme.bodySmall?.copyWith(
                        color: zamanRengi,
                        fontWeight: dakika >= 15 ? FontWeight.w700 : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // P-6 + P-7: Not ekle / Beklet popup
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_outlined, size: 16, color: PColors.muted),
                      padding: EdgeInsets.zero,
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'not', child: Row(children: [Icon(Icons.edit_note_outlined, size: 16), SizedBox(width: 8), Text('Personel Notu')])),
                        if (!widget.siparis.bekliyor)
                          const PopupMenuItem(value: 'beklet', child: Row(children: [Icon(Icons.pause_circle_outline, size: 16), SizedBox(width: 8), Text('Beklet')])),
                        if (widget.siparis.bekliyor)
                          const PopupMenuItem(value: 'devam', child: Row(children: [Icon(Icons.play_circle_outline, size: 16), SizedBox(width: 8), Text('Devam Et')])),
                      ],
                      onSelected: (v) async {
                        if (v == 'not') {
                          _personelNotuDialog();
                        } else if (v == 'beklet') {
                          await ref.read(masaSiparisleriProvider.notifier).durumGuncelle(widget.siparis.id, 'waiting');
                        } else if (v == 'devam') {
                          await ref.read(masaSiparisleriProvider.notifier).durumGuncelle(widget.siparis.id, 'seen');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...widget.siparis.kalemler.map(
              (k) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${k.adet}×',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: PColors.textStrong,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.urunAdi, style: textTheme.bodyMedium),
                          if (k.not != null && k.not!.isNotEmpty)
                            Text(
                              k.not!,
                              style: textTheme.bodySmall?.copyWith(color: PColors.muted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.siparis.not != null && widget.siparis.not!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _MusteriNotu(not: widget.siparis.not!),
            ],
            const SizedBox(height: 12),
            // P-7: Bekletme göstergesi
            if (widget.siparis.bekliyor)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PColors.warning.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pause_circle_outline, size: 14, color: PColors.warning),
                    SizedBox(width: 6),
                    Text('Bekletildi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PColors.warning)),
                  ],
                ),
              ),
            // P-6: Personel notu
            if (widget.siparis.personelNotu != null && widget.siparis.personelNotu!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PColors.info.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, size: 14, color: PColors.info),
                    const SizedBox(width: 6),
                    Expanded(child: Text(widget.siparis.personelNotu!, style: const TextStyle(fontSize: 12, color: PColors.info))),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isUpdating ? null : _aksiyonTap,
                child: _isUpdating
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.aksiyonEtiketi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// P-30: Alerji/diyet anahtar kelimeleri içeren notları kırmızıyla vurgula
class _MusteriNotu extends StatelessWidget {
  final String not;
  const _MusteriNotu({required this.not});

  static const _alerjiler = [
    'alerji', 'alerjik', 'gluten', 'vegan', 'vejetaryen', 'laktoz',
    'fıstık', 'fistik', 'süt', 'sut', 'yumurta', 'balık', 'balik',
    'karides', 'ceviz', 'badem', 'soya', 'buğday', 'bugday',
  ];

  bool get _kritik {
    final kucuk = not.toLowerCase();
    return _alerjiler.any((k) => kucuk.contains(k));
  }

  @override
  Widget build(BuildContext context) {
    final kritik = _kritik;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: kritik
            ? PColors.danger.withValues(alpha: 0.08)
            : PColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: kritik
            ? Border.all(color: PColors.danger.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            kritik ? Icons.warning_amber_outlined : Icons.notes_outlined,
            size: 14,
            color: kritik ? PColors.danger : PColors.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              not,
              style: TextStyle(
                fontSize: 12,
                fontWeight: kritik ? FontWeight.w700 : FontWeight.normal,
                color: kritik ? PColors.danger : PColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rozet extends StatelessWidget {
  final int sayi;
  final Color renk;
  const _Rozet(this.sayi, this.renk);

  @override
  Widget build(BuildContext context) {
    if (sayi == 0) return const SizedBox.shrink();
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: renk,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$sayi',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
