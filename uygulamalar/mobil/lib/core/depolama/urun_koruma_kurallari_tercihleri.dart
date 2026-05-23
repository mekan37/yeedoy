import 'package:shared_preferences/shared_preferences.dart';

class ProductGuardrailsPrefs {
  static const _kRequireSponsoredLabel =
      'guardrails_require_sponsored_label_v1';
  static const _kMinSponsoredTrustScore =
      'guardrails_min_sponsored_trust_score_v1';
  static const _kMinSponsoredRating = 'guardrails_min_sponsored_rating_v1';
  static const _kOwnerCanDeleteReviews =
      'guardrails_owner_can_delete_reviews_v1';
  static const _kAllowLowQualityGrowthBypass =
      'guardrails_allow_low_quality_growth_bypass_v1';

  static Future<Map<String, Object?>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      _kRequireSponsoredLabel: prefs.getBool(_kRequireSponsoredLabel),
      _kMinSponsoredTrustScore: prefs.getDouble(_kMinSponsoredTrustScore),
      _kMinSponsoredRating: prefs.getDouble(_kMinSponsoredRating),
      _kOwnerCanDeleteReviews: prefs.getBool(_kOwnerCanDeleteReviews),
      _kAllowLowQualityGrowthBypass: prefs.getBool(
        _kAllowLowQualityGrowthBypass,
      ),
    };
  }

  static Future<void> save({
    required bool requireSponsoredLabel,
    required double minSponsoredTrustScore,
    required double minSponsoredRating,
    required bool ownerCanDeleteReviews,
    required bool allowLowQualityGrowthBypass,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRequireSponsoredLabel, requireSponsoredLabel);
    await prefs.setDouble(_kMinSponsoredTrustScore, minSponsoredTrustScore);
    await prefs.setDouble(_kMinSponsoredRating, minSponsoredRating);
    await prefs.setBool(_kOwnerCanDeleteReviews, ownerCanDeleteReviews);
    await prefs.setBool(
      _kAllowLowQualityGrowthBypass,
      allowLowQualityGrowthBypass,
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRequireSponsoredLabel);
    await prefs.remove(_kMinSponsoredTrustScore);
    await prefs.remove(_kMinSponsoredRating);
    await prefs.remove(_kOwnerCanDeleteReviews);
    await prefs.remove(_kAllowLowQualityGrowthBypass);
  }

  static String get requireSponsoredLabelKey => _kRequireSponsoredLabel;
  static String get minSponsoredTrustScoreKey => _kMinSponsoredTrustScore;
  static String get minSponsoredRatingKey => _kMinSponsoredRating;
  static String get ownerCanDeleteReviewsKey => _kOwnerCanDeleteReviews;
  static String get allowLowQualityGrowthBypassKey =>
      _kAllowLowQualityGrowthBypass;
}
