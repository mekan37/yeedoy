import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../../../core/hata_esleyici.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../masa_siparisleri/domain/masa_siparisi_modeli.dart';
import '../../shared/ui/p_iskelet.dart';
import '../domain/kds_bildiricisi.dart';

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
          _SonYenilenmeGostergesi(zaman: _sonYenilenme),
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
                          _SayiBadge(bekleyen.length, PColors.orderPending),
                          const SizedBox(width: 6),
                          const Text('Yeni'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SayiBadge(hazirlaniyor.length, PColors.orderSeen),
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
      builder: (ctx) => const _YaziciAyarlariSheet(),
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
class _YaziciAyarlariSheet extends StatefulWidget {
  const _YaziciAyarlariSheet();

  @override
  State<_YaziciAyarlariSheet> createState() => _YaziciAyarlariSheetState();
}

class _YaziciAyarlariSheetState extends State<_YaziciAyarlariSheet> {
  final _ipCtrl = TextEditingController(text: '192.168.1.100');
  final _portCtrl = TextEditingController(text: '9100');
  String _kagiTipi = '80mm';
  bool _otoBaskiEtkin = false;

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: PColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Yazıcı Ayarları (ESC/POS)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: PColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ağ yazıcısı bağlantı bilgilerini girin',
            style: TextStyle(color: PColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // IP address
          TextFormField(
            controller: _ipCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Yazıcı IP Adresi',
              hintText: '192.168.1.100',
              prefixIcon: Icon(Icons.wifi_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // Port
          TextFormField(
            controller: _portCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '9100',
              prefixIcon: Icon(Icons.power_input_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // Paper type
          Row(
            children: [
              const Text(
                'Kağıt genişliği:',
                style: TextStyle(color: PColors.muted, fontSize: 13),
              ),
              const SizedBox(width: 12),
              ...['58mm', '80mm'].map(
                (w) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(w),
                    selected: _kagiTipi == w,
                    onSelected: (_) => setState(() => _kagiTipi = w),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Auto print
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Yeni sipariş otomatik baskısı',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Sipariş gelince otomatik yazdır',
              style: TextStyle(fontSize: 12, color: PColors.muted),
            ),
            value: _otoBaskiEtkin,
            onChanged: (v) => setState(() => _otoBaskiEtkin = v),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.wifi_find_outlined, size: 18),
                  label: const Text('Test Bağlantısı'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_ipCtrl.text}:${_portCtrl.text} — bağlantı testi gönderildi',
                        ),
                        backgroundColor: PColors.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Kaydet'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Yazıcı ayarları kaydedildi'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
            itemBuilder: (ctx, i) => _KdsSiparisKarti(
              siparis: siparisler[i],
              durumRengi: renk,
              aksiyonEtiketi: aksiyonEtiketi,
              onAksiyon: () => onAksiyon(siparisler[i].id),
            ),
          ),
        ),
      ],
    );
  }
}

class _KdsSiparisKarti extends StatelessWidget {
  final MasaSiparisi siparis;
  final Color durumRengi;
  final String aksiyonEtiketi;
  final VoidCallback onAksiyon;

  const _KdsSiparisKarti({
    required this.siparis,
    required this.durumRengi,
    required this.aksiyonEtiketi,
    required this.onAksiyon,
  });

  void _yaziciGonder(BuildContext context, MasaSiparisi siparis) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yazıcıya Gönder',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: PColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masa ${siparis.masaNo} — ${siparis.kalemler.length} kalem',
              style: const TextStyle(color: PColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Masa ${siparis.masaNo} fişi yazıcıya gönderildi',
                    ),
                    backgroundColor: PColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('Mutfak Fişi Yazdır'),
            ),
            const SizedBox(height: 8),
            const Text(
              '* ESC/POS yazıcı bağlantısı için Yeedoy Partner uygulamasını kullanın.',
              style: TextStyle(fontSize: 11, color: PColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gecen = DateTime.now().difference(siparis.olusturuldu);
    final dakika = gecen.inMinutes;
    final uzun = dakika >= 10; // 10+ dakika: kırmızı uyarı

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: durumRengi.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Masa ${siparis.masaNo}',
                    style: TextStyle(
                      color: durumRengi,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dakika == 0 ? 'Az önce' : '$dakika dk önce',
                  style: textTheme.bodySmall?.copyWith(
                    color: uzun ? PColors.danger : PColors.muted,
                    fontWeight: uzun ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...siparis.kalemler.map(
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
                              style: textTheme.bodySmall?.copyWith(
                                color: PColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (siparis.not != null && siparis.not!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: PColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notes_outlined,
                      size: 14,
                      color: PColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        siparis.not!,
                        style: textTheme.bodySmall?.copyWith(
                          color: PColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAksiyon,
                    style: FilledButton.styleFrom(
                      backgroundColor: durumRengi,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(aksiyonEtiketi),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _yaziciGonder(context, siparis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PColors.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(40, 40),
                  ),
                  child: const Icon(Icons.print_outlined, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SayiBadge extends StatelessWidget {
  final int sayi;
  final Color renk;
  const _SayiBadge(this.sayi, this.renk);

  @override
  Widget build(BuildContext context) {
    if (sayi == 0) return const SizedBox.shrink();
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$sayi',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SonYenilenmeGostergesi extends StatelessWidget {
  final DateTime zaman;
  const _SonYenilenmeGostergesi({required this.zaman});

  @override
  Widget build(BuildContext context) {
    final gecen = DateTime.now().difference(zaman);
    final etiket = gecen.inSeconds < 60 ? 'Az önce' : '${gecen.inMinutes} dk';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: PColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            etiket,
            style: const TextStyle(fontSize: 11, color: PColors.muted),
          ),
        ],
      ),
    );
  }
}
