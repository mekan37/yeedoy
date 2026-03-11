import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<MediaUploadResult?> uploadImageFromXFile({
    required XFile file,
    String? title,
    String? businessId,
    String? menuItemId,
    bool critical = false,
  }) {
    return uploadClient.uploadImageFromXFile(
      client: client,
      file: file,
      title: title,
      businessId: businessId,
      menuItemId: menuItemId,
      critical: critical,
    );
  }
}
