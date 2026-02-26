import 'business_card.dart';
import 'regional_price_index.dart';
import 'trend_business.dart';

class HomeFeedData {
  const HomeFeedData({
    required this.nearOpenBusinesses,
    required this.topCategories,
    required this.topViews,
    required this.priceChanges,
    required this.nightFavorites,
    required this.generatedAt,
  });

  final List<BusinessCardModel> nearOpenBusinesses;
  final List<RegionalPriceIndexItem> topCategories;
  final List<TrendBusiness> topViews;
  final List<TrendBusiness> priceChanges;
  final List<TrendBusiness> nightFavorites;
  final DateTime? generatedAt;

  factory HomeFeedData.fromMap(Map<String, dynamic> map) {
    List<T> readList<T>(String key, T Function(Map<String, dynamic>) parser) {
      final raw = map[key];
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map>()
          .map((e) => parser(e.cast<String, dynamic>()))
          .toList();
    }

    List<TrendBusiness> readTrend(String key, String metricField) {
      final raw = map[key];
      if (raw is! List) return const <TrendBusiness>[];
      return raw.whereType<Map>().map((e) {
        final data = e.cast<String, dynamic>();
        return TrendBusiness(
          business: BusinessCardModel.fromMap(data),
          metric: (data[metricField] as num?)?.toInt() ?? 0,
        );
      }).toList();
    }

    return HomeFeedData(
      nearOpenBusinesses: readList(
        'near_open_businesses',
        BusinessCardModel.fromMap,
      ),
      topCategories: readList('top_categories', RegionalPriceIndexItem.fromMap),
      topViews: readTrend('trending_top_views', 'views_count'),
      priceChanges: readTrend('trending_price_changes', 'price_changes_count'),
      nightFavorites: readTrend('trending_night_favorites', 'favorites_count'),
      generatedAt: DateTime.tryParse((map['generated_at'] ?? '').toString()),
    );
  }

  static HomeFeedData empty() => const HomeFeedData(
    nearOpenBusinesses: <BusinessCardModel>[],
    topCategories: <RegionalPriceIndexItem>[],
    topViews: <TrendBusiness>[],
    priceChanges: <TrendBusiness>[],
    nightFavorites: <TrendBusiness>[],
    generatedAt: null,
  );
}
