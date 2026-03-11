import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/media/media_upload_client.dart';

@Deprecated('Use MediaUploadResult from core/media/media_upload_client.dart.')
typedef WpUploadResult = MediaUploadResult;

@Deprecated(
  'Use MediaUploadClient or MediaUploadRepository from core/media instead.',
)
Future<MediaUploadResult?> pickAndUploadWpImage({
  required SupabaseClient client,
  String? title,
  String? businessId,
  String? menuItemId,
  bool critical = false,
}) {
  return const MediaUploadClient().pickAndUploadImage(
    client: client,
    title: title,
    businessId: businessId,
    menuItemId: menuItemId,
    critical: critical,
  );
}
