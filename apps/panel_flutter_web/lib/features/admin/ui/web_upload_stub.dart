import 'package:supabase_flutter/supabase_flutter.dart';

class WpUploadResult {
  WpUploadResult({
    required this.url,
    required this.urlLarge,
    required this.urlThumb,
    required this.width,
    required this.height,
  });

  final String url;
  final String urlLarge;
  final String urlThumb;
  final int? width;
  final int? height;
}

Future<WpUploadResult?> pickAndUploadWpImage({
  required SupabaseClient client,
  String? title,
}) async {
  throw UnsupportedError('WP upload is only supported on web.');
}
