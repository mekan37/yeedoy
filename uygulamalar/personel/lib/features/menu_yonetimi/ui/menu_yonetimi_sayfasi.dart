import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata_esleyici.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../shared/ui/p_iskelet.dart';
import '../domain/menu_kalemi_modeli.dart';
import '../domain/menu_yonetimi_bildiricisi.dart';
import 'menu_karti_kalemi.dart';

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
                    ...liste.map((k) => MenuKartiKalemi(kalem: k)),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
