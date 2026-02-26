import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/security/edge_rate_limit_guard.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return ReportRepository(client);
});

class ReportResult {
  const ReportResult({required this.ok, this.error, this.reportId});

  final bool ok;
  final String? error;
  final String? reportId;

  factory ReportResult.fromMap(Map<String, dynamic> m) => ReportResult(
    ok: (m['ok'] as bool?) ?? false,
    error: m['error'] as String?,
    reportId: m['report_id'] as String?,
  );
}

class ReportRepository {
  ReportRepository(this.client);
  final SupabaseClient client;

  Future<ReportResult> submitBusinessReport({
    required String businessId,
    required String reason,
    String? details,
  }) async {
    try {
      await enforceEdgeRateLimit(
        client,
        action: 'report_submit',
        scope: businessId,
      );
      final res = await client.rpc(
        'submit_report_v1',
        params: {
          'p_business_id': businessId,
          'p_reason': reason,
          'p_details': (details ?? '').trim().isEmpty ? null : details!.trim(),
        },
      );
      if (res is Map) {
        return ReportResult.fromMap(res.cast<String, dynamic>());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        return ReportResult.fromMap((res.first as Map).cast<String, dynamic>());
      }
      return const ReportResult(ok: false, error: 'unknown');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<ReportResult> submitReviewReport({
    required String reviewId,
    required String reason,
    String? details,
  }) async {
    try {
      await enforceEdgeRateLimit(
        client,
        action: 'report_submit',
        scope: reviewId,
      );
      final res = await client.rpc(
        'submit_report_v1',
        params: {
          'p_review_id': reviewId,
          'p_reason': reason,
          'p_details': (details ?? '').trim().isEmpty ? null : details!.trim(),
        },
      );
      if (res is Map) {
        return ReportResult.fromMap(res.cast<String, dynamic>());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        return ReportResult.fromMap((res.first as Map).cast<String, dynamic>());
      }
      return const ReportResult(ok: false, error: 'unknown');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<ReportResult> submitMenuItemPhotoReport({
    required String menuItemPhotoId,
    required String reason,
    String? details,
  }) async {
    try {
      await enforceEdgeRateLimit(
        client,
        action: 'report_submit',
        scope: menuItemPhotoId,
      );
      final res = await client.rpc(
        'submit_report_v1',
        params: {
          'p_menu_item_photo_id': menuItemPhotoId,
          'p_reason': reason,
          'p_details': (details ?? '').trim().isEmpty ? null : details!.trim(),
        },
      );
      if (res is Map) {
        return ReportResult.fromMap(res.cast<String, dynamic>());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        return ReportResult.fromMap((res.first as Map).cast<String, dynamic>());
      }
      return const ReportResult(ok: false, error: 'unknown');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
