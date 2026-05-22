import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/riverpod_uzantilari.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import '../../masa_siparisleri/domain/masa_siparisi_bildiricisi.dart';
import '../../masa_siparisleri/domain/masa_siparisi_modeli.dart';

class QrTarayiciSayfasi extends ConsumerStatefulWidget {
  const QrTarayiciSayfasi({super.key});

  @override
  ConsumerState<QrTarayiciSayfasi> createState() => _QrTarayiciSayfasiState();
}

class _QrTarayiciSayfasiState extends ConsumerState<QrTarayiciSayfasi> {
  final _ctrl = MobileScannerController();
  bool _islendi = false;
  bool _torchAcik = false;
  String? _sonHata;
  int _hataSayisi = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _qrBulundu(BarcodeCapture capture) {
    if (_islendi) return;
    final kod = capture.barcodes.firstOrNull?.rawValue;
    if (kod == null) return;

    final uri = Uri.tryParse(kod);
    if (uri == null) return;

    final masaNo = uri.queryParameters['t'];
    final isletmeId = uri.queryParameters['b'];

    if (masaNo == null || isletmeId == null) {
      _hataGoster(
        'Geçersiz QR kodu',
        ipucu:
            'Yeedoy masa QR kodunu tarıyor musunuz? Farklı bir QR kodu okundu.',
      );
      return;
    }

    final kimlik = ref.read(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) {
      _hataGoster('Oturum bulunamadı', ipucu: 'Lütfen tekrar giriş yapın.');
      return;
    }
    if (kimlik.isletmeId != isletmeId) {
      _hataGoster(
        'Yanlış işletme QR kodu',
        ipucu: 'Bu QR kodu ${kimlik.isletmeAdi} işletmesine ait değil.',
      );
      return;
    }

    setState(() => _islendi = true);
    _ctrl.stop();
    _masaDetayGoster(masaNo);
  }

  void _hataGoster(String mesaj, {String? ipucu}) {
    if (!mounted) return;
    setState(() {
      _sonHata = mesaj;
      _hataSayisi++;
    });
    // 3 saniye sonra hatayı temizle ve tekrar tara
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _sonHata = null);
    });
    // Ekranda snackbar göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mesaj, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (ipucu != null)
              Text(
                ipucu,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: PColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Tekrar Dene',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _sonHata = null);
            _ctrl.start();
          },
        ),
      ),
    );
  }

  Future<void> _manuelMasaGir() async {
    final ctrl = TextEditingController();
    final masaNo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Manuel Masa No Gir'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Masa Numarası',
            hintText: '1',
            prefixIcon: Icon(Icons.table_restaurant_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Görüntüle'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (masaNo != null && masaNo.isNotEmpty) {
      _ctrl.stop();
      setState(() {
        _islendi = true;
        _sonHata = null;
        _hataSayisi = 0;
      });
      _masaDetayGoster(masaNo);
    }
  }

  void _masaDetayGoster(String masaNo) {
    final siparisler = ref.read(masaSiparisleriProvider).valueOrNull ?? [];
    final masaSiparisleri = siparisler
        .where((s) => s.masaNo == masaNo && s.durum != 'done')
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _MasaDetayPanel(masaNo: masaNo, siparisler: masaSiparisleri),
    ).then((_) {
      if (mounted) {
        setState(() => _islendi = false);
        _ctrl.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masa Tara'),
        actions: [
          IconButton(
            icon: Icon(
              _torchAcik ? Icons.flash_on_outlined : Icons.flash_off_outlined,
            ),
            tooltip: 'Fener',
            onPressed: () {
              _ctrl.toggleTorch();
              setState(() => _torchAcik = !_torchAcik);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: _qrBulundu,
            errorBuilder: (context, error, child) {
              final izinHatasi = error.errorCode == MobileScannerErrorCode.permissionDenied;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        izinHatasi
                            ? Icons.no_photography_outlined
                            : Icons.videocam_off_outlined,
                        size: 56,
                        color: PColors.muted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        izinHatasi
                            ? 'Kamera İzni Gerekiyor'
                            : 'Kamera Başlatılamadı',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: PColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        izinHatasi
                            ? 'QR kod taramak için kamera iznine ihtiyaç var.\nAyarlardan Yeedoy uygulamasına kamera izni verin.'
                            : 'Kamera başlatılırken bir sorun oluştu.\nTekrar denemek için aşağıdaki butona tıklayın.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: PColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (izinHatasi)
                        FilledButton.icon(
                          onPressed: () async {
                            // ignore: deprecated_member_use
                            // Platform açık izin yöneticisine yönlendir
                            await _ctrl.start();
                          },
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('İzin Ver'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _ctrl.start(),
                          icon: const Icon(Icons.refresh_outlined, size: 18),
                          label: const Text('Tekrar Dene'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: PColors.primaryStrong, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_sonHata != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: PColors.danger.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _sonHata!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _sonHata == null
                      ? 'Masa QR kodunu çerçeve içine getirin'
                      : 'Yeedoy masa QR kodu tarıyın',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
                if (_hataSayisi >= 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () => _manuelMasaGir(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Masa No Manuel Gir',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasaDetayPanel extends StatelessWidget {
  final String masaNo;
  final List<MasaSiparisi> siparisler;

  const _MasaDetayPanel({required this.masaNo, required this.siparisler});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PColors.muted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Masa $masaNo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                if (siparisler.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PColors.orderPending.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${siparisler.length} aktif',
                      style: const TextStyle(
                        color: PColors.orderPending,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: siparisler.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: PColors.orderDone,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Bu masada aktif sipariş yok',
                          style: TextStyle(color: PColors.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: siparisler.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = siparisler[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _DurumRozet(s.durum),
                                  const Spacer(),
                                  Text(
                                    '${DateTime.now().difference(s.olusturuldu).inMinutes} dk önce',
                                    style: const TextStyle(
                                      color: PColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...s.kalemler.map(
                                (k) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '${k.adet}× ${k.urunAdi}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              if (s.not != null && s.not!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  s.not!,
                                  style: const TextStyle(
                                    color: PColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DurumRozet extends StatelessWidget {
  final String durum;
  const _DurumRozet(this.durum);

  @override
  Widget build(BuildContext context) {
    final (renk, etiket) = switch (durum) {
      'pending' => (PColors.orderPending, 'Bekliyor'),
      'seen' => (PColors.orderSeen, 'Hazırlanıyor'),
      _ => (PColors.muted, durum),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        etiket,
        style: TextStyle(
          color: renk,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
