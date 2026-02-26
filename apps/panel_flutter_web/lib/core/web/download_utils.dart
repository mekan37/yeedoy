import 'download_utils_stub.dart'
    if (dart.library.html) 'download_utils_web.dart';

Future<void> downloadBytes({
  required List<int> bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) {
  return downloadBytesImpl(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}
