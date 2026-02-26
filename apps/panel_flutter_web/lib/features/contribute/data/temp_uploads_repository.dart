import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final tempUploadsRepositoryProvider = Provider<TempUploadsRepository>((ref) {
  return TempUploadsRepository(ref.watch(supabaseProvider));
});

class TempUploadsRepository {
  TempUploadsRepository(this._client);

  final SupabaseClient _client;
  final Random _random = Random.secure();

  Future<int> uploadTempFiles({
    required String businessId,
    required String kind,
    required List<XFile> files,
    String? userId,
  }) async {
    var uploadedCount = 0;
    final now = DateTime.now();
    final sinceIso = now.subtract(const Duration(days: 30)).toIso8601String();
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final sha1Hex = sha1.convert(bytes).toString();
      final duplicateCandidate = await _hasRecentDuplicate(
        businessId: businessId,
        sha1Hex: sha1Hex,
        sinceIso: sinceIso,
      );
      final ext = _normalizedExtension(file.name);
      final path =
          'temp_uploads/$businessId/${now.millisecondsSinceEpoch}_${_random.nextInt(1 << 24)}.$ext';
      final mimeType = _mimeTypeForExtension(ext);

      await _client.storage
          .from('temp')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      await _client.from('temp_uploads').insert({
        'business_id': businessId,
        'user_id': userId,
        'kind': kind,
        'storage_bucket': 'temp',
        'storage_path': path,
        'mime_type': mimeType,
        'bytes': bytes.length,
        'sha1': sha1Hex,
        'duplicate_candidate': duplicateCandidate,
        'status': 'pending',
      });
      uploadedCount += 1;
    }
    return uploadedCount;
  }

  String _normalizedExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot >= name.length - 1) return 'jpg';
    final ext = name.substring(dot + 1).toLowerCase().trim();
    if (ext == 'jpeg') return 'jpg';
    if (ext == 'png' || ext == 'webp' || ext == 'jpg') return ext;
    return 'jpg';
  }

  String _mimeTypeForExtension(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<bool> _hasRecentDuplicate({
    required String businessId,
    required String sha1Hex,
    required String sinceIso,
  }) async {
    final rows = await _client
        .from('temp_uploads')
        .select('id')
        .eq('business_id', businessId)
        .eq('sha1', sha1Hex)
        .gte('created_at', sinceIso)
        .limit(1);
    return (rows as List).isNotEmpty;
  }
}
