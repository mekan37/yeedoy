import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata_esleyici.dart';
import '../../../uygulama/tema/renkler.dart';
import '../domain/yorum_modeli.dart';
import '../domain/yorumlar_bildiricisi.dart';

class YorumlarSayfasi extends ConsumerWidget {
  const YorumlarSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(yorumlarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yorumlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(yorumlarProvider.notifier).yenile(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(HataEsleyici.mesaj(e), style: const TextStyle(color: Colors.red))),
        data: (yorumlar) => yorumlar.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reviews_outlined,
                      size: 56,
                      color: PColors.muted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Henüz onaylı yorum yok',
                      style: TextStyle(color: PColors.muted),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: yorumlar.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _YorumKarti(yorum: yorumlar[i]),
              ),
      ),
    );
  }
}

class _YorumKarti extends ConsumerStatefulWidget {
  final IsletmeYorum yorum;
  const _YorumKarti({required this.yorum});

  @override
  ConsumerState<_YorumKarti> createState() => _YorumKartiState();
}

class _YorumKartiState extends ConsumerState<_YorumKarti> {
  bool _yanitFormAcik = false;
  final _ctrl = TextEditingController();
  bool _gonderiyor = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final metin = _ctrl.text.trim();
    if (metin.isEmpty) return;
    setState(() => _gonderiyor = true);
    await ref
        .read(yorumlarProvider.notifier)
        .yanitGonder(widget.yorum.id, metin);
    if (mounted) {
      setState(() {
        _gonderiyor = false;
        _yanitFormAcik = false;
      });
      _ctrl.clear();
    }
  }

  Future<void> _sil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yanıtı Sil'),
        content: const Text('Bu yanıt kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: PColors.danger),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay == true) {
      await ref.read(yorumlarProvider.notifier).yanitSil(widget.yorum.id);
    }
  }

  Future<void> _sikayet() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yorumu Şikayet Et'),
        content: const Text(
          'Bu yorumu uygunsuz olarak bildirmek istiyor musunuz? Ekibimiz inceleyecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: PColors.warning),
            child: const Text('Bildir'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    try {
      await ref.read(yorumlarProvider.notifier).sikayet(widget.yorum.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şikayetiniz iletildi. Teşekkürler.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hata oluştu')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yorum = widget.yorum;
    final textTheme = Theme.of(context).textTheme;
    final fark = DateTime.now().difference(yorum.olusturuldu);
    final sure = fark.inDays > 0
        ? '${fark.inDays} gün önce'
        : fark.inHours > 0
        ? '${fark.inHours} saat önce'
        : '${fark.inMinutes} dk önce';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _YildizRow(puan: yorum.puan),
                const SizedBox(width: 6),
                if (yorum.moderasyonDurum == ModerasayonDurum.bekliyor)
                  const _ModerasayonBadge(
                    etiket: 'İnceleniyor',
                    renk: PColors.warning,
                    ikon: Icons.hourglass_top_outlined,
                  )
                else if (yorum.moderasyonDurum == ModerasayonDurum.kaldirildi)
                  const _ModerasayonBadge(
                    etiket: 'Kaldırıldı',
                    renk: PColors.success,
                    ikon: Icons.check_circle_outline,
                  )
                else if (yorum.sikayet)
                  const _ModerasayonBadge(
                    etiket: 'Şikayet Edildi',
                    renk: PColors.muted,
                    ikon: Icons.flag_outlined,
                  ),
                const Spacer(),
                Text(
                  sure,
                  style: textTheme.bodySmall?.copyWith(color: PColors.muted),
                ),
                if (yorum.moderasyonDurum == ModerasayonDurum.temiz &&
                    !yorum.sikayet)
                  IconButton(
                    icon: const Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: PColors.muted,
                    ),
                    tooltip: 'Şikayet Et',
                    onPressed: _sikayet,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
            if (yorum.yazarAdi != null) ...[
              const SizedBox(height: 4),
              Text(
                yorum.yazarAdi!,
                style: textTheme.bodySmall?.copyWith(
                  color: PColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (yorum.icerik != null && yorum.icerik!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(yorum.icerik!, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 10),
            if (yorum.sahipYaniti != null && yorum.sahipYaniti!.isNotEmpty)
              _SahipYanitiBlok(yanit: yorum.sahipYaniti!, onSil: _sil)
            else if (!_yanitFormAcik)
              TextButton.icon(
                icon: const Icon(Icons.reply_outlined, size: 18),
                label: const Text('Yanıt Yaz'),
                onPressed: () => setState(() => _yanitFormAcik = true),
              )
            else
              _YanitForm(
                ctrl: _ctrl,
                gonderiyor: _gonderiyor,
                onGonder: _gonder,
                onIptal: () => setState(() {
                  _yanitFormAcik = false;
                  _ctrl.clear();
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _SahipYanitiBlok extends StatelessWidget {
  final String yanit;
  final VoidCallback onSil;

  const _SahipYanitiBlok({required this.yanit, required this.onSil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store_outlined,
                size: 14,
                color: PColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Sahibin Yanıtı',
                style: TextStyle(
                  color: PColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSil,
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: PColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            yanit,
            style: const TextStyle(color: PColors.text, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _YanitForm extends StatelessWidget {
  final TextEditingController ctrl;
  final bool gonderiyor;
  final VoidCallback onGonder;
  final VoidCallback onIptal;

  const _YanitForm({
    required this.ctrl,
    required this.gonderiyor,
    required this.onGonder,
    required this.onIptal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText: 'Yanıtınızı yazın...',
            hintStyle: TextStyle(color: PColors.muted),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(onPressed: onIptal, child: const Text('İptal')),
            const Spacer(),
            FilledButton(
              onPressed: gonderiyor ? null : onGonder,
              child: gonderiyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gönder'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModerasayonBadge extends StatelessWidget {
  final String etiket;
  final Color renk;
  final IconData ikon;

  const _ModerasayonBadge({
    required this.etiket,
    required this.renk,
    required this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 11, color: renk),
          const SizedBox(width: 3),
          Text(
            etiket,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}

class _YildizRow extends StatelessWidget {
  final int puan;
  const _YildizRow({required this.puan});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < puan ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: i < puan ? PColors.warning : PColors.muted,
        );
      }),
    );
  }
}
