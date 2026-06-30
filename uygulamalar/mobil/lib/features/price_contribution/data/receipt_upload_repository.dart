import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final receiptUploadRepositoryProvider = Provider<ReceiptUploadRepository>((
  ref,
) {
  return ReceiptUploadRepository(client: ref.watch(supabaseProvider));
});

/// Uploads receipt / price-evidence photos to the [_bucket] Supabase Storage
/// bucket.
///
/// Path scheme: `receipts/{userId}/{businessId}/{timestamp}.{ext}`
class ReceiptUploadRepository {
  const ReceiptUploadRepository({required this.client});

  final SupabaseClient client;

  static const _bucket = 'price-evidence';

  /// Uploads [bytes] to the price-evidence bucket and returns the public URL.
  ///
  /// Throws on network or storage errors — callers should catch and surface
  /// the error to the user.
  Future<String> uploadReceipt({
    required String userId,
    required String businessId,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final ext = mimeType.contains('png') ? 'png' : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'receipts/$userId/$businessId/$timestamp.$ext';

    await client.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );

    return client.storage.from(_bucket).getPublicUrl(path);
  }
}
