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
  String get nearbyVerifiedSpots => 'Nearby Verified Spots';

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
  String get trustDataUnavailable => 'Trust data unavailable';

  @override
  String get freshnessAndTrust => 'Freshness and trust';

  @override
  String get menuUpdatedLabel => 'Menu Updated';

  @override
  String get lastPriceVerification => 'Last Price Verification';

  @override
  String get trustScoreLabel => 'Trust Score';

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
  String featuredFromCuisine(String category, Object cuisine) {
    return 'Featured from $category cuisine.';
  }

  @override
  String get weeklyPriceChange => '+₺50 this week';

  @override
  String get chartPlaceholderSoon => 'Chart area (coming soon)';

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
  String amenityCountLabel(Object count) {
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
  String rankedAt(String prefix, int rank) {
    return '$prefix ranked #$rank';
  }

  @override
  String yourScore(Object score) {
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
      'This trust score is not user voting; it is based on contribution quality.';

  @override
  String plusPoints(int points) {
    return '+$points points';
  }

  @override
  String get verifyContributionRaisedScore =>
      'Your price verification increased your contribution score.';

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
  String get ownerSections => 'Sections';

  @override
  String get ownerAddSection => 'Add Section';

  @override
  String get ownerSectionNotFound => 'No sections yet.';

  @override
  String get ownerEditSection => 'Edit Section';

  @override
  String get ownerDeleteSection => 'Delete Section';

  @override
  String get ownerSectionWillBeDeleted => 'This section will be deleted.';

  @override
  String get ownerArchiveItemsInSection => 'Archive items in this section';

  @override
  String get ownerSectionAdded => 'Section added.';

  @override
  String get ownerSectionUpdated => 'Section updated.';

  @override
  String get ownerSectionDeleted => 'Section deleted.';

  @override
  String get ownerEditMenu => 'Edit Menu';

  @override
  String get ownerMenuTypeOptional => 'Menu type (optional)';

  @override
  String get ownerMenuUpdated => 'Menu updated.';

  @override
  String get ownerArchiveMenuConfirm => 'Do you want to archive this menu?';

  @override
  String get ownerPublishMenuConfirm => 'Do you want to publish this menu?';

  @override
  String get ownerSharePanel => 'Menu Share Panel';

  @override
  String get ownerMenuLink => 'Menu link';

  @override
  String get ownerQrPng => 'QR PNG';

  @override
  String get ownerQrPdf => 'QR PDF';

  @override
  String get ownerA6Pdf => 'A6 PDF';

  @override
  String get ownerFieldGainCardTitle => 'Visibility card for in-store use';

  @override
  String get ownerFieldGainCardLine1 =>
      'Print the QR card and ask customers to verify your menu.';

  @override
  String get ownerFieldGainCardLine2 =>
      'The more up-to-date your menu is, the more visible you become.';

  @override
  String get ownerCopyMiniDashboard => 'Copy mini dashboard link';

  @override
  String get ownerMoatTitle => 'Business trust summary';

  @override
  String ownerMoatSummary(int trust, int freshness, int accuracy) {
    return 'Trust: $trust | Menu freshness: $freshness | Price accuracy: $accuracy';
  }

  @override
  String ownerMoatSignal(int validators, int evidencePct, int viewsToday) {
    return 'Signal: $validators validators, evidence rate %$evidencePct, menu views today: $viewsToday';
  }

  @override
  String get ownerCopyMoatText => 'Copy summary text';

  @override
  String get ownerWhatsappText => 'WhatsApp text';

  @override
  String get ownerCopyWhatsapp => 'Copy for WhatsApp';

  @override
  String get ownerXText => 'X (Twitter) text';

  @override
  String get ownerCopyX => 'Copy for X';

  @override
  String get ownerInstagramBio => 'Instagram bio text';

  @override
  String get ownerCopyInstagram => 'Copy for Instagram';

  @override
  String get ownerCopied => 'Copied';

  @override
  String ownerNearbyViewed(int count) {
    return '$count people nearby viewed this menu';
  }

  @override
  String ownerViewed(int count) {
    return '$count people viewed';
  }

  @override
  String get ownerCurrentMenuVerifiedPrices =>
      'Current menu and verified prices';

  @override
  String get ownerCurrentMenuVerifiedPricesColon =>
      'Current menu and verified prices:';

  @override
  String get ownerStatusPublished => 'Published';

  @override
  String get ownerStatusArchived => 'Archived';

  @override
  String get ownerStatusDraft => 'Draft';

  @override
  String ownerMenuStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get ownerProducts => 'Items';

  @override
  String get ownerApplying => 'Applying...';

  @override
  String get ownerBulkPrice => 'Bulk Price';

  @override
  String get ownerCsvImport => 'CSV Import';

  @override
  String get ownerAddItem => 'Add Item';

  @override
  String get ownerProductNotFound => 'No items yet.';

  @override
  String get ownerLoadMore => 'Load more';

  @override
  String get ownerEditItem => 'Edit Item';

  @override
  String get ownerItemAdded => 'Item added.';

  @override
  String get ownerItemUpdated => 'Item updated.';

  @override
  String get ownerArchiveItemConfirm => 'Do you want to archive this item?';

  @override
  String get ownerItemArchived => 'Item archived.';

  @override
  String get ownerBulkPriceUpdate => 'Bulk price update';

  @override
  String get ownerMethod => 'Method';

  @override
  String get ownerPercent => 'Percent';

  @override
  String get ownerFixedAmountTl => 'Fixed amount (TL)';

  @override
  String get ownerOperation => 'Operation';

  @override
  String get ownerIncrease => 'Increase';

  @override
  String get ownerDecrease => 'Decrease';

  @override
  String get ownerValuePercent => 'Value (%)';

  @override
  String get ownerValueTl => 'Value (TL)';

  @override
  String get ownerEnterValidValue => 'Please enter a valid value.';

  @override
  String ownerUpdatedItemPrices(int count) {
    return 'Updated prices for $count items.';
  }

  @override
  String get ownerCsvFormatHint => 'Format: name,price,description,currency';

  @override
  String get ownerSelecting => 'Selecting...';

  @override
  String get ownerSelectFile => 'Select File';

  @override
  String get ownerCsvExample => 'Doner,220,100 gr meat,TRY';

  @override
  String get ownerImportContent => 'Import';

  @override
  String get ownerNoValidRows => 'No valid rows found.';

  @override
  String ownerImportedItems(int success) {
    return 'Imported $success items.';
  }

  @override
  String ownerImportedItemsWithSkipped(int success, int failed) {
    return 'Added $success items, skipped $failed rows.';
  }

  @override
  String get ownerAreYouSure => 'Are you sure?';

  @override
  String get ownerConfirm => 'Confirm';

  @override
  String get ownerArchiveAction => 'Archive';

  @override
  String get ownerPublishAction => 'Publish';

  @override
  String get ownerDelete => 'Delete';

  @override
  String get ownerItemName => 'Item name';

  @override
  String get ownerDescriptionOptional => 'Description (optional)';

  @override
  String get ownerPriceTl => 'Price (TL)';

  @override
  String get ownerCurrency => 'Currency';

  @override
  String get ownerCatalogSearch => 'Search catalog';

  @override
  String get ownerCatalogSearchHint => 'e.g. Kofte, Burger...';

  @override
  String ownerSelectedCatalogId(int id) {
    return 'Selected catalog ID: $id';
  }

  @override
  String get ownerItemNameMin2 => 'Item name must be at least 2 characters.';

  @override
  String get ownerInvalidPrice => 'Invalid price.';

  @override
  String get ownerVariants => 'Variants';

  @override
  String get ownerAddVariant => 'Add Variant';

  @override
  String get ownerNoVariantsHint => 'No variants yet. Example: 80gr / 120gr';

  @override
  String get ownerDefaultVariant => 'Default';

  @override
  String get ownerSetDefault => 'Set default';

  @override
  String get ownerLabelExample => 'Label (e.g. 120gr)';

  @override
  String get ownerDefaultVariantSwitch => 'Default variant';

  @override
  String get ownerPhotos => 'Photos';

  @override
  String get ownerUploading => 'Uploading...';

  @override
  String get ownerAddPhoto => 'Add Photo';

  @override
  String get ownerNoPhotoYet => 'No photos yet.';

  @override
  String get ownerViewAll => 'View all';

  @override
  String get ownerPhotoUploaded => 'Photo uploaded.';

  @override
  String get ownerDeletePhoto => 'Delete photo';

  @override
  String get ownerDeletePhotoConfirm => 'This photo will be deleted.';

  @override
  String get ownerPhotoDeleted => 'Photo deleted.';

  @override
  String get adminAppealsTitle => 'Appeals Queue';

  @override
  String get adminAppealsEmptySla =>
      'No appeals. Target SLA: reports 24h, ownership claims 48h.';

  @override
  String adminAppealSourceAndUser(String sourceId, String userId) {
    return 'Source: $sourceId · User: $userId';
  }

  @override
  String adminAppealDecisionTitle(String id) {
    return 'Appeal Decision · $id';
  }

  @override
  String get adminAppealApproveAction => 'Approve';

  @override
  String get adminAppealRejectAction => 'Reject';

  @override
  String get adminAppealDecisionLabel => 'Decision';

  @override
  String get adminAppealTemplateLabel => 'Template';

  @override
  String get adminAppealDecisionTextLabel => 'Decision note';

  @override
  String get adminAppealDecisionTextHint =>
      'Short explanation shown to the user';

  @override
  String get ownerNewBusinessTitle => 'Add new business';

  @override
  String get ownerNewBusinessIntro =>
      'Fill out the form to add your new business.';

  @override
  String get ownerBusinessNameLabel => 'Business name';

  @override
  String get ownerCategoryLabel => 'Category';

  @override
  String get ownerAddressLabel => 'Address';

  @override
  String get ownerPhoneOptionalLabel => 'Phone (optional)';

  @override
  String get ownerWebsiteOptionalLabel => 'Website (optional)';

  @override
  String get ownerSubmitApplication => 'Submit application';

  @override
  String get ownerSubmitting => 'Submitting...';

  @override
  String get ownerRequiredFieldsWarning => 'Please fill in required fields.';

  @override
  String get ownerApplicationReceived => 'Application received.';

  @override
  String get ownerBusinessesTitle => 'My businesses';

  @override
  String get ownerChainPage => 'Chain page';

  @override
  String get ownerMyApplications => 'My applications';

  @override
  String get ownerLinksUpdated => 'Links updated.';

  @override
  String get ownerReservationOrderLinksTitle => 'Reservation and order links';

  @override
  String get ownerReservationUrlLabel => 'Reservation URL';

  @override
  String get ownerYemeksepetiUrlLabel => 'Yemeksepeti URL';

  @override
  String get ownerTrendyolGoUrlLabel => 'Trendyol Go URL';

  @override
  String get ownerGetirUrlLabel => 'Getir URL';

  @override
  String get ownerChainLabel => 'Brand/Chain';

  @override
  String get ownerAllBranches => 'All branches';

  @override
  String get ownerBranchLabel => 'Branch';

  @override
  String ownerChainPrefix(String chain) {
    return 'Chain: $chain';
  }

  @override
  String get ownerPriceVerificationAction => 'Price verification';

  @override
  String get ownerRequestsAction => 'Requests';

  @override
  String get ownerRequestsOwnerOnly => 'Requests (owner)';

  @override
  String get ownerReservationOrderLinksAction => 'Reservation/Order links';

  @override
  String get ownerStatsNotFound => 'No stats found.';

  @override
  String get ownerPerformanceLast30Days => 'Last 30 days performance';

  @override
  String get ownerMetricMenuViews => 'Menu views';

  @override
  String get ownerMetricQrScans => 'QR scans';

  @override
  String get ownerMetricSearchImpressions => 'Search impressions';

  @override
  String get ownerMetricConversion => 'Conversion';

  @override
  String get ownerMetricOutboundClicks => 'Outbound clicks';

  @override
  String get ownerMetricPriceDropoff => 'Dropoff due to price (estimated)';

  @override
  String get ownerMetricPriceVsCompetitors => 'Price vs competitors';

  @override
  String ownerOutboundClicksValue(int outbound, int reservation, int order) {
    return '$outbound (Res: $reservation, Order: $order)';
  }

  @override
  String ownerPricePositionHigher(String pct) {
    return 'Higher$pct';
  }

  @override
  String ownerPricePositionLower(String pct) {
    return 'Lower$pct';
  }

  @override
  String get ownerPricePositionSimilar => 'In line with market';

  @override
  String get ownerPricePositionNoData => 'Not enough data';

  @override
  String get ownerNoBusinessesTitle => 'No businesses yet';

  @override
  String get ownerNoBusinessesDescription =>
      'You can create a new business application.';

  @override
  String get ownerRoleOwner => 'Owner';

  @override
  String get ownerRoleManager => 'Manager';

  @override
  String get ownerMenuAction => 'Menu';

  @override
  String get city => 'City';

  @override
  String get district => 'District';

  @override
  String ownerActiveRange(String from, String to) {
    return 'Active: $from - $to';
  }

  @override
  String get vatIncluded => 'VAT included';

  @override
  String get webHomeSubtitle =>
      'Live menu, price transparency, and community verification platform.';

  @override
  String get webHomeNextLinkLabel => 'QR Menu Web (Next.js)';

  @override
  String get webHomeBusinessAreaTitle => 'Business Area';

  @override
  String get webHomeBusinessAreaSubtitle =>
      'Sign in with your business or admin account to access the panel.';

  @override
  String get webHomeBusinessLogin => 'Business Login';

  @override
  String get webHomeBusinessRegister => 'Business Register';

  @override
  String get businessAuthEmailLabel => 'Email';

  @override
  String get businessAuthPasswordLabel => 'Password';

  @override
  String get businessAuthPasswordRepeatLabel => 'Password (repeat)';

  @override
  String get businessLoginTitle => 'Business Login';

  @override
  String get businessLoginIntro =>
      'Sign in to access the owner or admin panel.';

  @override
  String get businessLoginNoPermissionError =>
      'This account has no business or admin permission. You can continue with business registration.';

  @override
  String get businessLoginSubmitting => 'Signing in...';

  @override
  String get businessLoginGoRegister => 'Go to Business Register';

  @override
  String get businessRegisterTitle => 'Business Register';

  @override
  String get businessRegisterIntro =>
      'Create an account to access the business panel.';

  @override
  String get businessRegisterPasswordMinError =>
      'Password must be at least 6 characters.';

  @override
  String get businessRegisterPasswordMismatchError => 'Passwords do not match.';

  @override
  String get businessRegisterSuccess =>
      'Registration created. After completing verification, you can sign in from business login.';

  @override
  String get businessRegisterSubmitting => 'Creating registration...';

  @override
  String get businessRegisterBackToLogin => 'Back to Business Login';
}
