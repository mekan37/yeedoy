import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'media_upload_client_stub.dart';
export 'media_upload_client_stub.dart';

class MediaUploadClient {
  const MediaUploadClient();

  Future<MediaUploadResult?> pickAndUploadImage({
    required SupabaseClient client,
    String? title,
    String? businessId,
    String? menuItemId,
    bool critical = false,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return uploadImageFromXFile(
      client: client,
      file: file,
      title: title,
      businessId: businessId,
      menuItemId: menuItemId,
      critical: critical,
    );
  }

  Future<MediaUploadResult?> uploadImageFromXFile({
    required SupabaseClient client,
    required XFile file,
    String? title,
    String? businessId,
    String? menuItemId,
    bool critical = false,
  }) async {
    final accessToken = client.auth.currentSession?.accessToken ?? '';
    if (accessToken.isEmpty) {
      throw Exception('Oturum bulunamadi.');
    }

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        anonKey == null ||
        anonKey.isEmpty) {
      throw Exception('Supabase ayarlari eksik.');
    }

    final url = Uri.parse(
      '${supabaseUrl.replaceAll(RegExp(r"/$"), "")}/functions/v1/wp-upload-user',
    );
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.headers['apikey'] = anonKey;
    request.fields['title'] = title ?? file.name;
    if ((businessId ?? '').trim().isNotEmpty) {
      request.fields['business_id'] = businessId!.trim();
    }
    if ((menuItemId ?? '').trim().isNotEmpty) {
      request.fields['menu_item_id'] = menuItemId!.trim();
    }
    if (critical) {
      request.fields['critical'] = '1';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception('Yukleme basarisiz.');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final ok = data['ok'] == true || data['ok'] == 1;
    if (!ok) {
      final err = data['error']?.toString() ?? 'media_upload_failed';
      throw Exception(err);
    }

    return MediaUploadResult(
      url: (data['url'] ?? '').toString(),
      urlLarge: (data['url_large'] ?? data['url'] ?? '').toString(),
      urlThumb: (data['url_thumb'] ?? data['url'] ?? '').toString(),
      width: data['width'] is int
          ? data['width'] as int
          : int.tryParse('${data['width'] ?? ''}'),
      height: data['height'] is int
          ? data['height'] as int
          : int.tryParse('${data['height'] ?? ''}'),
      storagePath: (data['path'] ?? '').toString(),
      bucket: (data['bucket'] ?? '').toString(),
      isSigned: data['is_signed'] == true,
    );
  }
}
