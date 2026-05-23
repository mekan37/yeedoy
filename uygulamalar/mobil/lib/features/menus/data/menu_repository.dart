import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics/analytics_client.dart';
import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/critical_action_guard.dart';
import '../../../core/security/edge_rate_limit_guard.dart';
import '../../../core/storage/local_db/local_db_models.dart';
import '../../../core/storage/local_db/local_db_provider.dart';
import '../../../core/storage/local_db/local_db_store.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../../core/storage/offline_mutation_idempotency.dart';
import '../../../core/storage/offline_mutation_queue.dart';
import 'offline_verify_queue.dart';
import 'local_food_catalog_data_source.dart';
import '../domain/menu_models.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return MenuRepository(
    client,
    ref.watch(appTelemetryProvider),
    ref.watch(requestCacheProvider),
    ref.watch(localDbStoreProvider),
  );
});

class MenuRepository {
  MenuRepository(
    this.client,
    this._telemetry,
    RequestCache requestCache,
    this._localDb,
  )
    : _cache = requestCache.scope(_cacheScope);
  final SupabaseClient client;
  final AppTelemetry _telemetry;
  final RequestCacheScope _cache;
  final LocalDbStore _localDb;
  final LocalFoodCatalogDataSource _localCatalog =
      const LocalFoodCatalogDataSource();

  static const String _cacheScope = 'menus';
  static const Duration _menuTtl = Duration(minutes: 5);
  static const Duration _offlineSnapshotTtl = Duration(days: 7);

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  Future<List<BusinessMenu>> fetchBusinessMenus(String businessId) async {
    final key = 'business_menus|$businessId';
    final fresh = _cache.getFresh<List<BusinessMenu>>(key, ttl: _menuTtl);
    if (fresh != null) return fresh;
    try {
      final res = await _telemetry.traceRpc<dynamic>(
        operation: 'get_business_menus',
        run: () => client.rpc(
          'get_business_menus_v1',
          params: {'p_business_id': businessId},
        ),
        sampleRate: 0.2,
      );
      final rows = (res as List?) ?? const [];
      final menus = rows
          .whereType<Map>()
          .map((row) => BusinessMenu.fromMap(row.cast<String, dynamic>()))
          .toList();
      _cache.set(key, menus);
      await _writeMenuSnapshot(
        key,
        <String, dynamic>{
          'type': 'business_menus',
          'menus': menus.map((menu) => menu.toMap()).toList(),
        },
      );
      await OfflineCachePrefs.saveBusinessMenus(businessId, menus);
      return menus;
    } catch (e) {
      final stale = _cache.getStale<List<BusinessMenu>>(key);
      if (stale != null) return stale;
      final local = await _readBusinessMenusSnapshot(key);
      if (local != null) return local;
      final cached = await OfflineCachePrefs.loadBusinessMenus(businessId);
      if (cached != null) return cached;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, dynamic>> fetchPublicMenuShare(String menuId) async {
    try {
      final res = await client.rpc(
        'public_menu_share_view_v1',
        params: {'p_menu_id': menuId},
      );
      if (res is Map) return res.cast<String, dynamic>();
      if (res is List && res.isNotEmpty && res.first is Map) {
        return (res.first as Map).cast<String, dynamic>();
      }
      return {'menu': null, 'sections': []};
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, dynamic>?> fetchBusinessMini(String businessId) async {
    try {
      final res = await client
          .from('businesses')
          .select('id,name,logo_url')
          .eq('id', businessId)
          .maybeSingle();
      if (res == null) return null;
      return (res as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<List<MenuSection>> fetchMenuSections(String menuId) async {
    final key = 'menu_sections|$menuId';
    final fresh = _cache.getFresh<List<MenuSection>>(key, ttl: _menuTtl);
    if (fresh != null) return fresh;
    try {
      final res = await _telemetry.traceRpc<dynamic>(
        operation: 'get_menu_sections',
        run: () =>
            client.rpc('get_menu_sections_v1', params: {'p_menu_id': menuId}),
        sampleRate: 0.2,
      );
      final rows = (res as List?) ?? const [];
      final sections = rows
          .whereType<Map>()
          .map((row) => MenuSection.fromMap(row.cast<String, dynamic>()))
          .toList();
      _cache.set(key, sections);
      await _writeMenuSnapshot(
        key,
        <String, dynamic>{
          'type': 'menu_sections',
          'sections': sections.map((section) => section.toMap()).toList(),
        },
      );
      await OfflineCachePrefs.saveMenuSections(menuId, sections);
      return sections;
    } catch (e) {
      final stale = _cache.getStale<List<MenuSection>>(key);
      if (stale != null) return stale;
      final local = await _readMenuSectionsSnapshot(key);
      if (local != null) return local;
      final cached = await OfflineCachePrefs.loadMenuSections(menuId);
      if (cached != null) return cached;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<MenuItem>> fetchMenuItems(
    String menuId, {
    List<MenuSection>? sections,
    bool allowV1Fallback = true,
  }) async {
    if (menuId.isEmpty) return const [];
    final key = 'menu_items|$menuId';
    final fresh = _cache.getFresh<List<MenuItem>>(key, ttl: _menuTtl);
    if (fresh != null) return fresh;
    try {
      final items = await _telemetry.traceRpc<List<MenuItem>>(
        operation: 'get_menu_items_v2',
        run: () => _getMenuItemsV2(menuId, sections: sections),
        sampleRate: 0.2,
      );
      _cache.set(key, items);
      await _writeMenuSnapshot(
        key,
        <String, dynamic>{
          'type': 'menu_items',
          'items': items.map((item) => item.toMap()).toList(),
        },
      );
      await OfflineCachePrefs.saveMenuItems(menuId, items);
      final hasSuspiciousDuplicates = _hasDuplicatedItemIds(items);
      final hasNoSectionBinding =
          (sections?.isNotEmpty ?? false) &&
          items.isNotEmpty &&
          items.every((item) => (item.sectionId ?? '').trim().isEmpty);
      if ((items.isNotEmpty &&
              !hasSuspiciousDuplicates &&
              !hasNoSectionBinding) ||
          !allowV1Fallback) {
        return items;
      }
    } catch (e) {
      if (!allowV1Fallback) {
        throw Exception(AppErrorMapper.message(e));
      }
    }

    try {
      final items = await _telemetry.traceRpc<List<MenuItem>>(
        operation: 'get_menu_items_v1_fallback',
        run: () => _getMenuItemsV1(menuId),
        sampleRate: 0.2,
      );
      _cache.set(key, items);
      await _writeMenuSnapshot(
        key,
        <String, dynamic>{
          'type': 'menu_items',
          'items': items.map((item) => item.toMap()).toList(),
        },
      );
      await OfflineCachePrefs.saveMenuItems(menuId, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<MenuItem>>(key);
      if (stale != null) return stale;
      final local = await _readMenuItemsSnapshot(key);
      if (local != null) return local;
      final cached = await OfflineCachePrefs.loadMenuItems(menuId);
      if (cached != null) return cached;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<BusinessPriceTrust> fetchBusinessPriceTrust(String businessId) async {
    try {
      final res = await client.rpc(
        'get_business_price_trust_v1',
        params: {'p_business_id': businessId},
      );
      return BusinessPriceTrust.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> submitSuggestion({
    required String businessId,
    required String? menuItemId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await createOfflineMutationIdempotencyToken(
        action: 'menu_item_suggestion_$action',
        payload: {
          'business_id': businessId,
          'menu_item_id': menuItemId,
          'action': action,
          'payload': payload,
        },
      );
      dynamic res;
      try {
        res = await client.rpc(
          'submit_menu_item_suggestion_v2',
          params: {
            'p_business_id': businessId,
            'p_menu_item_id': menuItemId,
            'p_action': action,
            'p_payload': payload,
            'p_idempotency_key': token.idempotencyKey,
          },
        );
      } catch (e) {
        if (!_isMissingRpcError(e, 'submit_menu_item_suggestion_v2')) {
          rethrow;
        }
        res = await client.rpc(
          'submit_menu_item_suggestion_v1',
          params: {
            'p_business_id': businessId,
            'p_menu_item_id': menuItemId,
            'p_action': action,
            'p_payload': payload,
          },
        );
      }
      _ensureOkResponse(res, fallbackError: 'menu_item_suggestion_failed');
      _cache.invalidatePrefix('menu_items|');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<Map<String, dynamic>>> searchFoodCatalog({
    required String query,
    int limit = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    try {
      final res = await client.rpc(
        'search_food_catalog_v1',
        params: {'p_q': trimmed, 'p_limit': limit},
      );
      final remote = (res as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
      if (remote.length >= limit) return remote;

      final local = await _localCatalog.search(trimmed, limit: limit);
      final seen = remote
          .map((e) => (e['name'] ?? '').toString().toLowerCase())
          .toSet();
      final merged = <Map<String, dynamic>>[...remote];
      for (final hit in local) {
        if (seen.contains(hit.name.toLowerCase())) continue;
        merged.add({
          'id': hit.id,
          'name': hit.name,
          'category_name': hit.categoryName,
          'category_id': hit.categoryId,
        });
        if (merged.length >= limit) break;
      }
      return merged;
    } catch (e) {
      final local = await _localCatalog.search(trimmed, limit: limit);
      if (local.isNotEmpty) {
        return local
            .map(
              (hit) => {
                'id': hit.id,
                'name': hit.name,
                'category_name': hit.categoryName,
                'category_id': hit.categoryId,
              },
            )
            .toList(growable: false);
      }
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> bumpFoodCatalogPopularity(String id) async {
    try {
      await client.rpc('bump_food_catalog_popularity_v1', params: {'p_id': id});
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<MenuItemPhoto>> fetchMenuItemPhotos(
    String menuItemId, {
    int limit = 30,
  }) async {
    try {
      final res = await client.rpc(
        'get_menu_item_photos_v1',
        params: {'p_menu_item_id': menuItemId, 'p_limit': limit},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => MenuItemPhoto.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String?> addMenuItemPhoto({
    required String menuItemId,
    required String url,
    required String urlLarge,
    required String urlThumb,
    required String provider,
  }) async {
    try {
      ensureCriticalActionAllowed(client, action: 'menu_photo_upload');
      final res = await client.rpc(
        'add_menu_item_photo_v1',
        params: {
          'p_menu_item_id': menuItemId,
          'p_url': url,
          'p_url_large': urlLarge,
          'p_url_thumb': urlThumb,
          'p_provider': provider,
        },
      );
      _cache.invalidatePrefix('menu_items|');
      if (res is Map) {
        final data = res.cast<String, dynamic>();
        if (data['ok'] == true) {
          return (data['photo_id'] ?? '').toString();
        }
        final error = data['error'];
        if (error != null) throw Exception(error.toString());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        final data = (res.first as Map).cast<String, dynamic>();
        if (data['ok'] == true) {
          return (data['photo_id'] ?? '').toString();
        }
        final error = data['error'];
        if (error != null) throw Exception(error.toString());
      }
      return null;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> voteMenuItemPhoto({
    required String photoId,
    required int vote,
  }) async {
    try {
      final token = await createOfflineMutationIdempotencyToken(
        action: 'menu_item_photo_vote',
        payload: {
          'photo_id': photoId,
          'vote': vote,
        },
      );
      try {
        final res = await client.rpc(
          'set_menu_item_photo_vote_v2',
          params: {
            'p_photo_id': photoId,
            'p_vote': vote,
            'p_idempotency_key': token.idempotencyKey,
          },
        );
        _ensureOkResponse(res, fallbackError: 'photo_vote_failed');
      } catch (e) {
        if (!_isMissingRpcError(e, 'set_menu_item_photo_vote_v2')) {
          rethrow;
        }
        await _submitDesiredPhotoVoteLegacy(
          client: client,
          photoId: photoId,
          desiredVote: vote,
        );
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

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
        _ensureOkResponse(res, fallbackError: 'price_vote_failed');
      } catch (e) {
        if (!_isMissingRpcError(e, 'set_menu_item_price_vote_v2')) {
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
      if (queueOnOffline && _isLikelyOfflineError(e)) {
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
    final resolvedClientId =
        (clientId ?? await getAnalyticsClientId()).trim();
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
            'p_client_id': resolvedClientId.isEmpty
                ? null
                : resolvedClientId,
            'p_captured_at': capturedAtValue.toIso8601String(),
            'p_idempotency_key': queuedPayload['idempotency_key'],
          },
        );
      } catch (e) {
        if (!_isMissingRpcError(e, 'submit_menu_item_price_suggestion_v5')) {
          rethrow;
        }
        try {
          res = await client.rpc(
            'submit_menu_item_price_suggestion_v3',
            params: {
              ...params,
              'p_client_id': resolvedClientId.isEmpty
                  ? null
                  : resolvedClientId,
              'p_captured_at': capturedAtValue.toIso8601String(),
            },
          );
        } catch (legacyError) {
          if (!_isMissingRpcError(
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
      if (queueOnOffline && _isLikelyOfflineError(e)) {
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
          final vote = _asInt(item.payload['vote']) ?? 0;
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
          final cents = _asInt(item.payload['suggested_price_cents']) ?? 0;
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

  Future<MenuItemPriceStatus> fetchMenuItemPriceStatus(String menuItemId) async {
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

  Future<Map<String, _MenuItemPriceStatusSnapshot>> _getMenuItemPriceStatusMap(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return const {};
    try {
      final res = await client
          .from('menu_item_price_status_v1')
          .select('menu_item_id, price_status, total_30d')
          .inFilter('menu_item_id', itemIds);
      final rows = (res as List?) ?? const [];
      final map = <String, _MenuItemPriceStatusSnapshot>{};
      for (final row in rows) {
        if (row is! Map) continue;
        final data = row.cast<String, dynamic>();
        final id = (data['menu_item_id'] ?? '').toString();
        if (id.isEmpty) continue;
        final total = data['total_30d'];
        map[id] = _MenuItemPriceStatusSnapshot(
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

  Future<List<MenuItem>> _getMenuItemsV2(
    String menuId, {
    List<MenuSection>? sections,
    int limit = 200,
    int offset = 0,
  }) async {
    final resolvedSections = sections ?? await fetchMenuSections(menuId);
    final sectionIds = resolvedSections
        .map((section) => section.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (sectionIds.isEmpty) return const [];

    final responses = await Future.wait(
      sectionIds.map(
        (id) => client.rpc(
          'get_menu_items_v2',
          params: {'p_section_id': id, 'p_limit': limit, 'p_offset': offset},
        ),
      ),
    );
    final items = <MenuItem>[];
    for (final res in responses) {
      final rows = (res as List?) ?? const [];
      items.addAll(
        rows.whereType<Map>().map(
          (row) => MenuItem.fromMap(row.cast<String, dynamic>()),
        ),
      );
    }
    if (items.isEmpty) return items;
    final byId = <String, MenuItem>{};
    for (final item in items) {
      final id = item.id.trim();
      if (id.isEmpty) continue;
      byId[id] = byId[id] ?? item;
    }
    return byId.values.toList(growable: false);
  }

  Future<List<MenuItem>> _getMenuItemsV1(String menuId) async {
    final res = await client.rpc(
      'get_menu_items_v1',
      params: {'p_menu_id': menuId},
    );
    final rows = (res as List?) ?? const [];
    final items = rows
        .whereType<Map>()
        .map((row) => MenuItem.fromMap(row.cast<String, dynamic>()))
        .toList();
    if (items.isEmpty) return items;

    final ids = items
        .map((item) => item.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return items;

    final statusMap = await _getMenuItemPriceStatusMap(ids);
    if (statusMap.isEmpty) return items;

    return items.map((item) {
      final status = statusMap[item.id];
      if (status == null) return item;
      return item.copyWith(
        priceStatus: status.priceStatus,
        total30d: status.total30d,
      );
    }).toList();
  }

  Future<void> _writeMenuSnapshot(
    String id,
    Map<String, dynamic> payload,
  ) {
    return _localDb.upsert(
      bucket: LocalDbBucket.menuSnapshot,
      id: id,
      payload: payload,
      expiresAt: DateTime.now().toUtc().add(_offlineSnapshotTtl),
    );
  }

  Future<List<BusinessMenu>?> _readBusinessMenusSnapshot(String id) async {
    final record = await _localDb.read(
      LocalDbBucket.menuSnapshot,
      id,
      allowExpired: true,
    );
    final menus = record?.payload['menus'];
    if (menus is! List) return null;
    return menus
        .whereType<Map>()
        .map((row) => BusinessMenu.fromMap(row.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<MenuSection>?> _readMenuSectionsSnapshot(String id) async {
    final record = await _localDb.read(
      LocalDbBucket.menuSnapshot,
      id,
      allowExpired: true,
    );
    final sections = record?.payload['sections'];
    if (sections is! List) return null;
    return sections
        .whereType<Map>()
        .map((row) => MenuSection.fromMap(row.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<MenuItem>?> _readMenuItemsSnapshot(String id) async {
    final record = await _localDb.read(
      LocalDbBucket.menuSnapshot,
      id,
      allowExpired: true,
    );
    final items = record?.payload['items'];
    if (items is! List) return null;
    return items
        .whereType<Map>()
        .map((row) => MenuItem.fromMap(row.cast<String, dynamic>()))
        .toList(growable: false);
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
}

bool _hasDuplicatedItemIds(List<MenuItem> items) {
  if (items.length < 2) return false;
  final ids = <String>{};
  for (final item in items) {
    final id = item.id.trim();
    if (id.isEmpty) continue;
    if (!ids.add(id)) return true;
  }
  return false;
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

bool _isLikelyOfflineError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection closed before full header was received') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('timed out') ||
      text.contains('timeout');
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
      params: {
        'p_menu_item_id': menuItemId,
        'p_vote': currentVote,
      },
    );
    _ensureOkResponse(res, fallbackError: 'price_vote_failed');
    return;
  }
  final res = await client.rpc(
    'vote_menu_item_price_v1',
    params: {'p_menu_item_id': menuItemId, 'p_vote': desiredVote},
  );
  _ensureOkResponse(res, fallbackError: 'price_vote_failed');
}

Future<void> _submitDesiredPhotoVoteLegacy({
  required SupabaseClient client,
  required String photoId,
  required int desiredVote,
}) async {
  final currentVote = await _readCurrentUserMenuItemPhotoVote(
    client,
    photoId: photoId,
  );
  if (currentVote == desiredVote) return;
  if (desiredVote == 0) {
    if (currentVote == null || currentVote == 0) return;
    final res = await client.rpc(
      'vote_menu_item_photo_v1',
      params: {
        'p_photo_id': photoId,
        'p_vote': currentVote,
      },
    );
    _ensureOkResponse(res, fallbackError: 'photo_vote_failed');
    return;
  }
  final res = await client.rpc(
    'vote_menu_item_photo_v1',
    params: {'p_photo_id': photoId, 'p_vote': desiredVote},
  );
  _ensureOkResponse(res, fallbackError: 'photo_vote_failed');
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
  return _asInt((res as Map)['vote']);
}

Future<int?> _readCurrentUserMenuItemPhotoVote(
  SupabaseClient client, {
  required String photoId,
}) async {
  final res = await client
      .from('menu_item_photo_votes')
      .select('vote')
      .eq('photo_id', photoId)
      .maybeSingle();
  if (res == null) return null;
  return _asInt((res as Map)['vote']);
}

void _ensureOkResponse(dynamic res, {required String fallbackError}) {
  if (res is Map) {
    final data = res.cast<String, dynamic>();
    if (data['ok'] == true) return;
    final error = (data['error'] ?? '').toString().trim();
    throw Exception(error.isEmpty ? fallbackError : error);
  }
  if (res is List && res.isNotEmpty && res.first is Map) {
    _ensureOkResponse((res.first as Map).cast<String, dynamic>(), fallbackError: fallbackError);
    return;
  }
  throw Exception(fallbackError);
}

bool _isMissingRpcError(Object error, String rpcName) {
  final text = error.toString().toLowerCase();
  final normalized = rpcName.toLowerCase();
  return text.contains(normalized) &&
      (text.contains('could not find') ||
          text.contains('does not exist') ||
          text.contains('not found') ||
          text.contains('undefined function') ||
          text.contains('pgrst202'));
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}

class _MenuItemPriceStatusSnapshot {
  const _MenuItemPriceStatusSnapshot({
    required this.priceStatus,
    required this.total30d,
  });

  final String priceStatus;
  final int? total30d;
}
