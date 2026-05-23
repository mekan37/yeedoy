import '../../../core/i18n/app_localizations.dart';

enum ReviewRatingCriterion {
  taste,
  serviceSpeed,
  pricePerformance,
  cleanliness,
  atmosphere,
}

class ReviewCriterion {
  const ReviewCriterion({
    required this.criterion,
    required this.key,
    required this.reviewField,
    required this.summaryField,
    required this.rpcParameter,
  });

  final ReviewRatingCriterion criterion;
  final String key;
  final String reviewField;
  final String summaryField;
  final String rpcParameter;
}

class ReviewCatalog {
  const ReviewCatalog._();

  static const List<ReviewCriterion> definitions = [
    ReviewCriterion(
      criterion: ReviewRatingCriterion.taste,
      key: 'taste',
      reviewField: 'taste_rating',
      summaryField: 'avg_taste_rating',
      rpcParameter: 'p_taste_rating',
    ),
    ReviewCriterion(
      criterion: ReviewRatingCriterion.serviceSpeed,
      key: 'service_speed',
      reviewField: 'service_speed_rating',
      summaryField: 'avg_service_speed_rating',
      rpcParameter: 'p_service_speed_rating',
    ),
    ReviewCriterion(
      criterion: ReviewRatingCriterion.pricePerformance,
      key: 'price_performance',
      reviewField: 'price_performance_rating',
      summaryField: 'avg_price_performance_rating',
      rpcParameter: 'p_price_performance_rating',
    ),
    ReviewCriterion(
      criterion: ReviewRatingCriterion.cleanliness,
      key: 'cleanliness',
      reviewField: 'cleanliness_rating',
      summaryField: 'avg_cleanliness_rating',
      rpcParameter: 'p_cleanliness_rating',
    ),
    ReviewCriterion(
      criterion: ReviewRatingCriterion.atmosphere,
      key: 'atmosphere',
      reviewField: 'atmosphere_rating',
      summaryField: 'avg_atmosphere_rating',
      rpcParameter: 'p_atmosphere_rating',
    ),
  ];

  static final Map<ReviewRatingCriterion, ReviewCriterion>
  _byCriterion = {
    for (final definition in definitions) definition.criterion: definition,
  };

  static ReviewCriterion definitionFor(
    ReviewRatingCriterion criterion,
  ) {
    return _byCriterion[criterion]!;
  }

  static Map<ReviewRatingCriterion, int?> emptySelection() {
    return {
      for (final definition in definitions) definition.criterion: null,
    };
  }

  static Map<ReviewRatingCriterion, double?> emptyAverageSelection() {
    return {
      for (final definition in definitions) definition.criterion: null,
    };
  }

  static Map<String, dynamic> buildRpcParams(
    Map<ReviewRatingCriterion, int?> ratings,
  ) {
    final params = <String, dynamic>{};
    for (final entry in ratings.entries) {
      final value = entry.value;
      if (value == null) continue;
      final definition = _byCriterion[entry.key];
      if (definition == null) continue;
      params[definition.rpcParameter] = value;
    }
    return params;
  }

  static Map<String, dynamic> buildReviewPayload(
    Map<ReviewRatingCriterion, int?> ratings,
  ) {
    final payload = <String, dynamic>{};
    for (final entry in ratings.entries) {
      final value = entry.value;
      if (value == null) continue;
      final definition = _byCriterion[entry.key];
      if (definition == null) continue;
      payload[definition.reviewField] = value;
    }
    return payload;
  }

  static Map<ReviewRatingCriterion, int?> parseReviewRatings(
    Map<String, dynamic> map,
  ) {
    final ratings = emptySelection();
    for (final definition in definitions) {
      ratings[definition.criterion] = _asInt(map[definition.reviewField]);
    }
    return ratings;
  }

  static Map<ReviewRatingCriterion, double?> parseSummaryAverages(
    Map<String, dynamic> map,
  ) {
    final averages = emptyAverageSelection();
    for (final definition in definitions) {
      averages[definition.criterion] = _asDouble(map[definition.summaryField]);
    }
    return averages;
  }

  static int selectedCount(Map<ReviewRatingCriterion, int?> ratings) {
    var count = 0;
    for (final value in ratings.values) {
      if (value != null) count += 1;
    }
    return count;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }

  static double? _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString());
  }
}

extension ReviewCriterionL10n on ReviewCriterion {
  String label(AppLocalizations t) {
    switch (criterion) {
      case ReviewRatingCriterion.taste:
        return t.reviewRatingCriterionTaste;
      case ReviewRatingCriterion.serviceSpeed:
        return t.reviewRatingCriterionServiceSpeed;
      case ReviewRatingCriterion.pricePerformance:
        return t.reviewRatingCriterionPricePerformance;
      case ReviewRatingCriterion.cleanliness:
        return t.reviewRatingCriterionCleanliness;
      case ReviewRatingCriterion.atmosphere:
        return t.reviewRatingCriterionAtmosphere;
    }
  }
}
