import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/errors/app_error_mapper.dart';
import 'compare_controller.dart';

class CompareBusiness {
  CompareBusiness({
    required this.businessId,
    required this.name,
    required this.city,
    required this.district,
    required this.medianPriceCents,
    required this.verifiedRatio,
    required this.lastUpdateAt,
    required this.cheapestItemName,
    required this.cheapestItemPriceCents,
  });

  final String businessId;
  final String name;
  final String city;
  final String district;
  final int? medianPriceCents;
  final double? verifiedRatio;
  final DateTime? lastUpdateAt;
  final String? cheapestItemName;
  final int? cheapestItemPriceCents;
}

final compareBusinessesProvider = FutureProvider.autoDispose<List<CompareBusiness>>((ref) async {
  final ids = ref.watch(compareControllerProvider);
  if (ids.isEmpty) return const [];

  final client = ref.watch(supabaseProvider);
  try {
    final compareRes = await client.rpc('get_business_compare_v1', params: {
      'p_business_ids': ids,
    });
    final compareRows = (compareRes as List?) ?? const [];
    final compareMap = <String, Map<String, dynamic>>{};
    for (final row in compareRows) {
      if (row is! Map) continue;
      final data = row.cast<String, dynamic>();
      final id = (data['business_id'] ?? '').toString();
      if (id.isEmpty) continue;
      compareMap[id] = data;
    }

    final bizRes = await client
        .from('businesses')
        .select('id,name,city,district')
        .inFilter('id', ids);
    final bizRows = (bizRes as List?) ?? const [];

    final itemRes = await client
        .from('menu_items')
        .select('business_id,name,price_cents')
        .inFilter('business_id', ids)
        .eq('status', 'published')
        .not('price_cents', 'is', null)
        .order('price_cents', ascending: true);
    final itemRows = (itemRes as List?) ?? const [];
    final cheapestByBiz = <String, Map<String, dynamic>>{};
    for (final row in itemRows) {
      if (row is! Map) continue;
      final data = row.cast<String, dynamic>();
      final id = (data['business_id'] ?? '').toString();
      if (id.isEmpty || cheapestByBiz.containsKey(id)) continue;
      cheapestByBiz[id] = data;
    }

    final items = <CompareBusiness>[];
    for (final row in bizRows) {
      if (row is! Map) continue;
      final data = row.cast<String, dynamic>();
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final compare = compareMap[id] ?? const {};
      final cheapest = cheapestByBiz[id] ?? const {};
      items.add(
        CompareBusiness(
          businessId: id,
          name: (data['name'] ?? '').toString(),
          city: (data['city'] ?? '').toString(),
          district: (data['district'] ?? '').toString(),
          medianPriceCents: _toInt(compare['median_price_cents']),
          verifiedRatio: _toDouble(compare['verified_ratio']),
          lastUpdateAt: _toDate(compare['last_update_at']),
          cheapestItemName: (cheapest['name'] ?? '').toString(),
          cheapestItemPriceCents: _toInt(cheapest['price_cents']),
        ),
      );
    }

    return items;
  } catch (e) {
    throw Exception(AppErrorMapper.message(e));
  }
});

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
