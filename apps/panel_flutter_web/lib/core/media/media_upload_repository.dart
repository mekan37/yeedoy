import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_provider.dart';
import 'media_upload_client.dart';

final mediaUploadRepositoryProvider = Provider<MediaUploadRepository>((ref) {
  return MediaUploadRepository(
    client: ref.watch(supabaseProvider),
    uploadClient: const MediaUploadClient(),
  );
});

class MediaUploadRepository {
  MediaUploadRepository({
    required this.client,
    required this.uploadClient,
  });

  final SupabaseClient client;
  final MediaUploadClient uploadClient;

  Future<MediaUploadResult?> pickAndUploadImage({
    String? title,
    String? businessId,
    String? menuItemId,
    bool critical = false,
  }) {
    return uploadClient.pickAndUploadImage(
      client: client,
      title: title,
      businessId: businessId,
      menuItemId: menuItemId,
      critical: critical,
    );
  }

  Future<MediaUploadResult> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    String? title,
    String? businessId,
    String? menuItemId,
    bool critical = false,
  }) {
    return uploadClient.uploadImageBytes(
      client: client,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      title: title,
      businessId: businessId,
      menuItemId: menuItemId,
      critical: critical,
    );
  }
}
