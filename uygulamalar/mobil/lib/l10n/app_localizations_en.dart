// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Yeedoy';

  @override
  String get appTagline => 'Live menus, verified prices';

  @override
  String get appTaglineLine1 => 'Live menus';

  @override
  String get appTaglineLine2 => 'Verified prices';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get emptyRegionDescription =>
      'No data in this area yet on Yeedoy. You can add the first contribution.';

  @override
  String get webDescription =>
      'Yeedoy - Live menus, verified prices and smart discovery.';

  @override
  String get discover => 'Discover';

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get list => 'List';

  @override
  String get favorites => 'Favorites';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get privacy => 'Privacy';

  @override
  String get socialLinks => 'Social Links';

  @override
  String get logout => 'Log Out';

  @override
  String get contribute => 'Contribute';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get verifyPrice => 'Verify Price';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get linkPreview => 'Link Preview';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get saving => 'Saving...';

  @override
  String get loginRequired => 'Please sign in first.';

  @override
  String get profileSaved => 'Profile settings saved.';

  @override
  String saveError(String error) {
    return 'Save error: $error';
  }

  @override
  String get namePrivacy => 'Name Privacy';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get showFullName => 'Show full name';

  @override
  String get hideLastName => 'Hide last name only';

  @override
  String get hideBothNames => 'Hide first and last name';

  @override
  String get preview => 'Preview';

  @override
  String get socialMedia => 'Social Media';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System (Default)';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';

  @override
  String get account => 'Account';

  @override
  String get invalidLink => 'Enter a valid link.';

  @override
  String get socialPreview => 'Social Preview';

  @override
  String get pasteLinkHelper => 'Paste link (https://...)';

  @override
  String get privacySocialSubtitle => 'Name privacy and social media links';

  @override
  String updateBusinessTitle(String businessName) {
    return 'Update $businessName';
  }

  @override
  String get contributeSheetSubtitle =>
      'Help the community keep menu prices verified.';

  @override
  String get scanMenuQr => 'Scan Menu QR';

  @override
  String get scanMenuQrSubtitle => 'Instant verification via QR';

  @override
  String get uploadPhotoSubtitle => 'Take a picture of the menu';

  @override
  String get confirmPriceChange => 'Confirm Price Change';

  @override
  String get confirmPriceChangeSubtitle => 'Report an outdated price';

  @override
  String get qrAction => 'QR Action';

  @override
  String get embed => 'Embed';

  @override
  String get share => 'Share';

  @override
  String get shareAsImage => 'Share as Image';

  @override
  String get shareLink => 'Share Link';

  @override
  String get invalidLinkMessage => 'Invalid link';

  @override
  String get browserOpened => 'Opened in browser';

  @override
  String get embedFailed =>
      'Embed could not be displayed, redirected to browser.';

  @override
  String get back => 'Back';

  @override
  String updatedDaysAgo(int days) {
    return 'Updated $days days ago';
  }

  @override
  String verifiedDaysAgo(int days) {
    return 'Verified $days days ago';
  }

  @override
  String distanceKm(num km) {
    return '$km km';
  }

  @override
  String etaRangeMinutes(int min, int max) {
    return '$min-$max min';
  }

  @override
  String avgSpendPerPerson(String amount) {
    return '$amount / person';
  }

  @override
  String reviewsCount(int count) {
    return 'Reviews ($count)';
  }

  @override
  String get openNow => 'Open now';

  @override
  String get closedNow => 'Closed now';

  @override
  String get livePrices => 'Live Prices';

  @override
  String get trustScore => 'Trust Score';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get lastAudit => 'Last Audit';

  @override
  String get avgCost => 'Avg Cost';

  @override
  String get avgSpend => 'AVG. SPEND';

  @override
  String get verified => 'Verified';

  @override
  String get priceVerified => 'Price Verified';

  @override
  String get communityVerified => 'Community Verified';

  @override
  String confirmedByUsersToday(int users) {
    return 'Confirmed by $users users today';
  }

  @override
  String get priceHistory => 'Price History';

  @override
  String get contributeMenuPhoto => 'Contribute Menu Photo';

  @override
  String get verify => 'VERIFY';

  @override
  String get signatureSteaks => 'Signature Steaks';

  @override
  String signatureSection(String section) {
    return 'Signature $section';
  }

  @override
  String get spottedPriceChange => 'Spotted a price change?';

  @override
  String get spottedPriceChangeSubtitle =>
      'Help the community by updating this menu.';

  @override
  String get updateDateUnavailable => 'Update date unavailable';

  @override
  String get currentLocation => 'CURRENT LOCATION';

  @override
  String get changeLocation => 'Change location';

  @override
  String get filters => 'Filters';

  @override
  String get searchKebabsHint => 'Search for kebabs, burgers...';

  @override
  String get budget => 'Budget';

  @override
  String get freshMenuUpdates => 'Fresh Menu Updates';

  @override
  String get seeAll => 'See All';

  @override
  String get freshLinks => 'Fresh Links';

  @override
  String get discoveryNearbyTitle => 'Nearby mode';

  @override
  String get discoveryNearbySubtitle => 'Best results by your location';

  @override
  String get discoveryLocationSubtitle => 'Discover by city/district';

  @override
  String get nearbyVerifiedSpots => 'Nearby Spots';

  @override
  String get discoverForYou => 'Discover for you';

  @override
  String discoveryGreetingHello(String name) {
    return 'Hi $name 👋';
  }

  @override
  String get discoveryGreetingHelloAnon => 'Hi 👋';

  @override
  String get homeGreetingHelloExclaim => 'Hi! 👋';

  @override
  String get discoveryGreetingSubtitle => 'What do you feel like eating today?';

  @override
  String get discoveryFeaturedCategory => 'Featured';

  @override
  String get discoveryCampaignPromoTitle => 'Don\'t miss tasty deals! 🎉';

  @override
  String get discoveryCampaignPromoSubtitle =>
      'Discover deals picked just for you.';

  @override
  String get noNearbyVerifiedSpots => 'No nearby verified spots found';

  @override
  String get changeFiltersTryAgain => 'Try changing location or filters.';

  @override
  String get noFreshData => 'No fresh data';

  @override
  String get freshDataWillAppear => 'Nearby menu updates will appear here.';

  @override
  String get businessLabel => 'Business';

  @override
  String get report => 'Report';

  @override
  String get favoriteAdded => 'Favorited';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get writeReview => 'Write review';

  @override
  String get other => 'Other';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get weakConnectionQueueNotice =>
      'Weak connection. Verification queued and will be sent automatically when online.';

  @override
  String pendingVerificationsSent(int count) {
    return '$count pending verifications sent.';
  }

  @override
  String get loadMenuItemsFirst => 'Load menu items first.';

  @override
  String get menuNotAddedYet => 'Not added yet';

  @override
  String get menuNotAddedYetDescription =>
      'Menu has not been added for this business yet.';

  @override
  String get weakConnection => 'Weak connection';

  @override
  String get contentLoadFailedCheckInternet =>
      'Content could not be loaded right now. Cached data will be shown if available. Check internet and try again.';

  @override
  String get trustDataUnavailable => 'Data trust unavailable';

  @override
  String get freshnessAndTrust => 'Data trust breakdown';

  @override
  String get menuUpdatedLabel => 'Menu Updated';

  @override
  String get lastPriceVerification => 'Last Price Verification';

  @override
  String get trustScoreLabel => 'Trust Score';

  @override
  String get communityScoreDataTrustLabel => 'Data trust';

  @override
  String get communityScoreMenuFreshnessLabel => 'Menu freshness';

  @override
  String get last3MonthsPriceChange => 'Last 3 Months Price Change';

  @override
  String get hoursInfoUnavailable => 'Hours information unavailable';

  @override
  String get hoursInfoMissing => 'Hours information missing';

  @override
  String get addHoursHelp => 'Add business hours to help users.';

  @override
  String get reportHoursInfo => 'Report hours information';

  @override
  String get menus => 'Menus';

  @override
  String get menusLoadFailed => 'Menus failed to load';

  @override
  String get noMenu => 'No menu';

  @override
  String get addFirstMenuHelp => 'Help users by adding the first menu.';

  @override
  String get crowdInfoUnavailable => 'Crowd info unavailable';

  @override
  String liveCrowdLabel(String state) {
    return 'Live crowd: $state';
  }

  @override
  String get reviewsLoadFailed => 'Reviews failed to load';

  @override
  String get noReviews => 'No reviews';

  @override
  String get leaveFirstReviewHelp => 'Contribute by leaving the first review.';

  @override
  String get writeFirstReview => 'Write first review';

  @override
  String get recentReviews => 'Recent reviews';

  @override
  String get reviewFallbackTitle => 'Review';

  @override
  String get activeCampaigns => 'Active campaigns';

  @override
  String get menuDataUnavailable => 'Menu data unavailable';

  @override
  String get noMenuProductsYet => 'No products to list yet.';

  @override
  String get menu => 'Menu';

  @override
  String featuredFromCuisine(String cuisine) {
    return 'Featured from $cuisine cuisine.';
  }

  @override
  String get weeklyPriceChange => '+₺50 this week';

  @override
  String get chartPlaceholderSoon => 'Chart area (coming soon)';

  @override
  String get noPriceDataYet => 'No price data yet';

  @override
  String get featuredCuisineSuffix => 'cuisine highlights.';

  @override
  String get connectionProblemTryAgain =>
      'There may be a connection issue. Please try again.';

  @override
  String get noActiveCampaign => 'No active campaigns';

  @override
  String get activeCampaignCountLabel => 'active campaigns';

  @override
  String get noAmenityInfo => 'No amenity information';

  @override
  String amenityCountLabel(int count) {
    return 'amenities marked';
  }

  @override
  String get noLocationVerificationData => 'No location verification data';

  @override
  String get lastLocationVerification => 'Last location verification';

  @override
  String get noNewProductRecord => 'No new product record';

  @override
  String get newProduct => 'New product';

  @override
  String get reportInfoErrorPrefix => 'Report incorrect info. Last update:';

  @override
  String get noLocation => 'No location';

  @override
  String get noHoursInfo => 'No hours info';

  @override
  String get reviewsCountSuffix => 'reviews';

  @override
  String get noTime => 'No time';

  @override
  String get tabSteaks => 'Steaks';

  @override
  String get tabBurgers => 'Burgers';

  @override
  String get tabSides => 'Sides';

  @override
  String get tabBeverages => 'Beverages';

  @override
  String get locationNotAvailable => 'Location not available';

  @override
  String get sortRecommended => 'Recommended';

  @override
  String get sortDistance => 'Distance';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortPriceLow => 'Price';

  @override
  String get sortNewlyVerified => 'Newly verified';

  @override
  String get rankingFormulaTitle => 'Ranking Formula';

  @override
  String get rankingFormulaIntro => 'Yeedoy uses transparent ranking:';

  @override
  String get rankingWeightDistance => '30% Distance';

  @override
  String get rankingWeightAccuracy => '30% Accuracy (recent verifications)';

  @override
  String get rankingWeightEngagement => '20% Engagement (average rating)';

  @override
  String get rankingWeightQuality => '20% Quality (quality score)';

  @override
  String get rankingFormulaNote =>
      'These weights are fixed; admins cannot change them arbitrarily.';

  @override
  String minRatingLabel(String value) {
    return 'Minimum rating: $value';
  }

  @override
  String get priceLevel => 'Price level';

  @override
  String get prioritizeOpenNow => 'Prioritize currently open businesses';

  @override
  String get prioritizeNewlyVerified => 'Prioritize newly verified prices';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get priceTierAny => 'All';

  @override
  String get priceTierBudget => 'Budget';

  @override
  String get priceTierMedium => 'Medium';

  @override
  String get priceTierPremium => 'Premium';

  @override
  String get tabAllItems => 'All Items';

  @override
  String get tabStarters => 'Starters';

  @override
  String get usersLabel => 'users';

  @override
  String get unknown => 'Unknown';

  @override
  String get today => 'Today';

  @override
  String get dayUnit => 'days';

  @override
  String get tekrarDene => 'Retry';

  @override
  String get vazgec => 'Cancel';

  @override
  String get reddet => 'Reject';

  @override
  String get title => 'Title';

  @override
  String get isleniyor => 'Processing...';

  @override
  String get onayla => 'Approve';

  @override
  String get approved => 'Approved';

  @override
  String get tumu => 'All';

  @override
  String get kayitBulunamadi => 'No records found.';

  @override
  String get temizle => 'Clear';

  @override
  String get uygula => 'Apply';

  @override
  String get pending => 'Pending';

  @override
  String get reddedildi => 'Rejected';

  @override
  String get satirSec => 'Select row';

  @override
  String get gonder => 'Send';

  @override
  String get rejected => 'Rejected';

  @override
  String get detay => 'Detail';

  @override
  String get duzenle => 'Edit';

  @override
  String get eminMisin => 'Are you sure?';

  @override
  String get guncellendi => 'Updated.';

  @override
  String get reddedildi_2 => 'Rejected.';

  @override
  String get sla => 'SLA';

  @override
  String get csvDisaAktar => 'Export CSV';

  @override
  String get onaylandi => 'Approved';

  @override
  String get yenile => 'Refresh';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String get kapat => 'Close';

  @override
  String get suspendedMealsEmptyDescription =>
      'Your suspended meal plans will appear here.';

  @override
  String get ara => 'Search';

  @override
  String ratingLabel(int count) {
    return '$count stars';
  }

  @override
  String get atanan => 'Assigned';

  @override
  String get beklemede => 'Pending';

  @override
  String get durum => 'Status';

  @override
  String get tabRecommended => 'Recommended';

  @override
  String get tabCampaigns => 'Campaigns';

  @override
  String get tabFoods => 'Foods';

  @override
  String get whyTop => 'Why on top?';

  @override
  String get quickSuggestionTitle => 'Quick suggestion';

  @override
  String get quickSuggestionSubtitle =>
      'Start with a ready budget for 2 people';

  @override
  String get quickSuggestionPreset => '2 people / TL 600';

  @override
  String get whatToEatTitle => 'What should I eat now?';

  @override
  String get whatToEatSubtitle => 'Best combo in 3 steps';

  @override
  String get nearbyShort => 'Nearby';

  @override
  String get affordableShort => 'Affordable';

  @override
  String get quickDecisionShort => 'Quick choice';

  @override
  String get start => 'Start';

  @override
  String get friendGroupTitle => 'Friends group';

  @override
  String get friendGroupSubtitle => 'Share a link and let everyone suggest';

  @override
  String get openGroup => 'Open group';

  @override
  String get myGroups => 'My groups';

  @override
  String get onTheRoadTitle => 'On the road';

  @override
  String get onTheRoadSubtitle => 'Fast food options within 20 km';

  @override
  String get heroesTitle => 'Heroes';

  @override
  String get heroesSubtitle => 'Suspended meal good deeds list';

  @override
  String get view => 'View';

  @override
  String get bestBusinessesThisWeek => 'Best Businesses This Week';

  @override
  String get bestBusinessesThisMonth => 'Best Businesses This Month';

  @override
  String get onTheRoad20km => 'On the road • 20 km';

  @override
  String nearbyKm(int km) {
    return 'Nearby • $km km';
  }

  @override
  String get liveResultsUpdating =>
      'Live results are shown. Full result list is updating...';

  @override
  String get businessApprovedData => 'Business approved';

  @override
  String get communityData => 'Community data';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get locationPermissionTitle => 'Allow location';

  @override
  String get locationPermissionDescription =>
      'You can still use the app without permission. Nearby results may be less accurate.';

  @override
  String get allow => 'Allow';

  @override
  String get selectLocation => 'Select location';

  @override
  String get manualLocationHint =>
      'Manual start picks city/district and radius.';

  @override
  String get noResultsYet => 'No results yet';

  @override
  String get lowDataInArea => 'Low data in this area';

  @override
  String get tryDifferentSearchOrFilter => 'Try a different search or filter.';

  @override
  String get beFirstContributorInArea =>
      'Add the first contribution and help the list grow.';

  @override
  String get topVerifiedMenus => 'Top 10 most verified menus';

  @override
  String get mostTrustedMenusInCity => 'Most trusted menus in this city.';

  @override
  String get seeList => 'See list';

  @override
  String get localContributionCall =>
      'Local contribution call: extra badge for first 50 contributions.';

  @override
  String get addFirstMenu => 'Add first menu';

  @override
  String get suggestBusiness => 'Suggest business';

  @override
  String get noSurpriseSuggestionNow => 'No surprise suggestion right now.';

  @override
  String get priceVerifiedInLast48h =>
      'This price was verified in the last 48 hours';

  @override
  String get menuMayBeOutdated => 'Menu may be outdated';

  @override
  String get verifiedByBusiness => 'Verified by business';

  @override
  String get updatedByCommunity => 'Updated by community';

  @override
  String get topRankedInDistrict => 'Top ranked in your district';

  @override
  String get surpriseDiscoveryTitle => 'Surprise discovery';

  @override
  String get surpriseDiscoverySubtitle => 'Not boring, surprise picks.';

  @override
  String get randomButGood => 'Random but good today';

  @override
  String get outsideYourUsual => 'Outside your usual';

  @override
  String get pricePerformanceSurprise => 'Price-performance surprise';

  @override
  String get nearbyCampaignsAndAnnouncements =>
      'Nearby campaigns and announcements';

  @override
  String get campaignsGreeting => 'Hello! 👋';

  @override
  String get campaignsSearchPlaceholder => 'Search campaigns or businesses...';

  @override
  String get campaignFilterAll => 'All';

  @override
  String get campaignFilterSoon => 'Ending soon';

  @override
  String get campaignFilterToday => 'Today';

  @override
  String get campaignFilterFood => 'Food';

  @override
  String get campaignFilterDessert => 'Dessert';

  @override
  String get campaignFilterDiscount20 => '20%+';

  @override
  String get campaignsNearbyHeader => 'Campaigns near you';

  @override
  String get campaignsFeaturedBadge => 'Tasty Deals';

  @override
  String campaignDiscountLabel(int percent) {
    return '$percent% off';
  }

  @override
  String get noNearbyCampaign => 'No nearby campaign';

  @override
  String get noActiveAnnouncementInArea =>
      'No active announcement in this area. Try again later.';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String get campaign => 'Campaign';

  @override
  String get active => 'Active';

  @override
  String get noLocationDataForMap => 'No location data for map';

  @override
  String get mapDataMissingUseList =>
      'Some results do not have location data. You can use list view.';

  @override
  String get openMapView => 'Open map view';

  @override
  String get mapHintTapPins => 'Tip: Tap pins to open business details.';

  @override
  String get mapGreetingSubtitle => 'What\'s nearby?';

  @override
  String get mapSearchHint => 'Search for a place or area...';

  @override
  String get mapFilterOpen => 'Open';

  @override
  String get mapFilterPrice => 'Price';

  @override
  String get mapAttribution => '© OpenStreetMap contributors';

  @override
  String get mapRecenterTooltip => 'Go to my location';

  @override
  String get mapLayersTooltip => 'Layers';

  @override
  String get locationPermissionRequired => 'Location permission required.';

  @override
  String get noFoodFoundForCriteria =>
      'No food found for your criteria. Try loosening filters.';

  @override
  String get whatToEatDescription =>
      'Decide with people count, budget, and distance.';

  @override
  String get stepPeopleCount => '1) People count';

  @override
  String get quickDecisionThreeOptions => 'Quick choice: 3 options';

  @override
  String get stepBudgetTotal => '2) Budget (total)';

  @override
  String get budgetTl => 'Budget (₺)';

  @override
  String get stepDistance => '3) Distance';

  @override
  String get locationNotSelected => 'Location not selected';

  @override
  String get seeSuggestions => 'See suggestions';

  @override
  String get getSingleSuggestion => 'Get one suggestion';

  @override
  String get go => 'Go';

  @override
  String get restart => 'Restart';

  @override
  String get quickShortcuts => 'Quick shortcuts';

  @override
  String get quickShortcutsSubtitle => 'Access frequent actions from here.';

  @override
  String get savedItems => 'Saved items';

  @override
  String get myFriendGroup => 'My friend group';

  @override
  String get tasteExperts => 'Taste experts';

  @override
  String get businessTools => 'Business tools';

  @override
  String get businessToolsSubtitle => 'Tools you need to grow your business.';

  @override
  String get sponsoredLabelChip => 'Sponsored label';

  @override
  String get sponsored => 'Sponsored';

  @override
  String get ready => 'ready';

  @override
  String get plan => 'planned';

  @override
  String get sponsoredDisclosure =>
      'This area is for visibility. It does not affect normal ranking.';

  @override
  String get sponsoredTooltip =>
      'Sponsored records are shown in a separate section.';

  @override
  String localInsightsReady(String area) {
    return 'Local insights ready for $area';
  }

  @override
  String get show => 'Show';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get cafe => 'Cafe';

  @override
  String get venue => 'Venue';

  @override
  String get notifications => 'Notifications';

  @override
  String get businessPackage => 'Business package';

  @override
  String get redirectToReservation => 'Redirect to reservation';

  @override
  String get priceAlerts => 'Price alerts';

  @override
  String get corporateIntegration => 'Corporate integration';

  @override
  String get detailedReports => 'Detailed reports';

  @override
  String get qrTools => 'QR tools';

  @override
  String get unlockNewFeatures => 'Unlock new features';

  @override
  String get branchManagement => 'Branch management';

  @override
  String get menuWithQr => 'Menu with QR';

  @override
  String get newFeatures => 'New features';

  @override
  String nearOpenSectionTitle(String area) {
    return 'Nearby and open in $area';
  }

  @override
  String mostViewedThisWeekTitle(String area) {
    return 'Most viewed this week in $area';
  }

  @override
  String get noViewDataInArea => 'No view data in this area yet.';

  @override
  String viewsMetric(int count) {
    return '$count views';
  }

  @override
  String highestPriceChangeTitle(String area) {
    return 'Highest price changes in $area';
  }

  @override
  String get noPriceMovementInArea => 'No price movement in this area yet.';

  @override
  String priceChangeMetric(int count) {
    return '$count price changes';
  }

  @override
  String nightOpenFavoritesTitle(String area) {
    return 'Night-open favorites in $area';
  }

  @override
  String get noNightOpenFavoritesInArea =>
      'No night-open favorites found in this area.';

  @override
  String followersMetric(int count) {
    return '$count followers';
  }

  @override
  String popularCategoriesTitle(String area) {
    return 'Popular categories in $area';
  }

  @override
  String regionalPriceIndexTitle(String area) {
    return 'Regional price index in $area';
  }

  @override
  String get detailedAnalysis => 'Detailed analysis';

  @override
  String get loadWhenScrolledDown => 'Loads when you scroll down';

  @override
  String anomalyMonitoringTitle(String area) {
    return 'Anomaly monitoring in $area';
  }

  @override
  String get general => 'General';

  @override
  String get priceIndexLoadFailed =>
      'Price index could not be loaded right now.';

  @override
  String get noPriceIndexDataInArea => 'No price index data for this area.';

  @override
  String medianPriceLabel(String price) {
    return 'Median $price';
  }

  @override
  String get anomalyListLoadFailed =>
      'Anomaly list could not be loaded right now.';

  @override
  String get noPriceAnomalyLast30Days =>
      'No notable price anomaly in the last 30 days.';

  @override
  String get sectionLoadFailed => 'This section could not be loaded.';

  @override
  String rankedAt(int rank) {
    return 'Ranked #$rank';
  }

  @override
  String yourScore(String score) {
    return 'Your score';
  }

  @override
  String get createGroup => 'Create group';

  @override
  String get newPlaces => 'New places';

  @override
  String get campaignEnded => 'ended';

  @override
  String timeDays(int count) {
    return '$count d';
  }

  @override
  String timeHours(int count) {
    return '$count h';
  }

  @override
  String timeMinutes(int count) {
    return '$count m';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get statusVerifiedShort => 'Verified';

  @override
  String get statusMixedShort => 'Mixed';

  @override
  String get statusOutdatedShort => 'Outdated';

  @override
  String get statusUnknownShort => 'Unknown';

  @override
  String get threeMonthsShort => '(3 Mo)';

  @override
  String versionAndSource(int version, String source) {
    return '(v$version, $source)';
  }

  @override
  String get sourceOwner => 'owner';

  @override
  String get sourceCommunity => 'community';

  @override
  String get sourceAi => 'automatic';

  @override
  String shareBusinessMessage(
    String name,
    String location,
    String web,
    String deep,
  ) {
    return 'Discover on Yeedoy: $name\n$location\n$web\n$deep';
  }

  @override
  String get noLinkFound => 'No link found';

  @override
  String get newEmbedLinksWillAppear => 'New embed links will appear here.';

  @override
  String get link => 'Link';

  @override
  String get untitledLink => 'Untitled link';

  @override
  String menuShareNotFoundTitle(String appName) {
    return 'Menu not found • $appName';
  }

  @override
  String get menuShareNotFoundDescription =>
      'Menu was not found or is not published.';

  @override
  String get menuContentNotFound => 'Menu content not found.';

  @override
  String get openAppForBetterExperience =>
      'Open the app for a better experience';

  @override
  String get openApp => 'Open App';

  @override
  String nearbyPeopleViewed(int count) {
    return '$count people nearby viewed this';
  }

  @override
  String get verifiedPrices => 'Verified prices';

  @override
  String get selectRatingFirst => 'Please select a rating';

  @override
  String get thankYou => 'Thank you!';

  @override
  String get noProductsFound => 'No products found.';

  @override
  String preparedWithApp(String appName) {
    return 'Prepared with $appName';
  }

  @override
  String tableLabel(String tableNo) {
    return 'Table $tableNo';
  }

  @override
  String tableServiceQuestion(String tableNo) {
    return 'How was the service? (Table $tableNo)';
  }

  @override
  String get shortNoteOptional => 'Short note (optional)';

  @override
  String get submit => 'Submit';

  @override
  String get submitted => 'Submitted';

  @override
  String get submitting => 'Submitting...';

  @override
  String get mySuggestionsTitle => 'My Suggestions';

  @override
  String get mySuggestionsSubtitle =>
      'Track the status of businesses you submitted from here.';

  @override
  String get viewBusiness => 'View Business';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusPending => 'Pending';

  @override
  String get retry => 'Retry';

  @override
  String get notNow => 'Not now';

  @override
  String get onboardingLiveMenusTitle => 'Live menus';

  @override
  String get onboardingLiveMenusDescription =>
      'View up-to-date menus from businesses on a single screen. Follow price changes easily.';

  @override
  String get onboardingContributeTitle => 'Contribute and move faster';

  @override
  String get onboardingContributeDescription =>
      'You can continue quickly with actions like votes, reviews and price verification.';

  @override
  String get onboardingPriceTitle => 'You Set the\nCity\'s Prices';

  @override
  String get onboardingPriceBody1 => 'Discover restaurants with real prices';

  @override
  String get onboardingPriceBody2 => 'Track price history and city averages';

  @override
  String get onboardingPriceBody3 => 'Filter by budget, save money';

  @override
  String get onboardingCommunityTitle => 'The Power of Community';

  @override
  String get onboardingCommunitySubtitle =>
      'Every price verification helps everyone';

  @override
  String get onboardingCommunityBody1 => 'Real users keep menus up-to-date';

  @override
  String get onboardingCommunityBody2 =>
      'Price deviations are detected instantly';

  @override
  String get onboardingCommunityBody3 =>
      'Earn XP and badges for your contributions';

  @override
  String get onboardingNotificationTitle => 'Instant notifications';

  @override
  String get onboardingNotificationDescription =>
      'Get price changes, campaigns, and group requests from your favorite places as they happen.';

  @override
  String get onboardingNotificationsEnabled => 'Notifications are enabled';

  @override
  String get onboardingAllowNotifications => 'Allow Notifications';

  @override
  String get onboardingSkipNotifications => 'Not now';

  @override
  String get getStarted => 'Get Started';

  @override
  String get continueAction => 'Continue';

  @override
  String get register => 'Register';

  @override
  String get login => 'Login';

  @override
  String get enableLocationTitle => 'Enable location for better results';

  @override
  String get enableLocationSubtitle =>
      'Nearby results are much more accurate with location permission.';

  @override
  String get locationPermissionGranted => 'Location permission granted';

  @override
  String get locationOptionalInfo =>
      'If you skip permission, the app still works. You can choose city/district manually, but nearby quality is better with location.';

  @override
  String get allowLocation => 'Allow location';

  @override
  String get chooseLocationManually => 'Choose location manually';

  @override
  String get menuReading => 'Reading menu...';

  @override
  String get noPriceDetectionFound => 'No price detection found.';

  @override
  String get receiptOcrNotSupportedWeb =>
      'Receipt OCR is not supported on web.';

  @override
  String get receiptReading => 'Reading receipt...';

  @override
  String get noPriceFoundOnReceipt => 'No price was found on the receipt.';

  @override
  String get receiptUploading => 'Uploading receipt...';

  @override
  String get receiptUploadFailed => 'Receipt upload failed.';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get matchReceipt => 'Match receipt';

  @override
  String get matchPrices => 'Match prices';

  @override
  String autoMatchedRowsCheck(int count) {
    return '$count rows were auto-matched, please review.';
  }

  @override
  String get unlabeled => 'Unlabeled';

  @override
  String get priceTry => 'Price (₺)';

  @override
  String get selectMenuItem => 'Select menu item';

  @override
  String get sendReceipt => 'Send receipt';

  @override
  String get sendReceiptSuggestions => 'Send receipt suggestions';

  @override
  String get selectAtLeastOneItem => 'You must select at least one item.';

  @override
  String get invalidPriceExists => 'There is an invalid price.';

  @override
  String get sendingReceipt => 'Sending receipt...';

  @override
  String get receiptSent => 'Receipt sent.';

  @override
  String get sendingReceiptSuggestions => 'Sending receipt suggestions...';

  @override
  String get priceSuggestionsSent => 'Price suggestions sent.';

  @override
  String get searchFoodHint => 'Search food (e.g., burger, doner, latte)';

  @override
  String get profileActive => 'Profile active';

  @override
  String get profileLoading => 'Loading profile...';

  @override
  String get dietProfileNotFound => 'Diet profile was not found.';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get allowLocationForNearby =>
      'Allow location permission to show nearby items.';

  @override
  String get setPriceAlert => 'Set Price Alert';

  @override
  String get vegan => 'Vegan';

  @override
  String get vegetarian => 'Vegetarian';

  @override
  String get lactoseFree => 'Lactose-free';

  @override
  String get maxCalories => 'Maximum calories';

  @override
  String get onlyVerifiedPrice => 'Only verified price';

  @override
  String votes(int count) {
    return '$count votes';
  }

  @override
  String get glutenFree => 'Gluten-free';

  @override
  String get menuItem => 'Item';

  @override
  String get cataloged => 'Cataloged';

  @override
  String get priceAlert => 'Price Alert';

  @override
  String get priceAlertSubtitle =>
      'Notify me when it drops below the target price.';

  @override
  String get addToBill => 'Add to Bill';

  @override
  String get voteSaved => 'Vote saved';

  @override
  String get photoAdded => 'Photo added';

  @override
  String photoQualityWarning(String warnings) {
    return 'The photo looks $warnings. You can upload a clearer and brighter photo.';
  }

  @override
  String get suggestEdit => 'Suggest edit';

  @override
  String get verifyPriceWithReceipt => 'Verify price with receipt';

  @override
  String get cart => 'Cart';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get addItemToCalculate => 'Add an item to calculate.';

  @override
  String get tipPercentage => 'Tip percentage';

  @override
  String get serviceIncluded => 'Service included';

  @override
  String get coverIncluded => 'Cover included';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get cover => 'Cover';

  @override
  String serviceWithPercent(int percent) {
    return 'Service ($percent%)';
  }

  @override
  String tipWithPercent(int percent) {
    return 'Tip ($percent%)';
  }

  @override
  String get serviceCoverMayVary => 'Service/cover may vary by business.';

  @override
  String get estimatedTotal => 'Estimated Total';

  @override
  String get vatExcluded => 'VAT excluded';

  @override
  String get errorOccurred => 'Something went wrong';

  @override
  String get menuItemNotFoundDescription =>
      'The item may not be added yet. You can be the first to add it.';

  @override
  String get trustScoreInfoNote =>
      'This score is not user voting; it shows how reliably you contribute to the community.';

  @override
  String plusPoints(int points) {
    return '+$points points';
  }

  @override
  String get verifyContributionRaisedScore =>
      'Your price verification strengthened your community trust.';

  @override
  String get priceVerification => 'Price verification';

  @override
  String get priceVerificationSteps =>
      '1) Enter the seen price  2) Add note/photo if needed  3) Submit';

  @override
  String get newPriceTry => 'New price (₺)';

  @override
  String get note => 'Note';

  @override
  String get addEvidencePhoto => 'Add evidence photo';

  @override
  String get evidenceAdded => 'Evidence added';

  @override
  String get menuItemName => 'Item name';

  @override
  String get menuItemNameRequired => 'Item name cannot be empty';

  @override
  String get enterValidPrice => 'Enter a valid price';

  @override
  String get sendSuggestion => 'Send suggestion';

  @override
  String get noChanges => 'No changes';

  @override
  String get priceCannotBeEmpty => 'Price cannot be empty';

  @override
  String get suggestionSentPendingApproval =>
      'Your suggestion was sent (pending approval)';

  @override
  String get noSuggestionFound => 'No suggestion found';

  @override
  String get suggestedFoods => 'Suggested foods';

  @override
  String get priceHistoryLast3 => 'Price history (last 3)';

  @override
  String get price => 'Price';

  @override
  String last30DaysVotes(int ok, int bad) {
    return 'Last 30 days votes: +$ok / -$bad';
  }

  @override
  String lastVerificationDate(String date) {
    return 'Last verification: $date';
  }

  @override
  String uniqueVerifiersIn48h(int count) {
    return 'Unique verifiers in 48 hours: $count';
  }

  @override
  String get strongConsensusPriceSafe => 'Strong consensus: price is safe';

  @override
  String priceConfidenceScore(int score) {
    return 'Price confidence score: %$score';
  }

  @override
  String get priceConfidenceDataTrustHint =>
      'Price confidence is one part of data trust; it looks at recent verification and consensus.';

  @override
  String get seenCorrect => 'Seen • Correct';

  @override
  String get seenIncorrect => 'Seen • Incorrect';

  @override
  String get suggestNewPrice => 'Suggest new price';

  @override
  String get howCalculated => 'How calculated?';

  @override
  String get verificationRate => 'Verification rate';

  @override
  String get recentPositiveVotes => 'Recent positive votes';

  @override
  String get priceStability => 'Price stability';

  @override
  String priceChangeLast30Days(int count) {
    return 'Price changes in last 30 days: $count';
  }

  @override
  String get scoreForInfoOnly =>
      'This score is for informational purposes only.';

  @override
  String get pricePerformance => 'Price/Performance';

  @override
  String get valueScoreFormulaHint =>
      'Calculated by verification rate, recent positive votes, and price stability.';

  @override
  String get communityScoreExplainAction => 'What do these scores mean?';

  @override
  String get communityScoreWhatImproves => 'What improves it?';

  @override
  String get communityScoreHowUsed => 'How the app uses it';

  @override
  String get communityScoreUserTrustCategory => 'User trust';

  @override
  String get communityScoreDataTrustCategory => 'Data trust';

  @override
  String get communityScoreInfoOnlyCategory => 'Info score';

  @override
  String get communityScoreUserTrustSummary =>
      'Shows how reliable the community finds your contributions. Popularity does not grow this score; accuracy and approval quality do.';

  @override
  String get communityScoreUserTrustSignalAccuracy =>
      'Accurate contributions and price checks';

  @override
  String get communityScoreUserTrustSignalApproval =>
      'How often your contributions are approved';

  @override
  String get communityScoreUserTrustSignalSafety =>
      'Low spam, abuse, and rejection signals';

  @override
  String get communityScoreUserTrustUsage =>
      'More trusted contributions can surface faster in community flows and verification decisions.';

  @override
  String get communityScoreDataTrustSummary =>
      'Shows how dependable a menu or price data is right now.';

  @override
  String get communityScoreDataTrustSignalFreshness =>
      'Menu freshness and the latest audit date';

  @override
  String get communityScoreDataTrustSignalConsensus =>
      'Multiple verifiers and strong consensus';

  @override
  String get communityScoreDataTrustSignalStability =>
      'Low conflict and a consistent change history';

  @override
  String get communityScoreDataTrustUsage =>
      'The app uses this signal before presenting menu and price data as dependable.';

  @override
  String get communityScoreValueInsightSummary =>
      'This is not a trust score; it is an informational score built from verification, votes, and price stability.';

  @override
  String get communityScoreValueSignalVerification => 'Verification rate';

  @override
  String get communityScoreValueSignalVotes => 'Recent positive votes';

  @override
  String get communityScoreValueSignalStability => 'Price stability';

  @override
  String get communityScoreValueUsage =>
      'Use it as a decision aid, not as proof on its own.';

  @override
  String get menuPhotos => 'Menu Photos';

  @override
  String updateMenuEarnPoints(int points) {
    return 'Update menu, earn $points points';
  }

  @override
  String get menuPhotosHint =>
      'Menu photos should show the product. Auto-cropped; dark/blurry ones are warned.';

  @override
  String get noPhotosYet => 'No photos yet.';

  @override
  String get yesterday => 'Yesterday';

  @override
  String timeMonthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String get priceInvalid => 'Price is invalid.';

  @override
  String get noteNoLinkPhone => 'Note cannot contain links/phone numbers.';

  @override
  String get noteContainsProfanity => 'Note contains inappropriate language.';

  @override
  String get noteTooManyEmoji => 'Note contains too many emojis.';

  @override
  String get rateLimited24h => 'You already suggested within 24 hours.';

  @override
  String get dailyPriceSuggestionLimitReached =>
      'Daily price suggestion limit reached.';

  @override
  String get invalidEvidenceLink => 'Evidence link is invalid.';

  @override
  String get invalidCurrency => 'Currency is invalid.';

  @override
  String get loginPageTitle => 'Sign in';

  @override
  String get loginActionFailedTitle => 'Action could not be completed';

  @override
  String loginActionFailedDescription(String error) {
    return '$error\nCheck your connection and try again.';
  }

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPrimaryAction => 'Sign in';

  @override
  String get loginSigningInAction => 'Signing in...';

  @override
  String get loginSignupAction => 'Login / Sign up';

  @override
  String get loginSigningUpAction => 'Creating account...';

  @override
  String get loginSignupSuccessMessage =>
      'Account created. Complete email/phone verification.';

  @override
  String get authErrorInvalidCredentials =>
      'Incorrect email or password. Please try again.';

  @override
  String get authErrorEmailNotConfirmed => 'Please verify your email address.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please wait a moment.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorGeneric => 'Sign in failed. Please try again.';

  @override
  String get drawerTopBusinesses => 'Top businesses';

  @override
  String get drawerSocial => 'Social';

  @override
  String get drawerGourmets => 'Food experts';

  @override
  String get drawerFollowing => 'Following';

  @override
  String get drawerExperimental => 'Experimental';

  @override
  String get drawerFeed => 'Feed';

  @override
  String get drawerTasteTwin => 'Taste twin';

  @override
  String get drawerHeroes => 'Heroes';

  @override
  String get drawerGroupRequests => 'Group requests';

  @override
  String get drawerCompare => 'Compare';

  @override
  String get drawerQuickTools => 'Quick tools';

  @override
  String get drawerSmartSuggestionShortcut =>
      'Smart suggestion (2 people / 600 TRY)';

  @override
  String get drawerAccount => 'Account';

  @override
  String get drawerMyFavorites => 'My favorites';

  @override
  String get drawerInbox => 'Inbox';

  @override
  String drawerInboxWithCount(int count) {
    return 'Inbox ($count)';
  }

  @override
  String get drawerMySuggestions => 'My suggestions';

  @override
  String get drawerSuspendedMeals => 'Suspended meals';

  @override
  String get drawerLegalAndTrust => 'Legal and Trust';

  @override
  String get budgetComboEntryTitle => 'My budget is';

  @override
  String get budgetComboLocationNotSelected => 'Location not selected';

  @override
  String get budgetComboBudgetLabel => 'Budget (TRY)';

  @override
  String get budgetComboPartySizeLabel => 'People';

  @override
  String get budgetComboCategoryOptionalLabel => 'Category (optional)';

  @override
  String get budgetComboSeeSuggestions => 'See suggestions';

  @override
  String get budgetComboAllCategories => 'All categories';

  @override
  String get budgetComboCategoryCafe => 'Cafe';

  @override
  String get budgetComboCategoryRestaurant => 'Restaurant';

  @override
  String get budgetComboCategoryDessert => 'Dessert';

  @override
  String get budgetComboCategoryBreakfast => 'Breakfast';

  @override
  String get budgetComboCategoryFishMeat => 'Fish / Meat';

  @override
  String get budgetComboCategoryVenue => 'Venue';

  @override
  String get smartRecoTitle => 'Smart Picks';

  @override
  String get smartRecoSubtitle => 'Best picks for your budget and group size';

  @override
  String get smartRecoEmptyTitle => 'No matching places found';

  @override
  String get smartRecoEmptyDesc =>
      'Try raising your budget or reducing party size';

  @override
  String get smartRecoShuffleLabel => 'Feeling Lucky?';

  @override
  String get smartRecoShuffleDesc => 'Show different picks';

  @override
  String get budgetComboResultsTitle => 'Budget Combos';

  @override
  String get budgetComboMissingInfoTitle => 'Missing information';

  @override
  String get budgetComboMissingInfoDescription =>
      'Please enter budget and location information.';

  @override
  String get budgetComboNoResultsTitle => 'No suitable combo yet';

  @override
  String get budgetComboNoResultsDescription =>
      'Try increasing the budget or reducing the party size.';

  @override
  String get budgetComboAdjustCriteriaTitle => 'Adjust criteria';

  @override
  String get budgetComboDefaultAction => 'Default';

  @override
  String get budgetComboRadiusDistrictScope =>
      'Distance filter is applied at city/district level.';

  @override
  String budgetComboRadiusTarget(String km) {
    return 'Distance target: $km km';
  }

  @override
  String get budgetComboWeightDistance => 'Distance';

  @override
  String get budgetComboWeightPrice => 'Price';

  @override
  String get budgetComboWeightRating => 'Rating';

  @override
  String get budgetComboFallbackSortHint =>
      'If distance/rating data is missing, ranking is based on price.';

  @override
  String get budgetComboBestComboTitle => 'Best combo';

  @override
  String get budgetComboTagTop => 'Top';

  @override
  String get budgetComboOtherSuggestionsTitle => 'Other suggestions';

  @override
  String budgetComboRatingLabelValue(String rating) {
    return 'Rating $rating';
  }

  @override
  String get budgetComboBestTag => 'Best';

  @override
  String get budgetComboMainItemLabel => 'Main';

  @override
  String get budgetComboDrinkItemLabel => 'Drink';

  @override
  String budgetComboTotalLabel(String price) {
    return '$price total';
  }

  @override
  String get budgetComboGoToBusinessAction => 'Go to business';

  @override
  String get panelAccessTitle => 'Panel Access';

  @override
  String get panelWebOnlyMessage => 'This panel is available on the web.';

  @override
  String panelRedirectedPath(String path) {
    return 'Redirected path: $path';
  }

  @override
  String get panelBackToDiscover => 'Back to Discover';

  @override
  String get notFoundTitle => 'Page Not Found';

  @override
  String get businessHeaderStatusClosingLabel => 'Status / Closing';

  @override
  String get businessHeaderAveragePriceLabel => 'Average price';

  @override
  String get businessHeaderPopularItemLabel => 'Popular item';

  @override
  String get businessHeaderLastVerificationLabel => 'Last verification';

  @override
  String get businessStatusOpen => 'Open';

  @override
  String get businessStatusClosed => 'Closed';

  @override
  String get businessHeaderDirectionsAction => 'Directions';

  @override
  String get chainPageTitle => 'Chain';

  @override
  String get chainPageNoBranches => 'No branches found.';

  @override
  String get chainPageNearbyBranchesTitle => 'Nearby branches';

  @override
  String get chainPageBranchMenuPriceHint =>
      'Branch menus and prices may differ.';

  @override
  String chainPageBranchMoreExpensive(String pct) {
    return 'This branch is more expensive (%$pct)';
  }

  @override
  String chainPageBranchMoreAffordable(String pct) {
    return 'This branch is more affordable (%$pct)';
  }

  @override
  String get chainPageBranchNearAverage => 'Close to chain average';

  @override
  String get comparePageTitle => 'Comparison';

  @override
  String get compareEmptyTitle => 'Comparison is empty';

  @override
  String get compareEmptyDescription =>
      'Add items from business pages to compare.';

  @override
  String get compareBackToDiscover => 'Back to Discover';

  @override
  String get compareBestPickAction => 'Show the most sensible pick';

  @override
  String get compareSuggestedBadge => 'Suggested';

  @override
  String get compareMedianPriceLabel => 'Median price';

  @override
  String get compareVerifiedRateLabel => 'Verified rate';

  @override
  String get compareLastUpdateLabel => 'Last update';

  @override
  String get compareBestItemTitle => 'Affordable item';

  @override
  String get compareGoToBusinessAction => 'Go to business';

  @override
  String get compareRemoveTooltip => 'Remove';

  @override
  String compareRecommendedSnack(String name) {
    return 'Recommendation: $name';
  }

  @override
  String get contributeDefaultBusinessName => 'this place';

  @override
  String get contributeOpenBusinessFirst =>
      'Open a business page first for this contribution.';

  @override
  String get contributeUploadingProgress => 'Sending...';

  @override
  String get contributeUploadSentSingle =>
      'Sent - will be added to the menu after review.';

  @override
  String contributeUploadSentMultiple(int count) {
    return '$count pages sent - will be added to the menu after review.';
  }

  @override
  String get contributeUploadFailed => 'Upload failed. Please try again.';

  @override
  String get contributeQrDecodingProgress => 'Decoding QR...';

  @override
  String get contributeQrUnreadableSentReview =>
      'QR couldn\'t be read. Sending for visual review.';

  @override
  String get contributeQrVerifiedRedirecting => 'QR verified. Redirecting you.';

  @override
  String get contributeQrProcessFailed =>
      'QR processing failed. Please try again.';

  @override
  String get contributeExternalQrUseBusinessPage =>
      'For external QR codes, use Contribute from the business page.';

  @override
  String get contributeSendingForReviewProgress => 'Sending for review...';

  @override
  String get contributeQrImageSentForReview =>
      'QR image sent. It will be processed after review.';

  @override
  String get contributeExternalLinkSentForReview =>
      'External link sent for review.';

  @override
  String get contributeSourceCamera => 'Camera';

  @override
  String get contributeSourceGallery => 'Gallery';

  @override
  String get contributeSelectBusinessForPriceVerification =>
      'Select a business first for price verification.';

  @override
  String get contributeSelectMenuItemToVerifyPrice =>
      'Select one menu item and verify its price.';

  @override
  String get discoveryFilterCafe => 'Cafe';

  @override
  String get discoveryFilterRestaurant => 'Restaurant';

  @override
  String get discoveryFilterDessertPastry => 'Dessert / Pastry';

  @override
  String get discoveryFilterBreakfast => 'Breakfast';

  @override
  String get discoveryFilterFishMeat => 'Fish / Meat';

  @override
  String get discoveryFilterVenue => 'Venue';

  @override
  String get discoveryHomeCategoryDoner => 'Thin Doner';

  @override
  String get discoveryHomeCategoryPide => 'Pide';

  @override
  String get discoveryHomeCategoryLahmacun => 'Lahmacun';

  @override
  String get discoveryHomeCategoryBurger => 'Burger';

  @override
  String get discoveryHomeCategoryPizza => 'Pizza';

  @override
  String get discoveryHomeCategoryKebap => 'Kebab';

  @override
  String get discoveryHomeCategoryCorba => 'Soup';

  @override
  String get discoveryHomeCategoryKahvalti => 'Breakfast';

  @override
  String get discoveryHomeCategoryManti => 'Manti';

  @override
  String get discoveryHomeCategoryTatli => 'Dessert';

  @override
  String get discoveryRecentSearches => 'Recent searches';

  @override
  String get discoveryCatalogSuggestions => 'Catalog suggestions';

  @override
  String get discoveryFoodsGreeting => 'Hello! 👋';

  @override
  String get discoveryFoodsSearchHint => 'Search for food or category...';

  @override
  String get todaysPickTitle => 'Today\'s pick';

  @override
  String get popularFoodsTitle => 'Popular foods';

  @override
  String get feedEmptyMessage =>
      'No feed yet. Try following taste experts to get started.';

  @override
  String get all => 'All';

  @override
  String get sil => 'Delete';

  @override
  String get favoritesCollectionLabel => 'Collection';

  @override
  String get favoritesSavedHereSubtitle => 'Your saved places are here';

  @override
  String favoritesSharedCollectionSubtitle(String name) {
    return 'Shared collection: $name';
  }

  @override
  String get favoritesSearchHint => 'Search in favorites';

  @override
  String get favoritesNearbyLoadingLocation =>
      'Getting location for nearby mode...';

  @override
  String get favoritesNearbyFallbackOrdering =>
      'Location unavailable. Showing default order.';

  @override
  String get favoritesNearbySortedByDistance =>
      'Nearby items are sorted by distance.';

  @override
  String get favoritesCollectionsTitle => 'Collections';

  @override
  String get favoritesCreateCollectionTooltip => 'Create collection';

  @override
  String get favoritesShareCollectionTooltip => 'Share collection';

  @override
  String get favoritesDeleteCollectionTooltip => 'Delete collection';

  @override
  String get favoritesCreatorSelectCollectionHint =>
      'Select a collection first for creator mode.';

  @override
  String get favoritesCreatorCollectionTitle => 'Creator collection';

  @override
  String get favoritesCreatorCollectionSubtitle =>
      'Publish your collection and grow followers. Label sponsored content when needed.';

  @override
  String get favoritesPublishAction => 'Publish';

  @override
  String get favoritesPublishVisibleSubtitle =>
      'Visible on your profile and share links.';

  @override
  String get favoritesPublishPrivateSubtitle =>
      'Only you can see this collection.';

  @override
  String get favoritesSharedCollectionTitle => 'Shared collection';

  @override
  String get favoritesFollowCollectionHint =>
      'Follow this collection to avoid missing updates.';

  @override
  String get favoritesFollowAction => 'Follow';

  @override
  String get favoritesFollowingAction => 'Following';

  @override
  String favoritesFollowersChip(int count) {
    return '$count followers';
  }

  @override
  String favoritesEngagementChip(int count) {
    return '$count interactions';
  }

  @override
  String favoritesCountBanner(int count) {
    return '$count places in your favorites';
  }

  @override
  String get favoritesNewCollectionTitle => 'New Collection';

  @override
  String get favoritesCollectionNameExample => 'e.g. Late-night doner';

  @override
  String get favoritesCreateAction => 'Create';

  @override
  String get favoritesDeleteCollectionConfirmTitle => 'Delete this collection?';

  @override
  String get favoritesDeleteCollectionConfirmBody =>
      'This action cannot be undone.';

  @override
  String favoritesBusinessCollectionsTitle(String businessName) {
    return '\"$businessName\" collections';
  }

  @override
  String get favoritesNoCollectionYet => 'No collection yet. Create one first.';

  @override
  String get favoritesNewCollectionAction => 'New collection';

  @override
  String get favoritesDisclosureSponsored => 'Sponsored';

  @override
  String get favoritesDisclosureOrganic => 'Organic';

  @override
  String get favoritesDisclosurePrivate => 'Private';

  @override
  String favoritesShareText(String name, String link, String disclosure) {
    return 'My Yeedoy collection: $name\n$link\n\nMode: Nearby suggestions\nLabel: $disclosure';
  }

  @override
  String get favoritesAdDisclosureTitle => 'Sponsored content notice';

  @override
  String get favoritesAdDisclosureBody =>
      'If this collection includes a collaboration, you must mark it as \"Sponsored\".';

  @override
  String favoritesCacheStaleMessage(int days) {
    return 'Data may have been last updated $days days ago.';
  }

  @override
  String get favoritesAddToCollectionTooltip => 'Add to collection';

  @override
  String get followingPageTitle => 'Following';

  @override
  String get followingPageEmpty => 'You are not following anyone yet.';

  @override
  String get followingPageUnfollowAction => 'Unfollow';

  @override
  String get gourmetsPageTitle => 'Discover taste experts';

  @override
  String get gourmetsPageEmpty => 'No taste experts yet.';

  @override
  String get groupRequestWizardTitle => 'Group Meal Request';

  @override
  String get groupRequestWizardEnterDetails => 'Enter details';

  @override
  String get groupRequestWizardCityLabel => 'City';

  @override
  String get groupRequestWizardDistrictLabel => 'District';

  @override
  String get groupRequestWizardCategoryHint => 'Category (coffee, diner...)';

  @override
  String get groupRequestWizardPartySizeLabel => 'Party size';

  @override
  String get groupRequestWizardTotalBudgetLabel => 'Total budget (TL)';

  @override
  String get groupRequestWizardNotesLabel => 'Notes';

  @override
  String get groupRequestWizardCreateAction => 'Create Request';

  @override
  String get groupRequestWizardInfoTitle => 'Offers come from businesses';

  @override
  String get groupRequestWizardInfoDescription =>
      'After your request opens, businesses can submit offers.';

  @override
  String get groupRequestWizardMissingFields =>
      'There are missing required fields';

  @override
  String get groupRequestWizardPickDateTime => 'Pick date and time';

  @override
  String get groupRequestMyRequestsTitle => 'My Requests';

  @override
  String get groupRequestNewRequestAction => 'New Request';

  @override
  String get groupRequestNoRequestsTitle => 'No requests';

  @override
  String get groupRequestNoRequestsDescription =>
      'Create your first group meal request.';

  @override
  String groupRequestPartyAndBudget(int party, String budget) {
    return '$party people • $budget';
  }

  @override
  String get groupRequestStatusOpen => 'Open';

  @override
  String get groupRequestStatusAwarded => 'Awarded';

  @override
  String get groupRequestStatusClosed => 'Closed';

  @override
  String get groupRequestStatusCancelled => 'Cancelled';

  @override
  String get groupRequestDetailTitle => 'Group Request';

  @override
  String get groupRequestLinkCopied => 'Group link copied';

  @override
  String get groupRequestNotFound => 'Request not found';

  @override
  String get groupRequestCreatedBannerTitle => 'Your request is live';

  @override
  String get groupRequestCreatedBannerDescription =>
      'Share the group link. Everyone can add and vote on suggestions.';

  @override
  String get groupRequestLinkTitle => 'Group link';

  @override
  String get groupRequestCopyAction => 'Copy';

  @override
  String get groupRequestAddSuggestionTitle => 'Add suggestion';

  @override
  String get groupRequestAddSuggestionDescription =>
      'Pick a business, add an offer, and let the group vote.';

  @override
  String get groupRequestAddSuggestionAction => 'Add suggestion';

  @override
  String get groupRequestOffersTitle => 'Offers';

  @override
  String get groupRequestNoOffersTitle => 'No offers yet';

  @override
  String get groupRequestNoOffersDescription =>
      'Offers will appear here when submitted.';

  @override
  String get groupRequestBusinessFallback => 'Business';

  @override
  String get groupRequestTopContributorBadge => 'Top group contributor';

  @override
  String groupRequestOfferPriceLabel(String price) {
    return 'Offer: $price';
  }

  @override
  String get groupRequestUndoVoteAction => 'Undo vote';

  @override
  String get groupRequestVoteAction => 'Vote';

  @override
  String get groupRequestProcessing => 'Processing...';

  @override
  String get groupRequestAcceptOfferAction => 'Accept offer';

  @override
  String groupRequestVotesLabel(int count) {
    return 'Votes: $count';
  }

  @override
  String get groupRequestSearchMinChars => 'Type at least 2 characters';

  @override
  String get groupRequestBusinessAndPriceRequired =>
      'Business and price are required';

  @override
  String get groupRequestSuggestionAdded => 'Suggestion added';

  @override
  String get groupRequestSearchBusinessLabel => 'Search business';

  @override
  String get groupRequestSuggestIfMissing => 'Suggest if business is missing';

  @override
  String get groupRequestTryDifferentName => 'Try a different name.';

  @override
  String get groupRequestOfferTotalPriceLabel => 'Offer total price (TL)';

  @override
  String get groupRequestNoteLabel => 'Note';

  @override
  String get groupRequestChangeAction => 'Change';

  @override
  String groupRequestAcceptedSummary(String price) {
    return 'Result selected. Total: $price';
  }

  @override
  String get groupRequestCopyResultAction => 'Copy result';

  @override
  String get heroesPageTitle => 'Heroes';

  @override
  String get heroesPageSubtitle => 'People who left suspended meals';

  @override
  String get heroesPageEmpty => 'No heroes yet.';

  @override
  String get heroesPageUserFallback => 'User';

  @override
  String heroesPageDonatedMealCount(int count) {
    return '$count suspended meals';
  }

  @override
  String get verifyPriceIsCorrectQuestion => 'Is this price correct?';

  @override
  String get verifyPriceCorrectAction => 'Correct';

  @override
  String get verifyPriceIncorrectAction => 'Incorrect';

  @override
  String get verifyPriceCorrectPriceLabel => 'Correct price (TL)';

  @override
  String get verifyPriceCorrectPriceHint => 'e.g. 245.50';

  @override
  String get verifyPriceChooseCorrectnessFirst =>
      'Please choose correct/incorrect first.';

  @override
  String get verifyPriceEnterValidPrice => 'Please enter a valid price.';

  @override
  String menuItemCalories(int calories) {
    return '$calories kcal';
  }

  @override
  String get menuItemAutoApprovedMessage =>
      'Price auto-approved and menu updated.';

  @override
  String menuItemPendingCountMessage(int count) {
    return 'Suggestion received. $count suggestions are in queue for this item.';
  }

  @override
  String get menuItemPendingSingleMessage =>
      'Suggestion received and pending approval.';

  @override
  String get menuItemOnsiteVerifiedPrioritizedMessage =>
      'Thanks. On-site verification signal received; your suggestion was prioritized.';

  @override
  String get menuPhotoWarningDark => 'dark';

  @override
  String get menuPhotoWarningBlurry => 'blurry';

  @override
  String get menuContributionLevelLabel => 'Contribution Level';

  @override
  String get menuScoreUpdated => 'Your score was updated';

  @override
  String menuLevel(int level) {
    return 'Level $level';
  }

  @override
  String menuXpValue(int xp) {
    return '$xp XP';
  }

  @override
  String menuSelectedVariantLabel(String label, String price) {
    return 'Selected variant: $label ($price)';
  }

  @override
  String menuPriceHistoryCurrent(String current, String source) {
    return '$current > $source';
  }

  @override
  String menuPriceHistoryTransition(
    String previous,
    String current,
    String source,
  ) {
    return '$previous > $current > $source';
  }

  @override
  String menuPriceHistoryMeta(String relative, String date, String delta) {
    return '$relative • $date$delta';
  }

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxMarkAllRead => 'Mark all as read';

  @override
  String get inboxEmptyTitle => 'No notifications';

  @override
  String get inboxEmptyDescription =>
      'Price suggestions, claims, reports, and review reply notifications will appear here.';

  @override
  String inboxXpGain(int xp) {
    return '+$xp XP';
  }

  @override
  String inboxNewLevel(int level) {
    return 'New level: $level';
  }

  @override
  String inboxLevel(int level) {
    return 'Level: $level';
  }

  @override
  String get inboxNow => 'Now';

  @override
  String get inboxReengagementTitle => 'We missed you';

  @override
  String get inboxReengagementSubtitle => 'Check nearby new menus.';

  @override
  String get inboxRecentBusinessClosedTitle =>
      'The place you viewed last seems closed';

  @override
  String get inboxRecentBusinessPriceChangedTitle =>
      'Price changed at the place you viewed last';

  @override
  String get inboxRecentBusinessNearbyTitle =>
      'The place you viewed last is nearby';

  @override
  String get inboxRecentBusinessTitle => 'The place you viewed last';

  @override
  String get inboxRecentBusinessNearbyReason =>
      'Prioritized because it\'s near you';

  @override
  String get inboxFavoritesPriceChangedTitle =>
      'Price changed in your favorites';

  @override
  String inboxFavoritesPriceChangedSubtitle(String name, int count) {
    return '$name • Last $count verifications';
  }

  @override
  String get inboxDailyTaskTitle => 'Today\'s task for you';

  @override
  String get inboxSegmentPriceHunter =>
      'Verify 1 price today; your trust score will rise faster.';

  @override
  String get inboxSegmentPhotoProof => 'Add 1 clear menu/photo proof today.';

  @override
  String get inboxSegmentExplorer =>
      'Open a new place today and check its price status.';

  @override
  String get inboxSegmentSilentQuality =>
      'Your silent quality contribution is strong; keep data accurate.';

  @override
  String get inboxSegmentDefault =>
      'Strengthen your graph with a small contribution today.';

  @override
  String inboxAlertPriceUp(String pct) {
    return 'Price went up by %$pct';
  }

  @override
  String inboxAlertPriceDown(String pct) {
    return 'Price dropped by %$pct';
  }

  @override
  String inboxAlertCheaperNow(String pct) {
    return 'Now %$pct cheaper';
  }

  @override
  String get inboxAlertAboveDistrictAverage => 'Now above district average';

  @override
  String get inboxAlertBelowDistrictAverage => 'Now below district average';

  @override
  String get inboxAlertTriggered => 'Price alert triggered';

  @override
  String get inboxBusinessClosedArchived => 'Business closed (archived).';

  @override
  String get inboxBusinessMoved => 'Business moved.';

  @override
  String get inboxBusinessTemporarilyClosed => 'Business temporarily closed.';

  @override
  String get inboxBusinessStatusUpdated => 'Status updated';

  @override
  String get priceAlertSheetTitle => 'Create price alert';

  @override
  String get priceAlertSheetQueryLabel => 'Item or search text';

  @override
  String get priceAlertSheetMaxPriceLabel => 'Maximum price (TL)';

  @override
  String get priceAlertSheetCategoryLabel => 'Category';

  @override
  String get priceAlertSheetValidationError =>
      'Enter a search text and a valid price.';

  @override
  String get priceAlertSheetSaved => 'Price alert saved.';

  @override
  String get achievementStatusUnlocked => 'Status: Unlocked';

  @override
  String get achievementStatusLocked => 'Status: Locked';

  @override
  String get profileGuestUser => 'Guest';

  @override
  String get profileHomeTitle => 'Your Profile';

  @override
  String get profileStatFavoritesShort => 'Favorites';

  @override
  String get profileStatReviewsShort => 'Reviews';

  @override
  String get profileStatListsShort => 'Lists';

  @override
  String get profileQuickActionsTitle => 'Quick actions';

  @override
  String get profileQuickActionFavorites => 'My Favorites';

  @override
  String get profileQuickActionPriceAlerts => 'Price Alerts';

  @override
  String get profileQuickActionFeed => 'My Feed';

  @override
  String get profileAccountSectionTitle => 'Account';

  @override
  String get profileAccountSecurityTitle => 'Account Security';

  @override
  String get profileAccountSecuritySubtitle => 'Change password and email';

  @override
  String get profileBadgesBannerTitle => 'Your Badge Collection';

  @override
  String profileBadgesBannerCount(int count) {
    return 'You have $count badges!';
  }

  @override
  String get profileBadgesBannerSubtitle =>
      'Keep exploring to earn new badges! 🚀';

  @override
  String get profileIdentitySupportMessage =>
      'You can strengthen your profile by contributing to the community.';

  @override
  String get profileAlertsTab => 'Alerts';

  @override
  String get profileFeedTab => 'Feed';

  @override
  String get profileLoginToSeeContributions =>
      'Sign in to see your contributions and stats.';

  @override
  String get profileCreatorBadgeTitle => 'Creator badge';

  @override
  String get profileCreatorBadgeEnabled =>
      'Your profile is shown as a creator.';

  @override
  String get profileCreatorBadgeDisabled =>
      'You can enable the creator badge if you want.';

  @override
  String get profileAddSocialLinkTitle => 'Add social link';

  @override
  String get linkLabel => 'Link';

  @override
  String get profileSocialLinksHint => 'YouTube / Instagram / Facebook';

  @override
  String get profileSocialSaveComingSoon =>
      'Saving social links is coming soon.';

  @override
  String get profileSocialSaved => 'Social link saved.';

  @override
  String get profileSocialSaveError => 'Could not save. Please try again.';

  @override
  String get profileStatsTitle => 'Profile stats';

  @override
  String get profileCommunityTrustTitle => 'Community trust';

  @override
  String get profileCalculating => 'Calculating...';

  @override
  String profileTrustScorePercent(int score) {
    return 'Community trust: %$score';
  }

  @override
  String profileLevelXp(int level, int xp) {
    return 'Level $level • Total $xp XP';
  }

  @override
  String get profileMyAchievementsTitle => 'My achievement badges';

  @override
  String get profileNoAchievementYet => 'You have not earned a badge yet.';

  @override
  String get profileAlertsLoginRequired => 'Sign in to view alerts.';

  @override
  String get profileAlertsEmpty => 'No alert notifications yet.';

  @override
  String get profileFeedLoginRequired => 'Sign in to view your feed.';

  @override
  String get profileFeedEmpty => 'No feed items yet.';

  @override
  String get profileFeedEventPriceVerified => 'Price verified';

  @override
  String get profileFeedEventMenuUpdated => 'Menu updated';

  @override
  String get profileFeedEventSponsored => 'Sponsored update';

  @override
  String get profileDailyTaskTitle => 'Today\'s task';

  @override
  String get profileDailyTaskCompleted => 'Completed';

  @override
  String get profileSegmentHintPriceHunter =>
      'You are strong at price checks; one item verification today is enough.';

  @override
  String get profileSegmentHintPhotoProof =>
      'You are evidence-focused; a clear menu photo increases your impact.';

  @override
  String get profileSegmentHintExplorer =>
      'You are exploration-focused; checking a new business speeds up progress.';

  @override
  String get profileSegmentHintDefault =>
      'Small but accurate contributions grow your trust graph the fastest.';

  @override
  String get profileStatReviews => 'Reviews';

  @override
  String get profileStatHelpfulVotes => 'Helpful votes';

  @override
  String get profileStatFavorites => 'Favorites';

  @override
  String get profileStatContributions => 'Contributions';

  @override
  String get profileStatVisits => 'Visits';

  @override
  String get profileLatestAchievementTitle => 'Latest earned achievement';

  @override
  String profileAlertCurrentPrice(String price) {
    return 'Current price: $price TL';
  }

  @override
  String profileAlertPriceChanged(String previous, String current) {
    return 'Price changed: $previous → $current TL';
  }

  @override
  String get profileSegmentPriceHunter => 'Price hunter';

  @override
  String get profileSegmentExplorer => 'Explorer';

  @override
  String get profileSegmentPhotoProof => 'Photo proof';

  @override
  String get profileSegmentBalanced => 'Balanced';

  @override
  String get profileMoatSignalsTitle => 'Supporting signals';

  @override
  String get profileSignalTrust => 'Trust';

  @override
  String get profileSignalAccuracy => 'Accuracy';

  @override
  String get profileSignalSegment => 'Contribution style';

  @override
  String get profileSignalSilentQuality => 'Quality streak';

  @override
  String get profileSignalApprovalRate => 'Approval rate';

  @override
  String get profileSupportSignalsSummary =>
      'These signals feed your community trust; they are not separate primary scores.';

  @override
  String profileMoatTrustedRejectedSpam(int trusted, int rejected, int spam) {
    return 'Trusted contributions: $trusted • Rejected: $rejected • Spam signals: $spam';
  }

  @override
  String profileMoatBehaviorSummary(int price, int discovery, int photo) {
    return 'Behavior: price $price, discovery $discovery, photo $photo';
  }

  @override
  String get profileMoatSilentQualityHint =>
      'Your quality streak is strong; fewer but accurate contributions stand out.';

  @override
  String get businessReviewsCommunityExperiences => 'Community experiences';

  @override
  String get businessReviewsOwnerCanModerate =>
      'Business owners can moderate inappropriate reviews.';

  @override
  String get businessReviewsOwnersCanOnlyReply =>
      'Business owners can only reply to reviews.';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortMostHelpful => 'Most helpful';

  @override
  String get sortVerified => 'Verified first';

  @override
  String businessReviewsQualityLabel(String score) {
    return 'Quality score: $score';
  }

  @override
  String helpfulCount(int count) {
    return 'Helpful ($count)';
  }

  @override
  String get businessReviewsEmpty => 'No reviews yet.';

  @override
  String get reviewCreateRatingLabel => 'Rating';

  @override
  String get reviewCreateOptionalTitleLabel => 'Title (optional)';

  @override
  String get reviewCreateContentRequired => 'Review cannot be empty.';

  @override
  String get reviewCreateSubmitted => 'Review submitted.';

  @override
  String get reviewCreateErrorNewAccountRateLimited =>
      'Daily review limit reached for new accounts.';

  @override
  String get reviewCreateErrorSameBusinessCooldown =>
      'You cannot submit another review for the same business so soon.';

  @override
  String get reviewCreateErrorContainsLinkOrPhone =>
      'You cannot include links or phone numbers in a review.';

  @override
  String get reviewCreateErrorContainsProfanity =>
      'Review contains inappropriate language.';

  @override
  String get reviewCreateErrorEmojiSpam => 'Review contains too many emojis.';

  @override
  String get quality => 'Quality';

  @override
  String get smartFeedEmptyTitle => 'No feed yet';

  @override
  String get smartFeedEmptyDescription =>
      'You can loosen filters or add the first contribution.';

  @override
  String get smartFeedCurationTitle => 'Curation';

  @override
  String get smartFeedCategoriesLabel => 'Categories';

  @override
  String get smartFeedScenarioLabel => 'Scenario';

  @override
  String smartFeedBudgetMax(String amount) {
    return 'Up to ₺$amount';
  }

  @override
  String get smartFeedUnlimited => 'Unlimited';

  @override
  String smartFeedPreferenceHint(String label) {
    return 'Preference: $label';
  }

  @override
  String smartFeedScenarioHint(String label) {
    return 'Scenario: $label';
  }

  @override
  String get smartFeedContextDefault =>
      'We prepare today\'s feed according to your rhythm.';

  @override
  String get smartFeedCategoryMeyhane => 'Tavern';

  @override
  String get smartFeedCategoryAffordable => 'Affordable';

  @override
  String get smartFeedBundleStudentFriendly => 'Student friendly';

  @override
  String get smartFeedBundleFirstDate => 'First date';

  @override
  String get smartFeedBundleNightSoup => 'Night soup';

  @override
  String smartFeedMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String smartFeedHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String smartFeedDaysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get smartFeedEventMenu => 'Menu';

  @override
  String get smartFeedEventPrice => 'Price';

  @override
  String get smartFeedEventPhoto => 'Photo';

  @override
  String get smartFeedEventDaily => 'Daily';

  @override
  String get smartFeedEventSponsor => 'Sponsor';

  @override
  String get smartFeedFallbackPriceChanged => 'Price updated';

  @override
  String get smartFeedFallbackPhotoAdded => 'New photo added';

  @override
  String get smartFeedFallbackDailyMenu => 'Menu of the day';

  @override
  String get smartFeedFallbackNewContent => 'New content';

  @override
  String get smartFeedCtaGoToMenu => 'Go to menu';

  @override
  String get smartFeedCtaOpenItem => 'Open item';

  @override
  String get smartFeedCtaViewPhoto => 'View photo';

  @override
  String get smartFeedCtaGoToBusiness => 'Go to business';

  @override
  String smartFeedNearbyKm(String km) {
    return '$km km near you';
  }

  @override
  String get smartFeedReasonCategoryMatch => 'Category matches you';

  @override
  String get smartFeedReasonScenarioMatch => 'Your scenario';

  @override
  String get smartFeedReasonSimilarUsers => 'Loved by similar users';

  @override
  String get smartFeedDayWeekend => 'Weekend';

  @override
  String get smartFeedDayWeekday => 'Weekday';

  @override
  String get smartFeedTimeMorning => 'Morning';

  @override
  String get smartFeedTimeNoon => 'Noon';

  @override
  String get smartFeedTimeEvening => 'Evening';

  @override
  String get smartFeedTimeNight => 'Night';

  @override
  String get suggestBusinessSubmitDialogTitle => 'Suggestion received?';

  @override
  String suggestBusinessSubmitDialogContent(String code) {
    return 'Thanks! The business will be published after review.\n\nTracking Code: $code';
  }

  @override
  String get ok => 'OK';

  @override
  String get suggestBusinessPageTitle => 'Add Business';

  @override
  String get suggestBusinessPageSubtitle =>
      'Add the business you found and contribute to the community. We publish it after review.';

  @override
  String get suggestBusinessNameLabel => 'Business name';

  @override
  String get requiredField => 'Required';

  @override
  String get suggestBusinessCategoryLabel => 'Category';

  @override
  String get suggestBusinessAddressLabel => 'Address';

  @override
  String get suggestBusinessPhoneLabel => 'Phone';

  @override
  String get suggestBusinessWebsiteLabel => 'Website';

  @override
  String get suggestBusinessDuplicateTitle => 'This business may already exist';

  @override
  String get suggestBusinessDuplicateFound => 'Similar businesses were found:';

  @override
  String get suggestBusinessDuplicateConfirm =>
      'Do you still want to submit a new suggestion?';

  @override
  String get suggestBusinessSendAnyway => 'Send anyway';

  @override
  String get suggestBusinessOpenAction => 'Open';

  @override
  String get copy => 'Copy';

  @override
  String get topBusinessesNotEnoughData => 'Not enough data yet.';

  @override
  String get topBusinessesBadgeMonth => 'Month';

  @override
  String get topBusinessesBadgeWeek => 'Week';

  @override
  String get suspendedMealsMyClaimsTitle => 'My Suspended Meals';

  @override
  String get suspendedMealsStatusCodeReady => 'Code ready';

  @override
  String get suspendedMealsStatusFulfilled => 'Collected';

  @override
  String get suspendedMealsNoRecords => 'No records.';

  @override
  String get suspendedMealsDeliveryCode => 'Delivery code';

  @override
  String get suspendedMealsCodeCopied => 'Code copied';

  @override
  String get suspendedMealsCodeHint =>
      'Go to the restaurant and share this code.';

  @override
  String get suspendedMealsPendingReview => 'Under review';

  @override
  String suspendedMealsMonthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String get tasteTwinTitle => 'Taste Twin';

  @override
  String get tasteTwinLoginRequired => 'You need to sign in to view this page.';

  @override
  String get tasteTwinSubtitle =>
      'People who are similar to you based on your ratings';

  @override
  String get tasteTwinNoMatches => 'No matches yet.';

  @override
  String tasteTwinMatchSummary(int similarity, int places) {
    return '%$similarity match • $places shared places';
  }

  @override
  String get tasteTwinSignalHint => 'Review + menu signals';

  @override
  String get tasteTwinViewSuggestions => 'View suggestions';

  @override
  String tasteTwinRecommendationsTitle(String name) {
    return '$name\'s suggestions';
  }

  @override
  String get tasteTwinFollowGourmet => 'Follow this gourmet';

  @override
  String get tasteTwinNoSuggestionsYet => 'No suggestions for now.';

  @override
  String get tasteTwinWhyMatchedTitle => 'Why did you match?';

  @override
  String get tasteTwinReviewOverlapTitle => 'Review overlap';

  @override
  String get tasteTwinNoSampleYet => 'No samples yet.';

  @override
  String get tasteTwinMenuSignalOverlapTitle => 'Menu signal overlap';

  @override
  String get tasteTwinMenuSignalOverlapHint =>
      'Price verification / photo likes / photo contribution signals';

  @override
  String get tasteTwinDivergenceTitle => 'You disagreed here :)';

  @override
  String tasteTwinRatingComparison(int myRating, int otherRating) {
    return 'You: $myRating • Other: $otherRating';
  }

  @override
  String tasteTwinYouAt(String value) {
    return 'You $value';
  }

  @override
  String tasteTwinSignalComparison(int mySignal, int otherSignal) {
    return 'You: +$mySignal • Other: +$otherSignal';
  }

  @override
  String tasteTwinMatchRated(int rating) {
    return 'Your match gave $rating points';
  }

  @override
  String tasteTwinRatedAt(String when, String text) {
    return '$when $text';
  }

  @override
  String tasteTwinDebugReviewAndSignal(int review, int signal) {
    return 'Review $review% + signal $signal%';
  }

  @override
  String tasteTwinDebugReviewOnly(int review) {
    return 'Review $review%';
  }

  @override
  String tasteTwinDebugSignalOnly(int signal) {
    return 'Signal $signal%';
  }

  @override
  String get tasteTwinTodayLower => 'today';

  @override
  String get tasteTwinYesterdayLower => 'yesterday';

  @override
  String get use => 'Use';

  @override
  String get quickLoginTitle => 'Sign in to continue';

  @override
  String get quickLoginDescription =>
      'This action requires an account. You can sign in or skip for now.';

  @override
  String get quickLoginAction => 'Quick sign in';

  @override
  String get statusBadgeVerified => 'Verified';

  @override
  String get statusBadgePending => 'Pending';

  @override
  String get statusBadgeOutdated => 'Outdated';

  @override
  String get locationPickerManualHint =>
      'Manual selection works at city/district level. For better nearby quality, radius (5/10/20 km) and location permission give better results.';

  @override
  String get locationPickerUseAuto => 'Use automatic location';

  @override
  String get locationPickerMakeDefault => 'Set as default';

  @override
  String get locationPickerMakeDefaultHint =>
      'Use this location on next app launch too.';

  @override
  String get locationPickerRecent => 'Recent selections';

  @override
  String get locationPickerSearchDistrict => 'Search district';

  @override
  String get locationPickerPopularDistricts => 'Popular districts';

  @override
  String locationPickerBusinessCount(String city, int count) {
    return '$city • $count businesses';
  }

  @override
  String get legalPageTitle => 'Legal and Trust';

  @override
  String get legalKvkkSectionTitle => 'KVKK / GDPR';

  @override
  String get legalKvkkIntro =>
      'Yeedoy processes personal data only to provide the service. Consent is requested where required, and data is deleted or exported upon request.';

  @override
  String get legalKvkkCategoriesAndRights =>
      'Data categories: profile, location, device information, usage analytics. Rights: access, correction, deletion, objection, portability.';

  @override
  String get legalPrivacyPolicy => 'Privacy Policy';

  @override
  String get legalKvkkText => 'KVKK Text';

  @override
  String get legalGdprText => 'GDPR Text';

  @override
  String get legalApplicationByEmail =>
      'Application: create a request by email.';

  @override
  String get legalCopyrightSectionTitle => 'Photo Copyright Notice';

  @override
  String get legalCopyrightIntro =>
      'Menu and venue photos may be subject to copyright. If you see a violation, submit it via Report > Copyright.';

  @override
  String get legalCopyrightDetails =>
      'A content link, proof, and short explanation are enough for copyright notice. Verified violations are removed.';

  @override
  String get legalCopyrightPolicy => 'Copyright Policy';

  @override
  String get legalOwnershipAppealSectionTitle => 'Business Ownership Appeal';

  @override
  String get legalOwnershipAppealIntro =>
      'If your ownership request was rejected, you can appeal. Your documents are reviewed again.';

  @override
  String get legalOwnershipAppealRequiredInfo =>
      'Required information for appeal:';

  @override
  String get legalOwnershipAppealRequiredList =>
      '• Business legal name and tax/license info\n• Authorization document\n• Contact phone number';

  @override
  String get legalSendAppealEmail => 'Send appeal email';

  @override
  String get legalProductPrinciplesSectionTitle => 'Product Principles';

  @override
  String get legalDontsTitle => 'Things not to do:';

  @override
  String get legalDontsList =>
      '• Open everything to everyone\n• Hide sponsored content\n• Give owner accounts review delete access\n• Lower quality thresholds for growth';

  @override
  String legalPolicySummary(
    String requireSponsoredLabel,
    String minSponsoredTrust,
    String ownerCanDeleteReviews,
  ) {
    return 'Policy: sponsored label required=$requireSponsoredLabel, minimum sponsored trust=$minSponsoredTrust, owner review delete=$ownerCanDeleteReviews.';
  }

  @override
  String get legalFooter =>
      'Current policy texts and details are published on the website.';

  @override
  String topBusinessReviews(int count) {
    return 'Reviews: $count';
  }

  @override
  String get reportRateLimitBusiness =>
      'You already sent a report for this business today.';

  @override
  String get reportRateLimitReview =>
      'You already sent a report for this review in the last 24 hours.';

  @override
  String get reportRateLimitPhoto =>
      'You already sent a report for this photo in the last 24 hours.';

  @override
  String get reportReasonSpam => 'Spam / advertisement';

  @override
  String get reportReasonAbuse => 'Abuse / inappropriate';

  @override
  String get reportReasonWrongInfo => 'Wrong information';

  @override
  String get reportReasonCopyright => 'Copyright violation';

  @override
  String get reportReasonIllegal => 'Illegal';

  @override
  String get reportReasonWrongImage => 'Wrong image';

  @override
  String get reportReasonClosed => 'Business closed';

  @override
  String get reportReasonMoved => 'Moved';

  @override
  String get reportReasonWrongPrice => 'Wrong price';

  @override
  String get reportBusinessHint =>
      'Too many wrong-information reports reduce visibility. It rises again after owner verification.';

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get reportCopyrightUrlLabel => 'Violation URL (photo link)';

  @override
  String get reportCopyrightOwnerLabel => 'Copyright owner name (optional)';

  @override
  String get reportCopyrightEmailLabel => 'Copyright owner email (optional)';

  @override
  String get reportDetailsLabel => 'Details (optional)';

  @override
  String get reportSubmittedThanks => 'Thanks, it will be reviewed.';

  @override
  String get reportCopyrightUrlPrefix => 'Violation URL';

  @override
  String get reportCopyrightOwnerPrefix => 'Owner';

  @override
  String get reportCopyrightEmailPrefix => 'Email';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get weatherHeadlineRainy => 'Rainy weather';

  @override
  String get weatherHeadlineSnowy => 'Cold weather';

  @override
  String get weatherHeadlineHot => 'Hot weather';

  @override
  String get weatherHeadlineClear => 'Clear weather';

  @override
  String get weatherHintRainy => 'A warm option sounds good';

  @override
  String get weatherHintSnowy => 'A hot soup sounds good';

  @override
  String get weatherHintHot => 'A refreshing option sounds good';

  @override
  String get weatherHintClear => 'Outdoor seating feels great';

  @override
  String get paste => 'Paste';

  @override
  String get addFirstMenuCta => 'Add first menu';

  @override
  String get vatIncluded => 'VAT included';

  @override
  String businessViewingNow(int count) {
    return '$count people viewing now';
  }

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get create => 'Create';

  @override
  String get required => 'This field is required';

  @override
  String get collabListsTitle => 'My Shared Lists';

  @override
  String get collabListCreate => 'Create List';

  @override
  String get collabListsEmpty => 'No lists yet';

  @override
  String get collabListsEmptyDesc =>
      'Create shared lists with friends and vote on favorite spots together.';

  @override
  String get collabListNameLabel => 'List name';

  @override
  String get collabListDescLabel => 'Description (optional)';

  @override
  String get collabListItemsEmpty => 'List is empty';

  @override
  String get collabListItemsEmptyDesc =>
      'Add businesses from their page to this list.';

  @override
  String get collabListShare => 'Copy Invite Link';

  @override
  String get collabListDelete => 'Delete List';

  @override
  String get collabListDeleteConfirm =>
      'Are you sure you want to delete this list and all its content?';

  @override
  String get collabListLeave => 'Leave List';

  @override
  String get collabListLeaveConfirm =>
      'Are you sure you want to leave this list?';

  @override
  String get collabListLinkCopied => 'Invite link copied';

  @override
  String get collabListJoining => 'Joining list...';

  @override
  String get collabListInvalidInvite => 'Invalid invite link.';

  @override
  String get goToMyLists => 'Go to My Lists';

  @override
  String get businessTabGeneral => 'General';

  @override
  String get businessTabMenu => 'Menu';

  @override
  String get businessTabReviews => 'Reviews';

  @override
  String get businessBadgeMenuVerified => 'Verified Menu';

  @override
  String get businessBadgePopular => 'Popular';

  @override
  String get businessBadgeDelivery => 'Delivery';

  @override
  String get businessBadgeDineIn => 'Dine In';

  @override
  String get featuredSectionTitle => 'Featured';

  @override
  String get featuredRatingLabel => 'Rating';

  @override
  String get featuredMenuVerifiedSubtitle => 'Updated by the owner';

  @override
  String get popularDishesTitle => 'Popular dishes';

  @override
  String get locationHoursTitle => 'Location & hours';

  @override
  String get directions => 'Directions';

  @override
  String get viewMenu => 'View Menu';
}
