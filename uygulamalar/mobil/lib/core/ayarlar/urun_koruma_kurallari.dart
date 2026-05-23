class ProductGuardrails {
  const ProductGuardrails._();

  // Never show sponsored content without an explicit label.
  static const bool requireSponsoredLabel = true;

  // Sponsored visibility can exist, but quality cannot be bypassed.
  static const double minSponsoredTrustScore = 0.35;
  static const double minSponsoredRating = 3.8;

  // Owners can reply, but cannot remove community reviews.
  static const bool ownerCanDeleteReviews = false;

  // Growth cannot disable quality checks.
  static const bool allowLowQualityGrowthBypass = false;
}
