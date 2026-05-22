import 'package:flutter/material.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../masa_siparisleri/domain/masa_siparisi_modeli.dart';

class KdsSiparisKarti extends StatelessWidget {
  final MasaSiparisi siparis;
  final Color durumRengi;
  final String aksiyonEtiketi;
  final VoidCallback onAksiyon;

  const KdsSiparisKarti({
    super.key,
    required this.siparis,
    required this.durumRengi,
    required this.aksiyonEtiketi,
    required this.onAksiyon,
  });

  void _yaziciGonder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yazıcıya Gönder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: PColors.textStrong)),
            const SizedBox(height: 8),
            Text('Masa ${siparis.masaNo} — ${siparis.kalemler.length} kalem', style: const TextStyle(color: PColors.muted)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Masa ${siparis.masaNo} fişi yazıcıya gönderildi'), backgroundColor: PColors.success),
                );
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('Mutfak Fişi Yazdır'),
            ),
            const SizedBox(height: 8),
            const Text('* ESC/POS yazıcı bağlantısı için Yeedoy Partner uygulamasını kullanın.', style: TextStyle(fontSize: 11, color: PColors.muted)),
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
    final uzun = dakika >= 10;

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
                  decoration: BoxDecoration(color: durumRengi.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                  child: Text('Masa ${siparis.masaNo}', style: TextStyle(color: durumRengi, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
                const Spacer(),
                Text(
                  dakika == 0 ? 'Az önce' : '$dakika dk önce',
                  style: textTheme.bodySmall?.copyWith(color: uzun ? PColors.danger : PColors.muted, fontWeight: uzun ? FontWeight.w700 : FontWeight.normal),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...siparis.kalemler.map((k) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${k.adet}×', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: PColors.textStrong)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(k.urunAdi, style: textTheme.bodyMedium),
                        if (k.not != null && k.not!.isNotEmpty)
                          Text(k.not!, style: textTheme.bodySmall?.copyWith(color: PColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            if (siparis.not != null && siparis.not!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: PColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.notes_outlined, size: 14, color: PColors.muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(siparis.not!, style: textTheme.bodySmall?.copyWith(color: PColors.muted))),
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
                    style: FilledButton.styleFrom(backgroundColor: durumRengi, foregroundColor: Colors.white),
                    child: Text(aksiyonEtiketi),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _yaziciGonder(context),
                  style: OutlinedButton.styleFrom(foregroundColor: PColors.muted, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(40, 40)),
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

class KdsSayiBadge extends StatelessWidget {
  final int sayi;
  final Color renk;
  const KdsSayiBadge(this.sayi, this.renk, {super.key});

  @override
  Widget build(BuildContext context) {
    if (sayi == 0) return const SizedBox.shrink();
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
      child: Center(child: Text('$sayi', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))),
    );
  }
}

class KdsSonYenilenme extends StatelessWidget {
  final DateTime zaman;
  const KdsSonYenilenme({super.key, required this.zaman});

  @override
  Widget build(BuildContext context) {
    final gecen = DateTime.now().difference(zaman);
    final etiket = gecen.inSeconds < 60 ? 'Az önce' : '${gecen.inMinutes} dk';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: PColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(etiket, style: const TextStyle(fontSize: 11, color: PColors.muted)),
        ],
      ),
    );
  }
}
