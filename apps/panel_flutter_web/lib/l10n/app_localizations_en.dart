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
  String get map => 'Map';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get logout => 'Log Out';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get saving => 'Saving...';

  @override
  String get preview => 'Preview';

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
  String get embedUnsupported =>
      'This link is not supported as an embed. You can copy the link or open it in the browser.';

  @override
  String get embedCopyLinkAction => 'Copy link';

  @override
  String get embedOpenBrowserAction => 'Open in browser';

  @override
  String get back => 'Back';

  @override
  String reviewsCount(int count) {
    return 'Reviews ($count)';
  }

  @override
  String get openNow => 'Open now';

  @override
  String get verified => 'Verified';

  @override
  String get businessLabel => 'Business';

  @override
  String get menu => 'Menu';

  @override
  String get apply => 'Apply';

  @override
  String get unknown => 'Unknown';

  @override
  String get title => 'Title';

  @override
  String get approved => 'Approved';

  @override
  String get tumu => 'All';

  @override
  String get pending => 'Pending';

  @override
  String get rejected => 'Rejected';

  @override
  String get duzenle => 'Edit';

  @override
  String get sla => 'SLA';

  @override
  String get yenile => 'Refresh';

  @override
  String get start => 'Start';

  @override
  String get campaign => 'Campaign';

  @override
  String get go => 'Go';

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
  String get retry => 'Retry';

  @override
  String get register => 'Register';

  @override
  String get login => 'Login';

  @override
  String get cover => 'Cover';

  @override
  String get note => 'Note';

  @override
  String get menuItemName => 'Item name';

  @override
  String get price => 'Price';

  @override
  String get priceStability => 'Price stability';

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

  @override
  String get close => 'Close';

  @override
  String get adminSponsorshipCreateTitle => 'Create sponsorship';

  @override
  String get adminSponsorshipSurfaceLabel => 'Placement';

  @override
  String get adminSponsorshipSurfaceDiscovery => 'Discovery';

  @override
  String get adminSponsorshipSurfaceBusinessPage => 'Business page';

  @override
  String get adminSponsorshipPackageLabel => 'Package';

  @override
  String adminSponsorshipPackageOption(String name, int days) {
    return '$name • $days days';
  }

  @override
  String get adminSponsorshipStartDateLabel => 'Start date (YYYY-MM-DD)';

  @override
  String get adminSponsorshipEndDateLabel => 'End date (YYYY-MM-DD)';

  @override
  String get adminSponsorshipDailyCapLabel => 'Daily cap';

  @override
  String get adminSponsorshipTotalCapLabel => 'Total cap';

  @override
  String get adminSponsorshipPriorityOptionalLabel => 'Priority (optional)';

  @override
  String get adminSponsorshipTargetingTitle => 'Targeting';

  @override
  String get adminSponsorshipSearchBusinessHint =>
      'Search business (name or address)';

  @override
  String get adminSponsorshipSearchAction => 'Search';

  @override
  String get adminSponsorshipSearchingAction => 'Searching...';

  @override
  String get adminSponsorshipRemoveBusinessAction => 'Remove';

  @override
  String get adminSponsorshipAddTargetingValueAction => 'Add';

  @override
  String get adminSponsorshipCreateAction => 'Create';

  @override
  String get adminSponsorshipSavingAction => 'Saving...';

  @override
  String get adminSponsorshipSelectBusinessError => 'Select a business.';

  @override
  String get adminSponsorshipSelectPackageError => 'Select a package.';

  @override
  String get adminSponsorshipCreated => 'Sponsorship created.';

  @override
  String adminNewItemsBannerLabel(String label, int count) {
    return '$label (+$count)';
  }

  @override
  String get adminRiskQueueTitle => 'Risky users';

  @override
  String adminRiskQueueScoreThreshold(int score) {
    return 'Score >= $score';
  }

  @override
  String get adminRiskQueueFilterLabel => 'Filter';

  @override
  String get adminRiskQueueEmptyTitle => 'No risky users';

  @override
  String get adminRiskQueueEmptyDescription =>
      'There are no users requiring action for this filter right now.';

  @override
  String get adminRiskQueueReasonDialogTitle => 'Action reason';

  @override
  String adminRiskQueueActionWithName(String action) {
    return 'Action: $action';
  }

  @override
  String get adminRiskQueueReasonLabel => 'Reason (required)';

  @override
  String get adminRiskQueueReasonHint => 'Enter a short explanation';

  @override
  String get adminRiskQueueCopyUserId => 'Copy user ID';

  @override
  String adminRiskQueueSignalCount(int count) {
    return 'Signals: $count';
  }

  @override
  String adminRiskQueueNewAccountHits(int count) {
    return 'New account: $count';
  }

  @override
  String adminRiskQueueDeviceChangeHits(int count) {
    return 'Device changes: $count';
  }

  @override
  String adminRiskQueueSameIpHits(int count) {
    return 'IP burst: $count';
  }

  @override
  String adminRiskQueueDuplicateTextHits(int count) {
    return 'Duplicate text: $count';
  }

  @override
  String adminRiskQueueSoftLimitAction(int minutes) {
    return 'Soft limit $minutes min';
  }

  @override
  String adminRiskQueueAutoPendingAction(int hours) {
    return 'Auto pending $hours hr';
  }

  @override
  String adminRiskQueueShadowBanAction(int hours) {
    return 'Shadow ban $hours hr';
  }

  @override
  String get adminRiskQueueClearAction => 'Clear';

  @override
  String adminRiskQueueScoreLabel(int score) {
    return 'Score $score';
  }

  @override
  String get adminAuditTitle => 'Audit log';

  @override
  String get adminAuditOwnerTitle => 'Activity history';

  @override
  String adminAuditRecordCount(int count) {
    return '$count records';
  }

  @override
  String get adminAuditEmptyTitle => 'No records found';

  @override
  String get adminAuditEmptyDescription => 'Broaden the filters and try again.';

  @override
  String get adminAuditClearFilters => 'Clear filters';

  @override
  String get adminAuditCreatedAtColumn => 'Created';

  @override
  String get adminAuditActionColumn => 'Action';

  @override
  String get adminAuditTargetTypeColumn => 'Target type';

  @override
  String get adminAuditTargetIdColumn => 'Target ID';

  @override
  String get adminAuditActorColumn => 'Actor';

  @override
  String get adminAuditDetailsAction => 'Details';

  @override
  String get adminAuditCopyTargetId => 'Copy target ID';

  @override
  String get adminAuditCopied => 'Copied.';

  @override
  String get adminAuditDetailsTitle => 'Audit details';

  @override
  String get adminAuditActorIdLabel => 'Actor ID';

  @override
  String get adminAuditActorRoleLabel => 'Actor role';

  @override
  String get adminAuditBeforeAfterTitle => 'Before / After';

  @override
  String get adminAuditDiffFieldLabel => 'Field';

  @override
  String get adminAuditDiffBeforeLabel => 'Before';

  @override
  String get adminAuditDiffAfterLabel => 'After';

  @override
  String get adminAuditDiffNoChanges =>
      'No field-level diff was detected. Review the raw JSON below if needed.';

  @override
  String get adminAuditDiffRootField => 'Record';

  @override
  String get adminAuditRawBeforeTitle => 'Raw before payload';

  @override
  String get adminAuditRawAfterTitle => 'Raw after payload';

  @override
  String get adminAuditMetaTitle => 'Meta';

  @override
  String get adminAuditActionFilterAll => 'Action (all)';

  @override
  String get adminAuditTargetTypeFilterAll => 'Table (all)';

  @override
  String get adminAuditRelativeNow => 'Now';

  @override
  String adminAuditRelativeMinutes(int count) {
    return '$count min';
  }

  @override
  String adminAuditRelativeHours(int count) {
    return '$count hr';
  }

  @override
  String adminAuditRelativeDays(int count) {
    return '$count day';
  }

  @override
  String adminAuditRelativeWeeks(int count) {
    return '$count wk';
  }

  @override
  String adminAuditRelativeMonths(int count) {
    return '$count mo';
  }

  @override
  String get adminB2bExportsTitle => 'B2B data export';

  @override
  String get adminB2bExportsSubtitle =>
      'Download price index and regional trend reports as CSV for B2B insights.';

  @override
  String get adminB2bExportsPriceIndexChip => 'Price index';

  @override
  String get adminB2bExportsRegionalTrendChip => 'Regional trend';

  @override
  String get adminB2bExportsMenuInflationChip => 'Menu inflation';

  @override
  String get adminB2bExportsPeriodLabel => 'Period:';

  @override
  String adminB2bExportsDayOption(int days) {
    return '$days days';
  }

  @override
  String get adminB2bExportsAnonymousTrendsTitle => 'Anonymous trends';

  @override
  String get adminB2bExportsAnonymousTrendsDescription =>
      'Anonymized trend data by day, city, district, and event.';

  @override
  String get adminB2bExportsRegionalPriceIndexTitle => 'Regional price index';

  @override
  String get adminB2bExportsRegionalPriceIndexDescription =>
      'Average and median prices by city and district, plus change vs previous period.';

  @override
  String get adminB2bExportsMenuInflationTitle => 'Menu inflation report';

  @override
  String get adminB2bExportsMenuInflationDescription =>
      'First and last period prices per item and inflation percentage.';

  @override
  String get adminB2bExportsPriceAnomaliesTitle => 'Price anomaly report';

  @override
  String get adminB2bExportsPriceAnomaliesDescription =>
      'Lists items with unusually sharp price increases in a short period.';

  @override
  String get adminB2bExportsPreparingAction => 'Preparing...';

  @override
  String get adminB2bExportsDownloadCsvAction => 'Download CSV';

  @override
  String get adminB2bExportsGovernanceTitle => 'Data product boundary';

  @override
  String get adminB2bExportsGovernanceDescription =>
      'This screen does not treat every export as the same commercial product; each dataset is classified by product lane and anonymization strength.';

  @override
  String get adminB2bExportsGovernanceAnonymousRule =>
      'Anonymous aggregate: no raw user, device, or single-business trace leaves the dataset.';

  @override
  String get adminB2bExportsGovernanceRestrictedRule =>
      'Restricted aggregate: business or item-level signals exist; suitable for premium reporting candidates, but external sale needs extra review.';

  @override
  String get adminB2bExportsGovernanceContractRule =>
      'Contract only: anomaly and sensitive datasets default to internal ops or contract-governed analysis only.';

  @override
  String get adminB2bExportsLaneLabel => 'Product lane';

  @override
  String get adminB2bExportsPrivacyLabel => 'Privacy class';

  @override
  String get adminB2bExportsFreshnessLabel => 'Freshness';

  @override
  String get adminB2bExportsLaneInternalOps => 'Internal ops';

  @override
  String get adminB2bExportsLanePremiumCandidate =>
      'Premium reporting candidate';

  @override
  String get adminB2bExportsLaneExternalCandidate =>
      'External data product candidate';

  @override
  String get adminB2bExportsPrivacyAnonymousAggregate => 'Anonymous aggregate';

  @override
  String get adminB2bExportsPrivacyRestrictedAggregate =>
      'Restricted aggregate';

  @override
  String get adminB2bExportsPrivacyContractOnly => 'Contract only';

  @override
  String get adminB2bExportsFreshnessDailySeries => 'Daily series';

  @override
  String get adminB2bExportsFreshnessRollingWindow => 'Rolling window';

  @override
  String get adminB2bExportsStatusInternalReady => 'Ready for internal use';

  @override
  String get adminB2bExportsStatusPremiumCandidate =>
      'Premium package candidate';

  @override
  String get adminB2bExportsStatusExternalCandidate =>
      'External sale candidate';

  @override
  String get adminBusinessSubmissionsStatusLabel => 'Status:';

  @override
  String get adminBusinessSubmissionsNewStatus => 'New';

  @override
  String get adminBusinessSubmissionsEmpty => 'No applications found.';

  @override
  String get adminBusinessSubmissionsApproveConfirm =>
      'Do you want to approve this application?';

  @override
  String get adminBusinessSubmissionsOptionalNoteLabel => 'Note (optional)';

  @override
  String get adminBusinessesTitle => 'Businesses';

  @override
  String get adminBusinessesSearchHint => 'Search (name, address)';

  @override
  String get adminBusinessesLogoColumn => 'Logo';

  @override
  String get adminBusinessesNameColumn => 'Name';

  @override
  String get adminBusinessesRiskColumn => 'Risk';

  @override
  String get adminBusinessesCreatedAtColumn => 'Created';

  @override
  String get adminBusinessesAssignedColumn => 'Assigned';

  @override
  String get adminBusinessesMergeAction => 'Merge';

  @override
  String get adminBusinessesQrMenuAction => 'Digital Menu & QR';

  @override
  String get adminBusinessesPublicMenuAction => 'Public menu link';

  @override
  String get adminBusinessesEmpty => 'No records found.';

  @override
  String get adminBusinessesUpdated => 'Updated.';

  @override
  String get adminBusinessesEditTitle => 'Edit business';

  @override
  String get adminBusinessesPublicMenuLinkLabel => 'Public menu link';

  @override
  String get adminBusinessesQrGenerationLinkLabel => 'QR generation link';

  @override
  String get adminBusinessesCopyMenuLinkAction => 'Copy menu link';

  @override
  String get adminBusinessesInfoTab => 'Info';

  @override
  String get adminBusinessesMediaTab => 'Media';

  @override
  String get adminBusinessesLatitudeLabel => 'Latitude';

  @override
  String get adminBusinessesLongitudeLabel => 'Longitude';

  @override
  String get adminBusinessesUploadMediaAction => 'Upload';

  @override
  String get adminBusinessesClearAction => 'Clear';

  @override
  String get adminBusinessesLogoUrlLabel => 'Logo URL';

  @override
  String get adminBusinessesCoverLabel => 'Cover';

  @override
  String get adminBusinessesCoverUrlLabel => 'Cover URL';

  @override
  String get adminBusinessesPublicMenuCopied => 'Public menu link copied.';

  @override
  String get adminBusinessesStatusNeedsReview => 'Needs review';

  @override
  String get adminBusinessesEmptyTitle => 'No businesses found';

  @override
  String get adminBusinessesEmptyDescription =>
      'Clear filters and try a different search.';

  @override
  String get adminBusinessesErrorTitle => 'Businesses could not be loaded';

  @override
  String adminBusinessesVerificationUpdatedCount(int count) {
    return 'Updated verification status for $count selected businesses.';
  }

  @override
  String adminBusinessesAssignedCount(int count) {
    return 'Updated assignment for $count selected businesses.';
  }

  @override
  String get adminBusinessesBulkStatusLabel => 'Bulk status';

  @override
  String get adminBusinessesBulkStatusVerified => 'Mark as verified';

  @override
  String get adminBusinessesBulkStatusNeedsReview => 'Mark as needs review';

  @override
  String get adminBusinessesBulkStatusUnassigned => 'Clear assignment';

  @override
  String get adminBusinessesNoMergeCandidates => 'No merge candidates found.';

  @override
  String get adminBusinessesMergeSuggestedNote =>
      'This may be the same business record. Merge review is recommended.';

  @override
  String adminBusinessesMergeCandidateTitle(String name) {
    return 'Select a merge candidate for \"$name\"';
  }

  @override
  String get adminBusinessesMergeApplyNowTitle =>
      'Merge immediately (force merge)';

  @override
  String get adminBusinessesMergeApplyNowDescription =>
      'If disabled, only a merge proposal is written to the audit log.';

  @override
  String get adminBusinessesMergePreviewAction => 'Preview';

  @override
  String adminBusinessesMergePreviewSummary(
    int menus,
    int items,
    int reviews,
    int media,
  ) {
    return 'Preview: menus $menus, items $items, reviews $reviews, media $media';
  }

  @override
  String get adminBusinessesMergeApplyNowAction => 'Merge and apply';

  @override
  String get adminBusinessesMergeCreateProposalAction =>
      'Create merge proposal';

  @override
  String get adminBusinessesMergeCompleted => 'Merge completed.';

  @override
  String get adminBusinessesMergeProposalLogged =>
      'Merge proposal added to the audit log.';

  @override
  String get adminBusinessesRiskSuspicious => 'Suspicious';

  @override
  String get adminBusinessesRiskMedium => 'Medium';

  @override
  String get adminBusinessesRiskLow => 'Low';

  @override
  String get adminBusinessesRiskMissing => 'missing';

  @override
  String get adminBusinessesRiskAvailable => 'available';

  @override
  String adminBusinessesRiskTooltip(
    String address,
    String phone,
    int photoCount,
    int engagementCount,
  ) {
    return 'Address: $address • Phone: $phone • Photos: $photoCount • Engagement: $engagementCount';
  }

  @override
  String get adminClaimsTitle => 'Ownership claims';

  @override
  String get adminClaimsExportingAction => 'Downloading...';

  @override
  String get adminClaimsExportCsvAction => 'Export CSV';

  @override
  String get adminClaimsSearchHint => 'Search (ID, name, phone)';

  @override
  String get adminClaimsAssignedUnassigned => 'Unassigned';

  @override
  String get adminClaimsAssignedMine => 'Mine';

  @override
  String get adminClaimsAssignedAnotherAdmin => 'Another admin';

  @override
  String get adminClaimsNewRecordsAvailable => 'New records available';

  @override
  String get adminClaimsBulkUpdated => 'Updated.';

  @override
  String get adminClaimsSelectSamePhoneAction => 'Select same phone';

  @override
  String get adminClaimsAssignSelectedToMeAction => 'Assign selected to me';

  @override
  String get adminClaimsFullNameColumn => 'Full name';

  @override
  String get adminClaimsPriorityColumn => 'Priority';

  @override
  String get adminClaimsStatusColumn => 'Status';

  @override
  String get adminClaimsAssignedColumn => 'Assigned';

  @override
  String get adminClaimsCreatedAtColumn => 'Created';

  @override
  String get adminClaimsAgeColumn => 'Age';

  @override
  String get adminClaimsDetailsAction => 'Details';

  @override
  String get adminClaimsAutoModeratedTooltip => 'Automatic moderation applied';

  @override
  String get adminClaimsEmpty => 'No records found.';

  @override
  String adminClaimsSlaBreached(String age) {
    return 'This record breached SLA: $age';
  }

  @override
  String get adminClaimsDetailTitle => 'Record details';

  @override
  String get adminClaimsPhoneLabel => 'Phone';

  @override
  String get adminClaimsEvidenceLabel => 'Evidence';

  @override
  String get adminClaimsAdminNoteOptionalLabel => 'Admin note (optional)';

  @override
  String get adminClaimsAutoRulesTitle => 'Automatic rules';

  @override
  String get adminClaimsAutoRuleApplied => 'Automatic rule applied.';

  @override
  String get adminClaimsNoAutoRuleFound => 'No matching automatic rule found.';

  @override
  String get adminClaimsApplyingAction => 'Applying...';

  @override
  String get adminClaimsApplyRulesAction => 'Apply rules';

  @override
  String get adminClaimsDone => 'Done.';

  @override
  String get adminClaimsProcessingAction => 'Processing...';

  @override
  String get adminClaimsAssignToMeAction => 'Assign to me';

  @override
  String get adminClaimsUnassignAction => 'Remove assignment';

  @override
  String get adminClaimsAssignmentRemoved => 'Assignment removed.';

  @override
  String get adminClaimsApproved => 'Approved.';

  @override
  String get adminClaimsRejected => 'Rejected.';

  @override
  String get adminClaimsSelectRowFirst => 'Select a row';

  @override
  String get adminClaimsNoPhone => 'This record has no phone number.';

  @override
  String adminClaimsAssignedToYou(int count) {
    return '$count claims assigned to you.';
  }

  @override
  String adminClaimsSelectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get adminClaimsClearSelectionAction => 'Clear';

  @override
  String adminClaimsAgeValue(String days) {
    return '$days days';
  }

  @override
  String get adminClaimsDecisionTemplateApproved =>
      'Documents and details were verified, the claim was approved.';

  @override
  String get adminClaimsDecisionTemplateRejected =>
      'Verification criteria were not met, the claim was rejected.';

  @override
  String get adminClaimsDecisionTemplateNeedsDocuments =>
      'Additional documents are required, review is ongoing.';

  @override
  String get adminDashboardOverviewTitle => 'Overview';

  @override
  String get adminDashboardOverviewSubtitle => 'Operations and growth metrics';

  @override
  String get adminDashboardOpenReports => 'Open reports';

  @override
  String get adminDashboardPendingClaims => 'Pending claims';

  @override
  String get adminDashboardPendingSuggestions => 'Pending suggestions';

  @override
  String get adminDashboardReportAssignMinutes => 'Report assignment (min)';

  @override
  String get adminDashboardReportCloseMinutes => 'Report closure (min)';

  @override
  String get adminDashboardClaimAssignMinutes => 'Claim assignment (min)';

  @override
  String get adminDashboardClaimDecisionMinutes => 'Claim decision (min)';

  @override
  String get adminDashboardGrowth30Days => 'Growth (30 days)';

  @override
  String get adminDashboardMenuLinkOpened => 'Menu link opened';

  @override
  String get adminDashboardQrScanned => 'QR scanned';

  @override
  String get adminDashboardMenuShared => 'Menu shared';

  @override
  String get adminDashboardAppInstall => 'App installs';

  @override
  String get adminDashboardKpi30Days => 'KPI (30 days)';

  @override
  String get adminDashboardDau => 'DAU';

  @override
  String get adminDashboardWau => 'WAU';

  @override
  String get adminDashboardDiscoveryCtr => 'Discovery to Business CTR';

  @override
  String get adminDashboardBusinessToMenuRate => 'Business to Menu rate';

  @override
  String get adminDashboardPriceVerificationConversion =>
      'Price verification conversion';

  @override
  String get adminDashboardReportResolutionMinutes =>
      'Report resolution time (min)';

  @override
  String get adminDashboardQualityGateTitle => 'V3 Quality and Trust Gate (P0)';

  @override
  String get adminDashboardQualityGateSubtitle =>
      'Reduce misinformation, increase trust. Do not loosen quality for growth.';

  @override
  String adminDashboardLiveGate(int passed, int total) {
    return 'Live gate: $passed/$total';
  }

  @override
  String get adminDashboardGateAccuracyScores => 'Accuracy scores';

  @override
  String get adminDashboardGatePriceVerification => 'Price verification';

  @override
  String get adminDashboardGateMenuHistory => 'Menu version/history';

  @override
  String get adminDashboardGateFalseInfoReporting =>
      'False information reporting';

  @override
  String get adminDashboardGateBusinessLifecycle => 'Business lifecycle';

  @override
  String get adminDashboardGateReviewQuality => 'Review quality system';

  @override
  String get adminDashboardGateOpenNowCheck => 'Open now check';

  @override
  String get adminDashboardGateBusinessPanelCore => 'Business panel core';

  @override
  String get adminDashboardGateAdminQueue => 'Admin queue';

  @override
  String get adminDashboardGateInbox => 'In-app inbox';

  @override
  String adminDashboardGuardrailSummary(
    String requireLabel,
    String minTrust,
    String ownerDelete,
    String bypass,
  ) {
    return 'Guardrails: sponsored label=$requireLabel, min sponsored trust=$minTrust, owner delete reviews=$ownerDelete, quality bypass=$bypass.';
  }

  @override
  String get adminDevToolsTitle => 'Developer tools';

  @override
  String get adminDevToolsSubtitle =>
      'Feature, test user, and test city settings.';

  @override
  String get adminDevToolsAchievementRequired =>
      'User ID and Achievement ID are required.';

  @override
  String adminDevToolsResetFailed(String error) {
    return 'Reset failed: $error';
  }

  @override
  String get adminDevToolsAchievementResetLogged =>
      'Achievement reset and written to the audit log.';

  @override
  String get adminDevToolsNoRecordButLogged =>
      'No record found, but it was written to the audit log.';

  @override
  String adminDevToolsError(String error) {
    return 'Error: $error';
  }

  @override
  String get adminDevToolsAchievementModerationTitle =>
      'Achievement moderation';

  @override
  String get adminDevToolsAchievementModerationDescription =>
      'If needed, remove the achievement record and recalculate XP/level on the profile.';

  @override
  String get adminDevToolsUserIdUuidLabel => 'User ID (UUID)';

  @override
  String get adminDevToolsWriterUserIdHint => 'author user id';

  @override
  String get adminDevToolsAchievementIdLabel => 'Achievement ID';

  @override
  String get adminDevToolsAchievementIdHint => 'example: trusted_contributor';

  @override
  String get adminDevToolsReasonOptionalLabel => 'Reason (optional)';

  @override
  String get adminDevToolsResettingAction => 'Resetting...';

  @override
  String get adminDevToolsAchievementResetAction => 'Reset achievement';

  @override
  String get adminDevToolsGuardrailThresholdsTitle => 'Guardrail thresholds';

  @override
  String get adminDevToolsGuardrailThresholdsDescription =>
      'Adjust live quality thresholds from the admin panel.';

  @override
  String get adminDevToolsRequireSponsoredLabel => 'Require sponsored label';

  @override
  String get adminDevToolsOwnerCanDeleteReviews =>
      'Business can delete reviews';

  @override
  String get adminDevToolsLowQualityGrowthBypass => 'Low quality growth bypass';

  @override
  String get adminDevToolsMinSponsorTrustLabel => 'Min sponsored trust (0-1)';

  @override
  String get adminDevToolsMinSponsorRatingLabel => 'Min sponsored rating (0-5)';

  @override
  String get adminDevToolsEnterValidThresholds =>
      'Enter valid threshold values.';

  @override
  String get adminDevToolsSaveThresholdsAction => 'Save thresholds';

  @override
  String get adminDevToolsDefaultAction => 'Default';

  @override
  String get adminDevToolsFeatureFlagsTitle => 'Feature flags';

  @override
  String get adminDevToolsTestUserTitle => 'Test user';

  @override
  String adminDevToolsActiveUser(String userId) {
    return 'Active user: $userId';
  }

  @override
  String get adminDevToolsTestUserUidLabel => 'Test user UID';

  @override
  String get adminDevToolsClearAction => 'Clear';

  @override
  String get adminDevToolsTestCityTitle => 'Test city';

  @override
  String get adminDevToolsTestCityDescription =>
      'When location is invalidated, automatic location flow is disabled.';

  @override
  String adminDevToolsActiveLocation(String city, String district) {
    return 'Active: $city / $district';
  }

  @override
  String get adminGroupRequestsRequestsTitle => 'Requests';

  @override
  String get adminGroupRequestsOffersTitle => 'Offers';

  @override
  String get adminGroupRequestsNoRecords => 'No records';

  @override
  String adminGroupRequestsRequestSummary(String city, int partySize) {
    return '$city • $partySize people';
  }

  @override
  String get adminGrowthTitle => 'Growth';

  @override
  String adminGrowthLastDays(int days) {
    return 'Last $days days';
  }

  @override
  String get adminGrowthBusinessIdOptional => 'Business ID (optional)';

  @override
  String get adminGrowthNoData => 'No data found.';

  @override
  String get adminGrowthTodayBusinessTraffic => 'Today\'s business traffic';

  @override
  String get adminGrowthMenuLinkOpened => 'Menu link opened';

  @override
  String get adminGrowthQrScanned => 'QR scanned';

  @override
  String get adminGrowthMenuShared => 'Menu shared';

  @override
  String get adminGrowthAppInstall => 'App installs';

  @override
  String get adminGrowthDailyTrafficTotal => 'Daily traffic (total)';

  @override
  String get adminGrowthDayColumn => 'Day';

  @override
  String get adminIncidentCenterTitle => 'Incident response center';

  @override
  String get adminIncidentCenterSubtitle =>
      'Fast panel for fake business, wrong price, and media incidents.';

  @override
  String get adminIncidentCenterNoLogs => 'No incident logs yet.';

  @override
  String get adminIncidentCenterTransparentLogTitle => 'Transparent log';

  @override
  String adminIncidentCenterHowFixed(String action) {
    return 'How we fixed it: $action';
  }

  @override
  String get adminIncidentCenterFillAllFields => 'Fill in all fields.';

  @override
  String get adminIncidentCenterQuickPanelTitle => 'Quick response panel';

  @override
  String get adminIncidentCenterReportsQueueAction => 'Reports queue';

  @override
  String get adminIncidentCenterReviewBusinessAction => 'Review business';

  @override
  String get adminIncidentCenterAuditLogAction => 'Audit log';

  @override
  String get adminIncidentCenterHowWeFixedAction => 'How we fixed it screen';

  @override
  String get adminIncidentCenterReadyResponsesTitle => 'Ready responses';

  @override
  String get adminIncidentCenterReadyResponseWrongPrice =>
      'Wrong price: Incident record opened, relevant menu was temporarily deprioritized, it will be reactivated after verification.';

  @override
  String get adminIncidentCenterReadyResponseFakeBusiness =>
      'Fake business: Record was taken into review, visibility was reduced, and automatic restriction was applied for duplicate/fake signals.';

  @override
  String get adminIncidentCenterReadyResponseMedia =>
      'Media scenario: A public timeline was published and fixes plus SLA steps were shared transparently.';

  @override
  String get adminIncidentCenterLogEntryTitle => 'Transparent log entry';

  @override
  String get adminIncidentCenterIncidentKeyLabel => 'Incident key';

  @override
  String get adminIncidentCenterTitleLabel => 'Title';

  @override
  String get adminIncidentCenterWhatHappenedLabel => 'What happened?';

  @override
  String get adminIncidentCenterHowDidWeFixLabel => 'How did we fix it?';

  @override
  String get adminIncidentCenterStatusOpen => 'Open';

  @override
  String get adminIncidentCenterStatusMitigated => 'Mitigated';

  @override
  String get adminIncidentCenterStatusResolved => 'Resolved';

  @override
  String get adminIncidentCenterVisibilityPublic => 'Public';

  @override
  String get adminIncidentCenterVisibilityInternal => 'Internal';

  @override
  String get adminIncidentCenterAddLogAction => 'Add log';

  @override
  String get adminCommonUpdated => 'Updated.';

  @override
  String get adminCommonDownloading => 'Downloading...';

  @override
  String get adminCommonExportCsv => 'Export CSV';

  @override
  String get adminCommonUnassigned => 'Unassigned';

  @override
  String get adminCommonMine => 'Mine';

  @override
  String get adminCommonOtherAdmin => 'Another admin';

  @override
  String get adminCommonNewRecordsAvailable => 'New records available';

  @override
  String get adminCommonAge => 'Age';

  @override
  String get adminCommonPriority => 'Priority';

  @override
  String get adminCommonAssigned => 'Assigned';

  @override
  String get adminCommonDetails => 'Details';

  @override
  String get adminCommonNoRecordsFound => 'No records found.';

  @override
  String get adminCommonProcessing => 'Processing...';

  @override
  String get adminCommonConfirmTitle => 'Are you sure?';

  @override
  String get adminCommonSelectRow => 'Select a row.';

  @override
  String get adminCommonClear => 'Clear';

  @override
  String get adminLocationsTitle => 'Tools > Locations';

  @override
  String get adminLocationsTableBusinesses => 'Businesses';

  @override
  String get adminLocationsTableBusinessSuggestions => 'Business suggestions';

  @override
  String get adminLocationsTableLabel => 'Table';

  @override
  String get adminLocationsFieldLabel => 'Field';

  @override
  String get adminLocationsCaseInsensitive => 'Case insensitive';

  @override
  String get adminLocationsFromLabel => 'Old value';

  @override
  String get adminLocationsToLabel => 'New value';

  @override
  String adminLocationsAffectedCount(int count) {
    return 'Affected records: $count';
  }

  @override
  String get adminLocationsChecking => 'Checking...';

  @override
  String get adminLocationsValuesRequired =>
      'Old value and new value are required.';

  @override
  String get adminLocationsConfirmTitle => 'Confirm change';

  @override
  String adminLocationsConfirmMessage(String from, String to) {
    return 'The value \"$from\" will be updated to \"$to\". Do you want to continue?';
  }

  @override
  String get adminLocationsApplying => 'Applying...';

  @override
  String get adminObservabilityTitle => 'Observability';

  @override
  String get adminObservabilitySubtitle =>
      'Request trace, performance goals, and local preference visibility.';

  @override
  String get adminObservabilityRequestTraceTitle => 'Request Trace';

  @override
  String adminObservabilityRequestIdValue(String requestId) {
    return 'request_id: $requestId';
  }

  @override
  String adminObservabilityHeadersValue(String headers) {
    return 'headers: $headers';
  }

  @override
  String adminObservabilityPayloadValue(String payload) {
    return 'payload: $payload';
  }

  @override
  String get adminObservabilityGenerateRequestId => 'Generate new request_id';

  @override
  String get adminObservabilityPerfTitle =>
      'Performance SLO and alert simulation';

  @override
  String get adminObservabilityPerfSummary =>
      'SLO: cold<=2000ms, warm<=800ms, home_tti<=1200ms, jank<=1%';

  @override
  String get adminObservabilityCrashFreeLabel => 'Crash-free';

  @override
  String get adminObservabilityHomeTtiLabel => 'Home TTI p95';

  @override
  String get adminObservabilityEdgeSpikeLabel => 'Edge 429 spike';

  @override
  String get adminObservabilityCrashFreeInput => 'Crash-free rate (0-1)';

  @override
  String get adminObservabilityHomeTtiInput => 'Home TTI p95 (ms)';

  @override
  String get adminObservabilityEdgeCurrentInput => 'Edge 429 current window';

  @override
  String get adminObservabilityEdgeBaselineInput => 'Edge 429 baseline window';

  @override
  String adminObservabilityConstantsSummary(
    int cold,
    int warm,
    int homeTti,
    int searchHit,
    int searchMiss,
  ) {
    return 'Constants: startup(cold=$cold, warm=$warm) home_tti=$homeTti, search_hit=$searchHit, search_miss=$searchMiss';
  }

  @override
  String adminObservabilityPrefsReadError(String error) {
    return 'Could not read prefs: $error';
  }

  @override
  String get adminObservabilityPrefsEmpty => 'No prefs data.';

  @override
  String get adminObservabilityPrefsExplorerTitle => 'Prefs Explorer';

  @override
  String adminObservabilityStatusChip(String label, String status) {
    return '$label: $status';
  }

  @override
  String get adminObservabilityStatusOk => 'OK';

  @override
  String get adminObservabilityStatusAlarm => 'ALARM';

  @override
  String get adminPriceSuggestionsTitle => 'Price suggestions';

  @override
  String get adminPriceSuggestionsItemLabel => 'Item';

  @override
  String get adminPriceSuggestionsCurrentPrice => 'Current';

  @override
  String get adminPriceSuggestionsSuggestedPrice => 'Suggested';

  @override
  String adminPriceSuggestionsSlaExceeded(String age) {
    return 'SLA exceeded: $age';
  }

  @override
  String get adminPriceSuggestionsDetailTitle => 'Price suggestion details';

  @override
  String adminPriceSuggestionsLocationValue(String city, String district) {
    return 'Location: $city / $district';
  }

  @override
  String get adminPriceSuggestionsCurrencyLabel => 'Currency';

  @override
  String get adminPriceSuggestionsCreatedBy => 'Created by';

  @override
  String get adminPriceSuggestionsMetaTitle => 'Meta';

  @override
  String get adminPriceSuggestionsRejectNoteLabel =>
      'Rejection note (min. 3 characters)';

  @override
  String get adminPriceSuggestionsApproveConfirm => 'Approve this suggestion?';

  @override
  String get adminPriceSuggestionsRejectConfirm => 'Reject this suggestion?';

  @override
  String get adminPriceSuggestionsGoToBusiness => 'Go to business page';

  @override
  String get adminPriceSuggestionsGoToItem => 'Go to item page';

  @override
  String get adminReceiptSubmissionsTitle => 'Receipt verifications';

  @override
  String adminReceiptSubmissionsMatchSummary(int count, String date) {
    return 'Matches: $count • $date';
  }

  @override
  String get adminReceiptSubmissionsSubtitle =>
      'Manage receipt/OCR flows as a field triage workbench, not just a flat list.';

  @override
  String get adminReceiptSubmissionsSearchHint =>
      'Search business, city, district, or chain';

  @override
  String get adminReceiptSubmissionsStatusAll => 'All';

  @override
  String get adminReceiptSubmissionsStatusPending => 'Pending';

  @override
  String get adminReceiptSubmissionsStatusReviewed => 'Reviewed';

  @override
  String get adminReceiptSubmissionsStatusNeedsFollowup => 'Needs follow-up';

  @override
  String get adminReceiptSubmissionsOnlyUnmatched => 'Only unmatched';

  @override
  String get adminReceiptSubmissionsSummaryTotal => 'Total receipts';

  @override
  String get adminReceiptSubmissionsSummaryPending => 'Pending';

  @override
  String get adminReceiptSubmissionsSummaryNeedsFollowup => 'Needs follow-up';

  @override
  String get adminReceiptSubmissionsSummaryZeroMatch => 'Zero-match';

  @override
  String get adminReceiptSubmissionsSummaryRecent24h => 'Last 24h';

  @override
  String get adminReceiptSubmissionsSummaryBusinesses => 'Businesses';

  @override
  String get adminReceiptSubmissionsBatchTitle => 'Batch review opportunities';

  @override
  String get adminReceiptSubmissionsBatchDescription =>
      'Clusters of receipts in the same business or chain highlight candidates for bulk menu review.';

  @override
  String get adminReceiptSubmissionsBatchEmpty =>
      'No batch opportunity stands out right now.';

  @override
  String adminReceiptSubmissionsBatchValue(
    int pending,
    int zeroMatch,
    String date,
  ) {
    return '$pending pending • $zeroMatch zero-match • last $date';
  }

  @override
  String get adminReceiptSubmissionsEmptyTitle => 'Receipt queue is empty';

  @override
  String get adminReceiptSubmissionsEmptyDescription =>
      'No receipt record is waiting under these filters.';

  @override
  String get adminReceiptSubmissionsDetailEmptyTitle => 'Select a record';

  @override
  String get adminReceiptSubmissionsDetailEmptyDescription =>
      'When you select a receipt on the left, OCR matches and review tools will appear here.';

  @override
  String get adminReceiptSubmissionsReviewAction => 'Open review';

  @override
  String get adminReceiptSubmissionsOpenBusinessAction =>
      'Open public business';

  @override
  String get adminReceiptSubmissionsOpenBusinessAdminAction =>
      'Open admin business record';

  @override
  String get adminReceiptSubmissionsDetailMatches => 'OCR matches';

  @override
  String get adminReceiptSubmissionsDetailSubmittedAt => 'Submitted';

  @override
  String get adminReceiptSubmissionsDetailUser => 'Submitted by';

  @override
  String get adminReceiptSubmissionsMatchTableTitle => 'OCR match table';

  @override
  String get adminReceiptSubmissionsMatchTableDescription =>
      'Compare the detected price against the current system price.';

  @override
  String get adminReceiptSubmissionsNoMatches =>
      'No menu-item match was found for this receipt. Field follow-up may be needed.';

  @override
  String get adminReceiptSubmissionsMatchItemColumn => 'Item';

  @override
  String get adminReceiptSubmissionsMatchDetectedColumn => 'Detected';

  @override
  String get adminReceiptSubmissionsMatchCurrentColumn => 'Current price';

  @override
  String get adminReceiptSubmissionsMatchDeltaColumn => 'Delta';

  @override
  String get adminReceiptSubmissionsReviewSheetTitle => 'Receipt review';

  @override
  String get adminReceiptSubmissionsReviewStatusLabel => 'Review status';

  @override
  String get adminReceiptSubmissionsReviewNoteLabel => 'Operator note';

  @override
  String get adminReceiptSubmissionsSaveReview => 'Save review';

  @override
  String get adminReceiptSubmissionsSaved => 'Receipt review saved.';

  @override
  String get adminReportsOtherReason => 'Other';

  @override
  String get adminReportsTitle => 'Reports';

  @override
  String get adminReportsSearchHint => 'Search (ID, reason, details)';

  @override
  String get adminReportsStatusOpen => 'Open';

  @override
  String get adminReportsStatusInvestigating => 'Investigating';

  @override
  String get adminReportsStatusClosed => 'Closed';

  @override
  String get adminReportsSelectSameReporter => 'Select same account';

  @override
  String get adminReportsAssignSelectedToMe => 'Assign selected records to me';

  @override
  String get adminReportsCloseSpamWave => 'Close spam wave';

  @override
  String get adminReportsReasonColumn => 'Reason';

  @override
  String get adminReportsStatusColumn => 'Status';

  @override
  String get adminReportsCreatedAtColumn => 'Created at';

  @override
  String get adminReportsPhotoColumn => 'Photo';

  @override
  String get adminReportsAutoModerationApplied =>
      'Automatic moderation applied';

  @override
  String get adminReportsMenuPhotoTooltip => 'Menu photo';

  @override
  String get adminReportsBusinessPhotoTooltip => 'Venue photo';

  @override
  String adminReportsSlaExceeded(String age) {
    return 'This record exceeded SLA: $age';
  }

  @override
  String get adminReportsDetailTitle => 'Report details';

  @override
  String get adminReportsReviewLabel => 'Review';

  @override
  String get adminReportsMenuPhotoLabel => 'Menu photo';

  @override
  String get adminReportsBusinessPhotoLabel => 'Venue photo';

  @override
  String adminReportsTargetValue(String targetType, String targetId) {
    return 'Target: $targetType / $targetId';
  }

  @override
  String get adminReportsOpenPhoto => 'Open photo';

  @override
  String get adminReportsReasonLabel => 'Reason';

  @override
  String get adminReportsAdminNoteOptional => 'Admin note (optional)';

  @override
  String get adminReportsAutomaticRulesTitle => 'Automatic rules';

  @override
  String get adminReportsAutomaticRuleApplied => 'Automatic rule applied.';

  @override
  String get adminReportsAutomaticRuleNotFound =>
      'No matching automatic rule found.';

  @override
  String get adminReportsApplyingRules => 'Applying...';

  @override
  String get adminReportsApplyRules => 'Apply rules';

  @override
  String get adminReportsClaimed => 'Claimed.';

  @override
  String get adminReportsAssignToMe => 'Assign to me';

  @override
  String get adminReportsAssignmentRemoved => 'Assignment removed.';

  @override
  String get adminReportsUnassign => 'Remove assignment';

  @override
  String get adminReportsMissingReporterInfo =>
      'Reporter information is missing for this record.';

  @override
  String get adminReportsBulkSpamNote => 'Bulk: closed due to spam wave';

  @override
  String get adminReportsSelectedClosed => 'Selected reports were closed.';

  @override
  String adminReportsAssignedCount(int count) {
    return '$count reports assigned to you.';
  }

  @override
  String adminReportsModerationScanComplete(int photoGroups, int menuGroups) {
    return 'Scan completed. Similar photo groups: $photoGroups, copied menu groups: $menuGroups';
  }

  @override
  String adminReportsReasonDistribution(int total) {
    return 'Reason distribution ($total)';
  }

  @override
  String adminReportsModerationSummary(
    int duplicatePhotoGroups,
    int copiedMenuGroups,
  ) {
    return 'Moderation: similar photo groups $duplicatePhotoGroups, copied menu groups $copiedMenuGroups';
  }

  @override
  String get adminReportsScanning => 'Scanning...';

  @override
  String get adminReportsScan => 'Scan';

  @override
  String adminReportsSelectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String adminReportsHoursValue(String hours) {
    return '$hours hours';
  }

  @override
  String get adminReportsDecisionTemplateViolationConfirmed =>
      'Violation confirmed, necessary action applied.';

  @override
  String get adminReportsDecisionTemplateInsufficientEvidence =>
      'Insufficient evidence, report closed.';

  @override
  String get adminReportsDecisionTemplateNeedsMoreInfo =>
      'More information required, record under review.';

  @override
  String get adminReportsPhotoNotFound => 'Photo not found.';

  @override
  String adminReportsVisibilityLoading(String label) {
    return '$label · loading visibility...';
  }

  @override
  String adminReportsVisibilityUnknown(String label) {
    return '$label · visibility unknown';
  }

  @override
  String adminReportsVisibilityHidden(String label) {
    return '$label · shadow (hidden)';
  }

  @override
  String adminReportsVisibilityNormal(String label) {
    return '$label · normal (visible)';
  }

  @override
  String get adminCommonSaved => 'Saved.';

  @override
  String get adminShellAdminTitle => 'Admin';

  @override
  String get adminShellWebOnlyMessage =>
      'This screen is only available on the web.';

  @override
  String get adminShellAccessCheckFailed =>
      'Admin access could not be verified.';

  @override
  String get adminShellAccessDenied =>
      'You do not have permission to access this page.';

  @override
  String adminShellProjectInfo(String projectRef, String userId) {
    return 'Project: $projectRef • UID: $userId';
  }

  @override
  String get adminShellDashboardLabel => 'Overview';

  @override
  String get adminShellDashboardDescription =>
      'Admin panel overview and quick actions.';

  @override
  String get adminShellQueueLabel => 'Unified Queue';

  @override
  String get adminShellQueueDescription =>
      'Manage reports, claims, pricing, and media moderation from one queue.';

  @override
  String get adminShellReportsLabel => 'Reports';

  @override
  String get adminShellReportsDescription =>
      'Review user reports and manage status and assignment.';

  @override
  String get adminShellAppealsLabel => 'Appeals';

  @override
  String get adminShellAppealsDescription =>
      'Evaluate appeals submitted for moderation decisions.';

  @override
  String get adminShellGrowthLabel => 'Growth';

  @override
  String get adminShellGrowthDescription =>
      'Track menu link and QR traffic on a daily basis.';

  @override
  String get adminShellClaimsLabel => 'Ownership claims';

  @override
  String get adminShellClaimsDescription =>
      'Approve or reject business ownership claims.';

  @override
  String get adminShellSuspendedClaimsLabel => 'Suspended claims';

  @override
  String get adminShellSuspendedClaimsDescription =>
      'Validate and resolve suspended meal claims.';

  @override
  String get adminShellPriceSuggestionsLabel => 'Price approvals';

  @override
  String get adminShellPriceSuggestionsDescription =>
      'Review, approve, or reject price suggestions.';

  @override
  String get adminShellReceiptSubmissionsLabel => 'Receipt verification';

  @override
  String get adminShellReceiptSubmissionsDescription =>
      'List and review receipt verification submissions.';

  @override
  String get adminShellSuggestionsLabel => 'Business suggestions';

  @override
  String get adminShellSuggestionsDescription =>
      'Review and process new business suggestions.';

  @override
  String get adminShellBusinessesLabel => 'Businesses';

  @override
  String get adminShellBusinessesDescription =>
      'Edit, verify, and update business records.';

  @override
  String get adminShellBusinessSubmissionsLabel => 'Business submissions';

  @override
  String get adminShellBusinessSubmissionsDescription =>
      'Approve or reject new business submissions.';

  @override
  String get adminShellSponsorshipsLabel => 'Sponsored placements';

  @override
  String get adminShellSponsorshipsDescription =>
      'Manage sponsored placements and change their status.';

  @override
  String get adminShellSponsorshipPackagesLabel => 'Packages';

  @override
  String get adminShellSponsorshipPackagesDescription =>
      'Create sponsorship packages and manage pricing.';

  @override
  String get adminShellSponsorshipLeadsLabel => 'Leads';

  @override
  String get adminShellSponsorshipLeadsDescription =>
      'Track and close sponsorship sales inquiries.';

  @override
  String get adminShellVerifiedLabel => 'Verification';

  @override
  String get adminShellVerifiedDescription =>
      'Manage business verification and premium status.';

  @override
  String get adminShellLocationsLabel => 'Tools > Locations';

  @override
  String get adminShellLocationsDescription =>
      'Bulk-fix and update location data.';

  @override
  String get adminShellAuditLabel => 'Audit logs';

  @override
  String get adminShellAuditDescription =>
      'Review internal system activity logs.';

  @override
  String get adminShellTableFeedbackLabel => 'Table feedback';

  @override
  String get adminShellTableFeedbackDescription =>
      'View and filter table QR feedback.';

  @override
  String get adminShellGroupRequestsLabel => 'Group requests';

  @override
  String get adminShellGroupRequestsDescription =>
      'Monitor group meal requests and offers.';

  @override
  String get adminShellDevToolsLabel => 'Dev tools';

  @override
  String get adminShellDevToolsDescription =>
      'Feature flag and test override settings.';

  @override
  String get adminShellObservabilityLabel => 'Observability';

  @override
  String get adminShellObservabilityDescription =>
      'Request trace, perf SLO, and prefs overview.';

  @override
  String get adminShellB2bExportsLabel => 'B2B exports';

  @override
  String get adminShellB2bExportsDescription =>
      'Anonymous trend, regional price index, and menu inflation outputs.';

  @override
  String get adminShellIncidentCenterLabel => 'Incident response';

  @override
  String get adminShellIncidentCenterDescription =>
      'Transparent logs, prepared responses, and rapid response actions.';

  @override
  String get adminShellTempUploadsLabel => 'Temporary upload review';

  @override
  String get adminShellTempUploadsDescription =>
      'Review pending temporary menu uploads.';

  @override
  String get adminSponsorshipLeadsTitle => 'Sponsorship leads';

  @override
  String get adminSponsorshipLeadsContactColumn => 'Contact';

  @override
  String get adminSponsorshipLeadsOwnerColumn => 'Business owner';

  @override
  String get adminSponsorshipLeadsCreatedAtColumn => 'Created';

  @override
  String get adminSponsorshipLeadsDetailTitle => 'Lead details';

  @override
  String get adminSponsorshipLeadsPhoneLabel => 'Phone';

  @override
  String get adminSponsorshipLeadsMessageLabel => 'Message';

  @override
  String get adminSponsorshipLeadsTargetingLabel => 'Targeting';

  @override
  String get adminSponsorshipLeadsCreateSponsorship => 'Create sponsorship';

  @override
  String get adminSponsorshipLeadStatusNew => 'New';

  @override
  String get adminSponsorshipLeadStatusContacted => 'Contacted';

  @override
  String get adminSponsorshipLeadStatusClosed => 'Closed';

  @override
  String get adminSponsorshipPackagesTitle => 'Sponsorship packages';

  @override
  String get adminSponsorshipPackagesNewPackage => 'New package';

  @override
  String get adminSponsorshipPackagesEditPackage => 'Edit package';

  @override
  String get adminSponsorshipPackagesNameColumn => 'Name';

  @override
  String get adminSponsorshipPackagesDurationColumn => 'Duration';

  @override
  String get adminSponsorshipPackagesPriceColumn => 'Price';

  @override
  String get adminSponsorshipPackagesActiveColumn => 'Active';

  @override
  String get adminSponsorshipPackagesCreatedAtColumn => 'Created';

  @override
  String adminSponsorshipPackagesDurationValue(int days) {
    return '$days days';
  }

  @override
  String get adminSponsorshipPackagesDurationInput => 'Duration (days)';

  @override
  String get adminSponsorshipPackagesPriceInput => 'Price display';

  @override
  String get adminSponsorshipPackagesPriceAmountInput => 'Price (cents)';

  @override
  String get adminSponsorshipPackagesCurrencyInput => 'Currency';

  @override
  String get adminSponsorshipPackagesInventoryInput => 'Inventory limit';

  @override
  String get adminSponsorshipPackagesSurfaceDiscovery => 'Discovery';

  @override
  String get adminSponsorshipPackagesSurfaceBusinessPage => 'Business page';

  @override
  String get adminSponsorshipPackagesSurfaceStories => 'Stories';

  @override
  String get adminSponsorshipPackagesSurfaceVerified => 'Verified';

  @override
  String get adminSponsorshipPackagesSurfacePremium => 'Premium';

  @override
  String get adminSponsorshipPackagesInventoryColumn => 'Inventory';

  @override
  String get adminSponsorshipsTitle => 'Sponsorships';

  @override
  String get adminSponsorshipsNewAction => 'New sponsorship';

  @override
  String get adminSponsorshipsOverviewTitle => 'Portfolio summary';

  @override
  String get adminSponsorshipsOverviewDescription =>
      'Track active sponsorships, open leads, reach, and estimated revenue in one place.';

  @override
  String get adminSponsorshipsInventoryTitle => 'Surface inventory';

  @override
  String get adminSponsorshipsInventoryDescription =>
      'Review live occupancy, open slots, and last-30-day performance for each placement surface.';

  @override
  String get adminSponsorshipsSurfaceColumn => 'Surface';

  @override
  String get adminSponsorshipsStatusColumn => 'Status';

  @override
  String get adminSponsorshipsDateRangeColumn => 'Date range';

  @override
  String get adminSponsorshipsPackageColumn => 'Package';

  @override
  String get adminSponsorshipsQuotaColumn => 'Quota';

  @override
  String get adminSponsorshipsCreatedAtColumn => 'Created';

  @override
  String get adminSponsorshipsMetricActive => 'Active sponsorships';

  @override
  String get adminSponsorshipsMetricPending => 'Pending sponsorships';

  @override
  String get adminSponsorshipsMetricOpenLeads => 'Open leads';

  @override
  String get adminSponsorshipsMetricImpressions30d => '30d impressions';

  @override
  String get adminSponsorshipsMetricUniqueUsers30d => '30d unique users';

  @override
  String get adminSponsorshipsMetricEstimatedRevenue =>
      'Estimated active revenue';

  @override
  String get adminSponsorshipsInventoryPackagesColumn => 'Packages';

  @override
  String get adminSponsorshipsInventoryUnitsColumn => 'Live / open';

  @override
  String get adminSponsorshipsInventoryDemandColumn => 'Demand';

  @override
  String get adminSponsorshipsInventoryPerformanceColumn => 'Performance';

  @override
  String adminSponsorshipsInventoryPackagesValue(
    Object active,
    Object total,
    Object inventory,
  ) {
    return '$active active / $total total • limit $inventory';
  }

  @override
  String adminSponsorshipsInventoryUnitsValue(Object live, Object open) {
    return '$live live • $open open';
  }

  @override
  String adminSponsorshipsInventoryDemandValue(Object pending, Object leads) {
    return '$pending pending • $leads leads';
  }

  @override
  String adminSponsorshipsInventoryPerformanceValue(
    Object impressions,
    Object users,
  ) {
    return '$impressions impressions • $users users';
  }

  @override
  String get adminSponsorshipsActivateAction => 'Activate';

  @override
  String get adminSponsorshipsPauseAction => 'Pause';

  @override
  String get adminSponsorshipsEndAction => 'End';

  @override
  String get adminSponsorshipsStatusActive => 'Active';

  @override
  String get adminSponsorshipsStatusPaused => 'Paused';

  @override
  String get adminSponsorshipsStatusEnded => 'Ended';

  @override
  String adminSponsorshipsQuotaValue(String daily, String total) {
    return 'D:$daily / T:$total';
  }

  @override
  String get adminSponsorshipsInfinity => 'Unlimited';

  @override
  String adminSponsorshipsDateRangeValue(String start, String end) {
    return '$start -> $end';
  }

  @override
  String get adminSuggestionsTitle => 'Suggestions';

  @override
  String get adminSuggestionsSearchHint => 'Search (name, city, district)';

  @override
  String get adminSuggestionsNameColumn => 'Name';

  @override
  String get adminSuggestionsStatusColumn => 'Status';

  @override
  String get adminSuggestionsCreatedAtColumn => 'Created';

  @override
  String adminSuggestionsSlaExceeded(String age) {
    return 'This record exceeded SLA: $age';
  }

  @override
  String get adminSuggestionsDetailTitle => 'Suggestion details';

  @override
  String get adminSuggestionsCategoryLabel => 'Category';

  @override
  String get adminSuggestionsLocationLabel => 'Location';

  @override
  String get adminSuggestionsAdminNoteOptional => 'Admin note (optional)';

  @override
  String get adminSuggestionsAssignedToMe => 'Suggestion assigned to me.';

  @override
  String get adminSuggestionsPossibleDuplicatesTitle => 'Possible duplicates';

  @override
  String get adminSuggestionsNoSimilarBusiness => 'No similar business found.';

  @override
  String get adminSuggestionsCreatedNewBusiness => 'New business created.';

  @override
  String get adminSuggestionsCreateNewBusiness => 'Create new business';

  @override
  String get adminSuggestionsLinkExistingConfirmTitle =>
      'Link to an existing business?';

  @override
  String get adminSuggestionsLinkedToExisting =>
      'Linked to the existing business.';

  @override
  String get adminSuggestionsRejectSelected => 'Reject selected';

  @override
  String get adminSuggestionsLinkToThisBusiness => 'Link to this business';

  @override
  String get adminSuggestionsNoLocation => 'No location';

  @override
  String adminSuggestionsDaysValue(String days) {
    return '$days days';
  }

  @override
  String get adminSuspendedClaimsTitle => 'Suspended claims';

  @override
  String get adminSuspendedClaimsAmountColumn => 'Amount';

  @override
  String get adminSuspendedClaimsClaimantColumn => 'Claimant';

  @override
  String adminSuspendedClaimsSlaExceeded(String age) {
    return 'SLA exceeded: $age';
  }

  @override
  String get adminSuspendedClaimsDetailTitle => 'Claim details';

  @override
  String get adminSuspendedClaimsMealLabel => 'Meal';

  @override
  String get adminSuspendedClaimsRejectNoteOptional =>
      'Rejection note (optional)';

  @override
  String get adminSuspendedClaimsApproveConfirm => 'Approve this claim?';

  @override
  String get adminSuspendedClaimsRejectConfirm => 'Reject this claim?';

  @override
  String get adminTableFeedbackTitle => 'Table feedback';

  @override
  String adminTableFeedbackTableAndRating(String tableNo, String rating) {
    return 'Table $tableNo • Rating $rating';
  }

  @override
  String get adminTempUploadsTitle => 'Temporary upload review';

  @override
  String get adminTempUploadsPromoted => 'Moved to menu.';

  @override
  String get adminTempUploadsRejectReasonHint => 'Rejection reason (optional)';

  @override
  String get adminTempUploadsRejected => 'Record rejected.';

  @override
  String get adminTempUploadsEmptyTitle => 'No pending temporary uploads';

  @override
  String get adminTempUploadsEmptyDescription =>
      'New submissions will appear here.';

  @override
  String adminTempUploadsBusinessId(String businessId) {
    return 'business_id: $businessId';
  }

  @override
  String get adminTempUploadsPromoteAction => 'Move to menu';

  @override
  String get adminVerifiedTitle => 'Verification / Premium';

  @override
  String get adminVerifiedSearchHint => 'Search business (name/address)';

  @override
  String get adminVerifiedSearching => 'Searching...';

  @override
  String get adminVerifiedSearchAction => 'Search';

  @override
  String get adminVerifiedVerificationColumn => 'Verification';

  @override
  String get adminVerifiedYes => 'Yes';

  @override
  String get adminVerifiedNo => 'No';

  @override
  String get adminVerifiedSettingsTitle => 'Verification settings';

  @override
  String get adminVerifiedTierVerified => 'Verified';

  @override
  String get adminVerifiedTierPremium => 'Premium';

  @override
  String get adminVerifiedTierLabel => 'Tier';

  @override
  String get adminVerifiedEndsAtLabel => 'Ends at (YYYY-MM-DD)';

  @override
  String get loginSubmitting => 'Signing in...';

  @override
  String get loginRegisterSubmitting => 'Creating account...';

  @override
  String get loginRegisterSuccess =>
      'Account created. Complete email/phone verification.';

  @override
  String get loginActionFailedTitle => 'Action could not be completed';

  @override
  String loginActionFailedDescription(String error) {
    return '$error\nCheck your connection and try again.';
  }

  @override
  String get legalTitle => 'Legal and Trust';

  @override
  String get legalPrivacySectionTitle => 'KVKK / GDPR';

  @override
  String legalPrivacyIntro(String appName) {
    return '$appName processes personal data only to provide the service. Consent is obtained for actions that require explicit consent, and data is deleted or shared in portable form upon request.';
  }

  @override
  String get legalPrivacyCategoriesAndRights =>
      'Data categories: profile, location, device information, usage analytics. Rights: access, correction, deletion, objection, portability.';

  @override
  String get legalPrivacyPolicyAction => 'Privacy Policy';

  @override
  String get legalKvkkAction => 'KVKK Text';

  @override
  String get legalGdprAction => 'GDPR Text';

  @override
  String get legalPrivacyApplicationHint =>
      'Application: create a request by email.';

  @override
  String get legalCopyrightSectionTitle => 'Photo Copyright Notice';

  @override
  String get legalCopyrightIntro =>
      'Menu and venue photos may be subject to copyright. If you see an infringement, you can report it via Report > Copyright.';

  @override
  String get legalCopyrightBody =>
      'For a copyright notice, a content link, evidence, and a short explanation are sufficient. Verified infringements are removed from the content.';

  @override
  String get legalCopyrightPolicyAction => 'Copyright Policy';

  @override
  String get legalOwnershipAppealSectionTitle => 'Business Ownership Appeal';

  @override
  String get legalOwnershipAppealIntro =>
      'If your ownership claim was rejected, you can appeal. Your documents will be reviewed again.';

  @override
  String get legalOwnershipAppealRequirementsTitle =>
      'Required information for appeal:';

  @override
  String get legalOwnershipAppealRequirementsBody =>
      '• Business name and tax/license information\n• Authorization document\n• Contact phone number';

  @override
  String get legalOwnershipAppealMailAction => 'Send appeal email';

  @override
  String legalOwnershipAppealMailSubject(String appName) {
    return '$appName - Ownership Appeal';
  }

  @override
  String get legalProductPrinciplesSectionTitle => 'Product Principles';

  @override
  String get legalProductPrinciplesDontsTitle => 'What not to do:';

  @override
  String get legalProductPrinciplesDontsBody =>
      '• Open everything to everyone\n• Hide sponsored content\n• Give owners permission to delete reviews\n• Relax the quality threshold for growth';

  @override
  String legalProductPrinciplesPolicy(
    String requireSponsoredLabel,
    String minSponsoredTrust,
    String ownerCanDeleteReviews,
  ) {
    return 'Policy: sponsored label required=$requireSponsoredLabel, min sponsored trust=$minSponsoredTrust, owner review deletion=$ownerCanDeleteReviews.';
  }

  @override
  String get legalFooterNote =>
      'Current policy texts and details are published on the website.';

  @override
  String get ownerBusinessSubmissionsEmptyTitle => 'No applications yet';

  @override
  String get ownerBusinessSubmissionsEmptyDescription =>
      'New business applications will be listed here.';

  @override
  String get ownerPublicMenuLinkAction => 'Public menu link';

  @override
  String get ownerCatalogLabel => 'Catalog';

  @override
  String ownerSortOrder(int order) {
    return 'Order: $order';
  }

  @override
  String get ownerUploadRequiresOwnership =>
      'You must be the business owner for this action.';

  @override
  String get ownerUploadRateLimited =>
      'Too many attempts. Please try again shortly.';

  @override
  String get ownerUploadFailed => 'Upload failed.';

  @override
  String get ownerDashboardNoPermission =>
      'You do not have permission for this business.';

  @override
  String get ownerDashboardOverview => 'Operations overview';

  @override
  String get ownerDashboardOperationsDescription =>
      'Menu quality, trust signals, and day-to-day owner work are collected on this screen.';

  @override
  String get ownerDashboardOperationsActionsTitle => 'Operations actions';

  @override
  String get ownerDashboardOperationsActionsDescription =>
      'Shortcuts to the flows that need intervention for the selected business.';

  @override
  String get ownerDashboardSelectBusinessForActions =>
      'Select a business first. Then manage menus, team access, and suspended claims from this hub.';

  @override
  String get ownerDashboardKpiLoading => 'Loading KPI...';

  @override
  String get ownerDashboardSelectBusinessForKpi =>
      'Select a business first to view KPI.';

  @override
  String get ownerDashboardKpiNotFound => 'KPI not found.';

  @override
  String get ownerDashboardKpiLast30Days => 'KPI (30 days)';

  @override
  String get ownerDashboardViews => 'Views';

  @override
  String get ownerDashboardClicks => 'Clicks';

  @override
  String get ownerDashboardDirections => 'Directions';

  @override
  String get ownerDashboardSearchImpressions => 'Search impressions';

  @override
  String get ownerDashboardQualityScoreLoading => 'Loading quality score...';

  @override
  String get ownerDashboardSelectBusinessForScore =>
      'Select a business first to view the score.';

  @override
  String get ownerDashboardScoreNotFound => 'Score not found.';

  @override
  String ownerDashboardMenuQualityScore(int score) {
    return 'Menu quality score: $score';
  }

  @override
  String get ownerDashboardScoreGood => 'Score is at a good level.';

  @override
  String get ownerDashboardScoreTarget =>
      'Target is 80+: complete the tasks below.';

  @override
  String get ownerDashboardNoExtraTasks =>
      'There are no extra tasks right now.';

  @override
  String get ownerDashboardProTitle => 'Yeedoy Pro';

  @override
  String get ownerDashboardProDescription =>
      'Yeedoy Pro: campaign and visibility tools.';

  @override
  String get ownerDashboardProFeatureSponsoredLabel =>
      'Sponsored label and transparent placement';

  @override
  String get ownerDashboardProFeatureAdvancedAnalytics =>
      'Advanced analytics and conversion metrics';

  @override
  String get ownerDashboardProFeatureCampaignAreas =>
      'Campaign and announcement areas';

  @override
  String get ownerDashboardProFeatureFeaturedPlacement =>
      'Featured placement with measurement';

  @override
  String get ownerDashboardProFeatureMultiBranch =>
      'Manage multiple branches from one panel';

  @override
  String get ownerDashboardProDisclaimer =>
      'Sponsored areas do not break the organic quality ranking.';

  @override
  String get ownerDashboardSurfaceDiscovery => 'Discovery';

  @override
  String get ownerDashboardSurfaceBusinessPage => 'Business page';

  @override
  String get ownerDashboardSurfaceStories => 'Stories';

  @override
  String get ownerDashboardSurfaceVerified => 'Verified';

  @override
  String get ownerDashboardSurfacePremium => 'Premium';

  @override
  String get ownerDashboardPreferredSurface => 'Preferred surface';

  @override
  String get ownerDashboardTargetCities => 'Target cities (comma separated)';

  @override
  String get ownerDashboardTargetDistricts =>
      'Target districts (comma separated)';

  @override
  String get ownerDashboardTargetCategories =>
      'Target categories (comma separated)';

  @override
  String get ownerDashboardMonthlyBudgetOptional => 'Monthly budget (optional)';

  @override
  String get ownerDashboardMonthlyImpressionsOptional =>
      'Monthly impression target (optional)';

  @override
  String get ownerDashboardPhoneOptional => 'Phone (optional)';

  @override
  String get ownerDashboardNoteHint => 'Target region or campaign note...';

  @override
  String get ownerDashboardSubmitting => 'Submitting...';

  @override
  String get ownerDashboardSubmitProLead => 'Send Pro request';

  @override
  String get ownerDashboardSelectBusinessFirst =>
      'You must select a business first.';

  @override
  String get ownerDashboardRequestReceived => 'We received your request.';

  @override
  String get ownerDashboardMoatLoading => 'Loading trust summary...';

  @override
  String get ownerDashboardSelectBusinessForMoat =>
      'Select a business first to view these scores.';

  @override
  String get ownerDashboardMoatNotFound => 'Score data not found.';

  @override
  String ownerDashboardSignals(int validators) {
    return 'Signals: $validators validators';
  }

  @override
  String ownerDashboardLastVerification(String date) {
    return 'last verification $date';
  }

  @override
  String get ownerDashboardLongTermDefense => 'Long-term defense wall';

  @override
  String get ownerDashboardLongTermDefenseDescription =>
      'These scores are used in search ranking, featuring, and sponsored filters.';

  @override
  String get ownerDashboardBusinessTrust => 'Business trust';

  @override
  String get ownerDashboardMenuFreshness => 'Menu freshness';

  @override
  String get ownerDashboardPriceAccuracy => 'Price accuracy';

  @override
  String get ownerDashboardContributionTrust => 'Contribution trust';

  @override
  String ownerDashboardEvidenceSummary(int evidencePct, int qualityPct) {
    return 'Evidence rate: %$evidencePct - Historical contribution quality: %$qualityPct';
  }

  @override
  String ownerDashboardLocalMicroData(int viewsToday) {
    return 'Local micro data: menu views today $viewsToday';
  }

  @override
  String ownerDashboardLocalMicroDataWithRank(int viewsToday, int rank) {
    return 'Local micro data: menu views today $viewsToday - district rank #$rank';
  }

  @override
  String get ownerMenuManagementTitle => 'Menu management';

  @override
  String get ownerApprovedBusinessNotFound => 'No approved business found.';

  @override
  String get ownerMenuNotFound => 'No menus yet.';

  @override
  String get ownerCreateMenuAction => 'Create new menu';

  @override
  String get ownerCreateMenuTitle => 'New menu';

  @override
  String get ownerCreateAction => 'Create';

  @override
  String get ownerMenuCreated => 'Menu created.';

  @override
  String get ownerMenuArchived => 'Menu archived.';

  @override
  String get ownerMenuPublished => 'Menu published.';

  @override
  String get ownerDigitalMenuStudioTitle => 'Digital Menu & QR Studio';

  @override
  String get ownerDigitalMenuStudioSubtitle =>
      'Launch it from the panel and manage theme, language, link, and QR output in one place.';

  @override
  String get ownerAmenitiesTitle => 'Amenities';

  @override
  String get ownerAmenitiesUpdated => 'Amenities updated.';

  @override
  String get ownerProfileCompletionTitle => 'Profile completion';

  @override
  String ownerProfileCompletionPercent(int pct) {
    return '%$pct completed';
  }

  @override
  String get ownerSponsoredRequestsSoon => 'Sponsored requests will open soon.';

  @override
  String get ownerSponsoredVisibilityAction => 'Get sponsored visibility';

  @override
  String get ownerMenuErrorNotOwner =>
      'You do not have permission for this action.';

  @override
  String get ownerMenuErrorNotFound => 'Record not found.';

  @override
  String get ownerMenuErrorHasItems => 'This section still has items.';

  @override
  String get ownerMenuErrorGeneric => 'An error occurred.';

  @override
  String ownerMoatPitchText(
    String businessName,
    int trust,
    int freshness,
    int accuracy,
    int validators,
    int evidencePct,
    int viewsToday,
    String link,
  ) {
    return '$businessName | Trust score $trust/100 | Menu freshness $freshness/100 | Price accuracy $accuracy/100 | $validators validators | Evidence rate %$evidencePct | Menu views today $viewsToday\n$link';
  }

  @override
  String get ownerApproveAction => 'Approve';

  @override
  String get ownerRejectAction => 'Reject';

  @override
  String get ownerOnboardingTitle => 'Setup';

  @override
  String get ownerOnboardingContinue => 'Continue';

  @override
  String get ownerOnboardingFinish => 'Finish';

  @override
  String get ownerOnboardingStepProfile => 'Profile';

  @override
  String get ownerOnboardingStepAmenities => 'Amenities';

  @override
  String get ownerOnboardingStepMenu => 'Menu';

  @override
  String get ownerOnboardingStepPreview => 'Preview';

  @override
  String get ownerOnboardingStepShare => 'Share';

  @override
  String get ownerOnboardingUrlHint => 'https://...';

  @override
  String get ownerOnboardingPasteAction => 'Paste';

  @override
  String get ownerOnboardingProfileIntro =>
      'Add logo and cover, then set working hours.';

  @override
  String get ownerOnboardingLogoUrl => 'Logo URL';

  @override
  String get ownerOnboardingCoverUrl => 'Cover URL';

  @override
  String get ownerOnboardingSelectOpenTime => 'Select opening time';

  @override
  String ownerOnboardingOpenTime(String time) {
    return 'Opens: $time';
  }

  @override
  String get ownerOnboardingSelectCloseTime => 'Select closing time';

  @override
  String ownerOnboardingCloseTime(String time) {
    return 'Closes: $time';
  }

  @override
  String get ownerOnboardingHoursHint => 'Hours are applied to all days.';

  @override
  String get ownerOnboardingBusinessLinks =>
      'Business links (Instagram / YouTube / Facebook)';

  @override
  String get ownerOnboardingInstagramPreview => 'Instagram preview';

  @override
  String get ownerOnboardingYoutubePreview => 'YouTube preview';

  @override
  String get ownerOnboardingFacebookPreview => 'Facebook preview';

  @override
  String get ownerOnboardingLinksPending =>
      'Saving business links will be added soon.';

  @override
  String get ownerOnboardingAmenitiesListNotFound =>
      'Amenities list not found.';

  @override
  String get ownerOnboardingSelectAtLeastTwoAmenities =>
      'Select at least 2 amenities.';

  @override
  String get ownerOnboardingMenuRequirement =>
      'At least 1 section and 1 item are required.';

  @override
  String ownerOnboardingMenuCount(int count) {
    return 'Menu count: $count';
  }

  @override
  String ownerOnboardingSectionCount(int count) {
    return 'Section count: $count';
  }

  @override
  String ownerOnboardingItemCount(int count) {
    return 'Item count: $count';
  }

  @override
  String get ownerOnboardingNoShareWithoutMenu =>
      'You cannot share without a menu.';

  @override
  String get ownerOnboardingGoToMenuManagement => 'Go to menu management';

  @override
  String get ownerOnboardingPreviewRequiresMenu =>
      'Create a menu first for preview.';

  @override
  String get ownerOnboardingPreviewNoItems => 'No items found.';

  @override
  String get ownerOnboardingShareRequiresMenu =>
      'Create a menu first to share.';

  @override
  String get ownerOnboardingShareLinkTitle => 'Share link';

  @override
  String get ownerOnboardingCopyLink => 'Copy link';

  @override
  String get ownerOnboardingDownloadQr => 'Download QR';

  @override
  String ownerOnboardingPreviewMenu(String title) {
    return 'Menu: $title';
  }

  @override
  String get ownerOnboardingLogoCoverRequired => 'Logo and cover are required.';

  @override
  String get ownerOnboardingHoursRequired => 'Working hours are required.';

  @override
  String get ownerOnboardingQrNotReady => 'QR is not ready yet.';

  @override
  String get ownerOnboardingQrDownloadFailed => 'QR could not be downloaded.';

  @override
  String ownerOnboardingWhatsappShareText(String link) {
    return 'Our menu is up to date. You can review it here: $link';
  }

  @override
  String ownerOnboardingXShareText(String link) {
    return 'Current menu and verified prices: $link';
  }

  @override
  String ownerOnboardingInstagramShareText(String link) {
    return 'Current menu and verified prices: $link';
  }

  @override
  String get ownerPriceSuggestionsTitle => 'Price approvals';

  @override
  String get ownerPriceSuggestionsEmptyTitle => 'No records';

  @override
  String get ownerPriceSuggestionsEmptyDescription =>
      'New price suggestions will be listed here.';

  @override
  String get ownerPriceSuggestionsApproveConfirm =>
      'Approve this price suggestion?';

  @override
  String get ownerPriceSuggestionsApproved => 'Approved.';

  @override
  String get ownerPriceSuggestionsRejectReasonLabel =>
      'Rejection reason (minimum 3 characters)';

  @override
  String get ownerPriceSuggestionsRejected => 'Rejected.';

  @override
  String ownerPriceSuggestionsConfidence(int pct) {
    return 'Confidence $pct%';
  }

  @override
  String ownerPriceSuggestionsConflictCount(int count) {
    return 'Conflict: $count prices';
  }

  @override
  String get ownerPriceSuggestionsAnomaly => 'Anomaly';

  @override
  String ownerPriceSuggestionsAnomalyFlag(String flag) {
    return 'Anomaly: $flag';
  }

  @override
  String ownerPriceSuggestionsConflictVariants(int count) {
    return 'Conflict: there are $count different suggestions for the same item';
  }

  @override
  String get ownerGroupRequestsTitle => 'Requests';

  @override
  String get ownerGroupRequestsOpenRequests => 'Open requests';

  @override
  String get ownerGroupRequestsEmptyTitle => 'No requests';

  @override
  String get ownerGroupRequestsEmptyDescription =>
      'No open group dining request was found.';

  @override
  String ownerGroupRequestsPartyBudget(int partySize, String budget) {
    return '$partySize people • $budget';
  }

  @override
  String get ownerGroupRequestsOfferAction => 'Make offer';

  @override
  String get ownerGroupRequestsMyOffers => 'My offers';

  @override
  String get ownerGroupRequestsOffersEmptyTitle => 'No offers';

  @override
  String get ownerGroupRequestsOffersEmptyDescription =>
      'Offers you submit will appear here.';

  @override
  String ownerGroupRequestsOfferStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get ownerGroupRequestsTotalOfferLabel => 'Total offer (TL)';

  @override
  String get ownerGroupRequestsDessertIncluded => 'Dessert included';

  @override
  String get ownerGroupRequestsDrinksIncluded => 'Drinks included';

  @override
  String get ownerGroupRequestsMenuFixed => 'Fixed menu';

  @override
  String get ownerGroupRequestsEnterValidPrice => 'Enter a valid price.';

  @override
  String get ownerGroupRequestsOfferSent => 'Offer sent.';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get forbiddenTitle => 'Access denied';

  @override
  String get forbiddenDescription =>
      'You do not have permission to access this area. Continue with a different panel or business.';

  @override
  String forbiddenDescriptionWithRoute(String route) {
    return 'You do not have permission to access this area. Requested route: $route';
  }

  @override
  String get forbiddenBackHomeAction => 'Back to home';

  @override
  String get forbiddenGoBusinessesAction => 'Go to my businesses';

  @override
  String get ownerShellPanelTitle => 'Owner Panel';

  @override
  String get ownerShellOverviewLabel => 'Operations';

  @override
  String get ownerShellGrowthLabel => 'Growth';

  @override
  String get ownerShellPriceSuggestionsLabel => 'Price suggestions';

  @override
  String get ownerShellSuspendedClaimsLabel => 'Suspended claims';

  @override
  String get ownerShellRequestsLabel => 'Requests';

  @override
  String get ownerShellAuditLabel => 'Audit';

  @override
  String get ownerSelectedBusinessTitle => 'Selected business';

  @override
  String get ownerBusinessSwitcherLabel => 'Switch business';

  @override
  String get ownerGoBusinessesAction => 'Go to my businesses';

  @override
  String get ownerBusinessContextEmptyTitle => 'Select a business first';

  @override
  String get ownerBusinessContextEmptyDescription =>
      'Your business context appears here. Pick one from My Businesses to manage menus, prices, and requests.';

  @override
  String get ownerBusinessContextLoadError =>
      'Could not load business context.';

  @override
  String get ownerNoBusinessPermissionTitle =>
      'You do not have access to this business';

  @override
  String get ownerNoBusinessPermissionDescription =>
      'We could not verify your management access for this business. Pick another business or check your access.';

  @override
  String get ownerBusinessSelectionRequiredDescription =>
      'You need to select a business you can manage before opening this screen.';

  @override
  String get adminTableStatusLabel => 'Status filter';

  @override
  String get adminTableSavedViewsLabel => 'Saved view';

  @override
  String get adminTableNoSavedViews => 'No saved views';

  @override
  String get adminTableSaveViewAction => 'Save view';

  @override
  String get adminTableDeleteViewAction => 'Delete view';

  @override
  String get adminTableViewNameLabel => 'View name';

  @override
  String get adminTableViewNameHint => 'e.g. Last 7 days / Open items';

  @override
  String get adminTablePickDateRangeAction => 'Pick date range';

  @override
  String get adminTableClearDateRangeAction => 'Clear date';

  @override
  String adminTableDateRangeValue(String start, String end) {
    return '$start - $end';
  }

  @override
  String adminTableBulkSelectionCount(int count) {
    return '$count records selected';
  }

  @override
  String get adminTableRowsPerPageLabel => 'Rows per page';

  @override
  String adminTablePageRange(int start, int end, int total) {
    return '$start-$end / $total';
  }

  @override
  String get adminTablePrevPageAction => 'Previous page';

  @override
  String get adminTableNextPageAction => 'Next page';

  @override
  String get adminTableSavedViewCreated => 'View saved.';

  @override
  String get adminTableSavedViewDeleted => 'View deleted.';

  @override
  String get adminQueueTitle => 'Unified Queue';

  @override
  String get adminQueueDescription =>
      'Manage business submissions, reports, pricing, claims, and media flags from one operator queue.';

  @override
  String get adminQueueErrorTitle => 'Queue could not be loaded';

  @override
  String get adminQueueSearchHint => 'Search business, content, or notes';

  @override
  String get adminQueueTypeLabel => 'Queue type';

  @override
  String get adminQueueCityHint => 'City filter';

  @override
  String get adminQueueUnassignSelectedAction => 'Unassign selected';

  @override
  String get adminQueueEmptyDescription =>
      'No queue records match the selected filters.';

  @override
  String get adminQueueColumnType => 'Type';

  @override
  String get adminQueueColumnTitle => 'Record';

  @override
  String get adminQueueColumnCreatedAt => 'Created';

  @override
  String get adminQueueAssignToMeAction => 'Assign to me';

  @override
  String get adminQueueUnassignAction => 'Unassign';

  @override
  String get adminQueueOpenDetailsAction => 'Open details';

  @override
  String get adminQueueAssignedToMe => 'Record assigned to you.';

  @override
  String get adminQueueUnassigned => 'Record unassigned.';

  @override
  String adminQueueBulkAssignmentResult(int applied, int total) {
    return 'Assignment updated for $applied / $total records.';
  }

  @override
  String adminQueueBulkDecisionResult(int applied, int skipped) {
    return '$applied records processed, $skipped skipped.';
  }

  @override
  String get adminQueueRejectDialogTitle => 'Rejection note';

  @override
  String get adminQueueRejectDialogLabel => 'Operator note';

  @override
  String get adminQueueRejectDialogRequiredHint =>
      'A rejection note is required for this record type.';

  @override
  String get adminQueueRejectDialogOptionalHint =>
      'Add a reason if you want to keep context.';

  @override
  String get adminQueueDetailTitle => 'Queue details';

  @override
  String get adminQueueOpenSourceAction => 'Open source screen';

  @override
  String get adminQueueDetailPayloadTitle => 'Raw record payload';

  @override
  String get adminQueueExportCsvAction => 'Export CSV';

  @override
  String adminQueueExportReady(Object count) {
    return '$count queue records downloaded as CSV.';
  }

  @override
  String get adminQueuePreviewTitle => 'Operator summary';

  @override
  String get adminQueuePreviewApplicantLabel => 'Applicant';

  @override
  String get adminQueuePreviewCategoryLabel => 'Category';

  @override
  String get adminQueuePreviewAddressLabel => 'Address';

  @override
  String get adminQueuePreviewPhoneLabel => 'Phone';

  @override
  String get adminQueuePreviewWebsiteLabel => 'Website';

  @override
  String get adminQueuePreviewReasonLabel => 'Reason';

  @override
  String get adminQueuePreviewTargetTypeLabel => 'Target type';

  @override
  String get adminQueuePreviewTargetIdLabel => 'Target record';

  @override
  String get adminQueuePreviewDetailsLabel => 'Details';

  @override
  String get adminQueuePreviewAdminNoteLabel => 'Operator note';

  @override
  String get adminQueuePreviewEvidenceLabel => 'Evidence URL';

  @override
  String get adminQueuePreviewCurrentPriceLabel => 'Current price';

  @override
  String get adminQueuePreviewSuggestedPriceLabel => 'Suggested price';

  @override
  String get adminQueuePreviewAnomalyLabel => 'Anomaly score';

  @override
  String get adminQueuePreviewConflictLabel => 'Conflict state';

  @override
  String get adminQueuePreviewCreatedByLabel => 'Created by';

  @override
  String get adminQueuePreviewMenuItemLabel => 'Menu item';

  @override
  String get adminQueueOpenFromReportsAction => 'Open in queue';

  @override
  String get adminQueueOpenFromClaimsAction => 'Open in queue';

  @override
  String get adminQueueTypeBusinessSubmission => 'Business submission';

  @override
  String get adminQueueTypeReport => 'Report';

  @override
  String get adminQueueTypePriceSuggestion => 'Price suggestion';

  @override
  String get adminQueueTypeClaim => 'Claim';

  @override
  String get adminQueueTypeMediaFlag => 'Media flag';

  @override
  String get adminQueueStatusNew => 'New';

  @override
  String get adminQueueStatusOpen => 'Open';

  @override
  String get adminQueueStatusReviewing => 'Reviewing';

  @override
  String get adminQueueStatusClosed => 'Closed';

  @override
  String adminQueueSlaWaitingHours(Object hours, int slaHours) {
    return 'Waiting ${hours}h • SLA ${slaHours}h';
  }

  @override
  String get adminQueueDecisionSupportTitle => 'Decision support';

  @override
  String get adminQueueDecisionSupportEmpty =>
      'There are no additional decision signals for this record.';

  @override
  String get adminQueuePendingReasonLabel => 'Why pending';

  @override
  String get adminQueueAnomalyReasonLabel => 'Why anomaly';

  @override
  String get adminQueueDecisionSignalsLabel => 'Signals';

  @override
  String get adminQueueDecisionHistoryTitle => 'Similar decision history';

  @override
  String get adminQueueDecisionHistoryLoading =>
      'Loading recent decision history';

  @override
  String get adminQueueDecisionHistoryEmpty =>
      'No recent decisions were found for this context.';

  @override
  String get adminQueueDecisionHistoryError =>
      'Decision history could not be loaded';

  @override
  String adminQueueDecisionHistorySummary(
    int relevantCount,
    int exactTargetCount,
    int approvedCount,
    int rejectedCount,
  ) {
    return '$relevantCount related records • exact target $exactTargetCount • approved $approvedCount • rejected $rejectedCount';
  }

  @override
  String adminQueueDecisionHistoryAssignments(
    int assignedCount,
    int handledCount,
  ) {
    return 'Assignments $assignedCount • handled $handledCount';
  }

  @override
  String get adminQueueDecisionHistoryExactTarget => 'Exact record';

  @override
  String get adminQueueDecisionHistorySimilarRecord => 'Similar record';

  @override
  String get adminQueuePendingReasonConflictAndAnomaly =>
      'Queued because prices conflict and anomaly score is high.';

  @override
  String get adminQueuePendingReasonPriceConflict =>
      'Conflicting prices for the same menu item were queued for review.';

  @override
  String get adminQueuePendingReasonAnomalyQueue =>
      'The anomaly score crossed the review threshold.';

  @override
  String get adminQueuePendingReasonLowConfidence =>
      'The confidence score is too low for automatic approval.';

  @override
  String get adminQueuePendingReasonManualReview =>
      'The rule engine could not auto-decide; operator review is required.';

  @override
  String get adminQueuePendingReasonGreyArea =>
      'The case stayed in the grey zone and was escalated to an operator.';

  @override
  String get adminQueuePendingReasonMissingEvidence =>
      'Verification is blocked because evidence is missing.';

  @override
  String get adminQueuePendingReasonClaimantAutoPending =>
      'The claimant was placed into auto-pending because of safety signals.';

  @override
  String get adminQueuePendingReasonMissingSubmissionData =>
      'The submission is missing core fields required for approval.';

  @override
  String get adminQueueAnomalyReasonHighAnomalyScore =>
      'The anomaly score is high.';

  @override
  String get adminQueueAnomalyReasonConflictingPrices =>
      'Multiple conflicting prices were detected recently.';

  @override
  String get adminQueueAnomalyReasonRiskyActor =>
      'The submitting account has a high risk score.';

  @override
  String get adminQueueAnomalyReasonLowBusinessQuality =>
      'The business quality score is low.';

  @override
  String get adminQueueAnomalyReasonAutoModerated =>
      'The record already passed through the auto-moderation chain.';

  @override
  String adminQueueSignalQualityConfidence(Object value) {
    return '$value confidence';
  }

  @override
  String adminQueueSignalAnomalyScore(Object value) {
    return '$value anomaly';
  }

  @override
  String adminQueueSignalConflictVariants(int count) {
    return '$count distinct prices in 24h';
  }

  @override
  String adminQueueSignalAnomalyFlags(Object tags) {
    return 'Anomaly flags: $tags';
  }

  @override
  String adminQueueSignalActorReputation(int score) {
    return 'Contributor reputation score $score';
  }

  @override
  String adminQueueSignalActorRisk(int score) {
    return 'Account risk score $score';
  }

  @override
  String adminQueueSignalBusinessQuality(Object score) {
    return 'Business quality score $score';
  }

  @override
  String get adminQueueSignalAutoModerated => 'Auto-moderation signal detected';

  @override
  String adminQueueSignalShortDetails(int length) {
    return 'Details are too short ($length chars)';
  }

  @override
  String get adminQueueSignalMissingEvidence => 'Evidence link is missing';

  @override
  String adminQueueSignalMissingFields(int count, Object fields) {
    return '$count missing fields: $fields';
  }

  @override
  String get adminQueueAuditActionBusinessSubmissionAssigned =>
      'Business submission assigned';

  @override
  String get adminQueueAuditActionBusinessSubmissionUnassigned =>
      'Business submission unassigned';

  @override
  String get adminQueueAuditActionPriceSuggestionAssigned =>
      'Price suggestion assigned';

  @override
  String get adminQueueAuditActionPriceSuggestionUnassigned =>
      'Price suggestion unassigned';

  @override
  String get adminQueueAuditActionReportAutoCloseDuplicate =>
      'Duplicate report auto-closed';

  @override
  String get adminQueueAuditActionReportAutoRejectLowQuality =>
      'Low-quality report auto-rejected';

  @override
  String get adminQueueAuditActionReportAutoQueueGrey =>
      'Grey-zone report auto-queued';

  @override
  String get adminTableAssignToMeAction => 'Assign selected to me';

  @override
  String get adminTableApproveSelectedAction => 'Approve selected';

  @override
  String get adminTableRejectSelectedAction => 'Reject selected';

  @override
  String get adminCommonStatusLabel => 'Status';

  @override
  String get adminCommonLocationLabel => 'Location';

  @override
  String get adminCommonActionsLabel => 'Actions';

  @override
  String get adminBusinessSubmissionsSearchHint =>
      'Search business name, address, category, or applicant';

  @override
  String get adminBusinessSubmissionsBusinessColumn => 'Business';

  @override
  String get adminBusinessSubmissionsCategoryColumn => 'Category';

  @override
  String get adminBusinessSubmissionsApplicantColumn => 'Applicant';

  @override
  String get ownerDigitalMenuQrOpenStudioAction => 'Open Digital Menu & QR';

  @override
  String get ownerDigitalMenuQrOpenStudioTooltip =>
      'Opens the Digital Menu & QR experience in a new tab.';

  @override
  String get ownerDigitalMenuOpenPublicMenuAction => 'Open live menu';

  @override
  String get ownerDigitalMenuOpenPublicMenuTooltip =>
      'Opens the visitor-facing menu in a new tab.';

  @override
  String get ownerPublicMenuOpenedInNewTab => 'Live menu opened in a new tab.';

  @override
  String get ownerDigitalMenuOpenedInNewTab =>
      'Digital Menu & QR opened in a new tab.';

  @override
  String get ownerShellTeamLabel => 'Team';

  @override
  String get ownerShellActivityLabel => 'Activity';

  @override
  String adminImpersonationBannerTitle(String user) {
    return 'Viewing as $user';
  }

  @override
  String get adminImpersonationUsingActualRole =>
      'Using the user\'s actual role';

  @override
  String adminImpersonationRoleOverride(String role) {
    return 'Role override: $role';
  }

  @override
  String get adminImpersonationStopAction => 'Stop';

  @override
  String get adminImpersonationUseActualRoleOption => 'Use actual role';

  @override
  String get adminImpersonationRoleOverrideLabel => 'Role override';

  @override
  String get adminImpersonationRefreshAction => 'Refresh preview';

  @override
  String get adminImpersonationStartAction => 'Start preview';

  @override
  String get adminImpersonationStarted => 'Preview started.';

  @override
  String get adminImpersonationStopped => 'Preview stopped.';

  @override
  String get ownerTeamRoleOwner => 'Owner';

  @override
  String get ownerTeamRoleManager => 'Manager';

  @override
  String get ownerTeamRoleEditor => 'Editor';

  @override
  String get ownerTeamRoleStaff => 'Staff';

  @override
  String get ownerTeamRoleViewer => 'Viewer';

  @override
  String get ownerTeamScopeThisBusiness => 'Only this branch';

  @override
  String get ownerTeamScopeAllBranches => 'All branches';

  @override
  String get ownerTeamTitle => 'Team members';

  @override
  String get ownerTeamDescription =>
      'Invite branch staff, assign roles, and control whether access is limited to this branch or all chain branches.';

  @override
  String get ownerTeamLoadErrorTitle => 'Team members could not be loaded';

  @override
  String get ownerTeamEmptyTitle => 'No team members yet';

  @override
  String get ownerTeamEmptyDescription =>
      'Add your first team member to start branch-scoped access control.';

  @override
  String get ownerTeamEmailRequired => 'Email is required.';

  @override
  String get ownerTeamSaved => 'Team member saved.';

  @override
  String get ownerTeamUpdated => 'Team member updated.';

  @override
  String get ownerTeamRemoved => 'Team member removed.';

  @override
  String get ownerTeamSelectedBranchFallback => 'Selected branch';

  @override
  String get ownerTeamScopeAwareBadge => 'Scope-aware RBAC';

  @override
  String get ownerTeamInviteTitle => 'Invite or assign';

  @override
  String get ownerTeamEmailLabel => 'Email';

  @override
  String get ownerTeamEmailHint => 'teammate@company.com';

  @override
  String get ownerTeamRoleFieldLabel => 'Role';

  @override
  String get ownerTeamScopeFieldLabel => 'Scope';

  @override
  String get ownerTeamSaveMemberAction => 'Save member';

  @override
  String get ownerTeamStatusPendingInvite => 'Pending invite';

  @override
  String get ownerTeamStatusActive => 'Active';

  @override
  String ownerTeamSourceValue(String source) {
    return 'Source: $source';
  }

  @override
  String get ownerTeamUpdateAction => 'Update';

  @override
  String get ownerTeamRemoveAction => 'Remove';

  @override
  String get ownerTeamSourceOwnerClaim => 'Owner claim';

  @override
  String get ownerTeamSourceChainMembership => 'Chain membership';

  @override
  String get ownerTeamSourceDirect => 'Direct assignment';

  @override
  String get adminUserAccessForbiddenDescription =>
      'Only admins can override access or start impersonation.';

  @override
  String get adminUserAccessTitle => 'User access preview';

  @override
  String adminUserAccessDescription(String userId) {
    return 'Preview business access for user $userId. Role override only affects preview and impersonation context.';
  }

  @override
  String get adminUserAccessLoadErrorTitle => 'Access preview failed';

  @override
  String get adminUserAccessEmptyTitle => 'No accessible businesses';

  @override
  String get adminUserAccessEmptyDescription =>
      'This user currently has no owner or team access in the panel.';

  @override
  String adminUserAccessBusinessMeta(
    String city,
    String district,
    String role,
  ) {
    return '$city / $district • $role';
  }

  @override
  String get adminUserAccessOpenOwnerPanelAction => 'Open owner panel';

  @override
  String get ownerActivityTitle => 'Business activity';

  @override
  String get ownerActivityDescription =>
      'Review critical changes, team operations, and moderation outcomes for the selected business.';

  @override
  String get ownerActivityMissingBusinessTitle => 'Select a business first';

  @override
  String get ownerActivityMissingBusinessDescription =>
      'You need to select a business you can manage before viewing the activity stream.';

  @override
  String get adminAuditDescription =>
      'Filter and review critical system changes, moderation decisions, and security actions.';

  @override
  String get adminAuditErrorTitle => 'Audit records could not be loaded';

  @override
  String get adminAuditSearchHint =>
      'Search action, target ID, user ID, or meta';

  @override
  String get adminAuditDateRangeLabel => 'Date range';

  @override
  String get adminAuditDateRangeEmpty => 'All time';

  @override
  String adminAuditDateRangeValue(String start, String end) {
    return '$start - $end';
  }

  @override
  String get adminAuditOnlyMyActions => 'Only my actions';

  @override
  String get ownerActivityOnlyMyActions => 'Only my actions';

  @override
  String get ownerActivityPresetAll => 'All';

  @override
  String get ownerActivityPresetToday => 'Today';

  @override
  String get ownerActivityPresetLast7Days => 'Last 7 days';

  @override
  String get ownerActivityPresetTeamChanges => 'Team changes';

  @override
  String get adminAuditExportCsvAction => 'Export CSV';

  @override
  String get adminAuditExportReady => 'Audit CSV has been prepared.';

  @override
  String get adminAuditIpLabel => 'IP';

  @override
  String get adminAuditUserAgentLabel => 'User-Agent';

  @override
  String get adminAuditActorRoleAdmin => 'Admin';

  @override
  String get adminAuditActorRoleOwner => 'Owner';

  @override
  String get adminAuditActorRoleManager => 'Manager';

  @override
  String get adminAuditActorRoleEditor => 'Editor';

  @override
  String get adminAuditActorRoleStaff => 'Staff';

  @override
  String get adminAuditActorRoleViewer => 'Viewer';

  @override
  String get adminAuditActorRoleUser => 'User';

  @override
  String get auditActionBusinessVerificationChanged =>
      'Business verification changed';

  @override
  String get auditActionBusinessMerge => 'Business merged';

  @override
  String get auditActionBusinessMergeProposed =>
      'Business merge proposal logged';

  @override
  String get auditActionMenuCreated => 'Menu created';

  @override
  String get auditActionMenuUpdated => 'Menu updated';

  @override
  String get auditActionMenuArchived => 'Menu archived';

  @override
  String get auditActionMenuPublished => 'Menu published';

  @override
  String get auditActionMenuDeleted => 'Menu deleted';

  @override
  String get auditActionMenuItemCreated => 'Menu item created';

  @override
  String get auditActionMenuItemUpdated => 'Menu item updated';

  @override
  String get auditActionMenuItemArchived => 'Menu item archived';

  @override
  String get auditActionMenuItemPublished => 'Menu item published';

  @override
  String get auditActionMenuItemDeleted => 'Menu item deleted';

  @override
  String get auditActionPriceSuggestionApproved => 'Price suggestion approved';

  @override
  String get auditActionPriceSuggestionRejected => 'Price suggestion rejected';

  @override
  String get auditActionOwnerPriceSuggestionOverride =>
      'Owner overrode a price suggestion';

  @override
  String get auditActionOwnerPriceSuggestionRejected =>
      'Owner rejected a price suggestion';

  @override
  String get auditActionTeamMemberSaved => 'Team member added or updated';

  @override
  String get auditActionTeamMemberUpdated => 'Team member permissions updated';

  @override
  String get auditActionTeamMemberRemoved => 'Team member removed';

  @override
  String get auditActionClaimApproved => 'Claim approved';

  @override
  String get auditActionClaimRejected => 'Claim rejected';

  @override
  String get auditActionClaimAssigned => 'Claim assigned';

  @override
  String get auditActionClaimUpdated => 'Claim updated';

  @override
  String get auditActionReportUpdated => 'Report updated';

  @override
  String get auditActionReportBulkUpdated => 'Reports bulk-updated';

  @override
  String get auditActionReportAssigned => 'Report assigned';

  @override
  String get auditActionReportHandled => 'Report handled';

  @override
  String get auditActionReportExported => 'Report CSV exported';

  @override
  String get auditActionUserSafetyAction => 'User safety action applied';

  @override
  String get auditActionImpersonationStarted => 'Impersonation started';

  @override
  String get auditActionImpersonationStopped => 'Impersonation stopped';

  @override
  String get auditTargetTypeBusiness => 'Business';

  @override
  String get auditTargetTypeMenu => 'Menu';

  @override
  String get auditTargetTypeMenuItem => 'Menu item';

  @override
  String get auditTargetTypePriceSuggestion => 'Price suggestion';

  @override
  String get auditTargetTypeTeamMember => 'Team member';

  @override
  String get auditTargetTypeOwnerClaim => 'Owner claim';

  @override
  String get auditTargetTypeReport => 'Report';

  @override
  String get auditTargetTypeUser => 'User';

  @override
  String get adminSearchTitle => 'Admin search';

  @override
  String get adminSearchDescription =>
      'Find businesses, users, reports, submissions, claims, and menu items from one search surface.';

  @override
  String get adminSearchTopbarHint =>
      'Search businesses, users, or moderation records';

  @override
  String get adminSearchInputHint =>
      'Type at least 2 characters. Search by ID, email, phone, or name.';

  @override
  String get adminSearchRunAction => 'Search';

  @override
  String get adminSearchKeyboardHint =>
      'Use the up/down arrow keys to move through results and Enter to open the selected row.';

  @override
  String get adminSearchStartTitle => 'Start searching';

  @override
  String get adminSearchStartDescription =>
      'Enter at least 2 characters to find a business, user, or moderation record.';

  @override
  String get adminSearchEmptyTitle => 'No results';

  @override
  String adminSearchEmptyDescription(Object query) {
    return 'No records matched \"$query\".';
  }

  @override
  String get adminSearchErrorTitle => 'Search could not be loaded';

  @override
  String get adminSearchForbiddenDescription =>
      'Global admin search is available only to admin users.';

  @override
  String get adminSearchCopiedId => 'Record ID copied to clipboard.';

  @override
  String get adminSearchOpenInNewTabAction => 'Open in new tab';

  @override
  String get adminSearchCopyIdAction => 'Copy ID';

  @override
  String get adminSearchCategoryBusinesses => 'Businesses';

  @override
  String get adminSearchCategoryUsers => 'Users';

  @override
  String get adminSearchCategoryReports => 'Reports';

  @override
  String get adminSearchCategorySubmissions => 'Submissions';

  @override
  String get adminSearchCategoryClaims => 'Claims';

  @override
  String get adminSearchCategoryMenuItems => 'Menu items';

  @override
  String get ownerShellAnalyticsLabel => 'Analytics';

  @override
  String get ownerAnalyticsTitle => 'Business analytics';

  @override
  String get ownerAnalyticsDescription =>
      'Track QR scans, menu opens, and item interest from a single screen.';

  @override
  String get ownerAnalyticsMissingBusinessTitle => 'Select a business first';

  @override
  String get ownerAnalyticsMissingBusinessDescription =>
      'Choose a business from the context bar to view analytics.';

  @override
  String get ownerAnalyticsForbiddenTitle =>
      'You do not have access to this data';

  @override
  String get ownerAnalyticsForbiddenDescription =>
      'This analytics screen is available only to team members who can read the selected business.';

  @override
  String get ownerAnalyticsErrorTitle => 'Analytics could not be loaded';

  @override
  String get ownerAnalyticsPreset7Days => 'Last 7 days';

  @override
  String get ownerAnalyticsPreset30Days => 'Last 30 days';

  @override
  String get ownerAnalyticsPreset90Days => 'Last 90 days';

  @override
  String get ownerAnalyticsBranchCompareToggle => 'Compare branches';

  @override
  String get ownerAnalyticsQrScansTitle => 'QR scans';

  @override
  String get ownerAnalyticsMenuOpensTitle => 'Menu opens';

  @override
  String get ownerAnalyticsCategoryViewsTitle => 'Category views';

  @override
  String get ownerAnalyticsItemClicksTitle => 'Item clicks';

  @override
  String ownerAnalyticsDailyTrendTitle(Object days) {
    return 'Daily flow for the last $days days';
  }

  @override
  String get ownerAnalyticsNoTrendDataDescription =>
      'There is no daily trend data for the selected time range.';

  @override
  String get ownerAnalyticsTopItemsTitle => 'Top items';

  @override
  String get ownerAnalyticsNoItemDataTitle => 'No item data yet';

  @override
  String get ownerAnalyticsNoItemDataDescription =>
      'Top clicked items will appear here once item-level interactions are captured.';

  @override
  String get ownerAnalyticsTopCategoriesTitle => 'Top categories';

  @override
  String get ownerAnalyticsNoCategoryDataTitle => 'No category data yet';

  @override
  String get ownerAnalyticsNoCategoryDataDescription =>
      'Category-level viewing data will be listed here as soon as it becomes available.';

  @override
  String get ownerAnalyticsSourceBreakdownTitle => 'Source breakdown';

  @override
  String get ownerAnalyticsNoSourceDataTitle => 'No source data';

  @override
  String get ownerAnalyticsNoSourceDataDescription =>
      'QR short-link and normal menu entry sources will appear here once traffic arrives.';

  @override
  String get ownerAnalyticsSourceQrShortLink => 'QR short link';

  @override
  String get ownerAnalyticsSourceNormal => 'Normal entry';

  @override
  String get ownerAnalyticsBranchCompareTitle => 'Branch comparison';

  @override
  String get ownerAnalyticsBranchCompareEmptyTitle =>
      'No branch data to compare';

  @override
  String get ownerAnalyticsBranchCompareEmptyDescription =>
      'Branch comparison will appear here once you have access to another branch in the same chain.';

  @override
  String ownerAnalyticsBranchCompareMetrics(
    Object menuOpens,
    Object qrScans,
    Object menuViews,
  ) {
    return '$menuOpens menu opens • $qrScans QR scans • $menuViews menu views';
  }

  @override
  String get ownerDashboardAnalyticsTitle => 'Real-value analytics';

  @override
  String get ownerDashboardAnalyticsDescription =>
      'See QR, menu-open, and conversion signals at a glance, then jump into the full analytics screen.';

  @override
  String get ownerDashboardOpenAnalyticsAction => 'Open analytics';

  @override
  String get ownerDashboardAnalyticsLoadErrorTitle =>
      'Analytics summary could not be loaded';

  @override
  String get ownerDashboardAnalyticsSelectBusiness =>
      'Select a business first to view the analytics summary.';

  @override
  String get ownerDashboardAnalyticsNotFound =>
      'There is no analytics summary to show for this business yet.';

  @override
  String get ownerDashboardAnalyticsOutboundClicks => 'Outbound clicks';

  @override
  String get ownerDashboardAnalyticsConversions => 'Conversions';

  @override
  String get ownerGrowthTitle => 'Growth hub';

  @override
  String get ownerGrowthDescription =>
      'Demand, visibility, conversion, and sponsored visibility requests are collected on this screen.';

  @override
  String get ownerGrowthSignalsTitle => 'Growth signals';

  @override
  String get ownerGrowthSignalsDescription =>
      'Interest loss, price position, and outbound behavior are summarized for the last 30 days.';

  @override
  String get ownerGrowthCatalogTitle => 'Sponsorship catalog';

  @override
  String get ownerGrowthCatalogDescription =>
      'See active packages, open slot pressure, and the reach from your recent campaigns.';

  @override
  String get ownerGrowthCatalogLoadErrorTitle =>
      'Sponsorship catalog could not be loaded';

  @override
  String get ownerGrowthCatalogEmpty =>
      'No active sponsorship package is available yet.';

  @override
  String get ownerGrowthCatalogDurationLabel => 'Duration';

  @override
  String get ownerGrowthCatalogInventoryLabel => 'Open slots';

  @override
  String get ownerGrowthCatalogLiveUnitsLabel => 'Live units';

  @override
  String get ownerGrowthCatalogReachLabel => 'Last 30d reach';

  @override
  String ownerGrowthCatalogInventoryValue(Object open, Object total) {
    return '$open open / limit $total';
  }

  @override
  String ownerGrowthCatalogLiveUnitsValue(
    Object surfaceLive,
    Object businessLive,
  ) {
    return 'Surface $surfaceLive • yours $businessLive';
  }

  @override
  String ownerGrowthCatalogReachValue(Object impressions, Object users) {
    return '$impressions impressions • $users users';
  }

  @override
  String ownerGrowthCatalogLeadStatus(Object status) {
    return 'Latest lead status: $status';
  }

  @override
  String get ownerGrowthCatalogLeadStatusNone => 'No request yet';

  @override
  String get ownerGrowthConversionRateLabel => 'Conversion rate';

  @override
  String get ownerGrowthDistrictGapLabel => 'District price gap';

  @override
  String get ownerShellTrashLabel => 'Trash';

  @override
  String get ownerTrashTitle => 'Trash';

  @override
  String get ownerTrashDescription =>
      'Manage archived menus, deleted item photos, and other recoverable records from a single place.';

  @override
  String get ownerTrashMissingBusinessTitle => 'Select a business first';

  @override
  String get ownerTrashMissingBusinessDescription =>
      'The trash view requires an active business context.';

  @override
  String get ownerTrashFilterAll => 'All';

  @override
  String get ownerTrashFilterMenus => 'Menus';

  @override
  String get ownerTrashFilterItems => 'Items';

  @override
  String get ownerTrashFilterPhotos => 'Photos';

  @override
  String get ownerTrashLoadErrorTitle => 'Trash could not be loaded';

  @override
  String get ownerTrashEmptyTitle => 'Trash is empty';

  @override
  String get ownerTrashEmptyDescription =>
      'There are no recoverable deleted records for this business.';

  @override
  String get ownerTrashEntityMenu => 'menu';

  @override
  String get ownerTrashEntityItem => 'item';

  @override
  String get ownerTrashEntityPhoto => 'photo';

  @override
  String ownerTrashOccurredAt(Object value) {
    return 'Moved to trash: $value';
  }

  @override
  String get ownerTrashRestoreAction => 'Restore';

  @override
  String get ownerTrashDeleteForeverAction => 'Delete forever';

  @override
  String ownerTrashRestoreConfirm(Object entity) {
    return 'This $entity will be restored.';
  }

  @override
  String ownerTrashDeleteForeverConfirm(Object entity) {
    return 'This $entity will be permanently deleted. This action cannot be undone.';
  }

  @override
  String get ownerTrashRestoreSuccess => 'Record restored.';

  @override
  String get ownerTrashDeleteForeverSuccess => 'Record permanently deleted.';

  @override
  String get ownerTrashSearchLabel => 'Search trash';

  @override
  String get ownerTrashSortLabel => 'Sort';

  @override
  String get ownerTrashSortNewest => 'Newest first';

  @override
  String get ownerTrashSortOldest => 'Oldest first';

  @override
  String get ownerTrashSortTitle => 'By title';

  @override
  String get ownerTrashSortType => 'By type';

  @override
  String get ownerMenuVersionsAction => 'Versions';

  @override
  String get ownerMenuVersionsTitle => 'Published snapshots';

  @override
  String get ownerMenuVersionsDescription =>
      'Review published snapshots and safely roll back to a previous version when needed.';

  @override
  String get ownerMenuVersionsLoadErrorTitle => 'Versions could not be loaded';

  @override
  String get ownerMenuVersionsEmptyTitle => 'No snapshots yet';

  @override
  String get ownerMenuVersionsEmptyDescription =>
      'Version history will appear here after this menu is published for the first time.';

  @override
  String ownerMenuVersionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String ownerMenuVersionSummary(Object reason, Object createdAt) {
    return '$reason • $createdAt';
  }

  @override
  String ownerMenuVersionCounts(Object sectionCount, Object itemCount) {
    return '$sectionCount sections • $itemCount items';
  }

  @override
  String get ownerMenuVersionReasonPublish => 'Publish';

  @override
  String get ownerMenuVersionReasonRestore => 'Restore';

  @override
  String get ownerMenuVersionRestoreAction => 'Restore this version';

  @override
  String get ownerMenuVersionDiffAction => 'View diff';

  @override
  String ownerMenuVersionRestoreConfirm(Object version) {
    return 'A new published menu will be created from version $version. The current menu will be archived.';
  }

  @override
  String get ownerMenuVersionRestoreSuccess =>
      'Restored version is ready. Returning to the menu list.';

  @override
  String ownerMenuVersionDiffTitle(Object version) {
    return 'Version $version diff summary';
  }

  @override
  String get ownerMenuVersionDiffDescription =>
      'Review the differences between the selected snapshot and the current live menu.';

  @override
  String get ownerMenuVersionDiffLoadErrorTitle =>
      'Version diff could not be loaded';

  @override
  String get ownerMenuVersionDiffMenuMetaTitle => 'Summary changes';

  @override
  String ownerMenuVersionDiffMenuTitleLine(Object current, Object snapshot) {
    return 'Menu title: current \"$current\" • snapshot \"$snapshot\"';
  }

  @override
  String ownerMenuVersionDiffMenuKindLine(Object current, Object snapshot) {
    return 'Menu kind: current \"$current\" • snapshot \"$snapshot\"';
  }

  @override
  String ownerMenuVersionDiffCountLine(
    Object label,
    Object currentCount,
    Object snapshotCount,
  ) {
    return '$label: current $currentCount • snapshot $snapshotCount';
  }

  @override
  String get ownerMenuVersionDiffEmptyValue => 'Not set';

  @override
  String get ownerMenuVersionDiffNoChangesTitle => 'No meaningful difference';

  @override
  String get ownerMenuVersionDiffNoChangesDescription =>
      'This snapshot appears to match the current menu structure.';

  @override
  String get ownerMenuVersionDiffSectionsAddedTitle =>
      'Sections in the snapshot but not in the current menu';

  @override
  String get ownerMenuVersionDiffSectionsRemovedTitle =>
      'Sections in the current menu but not in the snapshot';

  @override
  String get ownerMenuVersionDiffItemsAddedTitle =>
      'Items in the snapshot but not in the current menu';

  @override
  String get ownerMenuVersionDiffItemsRemovedTitle =>
      'Items in the current menu but not in the snapshot';

  @override
  String get ownerMenuVersionDiffEmptyList => 'No changes';

  @override
  String ownerMenuVersionDiffMoreItems(Object count) {
    return '+$count more records';
  }

  @override
  String get adminShellTrashLabel => 'Restore center';

  @override
  String get adminShellTrashDescription =>
      'Restore deleted menus, items, and photos per business.';

  @override
  String get adminBusinessesTrashAction => 'Trash';

  @override
  String get adminMenuRestoreTitle => 'Menu restore center';

  @override
  String get adminMenuRestoreDescription =>
      'Pick a business, then restore or permanently delete menus, items, and photos from its trash.';

  @override
  String get adminMenuRestoreBusinessSearchLabel =>
      'Search business or enter ID';

  @override
  String get adminMenuRestoreSearchEmptyTitle => 'Business search is waiting';

  @override
  String get adminMenuRestoreSearchEmptyDescription =>
      'Search with at least 2 characters to open the restore workspace.';

  @override
  String get adminMenuRestoreNoBusinessTitle => 'No business found';

  @override
  String get adminMenuRestoreNoBusinessDescription =>
      'No matching business was found. Check the business name, phone number, or business ID.';

  @override
  String get adminMenuRestoreSelectBusinessAction => 'Select';

  @override
  String get adminMenuRestoreSelectBusinessTitle => 'Select a business first';

  @override
  String get adminMenuRestoreSelectBusinessDescription =>
      'Choose a business from the search results to use the restore panel below.';

  @override
  String get adminMenuRestorePanelTitle => 'Deleted records';

  @override
  String get adminMenuRestorePanelDescription =>
      'Manage the selected business trash with admin privileges.';

  @override
  String get ownerDeletePhotoToTrashConfirm =>
      'This photo will be moved to trash. You can restore it later if needed.';

  @override
  String get ownerPhotoMovedToTrash => 'Photo moved to trash.';
}
