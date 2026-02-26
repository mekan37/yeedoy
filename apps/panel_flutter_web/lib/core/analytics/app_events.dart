class AppEvents {
  const AppEvents._();

  static const homeView = 'home_view';
  static const categoryClick = 'category_click';
  static const searchSubmit = 'search_submit';
  static const businessOpen = 'business_open';
  static const menuOpen = 'menu_open';
  static const verifyPriceSubmit = 'verify_price_submit';
  static const reviewSubmit = 'review_submit';
  static const achievementUnlock = 'achievement_unlock';
  static const notificationOpen = 'notification_open';

  // Growth funnel
  static const funnelOpen = 'funnel_open';
  static const funnelLocationSet = 'funnel_location_set';
  static const funnelFirstBusiness = 'funnel_first_business';
  static const funnelMenuView = 'funnel_menu_view';
  static const funnelContribution = 'funnel_contribution';

  // A/B tests
  static const experimentExposure = 'experiment_exposure';
  static const experimentConversion = 'experiment_conversion';

  // Retention loops
  static const favoriteAdd = 'favorite_add';
  static const priceChangePushOpen = 'price_change_push_open';
  static const commentReplyPushOpen = 'comment_reply_push_open';
  static const achievementNearMiss = 'achievement_near_miss';

  // Observability metrics
  static const appStartMs = 'app_start_ms';
  static const homeTtiMs = 'home_tti_ms';
  static const searchLatencyMs = 'search_latency_ms';
  static const businessOpenMs = 'business_open_ms';
  static const frameJankRate = 'frame_jank_rate';

  // Alerting
  static const observabilityAlert = 'observability_alert';
}
