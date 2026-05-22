import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/riverpod_uzantilari.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import '../../../uygulama/tema/renkler.dart';

class QrSayfasi extends ConsumerWidget {
  const QrSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    final isletmeId =
        kimlik is KimlikGirilmis ? kimlik.isletmeId : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Masa QR Kodu')),
      body: isletmeId == null
          ? const Center(child: CircularProgressIndicator())
          : _QrIcerik(isletmeId: isletmeId),
    );
  }
}

class _QrIcerik extends StatefulWidget {
  final String isletmeId;
  const _QrIcerik({required this.isletmeId});

  @override
  State<_QrIcerik> createState() => _QrIcerikState();
}

class _QrIcerikState extends State<_QrIcerik> {
  final _masaCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _masaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final masaNo = _masaCtrl.text.trim();
    // Deep link: yeedoy://masa-siparisi?business={id}&table={no}
    final qrData =
        'https://yeedoy.com/masa?b=${widget.isletmeId}&t=${Uri.encodeComponent(masaNo)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Masa numarasını girin, QR kodu müşteriye gösterin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: PColors.muted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _masaCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Masa No',
              prefixIcon: Icon(Icons.table_restaurant_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Masa $masaNo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            qrData,
            style: const TextStyle(color: PColors.muted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // P-20: Kopyala butonu
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('QR Bağlantısını Kopyala'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: qrData));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Masa $masaNo bağlantısı kopyalandı'),
                      backgroundColor: PColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.print_outlined, size: 16, color: PColors.primary),
                    SizedBox(width: 8),
                    Text('Yazdırma İpucu', style: TextStyle(fontWeight: FontWeight.w800, color: PColors.primary, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Ekran görüntüsü alarak veya bağlantıyı tarayıcıda açarak QR kodunu yazdırabilirsiniz. '
                  'Yüksek çözünürlük için QR kodu büyütüp ekran görüntüsü alın.',
                  style: TextStyle(color: PColors.text, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
