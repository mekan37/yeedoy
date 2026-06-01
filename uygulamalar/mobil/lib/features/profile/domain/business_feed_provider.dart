import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';

class BusinessFeedEvent {
  BusinessFeedEvent({
    required this.eventId,
    required this.businessId,
    required this.type,
    required this.refId,
    required this.meta,
    required this.createdAt,
  });

  final String eventId;
  final String businessId;
  final String type;
  final String? refId;
  final Map<String, dynamic> meta;
  final DateTime createdAt;

  factory BusinessFeedEvent.fromMap(Map<String, dynamic> map) {
    return BusinessFeedEvent(
      eventId: (map['event_id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      refId: (map['ref_id'] ?? '').toString().isEmpty
          ? null
          : (map['ref_id'] ?? '').toString(),
      meta: (map['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class BusinessFeedItem {
  BusinessFeedItem({
    required this.event,
    required this.businessName,
    required this.businessCategory,
  });

  final BusinessFeedEvent event;
  final String businessName;
  final String businessCategory;
}

class BusinessFeedParams {
  const BusinessFeedParams({this.limit = 20, this.offset = 0});
  final int limit;
  final int offset;
}

final businessFeedProvider =
    FutureProvider.autoDispose.family<List<BusinessFeedItem>, BusinessFeedParams>((
      ref,
      params,
    ) async {
      final client = ref.watch(supabaseProvider);
      try {
        final res = await client.rpc(
          'get_my_feed_v1',
          params: {'p_limit': params.limit, 'p_offset': params.offset},
        );
        final rows = (res as List?) ?? const [];
        final events = rows
            .whereType<Map>()
            .map(
              (row) => BusinessFeedEvent.fromMap(row.cast<String, dynamic>()),
            )
            .where((e) => e.businessId.isNotEmpty)
            .toList();
        if (events.isEmpty) return const [];

        final ids = events.map((e) => e.businessId).toSet().toList();
        final bizRes = await client
            .from('businesses')
            .select('id,name,category')
            .inFilter('id', ids);
        final bizMap = <String, Map<String, String>>{};
        for (final row in (bizRes as List?) ?? const []) {
          if (row is! Map) continue;
          final data = row.cast<String, dynamic>();
          final id = (data['id'] ?? '').toString();
          if (id.isEmpty) continue;
          bizMap[id] = {
            'name': (data['name'] ?? '').toString(),
            'category': (data['category'] ?? '').toString(),
          };
        }

        return [
          for (final event in events)
            BusinessFeedItem(
              event: event,
              businessName: bizMap[event.businessId]?['name'] ?? 'İşletme',
              businessCategory: bizMap[event.businessId]?['category'] ?? '',
            ),
        ];
      } catch (e) {
        throw Exception(AppErrorMapper.message(e));
      }
    });

