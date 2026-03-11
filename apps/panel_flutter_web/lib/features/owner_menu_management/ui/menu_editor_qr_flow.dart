import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/colors.dart';
import '../../../core/web/download_utils.dart';

class MenuEditorQrPreview extends StatelessWidget {
  const MenuEditorQrPreview({
    super.key,
    required this.data,
    this.size = 180,
  });

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: QrImageView(
        data: data,
        size: size,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.textStrong,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

Future<void> exportMenuQrPng({
  required String data,
  required String businessName,
}) async {
  final bytes = await _buildQrBytes(data);
  final fileName = '${businessName}_menu_qr.png';
  if (kIsWeb) {
    await downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'image/png',
    );
    return;
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'image/png',
        ),
      ],
    ),
  );
}

Future<Uint8List> _buildQrBytes(String data) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: true,
  );
  final byteData = await painter.toImageData(1024);
  if (byteData == null) {
    throw Exception('qr_png_export_failed');
  }
  return byteData.buffer.asUint8List();
}
