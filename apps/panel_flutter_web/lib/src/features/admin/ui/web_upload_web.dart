// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();
  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;
  final file = files.first;

  final form = html.FormData();
  form.appendBlob('file', file, file.name);
  form.append('title', title ?? file.name);

  final accessToken = client.auth.currentSession?.accessToken ?? '';
  if (accessToken.isEmpty) {
    throw Exception('Oturum bulunamadı.');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw Exception('Supabase ayarları eksik.');
  }

  final url = '${supabaseUrl.replaceAll(RegExp(r"/$"), "")}/functions/v1/wp-upload';
  final completer = Completer<WpUploadResult?>();
  final req = html.HttpRequest();
  req.open('POST', url);
  req.setRequestHeader('Authorization', 'Bearer $accessToken');
  req.setRequestHeader('apikey', anonKey);

  req.onLoad.listen((_) {
    if (req.status == 200) {
      final data = jsonDecode(req.responseText ?? '{}') as Map<String, dynamic>;
      final ok = data['ok'] == true || data['ok'] == 1;
      if (!ok) {
        final err = data['error']?.toString() ?? 'wp_upload_failed';
        completer.completeError(Exception(err));
        return;
      }
      completer.complete(
        WpUploadResult(
          url: (data['url'] ?? '').toString(),
          urlLarge: (data['url_large'] ?? data['url'] ?? '').toString(),
          urlThumb: (data['url_thumb'] ?? data['url'] ?? '').toString(),
          width: data['width'] is int ? data['width'] as int : int.tryParse('${data['width'] ?? ''}'),
          height: data['height'] is int ? data['height'] as int : int.tryParse('${data['height'] ?? ''}'),
        ),
      );
    } else {
      completer.completeError(Exception('WP y?kleme ba?Yarisiz.'));
    }
  });

  req.onError.listen((_) {
    completer.completeError(Exception('WP y?kleme ba?Yarisiz.'));
  });

  req.send(form);
  return completer.future;
}




