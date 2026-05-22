import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata_esleyici.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../shared/ui/p_iskelet.dart';
import '../domain/menu_kalemi_modeli.dart';
import '../domain/menu_yonetimi_bildiricisi.dart';

class MenuYonetimiSayfasi extends ConsumerWidget {
  const MenuYonetimiSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(menuYonetimiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menü Yönetimi'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_outlined),
            tooltip: 'Toplu İşlemler',
            onSelected: (v) {
              if (v == 'hepsini_aktif') {
                ref.read(menuYonetimiProvider.notifier).topluGuncelle(true);
              } else if (v == 'hepsini_pasif') {
                ref.read(menuYonetimiProvider.notifier).topluGuncelle(false);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'hepsini_aktif',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: PColors.success),
                    SizedBox(width: 10),
                    Text('Hepsini Aktif Yap'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hepsini_pasif',
                child: Row(
                  children: [
                    Icon(Icons.block_outlined, size: 18, color: PColors.muted),
                    SizedBox(width: 10),
                    Text('Hepsini Pasif Yap'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                ref.read(menuYonetimiProvider.notifier).yenile(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const PersonelListIskeleti(satirSayisi: 8),
        error: (e, _) => Center(child: Text(HataEsleyici.mesaj(e), style: const TextStyle(color: Colors.red))),
        data: (kalemler) => kalemler.isEmpty
            ? const _BosMenuMesaji()
            : _MenuListesi(kalemler: kalemler),
      ),
    );
  }
}

class _BosMenuMesaji extends StatelessWidget {
  const _BosMenuMesaji();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: 56, color: PColors.muted),
          const SizedBox(height: 12),
          Text(
            'Henüz menü kalemi yok',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: PColors.muted),
          ),
        ],
      ),
    );
  }
}

enum _MenuFiltre { tumu, mevcut, pasif }
enum _MenuSiralama { varsayilan, adA, fiyatDusuk, fiyatYuksek, spesiyel }

class _MenuListesi extends StatefulWidget {
  final List<MenuKalemi> kalemler;
  const _MenuListesi({required this.kalemler});

  @override
  State<_MenuListesi> createState() => _MenuListesiState();
}

class _MenuListesiState extends State<_MenuListesi> {
  final _aramaCtrl = TextEditingController();
  _MenuFiltre _filtre = _MenuFiltre.tumu;
  _MenuSiralama _siralama = _MenuSiralama.varsayilan;
  String _aramaMetni = '';

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  List<MenuKalemi> get _filtrelenmis {
    var liste = widget.kalemler;
    if (_filtre == _MenuFiltre.mevcut) {
      liste = liste.where((k) => k.mevcut).toList();
    } else if (_filtre == _MenuFiltre.pasif) {
      liste = liste.where((k) => !k.mevcut).toList();
    }
    switch (_siralama) {
      case _MenuSiralama.varsayilan:
        break;
      case _MenuSiralama.adA:
        liste = [...liste]..sort((a, b) => a.ad.compareTo(b.ad));
      case _MenuSiralama.fiyatDusuk:
        liste = [...liste]..sort((a, b) => (a.fiyat ?? 0).compareTo(b.fiyat ?? 0));
      case _MenuSiralama.fiyatYuksek:
        liste = [...liste]..sort((a, b) => (b.fiyat ?? 0).compareTo(a.fiyat ?? 0));
      case _MenuSiralama.spesiyel:
        liste = [...liste]..sort((a, b) => b.bugunSpesiyel ? 1 : (a.bugunSpesiyel ? -1 : 0));
    }
    if (_aramaMetni.isNotEmpty) {
      final q = _aramaMetni.toLowerCase();
      liste = liste
          .where((k) =>
              k.ad.toLowerCase().contains(q) ||
              (k.kategori?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return liste;
  }

  @override
  Widget build(BuildContext context) {
    final filtrelenmis = _filtrelenmis;
    final Map<String, List<MenuKalemi>> gruplar = {};
    for (final k in filtrelenmis) {
      final kat = k.kategori ?? 'Diğer';
      gruplar.putIfAbsent(kat, () => []).add(k);
    }
    final kategoriler = gruplar.keys.toList()..sort();

    return Column(
      children: [
        // Arama + filtre
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              TextField(
                controller: _aramaCtrl,
                onChanged: (v) => setState(() => _aramaMetni = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Ürün veya kategori ara...',
                  prefixIcon: const Icon(Icons.search_outlined, size: 20),
                  suffixIcon: _aramaMetni.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _aramaCtrl.clear();
                            setState(() => _aramaMetni = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _MenuFiltre.values.map((f) {
                    final etiket = switch (f) {
                      _MenuFiltre.tumu   => 'Tümü',
                      _MenuFiltre.mevcut => 'Aktif',
                      _MenuFiltre.pasif  => 'Pasif',
                    };
                    final secili = _filtre == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(etiket),
                        selected: secili,
                        onSelected: (_) => setState(() => _filtre = f),
                        selectedColor: PColors.primarySoft,
                        checkmarkColor: PColors.primary,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: secili ? PColors.primary : PColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // P-27: Sıralama
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.sort_outlined, size: 14, color: PColors.muted),
                  const SizedBox(width: 4),
                  DropdownButton<_MenuSiralama>(
                    value: _siralama,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PColors.muted),
                    items: const [
                      DropdownMenuItem(value: _MenuSiralama.varsayilan, child: Text('Varsayılan Sıra')),
                      DropdownMenuItem(value: _MenuSiralama.adA,         child: Text('Ada Göre A→Z')),
                      DropdownMenuItem(value: _MenuSiralama.fiyatDusuk,  child: Text('Fiyat ↑')),
                      DropdownMenuItem(value: _MenuSiralama.fiyatYuksek, child: Text('Fiyat ↓')),
                      DropdownMenuItem(value: _MenuSiralama.spesiyel,    child: Text('Spesiyellar Önce')),
                    ],
                    onChanged: (v) { if (v != null) setState(() => _siralama = v); },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (filtrelenmis.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'Sonuç bulunamadı',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: PColors.muted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: kategoriler.length,
              itemBuilder: (ctx, i) {
                final kat = kategoriler[i];
                final liste = gruplar[kat]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        kat.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: PColors.muted,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    ...liste.map((k) => _MenuKartKalemi(kalem: k)),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MenuKartKalemi extends ConsumerWidget {
  final MenuKalemi kalem;
  const _MenuKartKalemi({required this.kalem});

  Future<void> _stokDialog(
      BuildContext context, MenuYonetimiBildiricisi notifier) async {
    final ctrl = TextEditingController(
        text: kalem.stokSayisi != null ? '${kalem.stokSayisi}' : '');
    final sonuc = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Stok — ${kalem.ad}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stok Adedi',
            hintText: '0',
            prefixIcon: Icon(Icons.inventory_outlined),
            helperText: '0 girilirse ürün pasife alınır',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (sonuc == null || sonuc.isEmpty) return;
    final yeniStok = int.tryParse(sonuc);
    if (yeniStok == null || yeniStok < 0) return;
    await notifier.stokGuncelle(kalem.id, yeniStok);
  }

  // P-10: Görsel URL dialog
  Future<void> _gorselDialog(
      BuildContext context, MenuYonetimiBildiricisi notifier) async {
    final ctrl = TextEditingController(text: kalem.gorselUrl ?? '');
    final sonuc = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${kalem.ad} — Görsel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Görsel URL',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image_outlined),
                helperText: 'Supabase Storage veya CDN URL girebilirsiniz',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          if (kalem.gorselUrl != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: PColors.danger),
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Görseli Kaldır'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (sonuc == null) return;
    await notifier.gorselGuncelle(kalem.id, sonuc.isEmpty ? null : sonuc);
  }

  Future<void> _fiyatDialog(
      BuildContext context, MenuYonetimiBildiricisi notifier) async {
    final ctrl = TextEditingController(
        text: kalem.fiyat != null ? kalem.fiyat!.toStringAsFixed(2) : '');
    final sonuc = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(kalem.ad),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Yeni Fiyat (₺)',
            prefixIcon: Icon(Icons.attach_money_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (sonuc == null || sonuc.isEmpty) return;
    final yeniFiyat = double.tryParse(sonuc.replaceAll(',', '.'));
    if (yeniFiyat == null || yeniFiyat < 0) return;
    await notifier.fiyatGuncelle(kalem.id, yeniFiyat);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(menuYonetimiProvider.notifier);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // P-10: Ürün görseli
      leading: GestureDetector(
        onTap: () => _gorselDialog(context, notifier),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kalem.gorselUrl != null && kalem.gorselUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: kalem.gorselUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, url, err) => _GorselYerTutucu(onTap: () => _gorselDialog(context, notifier)),
                )
              : _GorselYerTutucu(onTap: () => _gorselDialog(context, notifier)),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              kalem.ad,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: kalem.mevcut ? PColors.textStrong : PColors.muted,
                decoration:
                    kalem.mevcut ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          if (kalem.bugunSpesiyel)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: PColors.warning.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: PColors.warning.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Spesiyel',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: PColors.warning,
                ),
              ),
            ),
          // P-29: Allerjen/diyet etiketleri
          ..._dietEtiketleri(kalem.ad).map((etiket) => Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: PColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: PColors.success.withValues(alpha: 0.3)),
            ),
            child: Text(
              etiket,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: PColors.success),
            ),
          )),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kalem.fiyat != null)
            Text(
              '₺${kalem.fiyat!.toStringAsFixed(2)}',
              style: const TextStyle(color: PColors.muted, fontSize: 12),
            ),
          if (kalem.stokSayisi != null)
            Row(
              children: [
                Icon(
                  kalem.stokTukendi
                      ? Icons.inventory_2_outlined
                      : Icons.inventory_outlined,
                  size: 12,
                  color: kalem.stokTukendi
                      ? PColors.danger
                      : kalem.stokDusuk
                          ? PColors.warning
                          : PColors.success,
                ),
                const SizedBox(width: 3),
                Text(
                  kalem.stokTukendi
                      ? 'Stok tükendi'
                      : 'Stok: ${kalem.stokSayisi}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kalem.stokTukendi
                        ? PColors.danger
                        : kalem.stokDusuk
                            ? PColors.warning
                            : PColors.success,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stok güncelle
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, size: 18, color: PColors.muted),
            tooltip: 'Stok Güncelle',
            onPressed: () => _stokDialog(context, notifier),
          ),
          // Fiyat düzenle
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: PColors.muted),
            tooltip: 'Fiyat Düzenle',
            onPressed: () => _fiyatDialog(context, notifier),
          ),
          // Spesiyel toggle
          Tooltip(
            message: kalem.bugunSpesiyel
                ? 'Spesiyeli Kaldır'
                : 'Bugünün Spesiyeli Yap',
            child: IconButton(
              icon: Icon(
                kalem.bugunSpesiyel ? Icons.star : Icons.star_outline,
                color: kalem.bugunSpesiyel
                    ? PColors.warning
                    : PColors.muted,
              ),
              onPressed: () => notifier.spesiyelToggle(
                  kalem.id, !kalem.bugunSpesiyel),
            ),
          ),
          // Availability switch
          Switch(
            value: kalem.mevcut,
            activeThumbColor: PColors.success,
            onChanged: (v) => notifier.mevcutToggle(kalem.id, v),
          ),
        ],
      ),
    );
  }
}

// P-10: Görsel yer tutucu (kameralı + tap ile dialog aç)
class _GorselYerTutucu extends StatelessWidget {
  final VoidCallback onTap;
  const _GorselYerTutucu({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: PColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PColors.border),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined, size: 20, color: PColors.muted),
      ),
    );
  }
}

// P-29: Ürün adından diyet/allerjen etiketleri çıkar
List<String> _dietEtiketleri(String ad) {
  final kucuk = ad.toLowerCase();
  final etiketler = <String>[];
  if (kucuk.contains('vegan') || kucuk.contains('bitkisel')) etiketler.add('🌱 Vegan');
  if (kucuk.contains('vejetaryen') || kucuk.contains('vejeteryan')) etiketler.add('🥗 Vejetaryen');
  if (kucuk.contains('glutensiz') || kucuk.contains('gluten free')) etiketler.add('🌾 Glutensiz');
  if (kucuk.contains('laktozsuz') || kucuk.contains('laktoz free')) etiketler.add('🥛 Laktozsuz');
  if (kucuk.contains('organik')) etiketler.add('✅ Organik');
  if (kucuk.contains('acili') || kucuk.contains('acı')) etiketler.add('🌶️ Acılı');
  return etiketler;
}
