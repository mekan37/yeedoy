Future<void> downloadBytesImpl({
  required List<int> bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  // No-op on non-web platforms.
}
