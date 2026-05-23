import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../../../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';
import '../../../features/menuler/domain/menu_modelleri.dart';
import '../domain/masa_siparisi_modeli.dart';
import '../domain/masa_siparisi_sepet_bildiricisi.dart';
import '../domain/masa_siparisi_gonder_bildiricisi.dart';
import 'siparis_basarili_sayfasi.dart';

class MasaSiparisiSayfasi extends ConsumerStatefulWidget {
  const MasaSiparisiSayfasi({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.menuItems,
  });

  final String businessId;
  final String businessName;
  final List<MenuItem> menuItems;

  @override
  ConsumerState<MasaSiparisiSayfasi> createState() =>
      _MasaSiparisiSayfasiState();
}

class _MasaSiparisiSayfasiState extends ConsumerState<MasaSiparisiSayfasi> {
  final _masaNoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Sepeti her açılışta temizle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(masaSiparisiSepetProvider.notifier).temizle();
      ref.read(masaSiparisiGonderProvider.notifier).sifirla();
    });
  }

  @override
  void dispose() {
    _masaNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sepet = ref.watch(masaSiparisiSepetProvider);
    final gonderState = ref.watch(masaSiparisiGonderProvider);
    final toplamAdet =
        ref.watch(masaSiparisiSepetProvider.notifier).toplamAdet;
    final toplamCents =
        ref.watch(masaSiparisiSepetProvider.notifier).toplamFiyatCents;

    final isGonderiliyor = gonderState.isLoading;

    return AppScaffold(
      appBar: AppAppBar(title: Text('Sipariş Ver — ${widget.businessName}')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _MasaNoGirdisi(controller: _masaNoController),
                  const SizedBox(height: 20),
                  const _BolumBasligi(title: 'Menü'),
                  const SizedBox(height: 8),
                  ...widget.menuItems
                      .where((item) => item.isAvailable)
                      .map(
                        (item) => RepaintBoundary(
                          child: _MenuKalemSatiri(
                            item: item,
                            adet: sepet
                                    .firstWhere(
                                      (k) => k.menuItemId == item.id,
                                      orElse: () => MasaSiparisKalemi(
                                        menuItemId: '',
                                        name: '',
                                        priceCents: 0,
                                        adet: 0,
                                      ),
                                    )
                                    .adet,
                            onEkle: () {
                              HapticFeedback.selectionClick();
                              final priceCents =
                                  ((item.price ?? 0) * 100).round();
                              ref
                                  .read(masaSiparisiSepetProvider.notifier)
                                  .ekle(
                                    MasaSiparisKalemi(
                                      menuItemId: item.id,
                                      name: item.name,
                                      priceCents: priceCents,
                                    ),
                                  );
                            },
                            onCikar: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(masaSiparisiSepetProvider.notifier)
                                  .cikar(item.id);
                            },
                          ),
                        ),
                      ),
                  if (widget.menuItems.isEmpty)
                    const AppEmptyState(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Menü bulunamadı',
                      description: 'Bu işletmenin menüsü henüz yüklenmedi.',
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            _SepetAltCubugu(
              toplamAdet: toplamAdet,
              toplamCents: toplamCents,
              isGonderiliyor: isGonderiliyor,
              onSiparisVer: toplamAdet == 0 ? null : () => _siparisVer(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _siparisVer(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final masaNo = _masaNoController.text.trim();
    final sepet = ref.read(masaSiparisiSepetProvider);

    final onaylandimi = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SiparisOnayDiyalogu(
        businessName: widget.businessName,
        masaNo: masaNo,
        sepet: sepet,
      ),
    );

    if (onaylandimi != true || !context.mounted) return;

    final sonuc = await ref
        .read(masaSiparisiGonderProvider.notifier)
        .gonder(
          businessId: widget.businessId,
          tableNo: masaNo,
          kalemler: sepet,
        );

    if (!context.mounted) return;

    if (sonuc.basarili) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SiparisBasariliSayfasi(
            businessName: widget.businessName,
            masaNo: masaNo,
            orderId: sonuc.orderId ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş gönderilemedi: ${sonuc.hata}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _MasaNoGirdisi extends StatelessWidget {
  const _MasaNoGirdisi({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masa Numarası',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              hintText: 'Masanızın numarasını giriniz (1-99)',
              prefixIcon: Icon(Icons.table_restaurant_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen masa numarasını giriniz';
              }
              final n = int.tryParse(value.trim());
              if (n == null || n < 1 || n > 99) {
                return 'Geçerli bir masa numarası giriniz (1-99)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  const _BolumBasligi({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 17,
        color: AppColors.textStrong,
      ),
    );
  }
}

class _MenuKalemSatiri extends StatelessWidget {
  const _MenuKalemSatiri({
    required this.item,
    required this.adet,
    required this.onEkle,
    required this.onCikar,
  });

  final MenuItem item;
  final int adet;
  final VoidCallback onEkle;
  final VoidCallback onCikar;

  @override
  Widget build(BuildContext context) {
    final priceCents = ((item.price ?? 0) * 100).round();
    final priceText = priceCents > 0
        ? '${(priceCents / 100).toStringAsFixed(0)} ₺'
        : 'Fiyat yok';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textStrong,
                    ),
                  ),
                  if ((item.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _AdetKontrol(adet: adet, onEkle: onEkle, onCikar: onCikar),
          ],
        ),
      ),
    );
  }
}

class _AdetKontrol extends StatelessWidget {
  const _AdetKontrol({
    required this.adet,
    required this.onEkle,
    required this.onCikar,
  });

  final int adet;
  final VoidCallback onEkle;
  final VoidCallback onCikar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (adet > 0) ...[
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton.outlined(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onPressed: onCikar,
              icon: const Icon(Icons.remove),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$adet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton.filled(
            padding: EdgeInsets.zero,
            iconSize: 18,
            onPressed: onEkle,
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _SepetAltCubugu extends StatelessWidget {
  const _SepetAltCubugu({
    required this.toplamAdet,
    required this.toplamCents,
    required this.isGonderiliyor,
    required this.onSiparisVer,
  });

  final int toplamAdet;
  final int toplamCents;
  final bool isGonderiliyor;
  final VoidCallback? onSiparisVer;

  @override
  Widget build(BuildContext context) {
    final priceText = '${(toplamCents / 100).toStringAsFixed(0)} ₺';
    final sepetLabel = toplamAdet == 0
        ? 'Sepet boş'
        : 'Sepet: $toplamAdet ürün · $priceText';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: isGonderiliyor ? null : onSiparisVer,
            icon: isGonderiliyor
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              isGonderiliyor ? 'Gönderiliyor...' : sepetLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _SiparisOnayDiyalogu extends StatelessWidget {
  const _SiparisOnayDiyalogu({
    required this.businessName,
    required this.masaNo,
    required this.sepet,
  });

  final String businessName;
  final String masaNo;
  final List<MasaSiparisKalemi> sepet;

  @override
  Widget build(BuildContext context) {
    final toplamCents = sepet.fold<int>(0, (s, k) => s + k.priceCents * k.adet);
    final toplamText = '${(toplamCents / 100).toStringAsFixed(0)} ₺';

    return AlertDialog(
      title: const Text(
        'Siparişi Onayla',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            businessName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Masa: $masaNo',
            style: const TextStyle(color: AppColors.muted),
          ),
          const Divider(height: 20),
          ...sepet.map(
            (k) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${k.adet}x ${k.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${((k.priceCents * k.adet) / 100).toStringAsFixed(0)} ₺',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Toplam',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Text(
                toplamText,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Siparişi Gönder'),
        ),
      ],
    );
  }
}
