import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics/analytics_client.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/critical_action_guard.dart';
import '../../../core/security/edge_rate_limit_guard.dart';
import '../../../core/cache/request_cache.dart';
import '../../../core/storage/offline_mutation_idempotency.dart';
import '../../../core/storage/offline_mutation_queue.dart';
import '../domain/menu_models.dart';
import 'offline_verify_queue.dart';
import 'menu_rpc_utils.dart';

// MenuRepository'nin bölünmesiyle (B42) ayrılan en büyük sorumluluk: fiyat
// doğrulama/oylama, fiyat önerisi gönderimi (+ çevrimdışı kuyruk flush'ı),
// fiş gönderimi, fiyat geçmişi/durumu/değer skoru, kategori fiyat kıyası,
// hesap tahmini. Menü ağacı okuma (bölüm/ürün) ve fotoğraf akışlarından
// bağımsız — tek paylaşılan yan etki `menu_items|` cache prefix
// invalidasyonu (fiyat oyu/önerisi ürün listesindeki price_status'u
// etkiler).

final menuPriceRepositoryProvider = Provider<MenuPriceRepository>((ref) {
  return MenuPriceRepository(
    ref.watch(supabaseProvider),
    ref.watch(appTelemetryProvider),
    ref.watch(requestCacheProvider).scope('menus'),
  );
});

class MenuPriceRepository {
  MenuPriceRepository(this.client, this._telemetry, this._cache);
  final SupabaseClient client;
  final AppTelemetry _telemetry;
  final RequestCacheScope _cache;

  Future<void> voteMenuItemPrice({
    required String menuItemId,
    required int vote,
    bool queueOnOffline = true,
    String? businessId,
    String? menuId,
  }) async {
    final queuedPayload = await attachOfflineMutationIdempotency(
      action: OfflineVerifyActionType.votePrice.name,
      payload: {
        'menu_item_id': menuItemId,
        'vote': vote,
        'business_id': businessId,
        'menu_id': menuId,
      },
    );
    try {
      try {
        final res = await client.rpc(
          'set_menu_item_price_vote_v2',
          params: {
            'p_menu_item_id': menuItemId,
            'p_vote': vote,
            'p_idempotency_key': queuedPayload['idempotency_key'],
          },
        );
        ensureOkResponse(res, fallbackError: 'price_vote_failed');
      } catch (e) {
        if (!isMissingRpcError(e, 'set_menu_item_price_vote_v2')) {
          rethrow;
        }
        await _submitDesiredPriceVoteLegacy(
          client: client,
          menuItemId: menuItemId,
          desiredVote: vote,
        );
      }
      _cache.invalidatePrefix('menu_items|');
    } catch (e) {
      if (queueOnOffline && isLikelyOfflineError(e)) {
        await OfflineVerifyQueueStore.enqueue(
          OfflineVerifyActionType.votePrice,
          queuedPayload,
        );
        throw const OfflineQueuedException();
      }
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<PriceSuggestionSubmissionResult> submitMenuItemPriceSuggestion({
    required String menuItemId,
    required int suggestedPriceCents,
    required String currency,
    required String note,
    String? evidenceUrl,
    String? clientId,
    DateTime? capturedAt,
    bool queueOnOffline = true,
    String? businessId,
    String? menuId,
  }) async {
    final resolvedClientId = (clientId ?? await getAnalyticsClientId()).trim();
    final capturedAtValue = capturedAt ?? DateTime.now();
    final queuedPayload = await attachOfflineMutationIdempotency(
      action: OfflineVerifyActionType.suggestPrice.name,
      payload: {
        'menu_item_id': menuItemId,
        'suggested_price_cents': suggestedPriceCents,
        'currency': currency,
        'note': note,
        'evidence_url': evidenceUrl,
        'client_id': resolvedClientId,
        'captured_at': capturedAtValue.toIso8601String(),
        'business_id': businessId,
        'menu_id': menuId,
      },
      clientId: resolvedClientId,
    );
    try {
      ensureCriticalActionAllowed(client, action: 'price_suggestion');
      await enforceEdgeRateLimit(
        client,
        action: 'price_verify',
        scope: menuItemId,
      );
      final params = {
        'p_menu_item_id': menuItemId,
        'p_suggested_price_cents': suggestedPriceCents,
        'p_currency': currency,
        'p_note': note.trim(),
        'p_evidence_url': (evidenceUrl ?? '').trim().isEmpty
            ? null
            : evidenceUrl!.trim(),
      };

      dynamic res;
      try {
        res = await client.rpc(
          'submit_menu_item_price_suggestion_v5',
          params: {
            ...params,
            'p_client_id': resolvedClientId.isEmpty ? null : resolvedClientId,
            'p_captured_at': capturedAtValue.toIso8601String(),
            'p_idempotency_key': queuedPayload['idempotency_key'],
          },
        );
      } catch (e) {
        if (!isMissingRpcError(e, 'submit_menu_item_price_suggestion_v5')) {
          rethrow;
        }
        try {
          res = await client.rpc(
            'submit_menu_item_price_suggestion_v3',
            params: {
              ...params,
              'p_client_id': resolvedClientId.isEmpty ? null : resolvedClientId,
              'p_captured_at': capturedAtValue.toIso8601String(),
            },
          );
        } catch (legacyError) {
          if (!isMissingRpcError(
            legacyError,
            'submit_menu_item_price_suggestion_v3',
          )) {
            rethrow;
          }
          res = await client.rpc(
            'submit_menu_item_price_suggestion_v2',
            params: params,
          );
        }
      }
      _cache.invalidatePrefix('menu_items|');
      if (res is Map) {
        final result = PriceSuggestionSubmissionResult.fromMap(
          res.cast<String, dynamic>(),
        );
        if (!result.ok && result.error != null) {
          throw Exception(result.error);
        }
        return result;
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        final result = PriceSuggestionSubmissionResult.fromMap(
          (res.first as Map).cast<String, dynamic>(),
        );
        if (!result.ok && result.error != null) {
          throw Exception(result.error);
        }
        return result;
      }
      return const PriceSuggestionSubmissionResult(
        ok: false,
        error: 'Beklenmeyen yanıt',
      );
    } catch (e) {
      if (queueOnOffline && isLikelyOfflineError(e)) {
        await OfflineVerifyQueueStore.enqueue(
          OfflineVerifyActionType.suggestPrice,
          queuedPayload,
        );
        throw const OfflineQueuedException();
      }
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<int> flushOfflineVerifyQueue({int maxItems = 20}) async {
    final queue = await OfflineVerifyQueueStore.readReady(limit: maxItems);
    if (queue.isEmpty) return 0;
    var sent = 0;
    for (final item in queue) {
      try {
        if (item.type == OfflineVerifyActionType.votePrice) {
          final menuItemId = (item.payload['menu_item_id'] ?? '').toString();
          final vote = asInt(item.payload['vote']) ?? 0;
          if (menuItemId.isEmpty || (vote != -1 && vote != 0 && vote != 1)) {
            await OfflineVerifyQueueStore.remove(item.id);
            unawaited(
              _telemetry.logOfflineMutationOutcome(
                kind: item.type.name,
                disposition: 'drop',
                source: 'offline_verify_replay',
                retryCount: item.retryCount,
                detail: 'invalid_payload',
              ),
            );
            continue;
          }
          await voteMenuItemPrice(
            menuItemId: menuItemId,
            vote: vote,
            queueOnOffline: false,
          );
          await OfflineVerifyQueueStore.remove(item.id);
          unawaited(
            _telemetry.logOfflineMutationOutcome(
              kind: item.type.name,
              disposition: 'success',
              source: 'offline_verify_replay',
              retryCount: item.retryCount,
            ),
          );
          sent++;
          continue;
        }

        if (item.type == OfflineVerifyActionType.suggestPrice) {
          final menuItemId = (item.payload['menu_item_id'] ?? '').toString();
          final cents = asInt(item.payload['suggested_price_cents']) ?? 0;
          final currency = (item.payload['currency'] ?? 'TRY').toString();
          final note = (item.payload['note'] ?? '').toString();
          final evidenceUrl = (item.payload['evidence_url'] ?? '').toString();
          final clientId = (item.payload['client_id'] ?? '').toString();
          final capturedAtRaw = (item.payload['captured_at'] ?? '').toString();
          final capturedAt = DateTime.tryParse(capturedAtRaw) ?? DateTime.now();

          if (menuItemId.isEmpty || cents <= 0) {
            await OfflineVerifyQueueStore.remove(item.id);
            unawaited(
              _telemetry.logOfflineMutationOutcome(
                kind: item.type.name,
                disposition: 'drop',
                source: 'offline_verify_replay',
                retryCount: item.retryCount,
                detail: 'invalid_payload',
              ),
            );
            continue;
          }
          await submitMenuItemPriceSuggestion(
            menuItemId: menuItemId,
            suggestedPriceCents: cents,
            currency: currency,
            note: note,
            evidenceUrl: evidenceUrl.isEmpty ? null : evidenceUrl,
            clientId: clientId.isEmpty ? null : clientId,
            capturedAt: capturedAt,
            queueOnOffline: false,
          );
          await OfflineVerifyQueueStore.remove(item.id);
          unawaited(
            _telemetry.logOfflineMutationOutcome(
              kind: item.type.name,
              disposition: 'success',
              source: 'offline_verify_replay',
              retryCount: item.retryCount,
            ),
          );
          sent++;
          continue;
        }
      } catch (e) {
        final decision = classifyOfflineMutationError(e);
        if (decision.disposition == OfflineMutationFailureDisposition.retry) {
          await OfflineVerifyQueueStore.markRetry(item, error: e);
          unawaited(
            _telemetry.logOfflineMutationOutcome(
              kind: item.type.name,
              disposition: 'retry',
              source: 'offline_verify_replay',
              retryCategory: classifyOfflineMutationRetryCategory(e).name,
              retryCount: item.retryCount + 1,
              detail: decision.reason,
            ),
          );
          break;
        }
        await OfflineVerifyQueueStore.remove(item.id);
        if (decision.disposition == OfflineMutationFailureDisposition.resolve) {
          unawaited(
            _telemetry.logOfflineMutationOutcome(
              kind: item.type.name,
              disposition: 'resolve',
              source: 'offline_verify_replay',
              retryCategory: classifyOfflineMutationRetryCategory(e).name,
              retryCount: item.retryCount,
              detail: decision.reason,
            ),
          );
          sent++;
        } else {
          unawaited(
            _telemetry.logOfflineMutationOutcome(
              kind: item.type.name,
              disposition: 'drop',
              source: 'offline_verify_replay',
              retryCategory: classifyOfflineMutationRetryCategory(e).name,
              retryCount: item.retryCount,
              detail: decision.reason,
            ),
          );
        }
        continue;
      }
    }
    return sent;
  }

  Future<void> submitReceiptSubmission({
    required String businessId,
    required String imageUrl,
    required List<Map<String, dynamic>> matches,
  }) async {
    if (imageUrl.trim().isEmpty) return;
    try {
      await client.rpc(
        'submit_receipt_submission_v1',
        params: {
          'p_business_id': businessId,
          'p_image_url': imageUrl,
          'p_matches': matches,
        },
      );
    } catch (_) {
      // Sunucuda RPC yoksa sessizce atla.
    }
  }

  Future<List<MenuItemPriceHistoryEntry>> fetchMenuItemPriceHistory(
    String menuItemId, {
    int limit = 5,
  }) async {
    try {
      final res = await client.rpc(
        'get_menu_item_price_history_v1',
        params: {'p_menu_item_id': menuItemId, 'p_limit': limit},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) =>
                MenuItemPriceHistoryEntry.fromMap(row.cast<String, dynamic>()),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<MenuItemPriceStatus> fetchMenuItemPriceStatus(
    String menuItemId,
  ) async {
    try {
      final res = await client.rpc(
        'get_menu_item_price_status_v1',
        params: {'p_menu_item_id': menuItemId},
      );
      return MenuItemPriceStatus.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<MenuItemValueScore> fetchMenuItemValueScore(String menuItemId) async {
    try {
      final res = await client.rpc(
        'get_menu_item_value_score_v1',
        params: {'p_menu_item_id': menuItemId},
      );
      return MenuItemValueScore.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, DateTime?>> fetchMenuItemsPriceAge(
    List<String> itemIds,
  ) async {
    try {
      final res = await client.rpc(
        'get_menu_items_price_age_v1',
        params: {'p_item_ids': itemIds},
      );
      final rows = (res as List?) ?? const [];
      final map = <String, DateTime?>{};
      for (final row in rows) {
        if (row is! Map) continue;
        final data = row.cast<String, dynamic>();
        final id = (data['menu_item_id'] ?? data['id'] ?? '').toString();
        if (id.isEmpty) continue;
        map[id] = DateTime.tryParse((data['last_price_at'] ?? '').toString());
      }
      return map;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, dynamic>> fetchBillEstimate({
    required String businessId,
    required List<Map<String, dynamic>> items,
    int? tipPct,
  }) async {
    try {
      final res = await client.rpc(
        'get_bill_estimate_v1',
        params: {
          'p_business_id': businessId,
          'p_items': items,
          'p_tip_pct': tipPct,
        },
      );
      if (res is Map) return res.cast<String, dynamic>();
      return {'ok': false, 'error': 'invalid_response'};
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<MenuItemPriceBenchmark?> fetchCategoryPriceBenchmark({
    required String itemName,
    required String city,
    String? excludeBusinessId,
  }) async {
    if (itemName.trim().isEmpty || city.trim().isEmpty) return null;
    try {
      final res = await client.rpc(
        'get_category_price_benchmark_v1',
        params: {
          'p_item_name': itemName.trim(),
          'p_city': city.trim(),
          'p_exclude_business_id': excludeBusinessId,
        },
      );
      final rows = (res as List?) ?? const [];
      if (rows.isEmpty) return null;
      final row = rows.first;
      if (row is! Map) return null;
      final m = row.cast<String, dynamic>();
      final avg = (m['avg_price_cents'] as num?)?.toInt() ?? 0;
      if (avg <= 0) return null;
      return MenuItemPriceBenchmark(
        avgPriceCents: avg,
        minPriceCents: (m['min_price_cents'] as num?)?.toInt() ?? avg,
        maxPriceCents: (m['max_price_cents'] as num?)?.toInt() ?? avg,
        sampleCount: (m['sample_count'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// `MenuRepository._getMenuItemsV1` (eski API fallback yolu) tarafından,
  /// ürünleri güncel fiyat durumu ile zenginleştirmek için kullanılır.
  Future<Map<String, MenuItemPriceStatusSnapshot>> getMenuItemPriceStatusMap(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return const {};
    try {
      final res = await client
          .from('menu_item_price_status_v1')
          .select('menu_item_id, price_status, total_30d')
          .inFilter('menu_item_id', itemIds);
      final rows = (res as List?) ?? const [];
      final map = <String, MenuItemPriceStatusSnapshot>{};
      for (final row in rows) {
        if (row is! Map) continue;
        final data = row.cast<String, dynamic>();
        final id = (data['menu_item_id'] ?? '').toString();
        if (id.isEmpty) continue;
        final total = data['total_30d'];
        map[id] = MenuItemPriceStatusSnapshot(
          priceStatus: (data['price_status'] ?? 'unverified').toString(),
          total30d: (total is num)
              ? total.toInt()
              : int.tryParse((total ?? '').toString()),
        );
      }
      return map;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

Future<void> _submitDesiredPriceVoteLegacy({
  required SupabaseClient client,
  required String menuItemId,
  required int desiredVote,
}) async {
  final currentVote = await _readCurrentUserMenuItemPriceVote(
    client,
    menuItemId: menuItemId,
  );
  if (currentVote == desiredVote) return;
  if (desiredVote == 0) {
    if (currentVote == null || currentVote == 0) return;
    final res = await client.rpc(
      'vote_menu_item_price_v1',
      params: {'p_menu_item_id': menuItemId, 'p_vote': currentVote},
    );
    ensureOkResponse(res, fallbackError: 'price_vote_failed');
    return;
  }
  final res = await client.rpc(
    'vote_menu_item_price_v1',
    params: {'p_menu_item_id': menuItemId, 'p_vote': desiredVote},
  );
  ensureOkResponse(res, fallbackError: 'price_vote_failed');
}

Future<int?> _readCurrentUserMenuItemPriceVote(
  SupabaseClient client, {
  required String menuItemId,
}) async {
  final res = await client
      .from('menu_item_price_votes')
      .select('vote')
      .eq('menu_item_id', menuItemId)
      .maybeSingle();
  if (res == null) return null;
  return asInt((res as Map)['vote']);
}

class MenuItemPriceBenchmark {
  const MenuItemPriceBenchmark({
    required this.avgPriceCents,
    required this.minPriceCents,
    required this.maxPriceCents,
    required this.sampleCount,
  });

  final int avgPriceCents;
  final int minPriceCents;
  final int maxPriceCents;
  final int sampleCount;
}

class PriceSuggestionSubmissionResult {
  const PriceSuggestionSubmissionResult({
    required this.ok,
    this.error,
    this.autoApproved = false,
    this.confidenceScore = 0,
    this.pendingCount = 0,
    this.onsiteVerified = false,
    this.onsiteSignal,
    this.xpMultiplier = 1,
    this.queuePriority = 'normal',
    this.queued = false,
  });

  final bool ok;
  final String? error;
  final bool autoApproved;
  final double confidenceScore;
  final int pendingCount;
  final bool onsiteVerified;
  final String? onsiteSignal;
  final double xpMultiplier;
  final String queuePriority;
  final bool queued;

  factory PriceSuggestionSubmissionResult.fromMap(Map<String, dynamic> map) {
    final confidence = map['confidence_score'];
    return PriceSuggestionSubmissionResult(
      ok: map['ok'] == true,
      error: map['error']?.toString(),
      autoApproved: map['auto_approved'] == true,
      confidenceScore: confidence is num ? confidence.toDouble() : 0,
      pendingCount: map['pending_count'] is num
          ? (map['pending_count'] as num).toInt()
          : 0,
      onsiteVerified: map['onsite_verified'] == true,
      onsiteSignal: map['onsite_signal']?.toString(),
      xpMultiplier: map['xp_multiplier'] is num
          ? (map['xp_multiplier'] as num).toDouble()
          : 1,
      queuePriority: map['queue_priority']?.toString() ?? 'normal',
      queued: map['queued'] == true,
    );
  }
}

class MenuItemPriceStatusSnapshot {
  const MenuItemPriceStatusSnapshot({
    required this.priceStatus,
    required this.total30d,
  });

  final String priceStatus;
  final int? total30d;
}
