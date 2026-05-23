import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/product_guardrails_prefs.dart';
import 'product_guardrails.dart';

class ProductGuardrailOverrides {
  const ProductGuardrailOverrides({
    required this.requireSponsoredLabel,
    required this.minSponsoredTrustScore,
    required this.minSponsoredRating,
    required this.ownerCanDeleteReviews,
    required this.allowLowQualityGrowthBypass,
  });

  final bool requireSponsoredLabel;
  final double minSponsoredTrustScore;
  final double minSponsoredRating;
  final bool ownerCanDeleteReviews;
  final bool allowLowQualityGrowthBypass;

  factory ProductGuardrailOverrides.defaults() =>
      const ProductGuardrailOverrides(
        requireSponsoredLabel: ProductGuardrails.requireSponsoredLabel,
        minSponsoredTrustScore: ProductGuardrails.minSponsoredTrustScore,
        minSponsoredRating: ProductGuardrails.minSponsoredRating,
        ownerCanDeleteReviews: ProductGuardrails.ownerCanDeleteReviews,
        allowLowQualityGrowthBypass:
            ProductGuardrails.allowLowQualityGrowthBypass,
      );

  ProductGuardrailOverrides copyWith({
    bool? requireSponsoredLabel,
    double? minSponsoredTrustScore,
    double? minSponsoredRating,
    bool? ownerCanDeleteReviews,
    bool? allowLowQualityGrowthBypass,
  }) {
    return ProductGuardrailOverrides(
      requireSponsoredLabel:
          requireSponsoredLabel ?? this.requireSponsoredLabel,
      minSponsoredTrustScore:
          minSponsoredTrustScore ?? this.minSponsoredTrustScore,
      minSponsoredRating: minSponsoredRating ?? this.minSponsoredRating,
      ownerCanDeleteReviews:
          ownerCanDeleteReviews ?? this.ownerCanDeleteReviews,
      allowLowQualityGrowthBypass:
          allowLowQualityGrowthBypass ?? this.allowLowQualityGrowthBypass,
    );
  }
}

final productGuardrailOverridesProvider =
    NotifierProvider<
      ProductGuardrailOverridesController,
      ProductGuardrailOverrides
    >(ProductGuardrailOverridesController.new);

class ProductGuardrailOverridesController
    extends Notifier<ProductGuardrailOverrides> {
  @override
  ProductGuardrailOverrides build() {
    Future.microtask(_loadFromPrefs);
    return ProductGuardrailOverrides.defaults();
  }

  Future<void> _loadFromPrefs() async {
    final raw = await ProductGuardrailsPrefs.read();
    state = state.copyWith(
      requireSponsoredLabel:
          raw[ProductGuardrailsPrefs.requireSponsoredLabelKey] as bool?,
      minSponsoredTrustScore:
          raw[ProductGuardrailsPrefs.minSponsoredTrustScoreKey] as double?,
      minSponsoredRating:
          raw[ProductGuardrailsPrefs.minSponsoredRatingKey] as double?,
      ownerCanDeleteReviews:
          raw[ProductGuardrailsPrefs.ownerCanDeleteReviewsKey] as bool?,
      allowLowQualityGrowthBypass:
          raw[ProductGuardrailsPrefs.allowLowQualityGrowthBypassKey] as bool?,
    );
  }

  Future<void> save(ProductGuardrailOverrides next) async {
    state = next;
    await ProductGuardrailsPrefs.save(
      requireSponsoredLabel: next.requireSponsoredLabel,
      minSponsoredTrustScore: next.minSponsoredTrustScore,
      minSponsoredRating: next.minSponsoredRating,
      ownerCanDeleteReviews: next.ownerCanDeleteReviews,
      allowLowQualityGrowthBypass: next.allowLowQualityGrowthBypass,
    );
  }

  Future<void> resetDefaults() async {
    state = ProductGuardrailOverrides.defaults();
    await ProductGuardrailsPrefs.clear();
  }
}
