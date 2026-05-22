import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../uygulama/tema/renkler.dart';
import '../domain/dashboard_istatistik_saglayicisi.dart';

// P-16: Personel performans kartı
class PersonelPerformansKarti extends ConsumerWidget {
  const PersonelPerformansKarti({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personelPerformansProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bugün işlenen siparişler', style: TextStyle(fontWeight: FontWeight.w800, color: PColors.textStrong, fontSize: 13)),
            const SizedBox(height: 10),
            state.when(
              loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => const Text('Yüklenemedi', style: TextStyle(color: PColors.muted, fontSize: 12)),
              data: (liste) {
                if (liste.isEmpty) {
                  return const Text('Henüz veri yok', style: TextStyle(color: PColors.muted, fontSize: 13));
                }
                return Column(
                  children: liste.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: const BoxDecoration(color: PColors.primarySoft, shape: BoxShape.circle),
                            child: Center(child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: PColors.primary))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Personel ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: PColors.textStrong, fontSize: 13))),
                          Text('${p.siparisSayisi} sipariş', style: const TextStyle(fontSize: 12, color: PColors.muted)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: PColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text('${p.tamamlanan} ✓', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PColors.success)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// P-14: Saatlik sipariş grafik kartı
class SaatlikGrafikKarti extends ConsumerWidget {
  const SaatlikGrafikKarti({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saatlikVeriProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saatlik Sipariş Yoğunluğu',
              style: TextStyle(fontWeight: FontWeight.w800, color: PColors.textStrong, fontSize: 13),
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => const SizedBox(height: 60, child: Center(child: Text('Yüklenemedi', style: TextStyle(color: PColors.muted)))),
              data: (veriler) {
                if (veriler.isEmpty) {
                  return const SizedBox(height: 60, child: Center(child: Text('Henüz sipariş yok', style: TextStyle(color: PColors.muted))));
                }
                final maksimum = veriler.fold(0, (m, v) => v.siparisSayisi > m ? v.siparisSayisi : m);
                final simdi = DateTime.now().hour;
                return SizedBox(
                  height: 70,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: veriler.map((v) {
                      final oran = maksimum > 0 ? v.siparisSayisi / maksimum : 0.0;
                      final simdiki = v.saat == simdi;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (simdiki && v.siparisSayisi > 0)
                                Text('${v.siparisSayisi}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: PColors.primary)),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                height: math.max(4, oran * 52),
                                decoration: BoxDecoration(
                                  color: simdiki ? PColors.primary : PColors.primary.withValues(alpha: 0.4),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (v.saat % 3 == 0)
                                Text('${v.saat}', style: const TextStyle(fontSize: 8, color: PColors.muted)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Haftalık sipariş/gelir grafik kartı
class HaftalikGrafikKarti extends ConsumerStatefulWidget {
  const HaftalikGrafikKarti({super.key});

  @override
  ConsumerState<HaftalikGrafikKarti> createState() => _HaftalikGrafikKartiState();
}

class _HaftalikGrafikKartiState extends ConsumerState<HaftalikGrafikKarti> {
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
                    style: const TextStyle(fontWeight: FontWeight.w800, color: PColors.textStrong, fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _gelirModu = !_gelirModu),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: PColors.primarySoft, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _gelirModu ? '₺' : '#',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: PColors.primary, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            state.when(
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => const SizedBox(height: 100, child: Center(child: Text('Grafik yüklenemedi', style: TextStyle(color: PColors.muted, fontSize: 12)))),
              data: (veriler) => veriler.isEmpty
                  ? const SizedBox(height: 100, child: Center(child: Text('Veri yok', style: TextStyle(color: PColors.muted))))
                  : BarGrafik(veriler: veriler, gelirModu: _gelirModu),
            ),
          ],
        ),
      ),
    );
  }
}

class BarGrafik extends StatelessWidget {
  final List<GunlukVeri> veriler;
  final bool gelirModu;
  static const double _yukseklik = 120;
  static const double _etiketGenislik = 32;
  static const List<String> _gunKisaltma = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  const BarGrafik({super.key, required this.veriler, required this.gelirModu});

  static double _niceMax(double val) {
    if (val <= 0) return 10;
    final adim = val <= 10 ? 2.0 : val <= 50 ? 10.0 : val <= 200 ? 50.0 : 100.0;
    return (val / adim).ceil() * adim;
  }

  static String _yEtiket(double val, bool gelir) {
    if (gelir) {
      return val >= 1000 ? '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}K' : val.toStringAsFixed(0);
    }
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final degerler = veriler.map((v) => gelirModu ? v.gelir : v.siparisSayisi.toDouble()).toList();
    final rawMax = degerler.fold(0.0, math.max);
    final yMax = _niceMax(rawMax);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _etiketGenislik,
          height: _yukseklik + 26,
          child: Stack(
            children: [
              Positioned(top: 0, right: 2, child: Text(_yEtiket(yMax, gelirModu), style: const TextStyle(fontSize: 9, color: PColors.muted))),
              Positioned(top: _yukseklik / 2 - 6, right: 2, child: Text(_yEtiket(yMax / 2, gelirModu), style: const TextStyle(fontSize: 9, color: PColors.muted))),
              const Positioned(top: _yukseklik - 6, right: 2, child: Text('0', style: TextStyle(fontSize: 9, color: PColors.muted))),
            ],
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: SizedBox(
            height: _yukseklik + 26,
            child: Stack(
              children: [
                Positioned(top: 0, left: 0, right: 0, child: Divider(height: 1, color: PColors.muted.withValues(alpha: 0.2))),
                Positioned(top: _yukseklik / 2, left: 0, right: 0, child: Divider(height: 1, color: PColors.muted.withValues(alpha: 0.15))),
                Positioned(top: _yukseklik, left: 0, right: 0, child: Divider(height: 1, color: PColors.muted.withValues(alpha: 0.2))),
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
                                Text(gelirModu ? '₺${deger.toStringAsFixed(0)}' : '$deger', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: PColors.primary)),
                              const SizedBox(height: 2),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                height: math.max(4, oran * _yukseklik),
                                decoration: BoxDecoration(
                                  color: bugun ? PColors.primary : PColors.primary.withValues(alpha: 0.35),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(gunAdi, style: TextStyle(fontSize: 10, fontWeight: bugun ? FontWeight.w900 : FontWeight.normal, color: bugun ? PColors.primary : PColors.muted)),
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
