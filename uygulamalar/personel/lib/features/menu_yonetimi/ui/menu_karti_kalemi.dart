import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../uygulama/tema/renkler.dart';
import '../domain/menu_kalemi_modeli.dart';
import '../domain/menu_yonetimi_bildiricisi.dart';

class MenuKartiKalemi extends ConsumerWidget {
  final MenuKalemi kalem;
  const MenuKartiKalemi({super.key, required this.kalem});

  Future<void> _stokDialog(BuildContext context, MenuYonetimiBildiricisi notifier) async {
    final ctrl = TextEditingController(text: kalem.stokSayisi != null ? '${kalem.stokSayisi}' : '');
    final sonuc = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Stok — ${kalem.ad}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stok Adedi', hintText: '0', prefixIcon: Icon(Icons.inventory_outlined), helperText: '0 girilirse ürün pasife alınır'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    ctrl.dispose();
    if (sonuc == null || sonuc.isEmpty) return;
    final yeniStok = int.tryParse(sonuc);
    if (yeniStok == null || yeniStok < 0) return;
    await notifier.stokGuncelle(kalem.id, yeniStok);
  }

  Future<void> _gorselDialog(BuildContext context, MenuYonetimiBildiricisi notifier) async {
    final ctrl = TextEditingController(text: kalem.gorselUrl ?? '');
    final sonuc = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${kalem.ad} — Görsel'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'Görsel URL', hintText: 'https://...', prefixIcon: Icon(Icons.image_outlined), helperText: 'Supabase Storage veya CDN URL girebilirsiniz'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          if (kalem.gorselUrl != null)
            TextButton(style: TextButton.styleFrom(foregroundColor: PColors.danger), onPressed: () => Navigator.pop(context, ''), child: const Text('Görseli Kaldır')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    ctrl.dispose();
    if (sonuc == null) return;
    await notifier.gorselGuncelle(kalem.id, sonuc.isEmpty ? null : sonuc);
  }

  Future<void> _fiyatDialog(BuildContext context, MenuYonetimiBildiricisi notifier) async {
    final ctrl = TextEditingController(text: kalem.fiyat != null ? kalem.fiyat!.toStringAsFixed(2) : '');
    final sonuc = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(kalem.ad),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Yeni Fiyat (₺)', prefixIcon: Icon(Icons.attach_money_outlined)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Kaydet')),
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
      leading: GestureDetector(
        onTap: () => _gorselDialog(context, notifier),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kalem.gorselUrl != null && kalem.gorselUrl!.isNotEmpty
              ? CachedNetworkImage(imageUrl: kalem.gorselUrl!, width: 52, height: 52, fit: BoxFit.cover, errorWidget: (ctx, url, err) => _GorselYerTutucu(onTap: () => _gorselDialog(context, notifier)))
              : _GorselYerTutucu(onTap: () => _gorselDialog(context, notifier)),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(kalem.ad, style: TextStyle(fontWeight: FontWeight.w700, color: kalem.mevcut ? PColors.textStrong : PColors.muted, decoration: kalem.mevcut ? null : TextDecoration.lineThrough)),
          ),
          if (kalem.bugunSpesiyel)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: PColors.warning.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6), border: Border.all(color: PColors.warning.withValues(alpha: 0.4))),
              child: const Text('Spesiyel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: PColors.warning)),
            ),
          ...dietEtiketleri(kalem.ad).map((etiket) => Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: PColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5), border: Border.all(color: PColors.success.withValues(alpha: 0.3))),
            child: Text(etiket, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: PColors.success)),
          )),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kalem.fiyat != null)
            Text('₺${kalem.fiyat!.toStringAsFixed(2)}', style: const TextStyle(color: PColors.muted, fontSize: 12)),
          if (kalem.stokSayisi != null)
            Row(
              children: [
                Icon(kalem.stokTukendi ? Icons.inventory_2_outlined : Icons.inventory_outlined, size: 12, color: kalem.stokTukendi ? PColors.danger : kalem.stokDusuk ? PColors.warning : PColors.success),
                const SizedBox(width: 3),
                Text(kalem.stokTukendi ? 'Stok tükendi' : 'Stok: ${kalem.stokSayisi}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kalem.stokTukendi ? PColors.danger : kalem.stokDusuk ? PColors.warning : PColors.success)),
              ],
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.inventory_2_outlined, size: 18, color: PColors.muted), tooltip: 'Stok Güncelle', onPressed: () => _stokDialog(context, notifier)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: PColors.muted), tooltip: 'Fiyat Düzenle', onPressed: () => _fiyatDialog(context, notifier)),
          Tooltip(
            message: kalem.bugunSpesiyel ? 'Spesiyeli Kaldır' : 'Bugünün Spesiyeli Yap',
            child: IconButton(
              icon: Icon(kalem.bugunSpesiyel ? Icons.star : Icons.star_outline, color: kalem.bugunSpesiyel ? PColors.warning : PColors.muted),
              onPressed: () => notifier.spesiyelToggle(kalem.id, !kalem.bugunSpesiyel),
            ),
          ),
          Switch(value: kalem.mevcut, activeThumbColor: PColors.success, onChanged: (v) => notifier.mevcutToggle(kalem.id, v)),
        ],
      ),
    );
  }
}

class _GorselYerTutucu extends StatelessWidget {
  final VoidCallback onTap;
  const _GorselYerTutucu({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: PColors.surfaceAlt, borderRadius: BorderRadius.circular(8), border: Border.all(color: PColors.border)),
        child: const Icon(Icons.add_photo_alternate_outlined, size: 20, color: PColors.muted),
      ),
    );
  }
}

// P-29: Ürün adından diyet/allerjen etiketleri çıkar
List<String> dietEtiketleri(String ad) {
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
