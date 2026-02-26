import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/inbox_models.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(ref.watch(supabaseProvider));
});

class InboxRepository {
  InboxRepository(this.client);
  final SupabaseClient client;

  Future<List<InboxItem>> listInboxItems({int limit = 60}) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final tableItems = await _listDbNotifications(
        userId: userId,
        limit: limit,
      );
      final legacyItems = await _listLegacyNotifications(
        userId: userId,
        limit: limit,
      );
      final existingIds = tableItems.map((e) => e.id).toSet();
      final merged = <InboxItem>[
        ...tableItems,
        ...legacyItems.where((e) => !existingIds.contains(e.id)),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged.take(limit).toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<InboxItem>> _listDbNotifications({
    required String userId,
    required int limit,
  }) async {
    List rows = const [];
    try {
      final dynamic res = await client
          .from('notifications')
          .select('id,type,title,body,data,is_read,created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      if (res is List) rows = res;
    } catch (_) {
      return const [];
    }

    return rows.whereType<Map>().map((row) {
      final map = row.cast<String, dynamic>();
      final id = (map['id'] ?? '').toString();
      final data =
          (map['data'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final targetPath = _targetPathFromNotification(
        type: (map['type'] ?? '').toString(),
        data: data,
      );
      return InboxItem(
        id: 'db_$id',
        type: (map['type'] ?? '').toString(),
        title: (map['title'] ?? 'Bildirim').toString(),
        message: (map['body'] ?? '').toString(),
        createdAt:
            DateTime.tryParse((map['created_at'] ?? '').toString()) ??
            DateTime.now(),
        targetPath: targetPath,
        isRead: map['is_read'] == true,
        meta: {'notification_id': id, ...data},
      );
    }).toList();
  }

  String _targetPathFromNotification({
    required String type,
    required Map<String, dynamic> data,
  }) {
    final businessId = (data['business_id'] ?? '').toString();
    final menuItemId = (data['menu_item_id'] ?? '').toString();
    switch (type) {
      case 'price_verification_result':
      case 'favorite_price_changed':
      case 'owner_new_price_suggestion':
        if (businessId.isNotEmpty && menuItemId.isNotEmpty) {
          return '/b/$businessId/menu-item/$menuItemId';
        }
        if (businessId.isNotEmpty) return '/b/$businessId';
        return '/inbox';
      case 'review_reply':
      case 'owner_new_review':
        if (businessId.isNotEmpty) return '/b/$businessId/reviews';
        return '/inbox';
      case 'owner_business_reported':
        if (businessId.isNotEmpty) return '/owner/businesses';
        return '/owner';
      case 'claim_result':
        return '/my-claims';
      case 'achievement_unlocked':
        return '/profile';
      case 'nearby_trending':
        return '/discover';
      case 'owner_daily_summary':
        return '/owner';
      default:
        if (businessId.isNotEmpty) return '/b/$businessId';
        return '/inbox';
    }
  }

  Future<List<InboxItem>> _listLegacyNotifications({
    required String userId,
    required int limit,
  }) async {
    final priceRows = await client
        .from('menu_item_price_suggestions')
        .select(
          'id,status,created_at,menu_item_id,business_id,suggested_price_cents',
        )
        .eq('created_by', userId)
        .inFilter('status', ['approved', 'rejected'])
        .order('created_at', ascending: false)
        .limit(limit);

    final claimRows = await client
        .from('owner_claims')
        .select('id,status,created_at,business_id,admin_note')
        .eq('user_id', userId)
        .inFilter('status', ['approved', 'rejected'])
        .order('created_at', ascending: false)
        .limit(limit);

    final reportRows = await client
        .from('reports')
        .select(
          'id,status,created_at,business_id,review_id,menu_item_photo_id,reason',
        )
        .eq('user_id', userId)
        .inFilter('status', ['closed', 'rejected', 'kapandi', 'reddedildi'])
        .order('created_at', ascending: false)
        .limit(limit);

    final businessIds = <String>{
      for (final row in (priceRows as List).whereType<Map>())
        (row['business_id'] ?? '').toString(),
      for (final row in (claimRows as List).whereType<Map>())
        (row['business_id'] ?? '').toString(),
      for (final row in (reportRows as List).whereType<Map>())
        (row['business_id'] ?? '').toString(),
    }.where((e) => e.isNotEmpty).toList();

    final businessNames = <String, String>{};
    if (businessIds.isNotEmpty) {
      final bizRes = await client
          .from('businesses')
          .select('id,name')
          .inFilter('id', businessIds);
      for (final row in (bizRes as List).whereType<Map>()) {
        final map = row.cast<String, dynamic>();
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;
        businessNames[id] = (map['name'] ?? '').toString();
      }
    }

    final items = <InboxItem>[];

    for (final row in (priceRows).whereType<Map>()) {
      final map = row.cast<String, dynamic>();
      final id = (map['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final status = (map['status'] ?? '').toString();
      final businessId = (map['business_id'] ?? '').toString();
      final menuItemId = (map['menu_item_id'] ?? '').toString();
      final cents = (map['suggested_price_cents'] as num?)?.toInt();
      final businessName = businessNames[businessId] ?? 'İşletme';
      final priceText = cents == null
          ? ''
          : ' (${(cents / 100).toStringAsFixed(0)} TL)';
      items.add(
        InboxItem(
          id: 'price_$id',
          type: 'price_verification_result',
          title: status == 'approved'
              ? 'Fiyat doğrulama onaylandi'
              : 'Fiyat doğrulama reddedildi',
          message: '$businessName için fiyat önerisi sonuçlandı$priceText.',
          createdAt:
              DateTime.tryParse((map['created_at'] ?? '').toString()) ??
              DateTime.now(),
          targetPath: menuItemId.isNotEmpty && businessId.isNotEmpty
              ? '/b/$businessId/menu-item/$menuItemId'
              : '/profile',
          isRead: false,
          meta: {'status': status, 'business_id': businessId},
        ),
      );
    }

    for (final row in (claimRows).whereType<Map>()) {
      final map = row.cast<String, dynamic>();
      final id = (map['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final status = (map['status'] ?? '').toString();
      final businessId = (map['business_id'] ?? '').toString();
      final businessName = businessNames[businessId] ?? 'İşletme';
      final note = (map['admin_note'] ?? '').toString().trim();
      items.add(
        InboxItem(
          id: 'claim_$id',
          type: 'claim_result',
          title: status == 'approved' ? 'Claim onaylandi' : 'Claim reddedildi',
          message: note.isEmpty
              ? '$businessName claim talebi: $status.'
              : '$businessName: $note',
          createdAt:
              DateTime.tryParse((map['created_at'] ?? '').toString()) ??
              DateTime.now(),
          targetPath: '/my-claims',
          isRead: false,
          meta: {'status': status, 'business_id': businessId},
        ),
      );
    }

    for (final row in (reportRows).whereType<Map>()) {
      final map = row.cast<String, dynamic>();
      final id = (map['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final status = (map['status'] ?? '').toString();
      final businessId = (map['business_id'] ?? '').toString();
      final title = (status == 'closed' || status == 'kapandi')
          ? 'Bildirim cozuldu'
          : 'Bildirim reddedildi';
      final message = businessId.isEmpty
          ? 'Gönderdigin bildirim sonuclandi.'
          : '${businessNames[businessId] ?? 'Icerik'} icin bildirim sonuclandi.';
      items.add(
        InboxItem(
          id: 'report_$id',
          type: 'report_result',
          title: title,
          message: message,
          createdAt:
              DateTime.tryParse((map['created_at'] ?? '').toString()) ??
              DateTime.now(),
          targetPath: businessId.isNotEmpty ? '/b/$businessId' : '/inbox',
          isRead: false,
          meta: {'status': status, 'business_id': businessId},
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  Future<void> markRead(String id) async {
    if (!id.startsWith('db_')) return;
    final notificationId = id.replaceFirst('db_', '');
    await client.rpc(
      'mark_notification_read_v1',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<void> markAllRead() async {
    await client.rpc('mark_all_notifications_read_v1');
  }

  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
    String? appVersion,
  }) async {
    await client.rpc(
      'register_user_device_v1',
      params: {
        'p_fcm_token': fcmToken,
        'p_platform': platform,
        'p_app_version': appVersion,
      },
    );
  }

  Future<void> unregisterDevice({String? fcmToken}) async {
    await client.rpc(
      'unregister_user_device_v1',
      params: {
        'p_fcm_token': (fcmToken ?? '').trim().isEmpty
            ? null
            : fcmToken!.trim(),
      },
    );
  }
}
