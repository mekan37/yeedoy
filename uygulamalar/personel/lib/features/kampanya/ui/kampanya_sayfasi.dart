import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/riverpod_uzantilari.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import '../../../core/ag/supabase_saglayicisi.dart';

class KampanyaSayfasi extends ConsumerStatefulWidget {
  const KampanyaSayfasi({super.key});

  @override
  ConsumerState<KampanyaSayfasi> createState() => _KampanyaSayfasiState();
}

const _segmentler = [
  {'key': 'all', 'label': 'Tüm Takipçiler'},
  {'key': 'recent_30d', 'label': 'Son 30 Günde Aktif'},
  {'key': 'loyal', 'label': 'Sadakat Kartı Sahipleri'},
];

class _KampanyaSayfasiState extends ConsumerState<KampanyaSayfasi> {
  final _baslikCtrl = TextEditingController();
  final _mesajCtrl = TextEditingController();
  String _segment = 'all';
  bool _gonderiyor = false;
  String? _sonuc;
  bool _hata = false;
  DateTime? _zamanlama;

  @override
  void initState() {
    super.initState();
    _baslikCtrl.addListener(() => setState(() {}));
    _mesajCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _mesajCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final baslik = _baslikCtrl.text.trim();
    final mesaj = _mesajCtrl.text.trim();
    if (baslik.isEmpty || mesaj.isEmpty) {
      setState(() { _sonuc = 'Başlık ve mesaj boş olamaz.'; _hata = true; });
      return;
    }
    final kimlik = ref.read(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return;
    setState(() { _gonderiyor = true; _sonuc = null; });
    try {
      final params = <String, dynamic>{
        'p_business_id': kimlik.isletmeId,
        'p_title': baslik,
        'p_message': mesaj,
        'p_segment': _segment,
      };
      if (_zamanlama != null) {
        params['p_scheduled_at'] = _zamanlama!.toUtc().toIso8601String();
      }
      final result = await ref.read(supabaseProvider).rpc('send_business_campaign_v1', params: params) as Map<String, dynamic>;
      if (result['ok'] == true) {
        final count = result['sent_to'] as int? ?? 0;
        final msg = _zamanlama != null
            ? '${_zamanlama!.day}.${_zamanlama!.month}.${_zamanlama!.year} için zamanlandı.'
            : '$count takipçiye bildirim gönderildi.';
        setState(() { _sonuc = msg; _hata = false; _gonderiyor = false; _zamanlama = null; });
        _baslikCtrl.clear();
        _mesajCtrl.clear();
      } else {
        final kod = result['error'] as String? ?? 'unknown';
        setState(() { _sonuc = _hataMetni(kod); _hata = true; _gonderiyor = false; });
      }
    } catch (e) {
      setState(() { _sonuc = 'Bir hata oluştu: $e'; _hata = true; _gonderiyor = false; });
    }
  }

  String _hataMetni(String kod) => switch (kod) {
    'forbidden' => 'Bu işletme için yetkiniz yok.',
    'invalid_title' => 'Başlık 1–100 karakter olmalıdır.',
    'invalid_message' => 'Mesaj 1–500 karakter olmalıdır.',
    _ => 'Hata: $kod',
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kampanya'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Gönder'), Tab(text: 'Geçmiş')],
          ),
        ),
        body: TabBarView(
          children: [
            _GonderTab(
              baslikCtrl: _baslikCtrl,
              mesajCtrl: _mesajCtrl,
              segment: _segment,
              zamanlama: _zamanlama,
              gonderiyor: _gonderiyor,
              sonuc: _sonuc,
              hata: _hata,
              onSegmentChange: (s) => setState(() => _segment = s),
              onZamanlamaChange: (z) => setState(() => _zamanlama = z),
              onGonder: _gonder,
            ),
            const _GecmisTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Gönder Tab ───────────────────────────────────────────────────────────────

class _GonderTab extends StatelessWidget {
  final TextEditingController baslikCtrl;
  final TextEditingController mesajCtrl;
  final String segment;
  final DateTime? zamanlama;
  final bool gonderiyor;
  final String? sonuc;
  final bool hata;
  final void Function(String) onSegmentChange;
  final void Function(DateTime?) onZamanlamaChange;
  final VoidCallback onGonder;

  const _GonderTab({
    required this.baslikCtrl,
    required this.mesajCtrl,
    required this.segment,
    this.zamanlama,
    required this.gonderiyor,
    this.sonuc,
    required this.hata,
    required this.onSegmentChange,
    required this.onZamanlamaChange,
    required this.onGonder,
  });

  @override
  Widget build(BuildContext context) {
    final baslik = baslikCtrl.text.trim();
    final mesaj = mesajCtrl.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Takipçilerinize anlık bildirim gönderin.', style: TextStyle(color: PColors.muted)),
          const SizedBox(height: 20),

          // Segment
          const Text('HEDEF KİTLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PColors.muted, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _segmentler.map((s) {
              final isSelected = segment == s['key'];
              return FilterChip(
                label: Text(s['label']!),
                selected: isSelected,
                onSelected: (_) => onSegmentChange(s['key']!),
                selectedColor: PColors.primary.withValues(alpha: 0.15),
                checkmarkColor: PColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? PColors.primary : PColors.text,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: baslikCtrl,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Başlık', hintText: 'Örn: Bugün özel fırsat!', prefixIcon: Icon(Icons.title_outlined)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: mesajCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Mesaj', hintText: 'Takipçilerinize iletmek istediğiniz mesajı yazın...', alignLabelWithHint: true, prefixIcon: Icon(Icons.message_outlined)),
          ),

          // P-17: Önizleme kartı
          if (baslik.isNotEmpty || mesaj.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('ÖNİZLEME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PColors.muted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _BildirimOnizleme(baslik: baslik.isEmpty ? 'Başlık' : baslik, mesaj: mesaj.isEmpty ? 'Mesaj...' : mesaj),
          ],

          const SizedBox(height: 16),
          const Text('GÖNDERİM ZAMANI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PColors.muted, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final simdi = DateTime.now();
              final tarih = await showDatePicker(context: context, initialDate: simdi, firstDate: simdi, lastDate: simdi.add(const Duration(days: 30)));
              if (tarih == null || !context.mounted) return;
              final saat = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(simdi.add(const Duration(hours: 1))));
              if (saat == null) return;
              onZamanlamaChange(DateTime(tarih.year, tarih.month, tarih.day, saat.hour, saat.minute));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(border: Border.all(color: PColors.border), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(zamanlama != null ? Icons.schedule_outlined : Icons.send_outlined, size: 18, color: zamanlama != null ? PColors.primary : PColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      zamanlama != null
                          ? '${zamanlama!.day}.${zamanlama!.month}.${zamanlama!.year} ${zamanlama!.hour.toString().padLeft(2, '0')}:${zamanlama!.minute.toString().padLeft(2, '0')}'
                          : 'Hemen gönder',
                      style: TextStyle(color: zamanlama != null ? PColors.primary : PColors.muted),
                    ),
                  ),
                  if (zamanlama != null)
                    IconButton(icon: const Icon(Icons.close, size: 16, color: PColors.muted), onPressed: () => onZamanlamaChange(null)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (sonuc != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: (hata ? PColors.danger : PColors.success).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(hata ? Icons.error_outline : Icons.check_circle_outline, color: hata ? PColors.danger : PColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(sonuc!, style: TextStyle(color: hata ? PColors.danger : PColors.success, fontWeight: FontWeight.w600))),
                ],
              ),
            ),

          FilledButton.icon(
            onPressed: gonderiyor ? null : onGonder,
            icon: gonderiyor ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_outlined),
            label: Text(gonderiyor ? 'Gönderiliyor...' : zamanlama != null ? 'Zamanla' : 'Hemen Gönder'),
          ),
        ],
      ),
    );
  }
}

// P-17: Bildirim önizleme kartı — müşteri telefonunda nasıl gözükür
class _BildirimOnizleme extends StatelessWidget {
  final String baslik;
  final String mesaj;
  const _BildirimOnizleme({required this.baslik, required this.mesaj});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: PColors.primary, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.campaign_outlined, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('Yeedoy', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              const Text('Şimdi', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(baslik, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(mesaj, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Geçmiş Tab (P-18) ────────────────────────────────────────────────────────

class _GecmisTab extends ConsumerWidget {
  const _GecmisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) {
      return const Center(child: Text('Oturum açık değil.', style: TextStyle(color: PColors.muted)));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _yukle(ref, kimlik.isletmeId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final liste = snap.data ?? [];
        if (liste.isEmpty) {
          return const Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.campaign_outlined, size: 56, color: PColors.muted),
              SizedBox(height: 12),
              Text('Henüz gönderilmiş kampanya yok.', style: TextStyle(color: PColors.muted)),
            ],
          ));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: liste.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _KampanyaKarti(kampanya: liste[i]),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _yukle(WidgetRef ref, String isletmeId) async {
    try {
      final rows = await ref.read(supabaseProvider).rpc('list_push_campaigns_v1', params: {
        'p_business_id': isletmeId,
        'p_limit': 20,
        'p_offset': 0,
      }) as Map<String, dynamic>;
      final items = rows['items'] as List<dynamic>? ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (_) { return []; }
  }
}

class _KampanyaKarti extends StatelessWidget {
  final Map<String, dynamic> kampanya;
  const _KampanyaKarti({required this.kampanya});

  @override
  Widget build(BuildContext context) {
    final gonderildi = kampanya['sent_at'] != null;
    final sentCount = kampanya['sent_count'] as int? ?? 0;
    final openedCount = kampanya['opened_count'] as int? ?? 0;
    final openRate = sentCount > 0 ? (openedCount / sentCount * 100).round() : 0;
    final tarih = gonderildi
        ? DateTime.tryParse(kampanya['sent_at'] as String? ?? '')?.toLocal()
        : DateTime.tryParse(kampanya['scheduled_at'] as String? ?? '')?.toLocal();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(kampanya['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w900, color: PColors.textStrong, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (gonderildi ? PColors.success : PColors.warning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    gonderildi ? 'Gönderildi' : 'Zamanlandı',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: gonderildi ? PColors.success : PColors.warning),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(kampanya['body'] as String? ?? '', style: const TextStyle(color: PColors.muted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                if (tarih != null)
                  Text('${tarih.day}.${tarih.month}.${tarih.year}', style: const TextStyle(fontSize: 11, color: PColors.muted)),
                const Spacer(),
                if (gonderildi) ...[
                  const Icon(Icons.send_outlined, size: 12, color: PColors.muted),
                  const SizedBox(width: 4),
                  Text('$sentCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PColors.muted)),
                  const SizedBox(width: 12),
                  const Icon(Icons.open_in_browser_outlined, size: 12, color: PColors.muted),
                  const SizedBox(width: 4),
                  Text('%$openRate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: openRate > 20 ? PColors.success : PColors.muted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
