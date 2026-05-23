import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadResult {
  MediaUploadResult({
    required this.url,
    required this.urlLarge,
    required this.urlThumb,
    required this.width,
    required this.height,
    this.storagePath,
    this.bucket,
    this.isSigned = false,
  });

  final String url;
  final String urlLarge;
  final String urlThumb;
  final int? width;
  final int? height;
  final String? storagePath;
  final String? bucket;
  final bool isSigned;
}

class MediaUploadClient {
  const MediaUploadClient();

  Future<MediaUploadResult?> pickAndUploadImage({
    required SupabaseClient client,
    String? title,
    String? businessId,
    String? menuItemId,
    bool critical = false,
  }) async {
    throw UnsupportedError('Media upload is not supported on this platform.');
  }

  Future<MediaUploadResult?> uploadImageFromXFile({
    required SupabaseClient client,
    required XFile file,
    String? title,
    String? businessId,
    String? menuItemId,
    bool critical = false,
  }) async {
    throw UnsupportedError('Media upload is not supported on this platform.');
  }
}
