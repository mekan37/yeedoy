class AdminKpiSummary {
  const AdminKpiSummary({
    required this.dau,
    required this.dauPrev,
    required this.wau,
    required this.wauPrev,
    required this.discoveryImpressions,
    required this.discoveryImpressionsPrev,
    required this.discoveryClicks,
    required this.discoveryClicksPrev,
    required this.discoveryCtr,
    required this.discoveryCtrPrev,
    required this.businessViews,
    required this.businessViewsPrev,
    required this.menuViews,
    required this.menuViewsPrev,
    required this.menuViewRate,
    required this.menuViewRatePrev,
    required this.priceSuggestions,
    required this.priceSuggestionsPrev,
    required this.priceVerificationRate,
    required this.priceVerificationRatePrev,
    required this.reportsAvgResolutionMinutes,
    required this.reportsAvgResolutionMinutesPrev,
  });

  final int dau;
  final int dauPrev;
  final int wau;
  final int wauPrev;
  final int discoveryImpressions;
  final int discoveryImpressionsPrev;
  final int discoveryClicks;
  final int discoveryClicksPrev;
  final double discoveryCtr;
  final double discoveryCtrPrev;
  final int businessViews;
  final int businessViewsPrev;
  final int menuViews;
  final int menuViewsPrev;
  final double menuViewRate;
  final double menuViewRatePrev;
  final int priceSuggestions;
  final int priceSuggestionsPrev;
  final double priceVerificationRate;
  final double priceVerificationRatePrev;
  final double reportsAvgResolutionMinutes;
  final double reportsAvgResolutionMinutesPrev;

  factory AdminKpiSummary.fromMap(Map<String, dynamic> map) {
    return AdminKpiSummary(
      dau: _asInt(map['dau']),
      dauPrev: _asInt(map['dau_prev']),
      wau: _asInt(map['wau']),
      wauPrev: _asInt(map['wau_prev']),
      discoveryImpressions: _asInt(map['discovery_impressions']),
      discoveryImpressionsPrev: _asInt(map['discovery_impressions_prev']),
      discoveryClicks: _asInt(map['discovery_clicks']),
      discoveryClicksPrev: _asInt(map['discovery_clicks_prev']),
      discoveryCtr: _asDouble(map['discovery_ctr']),
      discoveryCtrPrev: _asDouble(map['discovery_ctr_prev']),
      businessViews: _asInt(map['business_views']),
      businessViewsPrev: _asInt(map['business_views_prev']),
      menuViews: _asInt(map['menu_views']),
      menuViewsPrev: _asInt(map['menu_views_prev']),
      menuViewRate: _asDouble(map['menu_view_rate']),
      menuViewRatePrev: _asDouble(map['menu_view_rate_prev']),
      priceSuggestions: _asInt(map['price_suggestions']),
      priceSuggestionsPrev: _asInt(map['price_suggestions_prev']),
      priceVerificationRate: _asDouble(map['price_verification_rate']),
      priceVerificationRatePrev: _asDouble(map['price_verification_rate_prev']),
      reportsAvgResolutionMinutes: _asDouble(
        map['reports_avg_resolution_minutes'],
      ),
      reportsAvgResolutionMinutesPrev: _asDouble(
        map['reports_avg_resolution_minutes_prev'],
      ),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString()) ?? 0;
  }
}
