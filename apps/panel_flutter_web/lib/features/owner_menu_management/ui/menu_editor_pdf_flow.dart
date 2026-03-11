import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/web/download_utils.dart';

Future<void> exportMenuQrPdf({
  required String qrData,
  required String businessName,
  required bool isA6,
}) async {
  final pdf = pw.Document();
  final pageFormat = isA6 ? PdfPageFormat.a6 : PdfPageFormat.a4;
  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (_) => pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              businessName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrData,
              width: isA6 ? 140 : 220,
              height: isA6 ? 140 : 220,
            ),
          ],
        ),
      ),
    ),
  );

  final bytes = await pdf.save();
  final fileName = '${businessName}_menu_qr_${isA6 ? 'a6' : 'a4'}.pdf';
  if (kIsWeb) {
    await downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );
    return;
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'application/pdf',
        ),
      ],
    ),
  );
}
