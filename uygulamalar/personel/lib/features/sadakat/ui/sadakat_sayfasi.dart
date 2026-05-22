import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hata_esleyici.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../shared/ui/p_iskelet.dart';
import '../domain/sadakat_bildiricisi.dart';
import '../domain/sadakat_modeli.dart';

// Tier badge widget
class _TierBadge extends StatelessWidget {
  final LoyaltyTier tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final color = Color(tier.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        tier.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class SadakatSayfasi extends ConsumerWidget {
  const SadakatSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sadakatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sadakat Kartları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(sadakatProvider.notifier).yenile(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const PersonelListIskeleti(satirSayisi: 4),
        error: (e, _) => Center(child: Text(HataEsleyici.mesaj(e), style: const TextStyle(color: Colors.red))),
        data: (kartlar) => kartlar.isEmpty
            ? const _BosKartMesaji()
            : _KartListesi(kartlar: kartlar),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _puanEkleBottomSheet(context, ref),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Puan Ekle'),
        backgroundColor: PColors.primary,
        foregroundColor: PColors.onPrimary,
      ),
    );
  }

  Future<void> _puanEkleBottomSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _PuanEkleSheet(),
    );
  }
}

class _PuanEkleSheet extends ConsumerStatefulWidget {
  const _PuanEkleSheet();

  @override
  ConsumerState<_PuanEkleSheet> createState() => _PuanEkleSheetState();
}

class _PuanEkleSheetState extends ConsumerState<_PuanEkleSheet> {
  final _kullaniciIdKontrol = TextEditingController();
  final _puanKontrol = TextEditingController(text: '10');
  final _formKey = GlobalKey<FormState>();
  bool _yukleniyor = false;

  @override
  void dispose() {
    _kullaniciIdKontrol.dispose();
    _puanKontrol.dispose();
    super.dispose();
  }

  Future<void> _ekle() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final kullaniciId = _kullaniciIdKontrol.text.trim();
    final puan = int.tryParse(_puanKontrol.text.trim()) ?? 10;

    setState(() => _yukleniyor = true);

    final hata = await ref
        .read(sadakatProvider.notifier)
        .puanEkle(kullaniciId: kullaniciId, puan: puan);

    if (!mounted) return;
    setState(() => _yukleniyor = false);

    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hata),
          backgroundColor: PColors.danger,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$puan puan başarıyla eklendi.'),
        backgroundColor: PColors.success,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sürükleme tutacağı
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
            Text(
              'Puan Ekle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: PColors.textStrong,
                  ),
            ),
            const SizedBox(height: 20),

            // QR ile bul
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner_outlined),
              label: const Text('QR ile Müşteri Bul'),
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/qr-tarayici');
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'veya manuel girin',
                      style: TextStyle(color: PColors.muted, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // P-36: Kullanıcı ID — UUID otomatik kısa çizgi ekleme
            TextFormField(
              controller: _kullaniciIdKontrol,
              maxLength: 36,
              inputFormatters: [_UuidGirisFormati()],
              decoration: const InputDecoration(
                labelText: 'Kullanıcı ID (UUID)',
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                prefixIcon: Icon(Icons.person_outline),
                counterText: '',
                helperText: 'Yeedoy profil UUID\'si',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Kullanıcı ID boş olamaz';
                }
                final uuid = v.trim();
                final uuidRegex = RegExp(
                  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                  caseSensitive: false,
                );
                if (!uuidRegex.hasMatch(uuid)) {
                  return 'Geçersiz UUID formatı (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Puan miktarı
            TextFormField(
              controller: _puanKontrol,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Puan Miktarı',
                hintText: '10',
                prefixIcon: Icon(Icons.stars_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Puan miktarı boş olamaz';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Geçerli bir sayı girin';
                if (n > 1000) return 'En fazla 1000 puan eklenebilir';
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _yukleniyor ? null : _ekle,
              child: _yukleniyor
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PColors.onPrimary,
                      ),
                    )
                  : const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BosKartMesaji extends StatelessWidget {
  const _BosKartMesaji();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard_outlined,
              size: 56, color: PColors.muted),
          const SizedBox(height: 12),
          Text(
            'Henüz sadakat kartı yok',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: PColors.muted),
          ),
          const SizedBox(height: 8),
          const Text(
            'Müşteriler Yeedoy uygulaması üzerinden kart oluşturabilir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: PColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _KartListesi extends StatelessWidget {
  final List<LoyaltyKart> kartlar;
  const _KartListesi({required this.kartlar});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: kartlar.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _LoyaltyKartKarti(kart: kartlar[i]),
    );
  }
}

class _LoyaltyKartKarti extends ConsumerWidget {
  final LoyaltyKart kart;
  const _LoyaltyKartKarti({required this.kart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oran = kart.ilerleme.clamp(0.0, 1.0);
    final renkler = kart.tamamlandi ? PColors.success : PColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              kart.kullaniciAdi ?? 'Misafir',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: PColors.textStrong,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _TierBadge(tier: kart.tier),
                        ],
                      ),
                      if (kart.telefon != null)
                        Text(
                          kart.telefon!,
                          style: const TextStyle(
                              color: PColors.muted, fontSize: 12),
                        ),
                      Text(
                        '${kart.toplamStamp} toplam stamp',
                        style: const TextStyle(color: PColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (kart.tamamlandi)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.celebration,
                            size: 14, color: PColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Tamamlandı!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: PColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Stamp görsel
            _StampGrid(
              mevcut: kart.stampSayisi,
              hedef: kart.hedef,
              renk: renkler,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: oran,
                    backgroundColor: PColors.border,
                    color: renkler,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${kart.stampSayisi}/${kart.hedef}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: renkler,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Stamp Ekle'),
                onPressed: kart.tamamlandi
                    ? null
                    : () => _stampEkleDialog(context, ref, kart),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _stampEkleDialog(
      BuildContext context, WidgetRef ref, LoyaltyKart kart) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stamp Ekle'),
        content: Text(
          '${kart.kullaniciAdi ?? "Müşteri"} için 1 stamp eklenecek.\n'
          'Mevcut: ${kart.stampSayisi}/${kart.hedef}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (onay != true || !context.mounted) return;

    final hata =
        await ref.read(sadakatProvider.notifier).stampEkle(kart.id);
    if (hata != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $hata')),
      );
    }
  }
}

class _StampGrid extends StatelessWidget {
  final int mevcut;
  final int hedef;
  final Color renk;

  const _StampGrid({
    required this.mevcut,
    required this.hedef,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    final goster = hedef.clamp(1, 20);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(goster, (i) {
        final dolu = i < mevcut;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dolu ? renk : Colors.transparent,
            border: Border.all(
              color: dolu ? renk : PColors.border,
              width: 1.5,
            ),
          ),
          child: dolu
              ? const Icon(Icons.star, size: 14, color: Colors.white)
              : null,
        );
      }),
    );
  }
}

// P-36: UUID girerken otomatik kısa çizgi ekleyen formatter
class _UuidGirisFormati extends TextInputFormatter {
  static const _positions = [8, 13, 18, 23];

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll('-', '').toLowerCase();
    if (raw.length > 32) return oldValue;

    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (_positions.contains(buf.length)) buf.write('-');
      buf.write(raw[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
