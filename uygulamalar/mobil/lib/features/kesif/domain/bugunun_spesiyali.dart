import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/onbellek/istek_onbellegi.dart';

class TodaySpecialItem {
  TodaySpecialItem({
    required this.menuItemId,
    required this.itemName,
    this.specialNote,
    this.priceCents,
    this.currency = 'TRY',
    required this.businessId,
    required this.businessName,
    required this.businessSlug,
    this.city,
    this.distanceKm,
  });

  final String menuItemId;
  final String itemName;
  final String? specialNote;
  final int? priceCents;
  final String currency;
  final String businessId;
  final String businessName;
  final String businessSlug;
  final String? city;
  final double? distanceKm;

  double? get priceValue => priceCents != null ? priceCents! / 100.0 : null;

  factory TodaySpecialItem.fromMap(Map<String, dynamic> m) => TodaySpecialItem(
    menuItemId: m['menu_item_id']?.toString() ?? '',
    itemName: m['item_name']?.toString() ?? '',
    specialNote: m['special_note']?.toString(),
    priceCents: (m['price_cents'] as num?)?.toInt(),
    currency: m['currency']?.toString() ?? 'TRY',
    businessId: m['business_id']?.toString() ?? '',
    businessName: m['business_name']?.toString() ?? '',
    businessSlug: m['business_slug']?.toString() ?? '',
    city: m['city']?.toString(),
    distanceKm: (m['distance_km'] as num?)?.toDouble(),
  );
}

/// Provider: kullanıcının şehrindeki bugünün spesiyallerini çeker.
/// Konum veriliyse mesafe bazlı sıralar.
final todaySpecialsProvider = FutureProvider.family<
  List<TodaySpecialItem>,
  ({String? city, double? lat, double? lng})
>((ref, args) async {
  final key = stableRequestCacheKey('today_specials', {
    'city': args.city,
    'lat': args.lat?.toStringAsFixed(2),
    'lng': args.lng?.toStringAsFixed(2),
  });

  final cache = ref.watch(requestCacheProvider).scope('specials');
  final fresh = cache.getFresh<List<TodaySpecialItem>>(
    key,
    ttl: const Duration(minutes: 10),
  );
  if (fresh != null) return fresh;

  final client = ref.watch(supabaseProvider);
  final res = await client.rpc('get_today_specials_v1', params: {
    'p_city': args.city,
    'p_lat': args.lat,
    'p_lng': args.lng,
    'p_radius_km': 15.0,
    'p_limit': 10,
  });

  final items = (res as List)
      .whereType<Map>()
      .map((row) => TodaySpecialItem.fromMap(row.cast<String, dynamic>()))
      .toList(growable: false);

  cache.set(key, items);
  return items;
});
