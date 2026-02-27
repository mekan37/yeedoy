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
}
