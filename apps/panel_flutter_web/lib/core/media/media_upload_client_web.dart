// ignore_for_file: deprecated_member_use
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return null;
    final file = files.first;

    return _uploadHtmlFile(
      client: client,
      file: file,
      fileName: file.name,
      title: title ?? file.name,
      businessId: businessId,
      menuItemId: menuItemId,
      critical: critical,
    );
  }

  Future<MediaUploadResult> uploadImageBytes({
    required SupabaseClient client,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    String? title,
    String? businessId,
    String? menuItemId,
    bool critical = false,
  }) async {
    final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
    final upload = await _uploadHtmlFile(
      client: client,
      file: blob,
      fileName: fileName,
      title: title ?? fileName,
      businessId: businessId,
      menuItemId: menuItemId,
      critical: critical,
    );
    if (upload == null) {
      throw Exception('media_upload_cancelled');
    }
    return upload;
  }

  Future<MediaUploadResult?> _uploadHtmlFile({
    required SupabaseClient client,
    required dynamic file,
    required String fileName,
    required String title,
    String? businessId,
    String? menuItemId,
    required bool critical,
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

    final form = html.FormData();
    form.appendBlob('file', file, fileName);
    form.append('title', title);
    if (businessId != null && businessId.isNotEmpty) {
      form.append('business_id', businessId);
    }
    if (menuItemId != null && menuItemId.isNotEmpty) {
      form.append('menu_item_id', menuItemId);
    }
    if (critical) {
      form.append('critical', 'true');
    }

    final url =
        '${supabaseUrl.replaceAll(RegExp(r'/$'), '')}/functions/v1/media-upload';
    final request = html.HttpRequest();
    final completer = Completer<MediaUploadResult?>();

    request.open('POST', url);
    request.setRequestHeader('Authorization', 'Bearer $accessToken');
    request.setRequestHeader('apikey', anonKey);

    request.onLoad.listen((_) {
      if (request.status == 200) {
        final payload =
            jsonDecode(request.responseText ?? '{}') as Map<String, dynamic>;
        final ok = payload['ok'] == true || payload['ok'] == 1;
        if (!ok) {
          completer.completeError(
            Exception(payload['error']?.toString() ?? 'media_upload_failed'),
          );
          return;
        }

        completer.complete(
          MediaUploadResult(
            url: (payload['url'] ?? '').toString(),
            urlLarge: (payload['url_large'] ?? payload['url'] ?? '').toString(),
            urlThumb: (payload['url_thumb'] ?? payload['url'] ?? '').toString(),
            width: payload['width'] is int
                ? payload['width'] as int
                : int.tryParse('${payload['width'] ?? ''}'),
            height: payload['height'] is int
                ? payload['height'] as int
                : int.tryParse('${payload['height'] ?? ''}'),
            storagePath: payload['storage_path']?.toString(),
            bucket: payload['bucket']?.toString(),
            isSigned: payload['is_signed'] == true,
          ),
        );
        return;
      }

      completer.completeError(Exception('Media upload failed.'));
    });

    request.onError.listen((_) {
      completer.completeError(Exception('Media upload failed.'));
    });

    request.send(form);
    return completer.future;
  }
}
