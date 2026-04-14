import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/ai_analysis_models.dart';

final aiAnalysisRepositoryProvider = Provider<AiAnalysisRepository>((ref) {
  return AiAnalysisRepository(ref.watch(supabaseProvider));
});

class AiAnalysisRepository {
  AiAnalysisRepository(this.client);

  final SupabaseClient client;

  /// Upload menu image to Supabase Storage and return public URL
  Future<String> uploadMenuFile({
    required String businessId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
    if (!allowedExts.contains(ext)) {
      throw Exception('unsupported_file_type');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw Exception('file_too_large');
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'menu-ai-uploads/$businessId/${ts}_$fileName';

    await client.storage.from('menu-uploads').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: false),
    );

    final url = client.storage.from('menu-uploads').getPublicUrl(path);
    return url;
  }

  /// Create OCR job record in DB
  Future<String> createOcrJob({
    required String businessId,
    required String fileUrl,
    String? fileName,
  }) async {
    final res = await client.rpc('create_menu_ocr_job_v1', params: {
      'p_business_id': businessId,
      'p_file_url': fileUrl,
      'p_file_name': fileName,
    });
    return res as String;
  }

  /// Trigger edge function to process job
  Future<int> triggerAnalysis({
    required String jobId,
  }) async {
    final res = await client.functions.invoke(
      'ai-menu-analyze',
      body: {'job_id': jobId},
    );

    if (res.status != 200) {
      final body = res.data;
      final error = body is Map ? (body['error'] ?? 'analysis_failed') : 'analysis_failed';
      throw Exception(error.toString());
    }

    final data = res.data as Map?;
    return (data?['item_count'] as int?) ?? 0;
  }

  /// List OCR jobs for business
  Future<List<AiOcrJob>> listJobs({
    required String businessId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('list_menu_ocr_jobs_v1', params: {
        'p_business_id': businessId,
        'p_limit': limit,
        'p_offset': offset,
      });
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(AiOcrJob.fromMap).toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  /// List AI analysis items for business
  Future<List<AiAnalysisItem>> listAnalysis({
    required String businessId,
    String? statusFilter,
    String? ocrJobId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('list_menu_ai_analysis_v1', params: {
        'p_business_id': businessId,
        'p_status': statusFilter,
        'p_ocr_job_id': ocrJobId,
        'p_limit': limit,
        'p_offset': offset,
      });
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(AiAnalysisItem.fromMap).toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> approveAnalysis(String analysisId) async {
    await client.rpc('approve_menu_ai_analysis_v1', params: {
      'p_analysis_id': analysisId,
    });
  }

  Future<void> rejectAnalysis(String analysisId) async {
    await client.rpc('reject_menu_ai_analysis_v1', params: {
      'p_analysis_id': analysisId,
    });
  }
}
