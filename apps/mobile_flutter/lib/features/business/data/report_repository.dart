import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/edge_rate_limit_guard.dart';
import '../../../core/storage/offline_mutation_idempotency.dart';
import '../../../core/storage/offline_submission_queue.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return ReportRepository(client);
});

class ReportResult {
  const ReportResult({
    required this.ok,
    this.error,
    this.reportId,
    this.queued = false,
  });

  final bool ok;
  final String? error;
  final String? reportId;
  final bool queued;

  factory ReportResult.fromMap(Map<String, dynamic> map) => ReportResult(
    ok: (map['ok'] as bool?) ?? false,
    error: map['error'] as String?,
    reportId: map['report_id'] as String?,
    queued: map['queued'] == true,
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
    unawaited(flushOfflineSubmissionQueue(client, maxItems: 10));
    final queuedPayload = await attachOfflineMutationIdempotency(
      action: OfflineSubmissionType.reportBusiness.name,
      payload: {
        'business_id': businessId,
        'reason': reason,
        'details': details,
      },
    );
    try {
      await enforceEdgeRateLimit(
        client,
        action: 'report_submit',
        scope: businessId,
      );
      final res = await client.rpc(
        'submit_report_v2',
        params: {
          'p_business_id': businessId,
          'p_reason': reason,
          'p_details': (details ?? '').trim().isEmpty ? null : details!.trim(),
          'p_idempotency_key': queuedPayload['idempotency_key'],
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
      if (isLikelyOfflineError(e)) {
        await OfflineSubmissionQueueStore.enqueue(
          OfflineSubmissionType.reportBusiness,
          queuedPayload,
        );
        return const ReportResult(ok: true, queued: true);
      }
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<ReportResult> submitReviewReport({
    required String reviewId,
    required String reason,
    String? details,
  }) async {
    unawaited(flushOfflineSubmissionQueue(client, maxItems: 10));
    final queuedPayload = await attachOfflineMutationIdempotency(
      action: OfflineSubmissionType.reportReview.name,
      payload: {'review_id': reviewId, 'reason': reason, 'details': details},
    );
    try {
      await enforceEdgeRateLimit(
        client,
        action: 'report_submit',
        scope: reviewId,
      );
      final res = await client.rpc(
        'submit_report_v2',
        params: {
          'p_review_id': reviewId,
          'p_reason': reason,
          'p_details': (details ?? '').trim().isEmpty ? null : details!.trim(),
          'p_idempotency_key': queuedPayload['idempotency_key'],
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
      if (isLikelyOfflineError(e)) {
        await OfflineSubmissionQueueStore.enqueue(
          OfflineSubmissionType.reportReview,
          queuedPayload,
        );
        return const ReportResult(ok: true, queued: true);
      }
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<ReportResult> submitMenuItemPhotoReport({
    required String menuItemPhotoId,
    required String reason,
    String? details,
  }) async {
    unawaited(flushOfflineSubmissionQueue(client, maxItems: 10));
    final queuedPayload = await attachOfflineMutationIdempotency(
      action: OfflineSubmissionType.reportMenuPhoto.name,
      payload: {
        'menu_item_photo_id': menuItemPhotoId,
        'reason': reason,
        'details': details,
      },
    );
    try {
      await enforceEdgeRateLimit(
        client,
        action: 'report_submit',
        scope: menuItemPhotoId,
      );
      final res = await client.rpc(
        'submit_report_v2',
        params: {
          'p_menu_item_photo_id': menuItemPhotoId,
          'p_reason': reason,
          'p_details': (details ?? '').trim().isEmpty ? null : details!.trim(),
          'p_idempotency_key': queuedPayload['idempotency_key'],
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
      if (isLikelyOfflineError(e)) {
        await OfflineSubmissionQueueStore.enqueue(
          OfflineSubmissionType.reportMenuPhoto,
          queuedPayload,
        );
        return const ReportResult(ok: true, queued: true);
      }
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
