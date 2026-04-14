import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';

enum OwnerReviewRatingCriterion {
  taste,
  serviceSpeed,
  pricePerformance,
  cleanliness,
  atmosphere,
}

class OwnerReviewCriterion {
  const OwnerReviewCriterion({
    required this.criterion,
    required this.summaryField,
  });

  final OwnerReviewRatingCriterion criterion;
  final String summaryField;
}

class OwnerReviewRatingSummary {
  const OwnerReviewRatingSummary({
    required this.businessId,
    required this.ratingCount,
    required this.avgOverallRating,
    required this.criterionAverages,
  });

  final String businessId;
  final int ratingCount;
  final double? avgOverallRating;
  final Map<OwnerReviewRatingCriterion, double?> criterionAverages;

  bool get hasAnyRatings => ratingCount > 0 || avgOverallRating != null;

  bool get hasDetailedRatings =>
      criterionAverages.values.any((value) => value != null);

  double? averageFor(OwnerReviewRatingCriterion criterion) {
    return criterionAverages[criterion];
  }

  factory OwnerReviewRatingSummary.fromMap(Map<String, dynamic> map) {
    return OwnerReviewRatingSummary(
      businessId: (map['business_id'] ?? '').toString(),
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
      avgOverallRating: (map['avg_overall_rating'] as num?)?.toDouble(),
      criterionAverages: {
        for (final definition in ownerReviewRatingCriteria)
          definition.criterion:
              (map[definition.summaryField] as num?)?.toDouble(),
      },
    );
  }
}

const List<OwnerReviewCriterion> ownerReviewRatingCriteria = [
  OwnerReviewCriterion(
    criterion: OwnerReviewRatingCriterion.taste,
    summaryField: 'avg_taste_rating',
  ),
  OwnerReviewCriterion(
    criterion: OwnerReviewRatingCriterion.serviceSpeed,
    summaryField: 'avg_service_speed_rating',
  ),
  OwnerReviewCriterion(
    criterion: OwnerReviewRatingCriterion.pricePerformance,
    summaryField: 'avg_price_performance_rating',
  ),
  OwnerReviewCriterion(
    criterion: OwnerReviewRatingCriterion.cleanliness,
    summaryField: 'avg_cleanliness_rating',
  ),
  OwnerReviewCriterion(
    criterion: OwnerReviewRatingCriterion.atmosphere,
    summaryField: 'avg_atmosphere_rating',
  ),
];

final ownerReviewRatingSummaryProvider =
    FutureProvider.family<OwnerReviewRatingSummary?, String?>(
      (ref, businessId) async {
        if (businessId == null || businessId.trim().isEmpty) return null;
        final client = ref.watch(supabaseProvider);
        try {
          final res = await client.rpc(
            'get_business_rating_summary_v1',
            params: {'p_business_id': businessId},
          );
          if (res is Map) {
            return OwnerReviewRatingSummary.fromMap(
              res.cast<String, dynamic>(),
            );
          }
          if (res is List && res.isNotEmpty && res.first is Map) {
            return OwnerReviewRatingSummary.fromMap(
              (res.first as Map).cast<String, dynamic>(),
            );
          }
          return null;
        } catch (e) {
          throw Exception(AppErrorMapper.message(e));
        }
      },
    );
