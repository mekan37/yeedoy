import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('tr'),
    Locale('en'),
  ];

  /// Auto metadata for appName
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy'**
  String get appName;

  /// Auto metadata for appTagline
  ///
  /// In tr, this message translates to:
  /// **'CanlÃ„Â± menÃƒÂ¼ler, doÃ„Å¸rulanmÃ„Â±Ã…Å¸ fiyatlar'**
  String get appTagline;

  /// Auto metadata for appTaglineLine1
  ///
  /// In tr, this message translates to:
  /// **'CanlÃ„Â± menÃƒÂ¼ler'**
  String get appTaglineLine1;

  /// Auto metadata for appTaglineLine2
  ///
  /// In tr, this message translates to:
  /// **'Dogrulanmis fiyatlar'**
  String get appTaglineLine2;

  /// Auto metadata for emptyTitle
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÂ¼z eklenmemis'**
  String get emptyTitle;

  /// Auto metadata for emptyRegionDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy\'da bu bÃƒÂ¶lgede henÃƒÂ¼z veri yok. Ã„Â°stersen ilk katkÃ„Â±yÃ„Â± sen ekle.'**
  String get emptyRegionDescription;

  /// Auto metadata for webDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy - CanlÃ„Â± menÃƒÂ¼ler, doÃ„Å¸rulanmÃ„Â±Ã…Å¸ fiyatlar ve akÃ„Â±llÃ„Â± keÃ…Å¸if.'**
  String get webDescription;

  /// Auto metadata for discover
  ///
  /// In tr, this message translates to:
  /// **'KeÃ…Å¸fet'**
  String get discover;

  /// Auto metadata for home
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// Auto metadata for map
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get map;

  /// Auto metadata for list
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get list;

  /// Auto metadata for favorites
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get favorites;

  /// Auto metadata for profile
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// Auto metadata for settings
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// Auto metadata for save
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// Auto metadata for cancel
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°ptal'**
  String get cancel;

  /// Auto metadata for privacy
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get privacy;

  /// Auto metadata for socialLinks
  ///
  /// In tr, this message translates to:
  /// **'Sosyal BaÃ„Å¸lantÃ„Â±lar'**
  String get socialLinks;

  /// Auto metadata for logout
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€¡Ã„Â±kÃ„Â±Ã…Å¸ Yap'**
  String get logout;

  /// Auto metadata for contribute
  ///
  /// In tr, this message translates to:
  /// **'KatkÃ„Â± Yap'**
  String get contribute;

  /// Auto metadata for uploadPhoto
  ///
  /// In tr, this message translates to:
  /// **'FotoÃ„Å¸raf YÃƒÂ¼kle'**
  String get uploadPhoto;

  /// Auto metadata for scanQr
  ///
  /// In tr, this message translates to:
  /// **'QR Tara'**
  String get scanQr;

  /// Auto metadata for verifyPrice
  ///
  /// In tr, this message translates to:
  /// **'FiyatÃ„Â± DoÃ„Å¸rula'**
  String get verifyPrice;

  /// Auto metadata for openInBrowser
  ///
  /// In tr, this message translates to:
  /// **'TarayÃ„Â±cÃ„Â±da AÃƒÂ§'**
  String get openInBrowser;

  /// Auto metadata for linkPreview
  ///
  /// In tr, this message translates to:
  /// **'BaÃ„Å¸lantÃ„Â± Ãƒâ€“nizleme'**
  String get linkPreview;

  /// Auto metadata for profileSettings
  ///
  /// In tr, this message translates to:
  /// **'Profil AyarlarÃ„Â±'**
  String get profileSettings;

  /// Auto metadata for saving
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get saving;

  /// Auto metadata for loginRequired
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nce giris yapmalisin.'**
  String get loginRequired;

  /// Auto metadata for profileSaved
  ///
  /// In tr, this message translates to:
  /// **'Profil ayarlarÃ„Â± kaydedildi.'**
  String get profileSaved;

  /// No description provided for @saveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme hatasi: {error}'**
  String saveError(String error);

  /// Auto metadata for namePrivacy
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°sim GizliliÃ„Å¸i'**
  String get namePrivacy;

  /// Auto metadata for firstName
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get firstName;

  /// Auto metadata for lastName
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get lastName;

  /// Auto metadata for showFullName
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad GÃƒÂ¶rÃƒÂ¼nsÃƒÂ¼n'**
  String get showFullName;

  /// Auto metadata for hideLastName
  ///
  /// In tr, this message translates to:
  /// **'Sadece SoyadÃ„Â± Gizle'**
  String get hideLastName;

  /// Auto metadata for hideBothNames
  ///
  /// In tr, this message translates to:
  /// **'Ad ve SoyadÃ„Â± Gizle'**
  String get hideBothNames;

  /// Auto metadata for preview
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nizleme'**
  String get preview;

  /// Auto metadata for socialMedia
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Medya'**
  String get socialMedia;

  /// Auto metadata for language
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// Auto metadata for systemDefault
  ///
  /// In tr, this message translates to:
  /// **'Sistem (VarsayÃ„Â±lan)'**
  String get systemDefault;

  /// Auto metadata for turkish
  ///
  /// In tr, this message translates to:
  /// **'TÃƒÂ¼rkÃƒÂ§e'**
  String get turkish;

  /// Auto metadata for english
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°ngilizce'**
  String get english;

  /// Auto metadata for account
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get account;

  /// Auto metadata for invalidLink
  ///
  /// In tr, this message translates to:
  /// **'GeÃƒÂ§erli bir baÃ„Å¸lantÃ„Â± gir.'**
  String get invalidLink;

  /// Auto metadata for socialPreview
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Ãƒâ€“nizleme'**
  String get socialPreview;

  /// Auto metadata for pasteLinkHelper
  ///
  /// In tr, this message translates to:
  /// **'BaÃ„Å¸lantÃ„Â± yapÃ„Â±Ã…Å¸tÃ„Â±r (https://...)'**
  String get pasteLinkHelper;

  /// Auto metadata for privacySocialSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°sim gizliliÃ„Å¸i ve sosyal medya baÃ„Å¸lantÃ„Â±larÃ„Â±'**
  String get privacySocialSubtitle;

  /// No description provided for @updateBusinessTitle.
  ///
  /// In tr, this message translates to:
  /// **'{businessName} gÃƒÂ¼ncelle'**
  String updateBusinessTitle(String businessName);

  /// Auto metadata for contributeSheetSubtitle
  ///
  /// In tr, this message translates to:
  /// **'TopluluÃ„Å¸un menÃƒÂ¼ fiyatlarÃ„Â±nÃ„Â± doÃ„Å¸rulamasÃ„Â±na yardÃ„Â±mcÃ„Â± ol.'**
  String get contributeSheetSubtitle;

  /// Auto metadata for scanMenuQr
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ QR tara'**
  String get scanMenuQr;

  /// Auto metadata for scanMenuQrSubtitle
  ///
  /// In tr, this message translates to:
  /// **'QR ile anÃ„Â±nda doÃ„Å¸rulama'**
  String get scanMenuQrSubtitle;

  /// Auto metadata for uploadPhotoSubtitle
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼nÃƒÂ¼n fotoÃ„Å¸rafÃ„Â±nÃ„Â± ÃƒÂ§ek'**
  String get uploadPhotoSubtitle;

  /// Auto metadata for confirmPriceChange
  ///
  /// In tr, this message translates to:
  /// **'Fiyat deÃ„Å¸iÃ…Å¸imini doÃ„Å¸rula'**
  String get confirmPriceChange;

  /// Auto metadata for confirmPriceChangeSubtitle
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ncel olmayan bir fiyatÃ„Â± bildir'**
  String get confirmPriceChangeSubtitle;

  /// Auto metadata for qrAction
  ///
  /// In tr, this message translates to:
  /// **'QR Aksiyonu'**
  String get qrAction;

  /// Auto metadata for embed
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶mÃƒÂ¼lÃƒÂ¼'**
  String get embed;

  /// Auto metadata for share
  ///
  /// In tr, this message translates to:
  /// **'PaylaÃ…Å¸'**
  String get share;

  /// Auto metadata for invalidLinkMessage
  ///
  /// In tr, this message translates to:
  /// **'GeÃƒÂ§ersiz baÃ„Å¸lantÃ„Â±'**
  String get invalidLinkMessage;

  /// Auto metadata for browserOpened
  ///
  /// In tr, this message translates to:
  /// **'TarayÃ„Â±cÃ„Â±da aÃƒÂ§Ã„Â±ldÃ„Â±'**
  String get browserOpened;

  /// Auto metadata for embedFailed
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°ÃƒÂ§erik gÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼lenemedi, tarayÃ„Â±cÃ„Â±ya yÃƒÂ¶nlendirdik.'**
  String get embedFailed;

  /// Auto metadata for back
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @updatedDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gÃƒÂ¼n ÃƒÂ¶nce gÃƒÂ¼ncellendi'**
  String updatedDaysAgo(int days);

  /// No description provided for @verifiedDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gÃƒÂ¼n ÃƒÂ¶nce doÃ„Å¸rulandÃ„Â±'**
  String verifiedDaysAgo(int days);

  /// No description provided for @distanceKm.
  ///
  /// In tr, this message translates to:
  /// **'{km} km'**
  String distanceKm(num km);

  /// No description provided for @avgSpendPerPerson.
  ///
  /// In tr, this message translates to:
  /// **'KiÃ…Å¸i baÃ…Å¸Ã„Â± {amount}'**
  String avgSpendPerPerson(String amount);

  /// No description provided for @reviewsCount.
  ///
  /// In tr, this message translates to:
  /// **'Yorum ({count})'**
  String reviewsCount(int count);

  /// Auto metadata for openNow
  ///
  /// In tr, this message translates to:
  /// **'Ã…Âuan aÃƒÂ§Ã„Â±k'**
  String get openNow;

  /// Auto metadata for closedNow
  ///
  /// In tr, this message translates to:
  /// **'Ã…Âuan kapalÃ„Â±'**
  String get closedNow;

  /// Auto metadata for livePrices
  ///
  /// In tr, this message translates to:
  /// **'CanlÃ„Â± Fiyatlar'**
  String get livePrices;

  /// Auto metadata for trustScore
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ven Skoru'**
  String get trustScore;

  /// Auto metadata for lastUpdated
  ///
  /// In tr, this message translates to:
  /// **'Son GÃƒÂ¼ncelleme'**
  String get lastUpdated;

  /// Auto metadata for lastAudit
  ///
  /// In tr, this message translates to:
  /// **'Son Denetim'**
  String get lastAudit;

  /// Auto metadata for avgCost
  ///
  /// In tr, this message translates to:
  /// **'Ortalama Tutar'**
  String get avgCost;

  /// Auto metadata for avgSpend
  ///
  /// In tr, this message translates to:
  /// **'ORT. HARCAMA'**
  String get avgSpend;

  /// Auto metadata for verified
  ///
  /// In tr, this message translates to:
  /// **'DoÃ„Å¸rulandÃ„Â±'**
  String get verified;

  /// Auto metadata for priceVerified
  ///
  /// In tr, this message translates to:
  /// **'Fiyat DoÃ„Å¸rulandÃ„Â±'**
  String get priceVerified;

  /// Auto metadata for communityVerified
  ///
  /// In tr, this message translates to:
  /// **'ToplulukÃƒÂ§a DoÃ„Å¸rulandÃ„Â±'**
  String get communityVerified;

  /// No description provided for @confirmedByUsersToday.
  ///
  /// In tr, this message translates to:
  /// **'BugÃƒÂ¼n {users} kullanÃ„Â±cÃ„Â± tarafÃ„Â±ndan doÃ„Å¸rulandÃ„Â±'**
  String confirmedByUsersToday(int users);

  /// Auto metadata for priceHistory
  ///
  /// In tr, this message translates to:
  /// **'Fiyat GeÃƒÂ§miÃ…Å¸i'**
  String get priceHistory;

  /// Auto metadata for contributeMenuPhoto
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ FotoÃ„Å¸rafÃ„Â± KatkÃ„Â±sÃ„Â± Yap'**
  String get contributeMenuPhoto;

  /// Fiyat doÄŸrulama aksiyon butonu metni.
  ///
  /// In tr, this message translates to:
  /// **'DOÃ„ÂRULA'**
  String get verify;

  /// Auto metadata for signatureSteaks
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“ne Ãƒâ€¡Ã„Â±kan Steakler'**
  String get signatureSteaks;

  /// No description provided for @signatureSection.
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“ne Ãƒâ€¡Ã„Â±kan {section}'**
  String signatureSection(String section);

  /// Auto metadata for spottedPriceChange
  ///
  /// In tr, this message translates to:
  /// **'Fiyat deÃ„Å¸iÃ…Å¸ikliÃ„Å¸i mi fark ettin?'**
  String get spottedPriceChange;

  /// Auto metadata for spottedPriceChangeSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Bu menÃƒÂ¼yÃƒÂ¼ gÃƒÂ¼ncelleyerek katkÃ„Â± saÃ„Å¸la.'**
  String get spottedPriceChangeSubtitle;

  /// Auto metadata for updateDateUnavailable
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ncelleme tarihi yok'**
  String get updateDateUnavailable;

  /// Auto metadata for currentLocation
  ///
  /// In tr, this message translates to:
  /// **'MEVCUT KONUM'**
  String get currentLocation;

  /// Auto metadata for changeLocation
  ///
  /// In tr, this message translates to:
  /// **'Konumu DeÃ„Å¸iÃ…Å¸tir'**
  String get changeLocation;

  /// Auto metadata for filters
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get filters;

  /// Auto metadata for searchKebabsHint
  ///
  /// In tr, this message translates to:
  /// **'Kebap, burger ara...'**
  String get searchKebabsHint;

  /// Auto metadata for budget
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¼tÃƒÂ§e'**
  String get budget;

  /// Auto metadata for freshMenuUpdates
  ///
  /// In tr, this message translates to:
  /// **'Taze MenÃƒÂ¼ GÃƒÂ¼ncellemeleri'**
  String get freshMenuUpdates;

  /// Auto metadata for seeAll
  ///
  /// In tr, this message translates to:
  /// **'TÃƒÂ¼mÃƒÂ¼nÃƒÂ¼ GÃƒÂ¶r'**
  String get seeAll;

  /// Auto metadata for freshLinks
  ///
  /// In tr, this message translates to:
  /// **'Yeni BaÃ„Å¸lantÃ„Â±lar'**
  String get freshLinks;

  /// Auto metadata for discoveryNearbyTitle
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±nÃ„Â±mda'**
  String get discoveryNearbyTitle;

  /// Auto metadata for discoveryNearbySubtitle
  ///
  /// In tr, this message translates to:
  /// **'Konumuna gÃƒÂ¶re en iyi sonuÃƒÂ§lar'**
  String get discoveryNearbySubtitle;

  /// Auto metadata for discoveryLocationSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Ã…Âehir/ilÃƒÂ§eye gÃƒÂ¶re keÃ…Å¸fet'**
  String get discoveryLocationSubtitle;

  /// Auto metadata for nearbyVerifiedSpots
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±ndaki DoÃ„Å¸rulanmÃ„Â±Ã…Å¸ Mekanlar'**
  String get nearbyVerifiedSpots;

  /// Auto metadata for noNearbyVerifiedSpots
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±nda doÃ„Å¸rulanmÃ„Â±Ã…Å¸ mekan bulunamadÃ„Â±'**
  String get noNearbyVerifiedSpots;

  /// Auto metadata for changeFiltersTryAgain
  ///
  /// In tr, this message translates to:
  /// **'Konumu veya filtreleri deÃ„Å¸iÃ…Å¸tirip tekrar dene.'**
  String get changeFiltersTryAgain;

  /// Auto metadata for noFreshData
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÂ¼z taze veri yok'**
  String get noFreshData;

  /// Auto metadata for freshDataWillAppear
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±ndaki menÃƒÂ¼ gÃƒÂ¼ncellemeleri burada gÃƒÂ¶rÃƒÂ¼necek.'**
  String get freshDataWillAppear;

  /// Auto metadata for businessLabel
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã…Å¸letme'**
  String get businessLabel;

  /// Auto metadata for report
  ///
  /// In tr, this message translates to:
  /// **'Bildir'**
  String get report;

  /// Auto metadata for favoriteAdded
  ///
  /// In tr, this message translates to:
  /// **'Favorilerde'**
  String get favoriteAdded;

  /// Auto metadata for addToFavorites
  ///
  /// In tr, this message translates to:
  /// **'Favoriye ekle'**
  String get addToFavorites;

  /// Auto metadata for writeReview
  ///
  /// In tr, this message translates to:
  /// **'Yorum yap'**
  String get writeReview;

  /// Auto metadata for other
  ///
  /// In tr, this message translates to:
  /// **'DiÃ„Å¸er'**
  String get other;

  /// No description provided for @itemsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ÃƒÂ¼rÃƒÂ¼n'**
  String itemsCount(int count);

  /// Auto metadata for weakConnectionQueueNotice
  ///
  /// In tr, this message translates to:
  /// **'BaÃ„Å¸lantÃ„Â± zayÃ„Â±f. DoÃ„Å¸rulama sÃ„Â±raya alÃ„Â±ndÃ„Â±, ÃƒÂ§evrimiÃƒÂ§i olunca otomatik gÃƒÂ¶nderilecek.'**
  String get weakConnectionQueueNotice;

  /// No description provided for @pendingVerificationsSent.
  ///
  /// In tr, this message translates to:
  /// **'{count} bekleyen doÃ„Å¸rulama gÃƒÂ¶nderildi.'**
  String pendingVerificationsSent(int count);

  /// Auto metadata for loadMenuItemsFirst
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nce menÃƒÂ¼ ÃƒÂ¼rÃƒÂ¼nlerini yÃƒÂ¼kle.'**
  String get loadMenuItemsFirst;

  /// Auto metadata for menuNotAddedYet
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÂ¼z eklenmedi'**
  String get menuNotAddedYet;

  /// Auto metadata for menuNotAddedYetDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu iÃ…Å¸letme iÃƒÂ§in henÃƒÂ¼z menÃƒÂ¼ eklenmemiÃ…Å¸.'**
  String get menuNotAddedYetDescription;

  /// Auto metadata for weakConnection
  ///
  /// In tr, this message translates to:
  /// **'BaÃ„Å¸lantÃ„Â± zayÃ„Â±f'**
  String get weakConnection;

  /// Auto metadata for contentLoadFailedCheckInternet
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°ÃƒÂ§erik Ã…Å¸u anda yÃƒÂ¼klenemedi. Varsa ÃƒÂ¶nbellek verisi gÃƒÂ¶sterilecek. Ã„Â°nterneti kontrol edip tekrar dene.'**
  String get contentLoadFailedCheckInternet;

  /// Auto metadata for trustDataUnavailable
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ven verisi yok'**
  String get trustDataUnavailable;

  /// Auto metadata for freshnessAndTrust
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ncellik ve gÃƒÂ¼ven'**
  String get freshnessAndTrust;

  /// Auto metadata for menuUpdatedLabel
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ GÃƒÂ¼ncellendi'**
  String get menuUpdatedLabel;

  /// Auto metadata for lastPriceVerification
  ///
  /// In tr, this message translates to:
  /// **'Son Fiyat DoÃ„Å¸rulamasÃ„Â±'**
  String get lastPriceVerification;

  /// Auto metadata for trustScoreLabel
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ven Skoru'**
  String get trustScoreLabel;

  /// Auto metadata for last3MonthsPriceChange
  ///
  /// In tr, this message translates to:
  /// **'Son 3 Ay Fiyat DeÃ„Å¸iÃ…Å¸imi'**
  String get last3MonthsPriceChange;

  /// Auto metadata for hoursInfoUnavailable
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€¡alÃ„Â±Ã…Å¸ma saatleri bilgisi yok'**
  String get hoursInfoUnavailable;

  /// Auto metadata for hoursInfoMissing
  ///
  /// In tr, this message translates to:
  /// **'Saat bilgisi yok'**
  String get hoursInfoMissing;

  /// Auto metadata for addHoursHelp
  ///
  /// In tr, this message translates to:
  /// **'KullanÃ„Â±cÃ„Â±lara yardÃ„Â±mcÃ„Â± olmak iÃƒÂ§in ÃƒÂ§alÃ„Â±Ã…Å¸ma saatlerini ekle.'**
  String get addHoursHelp;

  /// Auto metadata for reportHoursInfo
  ///
  /// In tr, this message translates to:
  /// **'Saat bilgisi bildir'**
  String get reportHoursInfo;

  /// Auto metadata for menus
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ler'**
  String get menus;

  /// Auto metadata for menusLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ler yÃƒÂ¼klenemedi'**
  String get menusLoadFailed;

  /// Auto metadata for noMenu
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ yok'**
  String get noMenu;

  /// Auto metadata for addFirstMenuHelp
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°lk menÃƒÂ¼yÃƒÂ¼ ekleyerek kullanÃ„Â±cÃ„Â±lara yardÃ„Â±mcÃ„Â± ol.'**
  String get addFirstMenuHelp;

  /// Auto metadata for crowdInfoUnavailable
  ///
  /// In tr, this message translates to:
  /// **'YoÃ„Å¸unluk bilgisi yok'**
  String get crowdInfoUnavailable;

  /// No description provided for @liveCrowdLabel.
  ///
  /// In tr, this message translates to:
  /// **'AnlÃ„Â±k yoÃ„Å¸unluk: {state}'**
  String liveCrowdLabel(String state);

  /// Auto metadata for reviewsLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar yÃƒÂ¼klenemedi'**
  String get reviewsLoadFailed;

  /// Auto metadata for noReviews
  ///
  /// In tr, this message translates to:
  /// **'Yorum yok'**
  String get noReviews;

  /// Auto metadata for leaveFirstReviewHelp
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°lk yorumu sen yaz.'**
  String get leaveFirstReviewHelp;

  /// Auto metadata for writeFirstReview
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°lk yorumu yaz'**
  String get writeFirstReview;

  /// Auto metadata for recentReviews
  ///
  /// In tr, this message translates to:
  /// **'Son yorumlar'**
  String get recentReviews;

  /// Auto metadata for reviewFallbackTitle
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get reviewFallbackTitle;

  /// Auto metadata for activeCampaigns
  ///
  /// In tr, this message translates to:
  /// **'Aktif kampanyalar'**
  String get activeCampaigns;

  /// Auto metadata for menuDataUnavailable
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ verisi yok'**
  String get menuDataUnavailable;

  /// Auto metadata for noMenuProductsYet
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÂ¼z menÃƒÂ¼ ÃƒÂ¼rÃƒÂ¼nÃƒÂ¼ yok'**
  String get noMenuProductsYet;

  /// Auto metadata for menu
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼'**
  String get menu;

  /// No description provided for @featuredFromCuisine.
  ///
  /// In tr, this message translates to:
  /// **'{cuisine} mutfaÃ„Å¸Ã„Â±ndan ÃƒÂ¶ne ÃƒÂ§Ã„Â±kanlar'**
  String featuredFromCuisine(String cuisine);

  /// Auto metadata for weeklyPriceChange
  ///
  /// In tr, this message translates to:
  /// **'+Ã¢â€šÂº50 bu hafta'**
  String get weeklyPriceChange;

  /// Auto metadata for chartPlaceholderSoon
  ///
  /// In tr, this message translates to:
  /// **'Grafik alanÃ„Â± (yakÃ„Â±nda)'**
  String get chartPlaceholderSoon;

  /// Auto metadata for featuredCuisineSuffix
  ///
  /// In tr, this message translates to:
  /// **'mutfaÃ„Å¸Ã„Â±ndan ÃƒÂ¶ne ÃƒÂ§Ã„Â±kan lezzetler'**
  String get featuredCuisineSuffix;

  /// Auto metadata for connectionProblemTryAgain
  ///
  /// In tr, this message translates to:
  /// **'BaÃ„Å¸lantÃ„Â± sorunu var, tekrar dene.'**
  String get connectionProblemTryAgain;

  /// Auto metadata for noActiveCampaign
  ///
  /// In tr, this message translates to:
  /// **'Aktif kampanya yok'**
  String get noActiveCampaign;

  /// Auto metadata for activeCampaignCountLabel
  ///
  /// In tr, this message translates to:
  /// **'aktif kampanya'**
  String get activeCampaignCountLabel;

  /// Auto metadata for noAmenityInfo
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°mkan bilgisi yok'**
  String get noAmenityInfo;

  /// No description provided for @amenityCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'{count} imkan'**
  String amenityCountLabel(int count);

  /// Auto metadata for noLocationVerificationData
  ///
  /// In tr, this message translates to:
  /// **'Konum doÃ„Å¸rulama verisi yok'**
  String get noLocationVerificationData;

  /// Auto metadata for lastLocationVerification
  ///
  /// In tr, this message translates to:
  /// **'Son konum doÃ„Å¸rulamasÃ„Â±'**
  String get lastLocationVerification;

  /// Auto metadata for noNewProductRecord
  ///
  /// In tr, this message translates to:
  /// **'Yeni ÃƒÂ¼rÃƒÂ¼n kaydÃ„Â± yok'**
  String get noNewProductRecord;

  /// Auto metadata for newProduct
  ///
  /// In tr, this message translates to:
  /// **'Yeni ÃƒÂ¼rÃƒÂ¼n'**
  String get newProduct;

  /// Auto metadata for reportInfoErrorPrefix
  ///
  /// In tr, this message translates to:
  /// **'Bildirim bilgisi hatasÃ„Â±:'**
  String get reportInfoErrorPrefix;

  /// Auto metadata for noLocation
  ///
  /// In tr, this message translates to:
  /// **'Konum yok'**
  String get noLocation;

  /// Auto metadata for noHoursInfo
  ///
  /// In tr, this message translates to:
  /// **'Saat bilgisi yok'**
  String get noHoursInfo;

  /// Auto metadata for reviewsCountSuffix
  ///
  /// In tr, this message translates to:
  /// **'yorum'**
  String get reviewsCountSuffix;

  /// Auto metadata for noTime
  ///
  /// In tr, this message translates to:
  /// **'Saat yok'**
  String get noTime;

  /// Auto metadata for tabSteaks
  ///
  /// In tr, this message translates to:
  /// **'Etler'**
  String get tabSteaks;

  /// Auto metadata for tabBurgers
  ///
  /// In tr, this message translates to:
  /// **'Burgerler'**
  String get tabBurgers;

  /// Auto metadata for tabSides
  ///
  /// In tr, this message translates to:
  /// **'Yan ÃƒÅ“rÃƒÂ¼nler'**
  String get tabSides;

  /// Auto metadata for tabBeverages
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°ÃƒÂ§ecekler'**
  String get tabBeverages;

  /// Auto metadata for locationNotAvailable
  ///
  /// In tr, this message translates to:
  /// **'Konum kullanÃ„Â±lamÃ„Â±yor'**
  String get locationNotAvailable;

  /// Auto metadata for sortRecommended
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nerilen'**
  String get sortRecommended;

  /// Auto metadata for sortDistance
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get sortDistance;

  /// Auto metadata for sortRating
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get sortRating;

  /// Auto metadata for sortPriceLow
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get sortPriceLow;

  /// Auto metadata for sortNewlyVerified
  ///
  /// In tr, this message translates to:
  /// **'Yeni DoÃ„Å¸rulanan'**
  String get sortNewlyVerified;

  /// Auto metadata for rankingFormulaTitle
  ///
  /// In tr, this message translates to:
  /// **'SÃ„Â±ralama FormÃƒÂ¼lÃƒÂ¼'**
  String get rankingFormulaTitle;

  /// Auto metadata for rankingFormulaIntro
  ///
  /// In tr, this message translates to:
  /// **'SÃ„Â±ralama puanÃ„Â± Ã…Å¸u bileÃ…Å¸enlerden oluÃ…Å¸ur:'**
  String get rankingFormulaIntro;

  /// Auto metadata for rankingWeightDistance
  ///
  /// In tr, this message translates to:
  /// **'%30 Mesafe'**
  String get rankingWeightDistance;

  /// Auto metadata for rankingWeightAccuracy
  ///
  /// In tr, this message translates to:
  /// **'DoÃ„Å¸ruluk aÃ„Å¸Ã„Â±rlÃ„Â±Ã„Å¸Ã„Â±'**
  String get rankingWeightAccuracy;

  /// Auto metadata for rankingWeightEngagement
  ///
  /// In tr, this message translates to:
  /// **'EtkileÃ…Å¸im aÃ„Å¸Ã„Â±rlÃ„Â±Ã„Å¸Ã„Â±'**
  String get rankingWeightEngagement;

  /// Auto metadata for rankingWeightQuality
  ///
  /// In tr, this message translates to:
  /// **'%20 Kalite (kalite skoru)'**
  String get rankingWeightQuality;

  /// Auto metadata for rankingFormulaNote
  ///
  /// In tr, this message translates to:
  /// **'Not: Puanlar dÃƒÂ¼zenli olarak gÃƒÂ¼ncellenir.'**
  String get rankingFormulaNote;

  /// No description provided for @minRatingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Minimum puan: {value}'**
  String minRatingLabel(String value);

  /// Auto metadata for priceLevel
  ///
  /// In tr, this message translates to:
  /// **'Fiyat seviyesi'**
  String get priceLevel;

  /// Auto metadata for prioritizeOpenNow
  ///
  /// In tr, this message translates to:
  /// **'Ã…Âu an aÃƒÂ§Ã„Â±k olanlarÃ„Â± ÃƒÂ¶ne ÃƒÂ§Ã„Â±kar'**
  String get prioritizeOpenNow;

  /// Auto metadata for prioritizeNewlyVerified
  ///
  /// In tr, this message translates to:
  /// **'Yeni doÃ„Å¸rulananlarÃ„Â± ÃƒÂ¶ne ÃƒÂ§Ã„Â±kar'**
  String get prioritizeNewlyVerified;

  /// Auto metadata for reset
  ///
  /// In tr, this message translates to:
  /// **'SÃ„Â±fÃ„Â±rla'**
  String get reset;

  /// Auto metadata for apply
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// Auto metadata for priceTierAny
  ///
  /// In tr, this message translates to:
  /// **'Her seviye'**
  String get priceTierAny;

  /// Auto metadata for priceTierBudget
  ///
  /// In tr, this message translates to:
  /// **'Ekonomik'**
  String get priceTierBudget;

  /// Auto metadata for priceTierMedium
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get priceTierMedium;

  /// Auto metadata for priceTierPremium
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÅ“st Seviye'**
  String get priceTierPremium;

  /// Auto metadata for tabAllItems
  ///
  /// In tr, this message translates to:
  /// **'TÃƒÂ¼m ÃƒÅ“rÃƒÂ¼nler'**
  String get tabAllItems;

  /// Auto metadata for tabStarters
  ///
  /// In tr, this message translates to:
  /// **'BaÃ…Å¸langÃ„Â±ÃƒÂ§lar'**
  String get tabStarters;

  /// Auto metadata for usersLabel
  ///
  /// In tr, this message translates to:
  /// **'kullanÃ„Â±cÃ„Â±'**
  String get usersLabel;

  /// Auto metadata for unknown
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknown;

  /// Auto metadata for today
  ///
  /// In tr, this message translates to:
  /// **'BugÃƒÂ¼n'**
  String get today;

  /// Auto metadata for dayUnit
  ///
  /// In tr, this message translates to:
  /// **'gÃƒÂ¼n'**
  String get dayUnit;

  /// Auto metadata for tekrarDene
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get tekrarDene;

  /// Auto metadata for vazgec
  ///
  /// In tr, this message translates to:
  /// **'VazgeÃƒÂ§'**
  String get vazgec;

  /// Auto metadata for reddet
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get reddet;

  /// Auto metadata for title
  ///
  /// In tr, this message translates to:
  /// **'title'**
  String get title;

  /// Auto metadata for isleniyor
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã…Å¸leniyor...'**
  String get isleniyor;

  /// Auto metadata for onayla
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get onayla;

  /// Auto metadata for approved
  ///
  /// In tr, this message translates to:
  /// **'OnaylandÃ„Â±'**
  String get approved;

  /// Auto metadata for tumu
  ///
  /// In tr, this message translates to:
  /// **'TÃƒÂ¼mÃƒÂ¼'**
  String get tumu;

  /// Auto metadata for kayitBulunamadi
  ///
  /// In tr, this message translates to:
  /// **'KayÃ„Â±t bulunamadÃ„Â±.'**
  String get kayitBulunamadi;

  /// Auto metadata for temizle
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get temizle;

  /// Auto metadata for uygula
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get uygula;

  /// Auto metadata for pending
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get pending;

  /// Auto metadata for reddedildi
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get reddedildi;

  /// Auto metadata for satirSec
  ///
  /// In tr, this message translates to:
  /// **'SatÃ„Â±r seÃƒÂ§'**
  String get satirSec;

  /// Auto metadata for gonder
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶nder'**
  String get gonder;

  /// Auto metadata for rejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get rejected;

  /// Auto metadata for detay
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get detay;

  /// Auto metadata for duzenle
  ///
  /// In tr, this message translates to:
  /// **'DÃƒÂ¼zenle'**
  String get duzenle;

  /// Auto metadata for eminMisin
  ///
  /// In tr, this message translates to:
  /// **'Emin misin?'**
  String get eminMisin;

  /// Auto metadata for guncellendi
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ncellendi.'**
  String get guncellendi;

  /// Auto metadata for reddedildi_2
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi.'**
  String get reddedildi_2;

  /// Auto metadata for sla
  ///
  /// In tr, this message translates to:
  /// **'Geri DÃƒÂ¶nÃƒÂ¼Ã…Å¸ SÃƒÂ¼resi'**
  String get sla;

  /// Auto metadata for csvDisaAktar
  ///
  /// In tr, this message translates to:
  /// **'CSV DÃ„Â±Ã…Å¸a Aktar'**
  String get csvDisaAktar;

  /// Auto metadata for onaylandi
  ///
  /// In tr, this message translates to:
  /// **'OnaylandÃ„Â±'**
  String get onaylandi;

  /// Auto metadata for yenile
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get yenile;

  /// Auto metadata for atanan
  ///
  /// In tr, this message translates to:
  /// **'Atanan'**
  String get atanan;

  /// Auto metadata for beklemede
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get beklemede;

  /// Auto metadata for durum
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get durum;

  /// Auto metadata for tabRecommended
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nerilenler'**
  String get tabRecommended;

  /// Auto metadata for tabCampaigns
  ///
  /// In tr, this message translates to:
  /// **'Kampanyalar'**
  String get tabCampaigns;

  /// Auto metadata for tabFoods
  ///
  /// In tr, this message translates to:
  /// **'Yemekler'**
  String get tabFoods;

  /// Auto metadata for whyTop
  ///
  /// In tr, this message translates to:
  /// **'Neden ÃƒÂ¼stte?'**
  String get whyTop;

  /// Auto metadata for quickSuggestionTitle
  ///
  /// In tr, this message translates to:
  /// **'HÃ„Â±zlÃ„Â± Ãƒâ€“neri'**
  String get quickSuggestionTitle;

  /// Auto metadata for quickSuggestionSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Dakikalar iÃƒÂ§inde karar ver'**
  String get quickSuggestionSubtitle;

  /// Auto metadata for quickSuggestionPreset
  ///
  /// In tr, this message translates to:
  /// **'2 kiÃ…Å¸i / Ã¢â€šÂº600'**
  String get quickSuggestionPreset;

  /// Auto metadata for whatToEatTitle
  ///
  /// In tr, this message translates to:
  /// **'Ne yesek?'**
  String get whatToEatTitle;

  /// Auto metadata for whatToEatSubtitle
  ///
  /// In tr, this message translates to:
  /// **'HÃ„Â±zlÃ„Â± ÃƒÂ¶neriler'**
  String get whatToEatSubtitle;

  /// Auto metadata for nearbyShort
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±nda'**
  String get nearbyShort;

  /// Auto metadata for affordableShort
  ///
  /// In tr, this message translates to:
  /// **'Uygun fiyat'**
  String get affordableShort;

  /// Auto metadata for quickDecisionShort
  ///
  /// In tr, this message translates to:
  /// **'HÃ„Â±zlÃ„Â± Karar'**
  String get quickDecisionShort;

  /// Auto metadata for start
  ///
  /// In tr, this message translates to:
  /// **'BaÃ…Å¸la'**
  String get start;

  /// Auto metadata for friendGroupTitle
  ///
  /// In tr, this message translates to:
  /// **'ArkadaÃ…Å¸ Grubu'**
  String get friendGroupTitle;

  /// Auto metadata for friendGroupSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Birlikte karar verin'**
  String get friendGroupSubtitle;

  /// Auto metadata for openGroup
  ///
  /// In tr, this message translates to:
  /// **'Grubu AÃƒÂ§'**
  String get openGroup;

  /// Auto metadata for myGroups
  ///
  /// In tr, this message translates to:
  /// **'GruplarÃ„Â±m'**
  String get myGroups;

  /// Auto metadata for onTheRoadTitle
  ///
  /// In tr, this message translates to:
  /// **'YoldayÃ„Â±m'**
  String get onTheRoadTitle;

  /// Auto metadata for onTheRoadSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Rotandaki duraklar'**
  String get onTheRoadSubtitle;

  /// Auto metadata for heroesTitle
  ///
  /// In tr, this message translates to:
  /// **'Kahramanlar'**
  String get heroesTitle;

  /// Auto metadata for heroesSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“ne ÃƒÂ§Ã„Â±kan keÃ…Å¸ifler'**
  String get heroesSubtitle;

  /// Auto metadata for view
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼le'**
  String get view;

  /// Auto metadata for bestBusinessesThisWeek
  ///
  /// In tr, this message translates to:
  /// **'Bu HaftanÃ„Â±n En Ã„Â°yi Ã„Â°Ã…Å¸letmeleri'**
  String get bestBusinessesThisWeek;

  /// Auto metadata for bestBusinessesThisMonth
  ///
  /// In tr, this message translates to:
  /// **'Bu AyÃ„Â±n En Ã„Â°yi Ã„Â°Ã…Å¸letmeleri'**
  String get bestBusinessesThisMonth;

  /// Auto metadata for onTheRoad20km
  ///
  /// In tr, this message translates to:
  /// **'Yolda Ã¢â‚¬Â¢ 20 km'**
  String get onTheRoad20km;

  /// No description provided for @nearbyKm.
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±nda Ã¢â‚¬Â¢ {km} km'**
  String nearbyKm(int km);

  /// Auto metadata for liveResultsUpdating
  ///
  /// In tr, this message translates to:
  /// **'CanlÃ„Â± sonuÃƒÂ§lar gÃƒÂ¼ncelleniyor'**
  String get liveResultsUpdating;

  /// Auto metadata for businessApprovedData
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã…Å¸letme onaylÃ„Â± verisi'**
  String get businessApprovedData;

  /// Auto metadata for communityData
  ///
  /// In tr, this message translates to:
  /// **'Topluluk verisi'**
  String get communityData;

  /// Auto metadata for removeFromFavorites
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden ÃƒÂ§Ã„Â±kar'**
  String get removeFromFavorites;

  /// Auto metadata for locationPermissionTitle
  ///
  /// In tr, this message translates to:
  /// **'Konum izni ver'**
  String get locationPermissionTitle;

  /// Auto metadata for locationPermissionDescription
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±ndaki yerleri gÃƒÂ¶stermek iÃƒÂ§in konum izni gerekli.'**
  String get locationPermissionDescription;

  /// Auto metadata for allow
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°zin Ver'**
  String get allow;

  /// Auto metadata for selectLocation
  ///
  /// In tr, this message translates to:
  /// **'Konum SeÃƒÂ§'**
  String get selectLocation;

  /// Auto metadata for manualLocationHint
  ///
  /// In tr, this message translates to:
  /// **'Konumu manuel seÃƒÂ§ebilirsin.'**
  String get manualLocationHint;

  /// Auto metadata for noResultsYet
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÂ¼z sonuÃƒÂ§ yok'**
  String get noResultsYet;

  /// Auto metadata for lowDataInArea
  ///
  /// In tr, this message translates to:
  /// **'Bu bÃƒÂ¶lgede veri az'**
  String get lowDataInArea;

  /// Auto metadata for tryDifferentSearchOrFilter
  ///
  /// In tr, this message translates to:
  /// **'FarklÃ„Â± bir arama ya da filtre dene.'**
  String get tryDifferentSearchOrFilter;

  /// Auto metadata for beFirstContributorInArea
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¶lgede ilk katkÃ„Â±yÃ„Â± sen yap.'**
  String get beFirstContributorInArea;

  /// Auto metadata for topVerifiedMenus
  ///
  /// In tr, this message translates to:
  /// **'En Ãƒâ€¡ok DoÃ„Å¸rulanan MenÃƒÂ¼ler'**
  String get topVerifiedMenus;

  /// Auto metadata for mostTrustedMenusInCity
  ///
  /// In tr, this message translates to:
  /// **'Ã…Âehirde En GÃƒÂ¼venilen MenÃƒÂ¼ler'**
  String get mostTrustedMenusInCity;

  /// Auto metadata for seeList
  ///
  /// In tr, this message translates to:
  /// **'Listeyi GÃƒÂ¶r'**
  String get seeList;

  /// Auto metadata for localContributionCall
  ///
  /// In tr, this message translates to:
  /// **'Yerel katkÃ„Â± ÃƒÂ§aÃ„Å¸rÃ„Â±sÃ„Â±'**
  String get localContributionCall;

  /// Auto metadata for addFirstMenu
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°lk MenÃƒÂ¼yÃƒÂ¼ Ekle'**
  String get addFirstMenu;

  /// Auto metadata for suggestBusiness
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã…Å¸letme Ãƒâ€“ner'**
  String get suggestBusiness;

  /// Auto metadata for noSurpriseSuggestionNow
  ///
  /// In tr, this message translates to:
  /// **'Ã…Âu an sÃƒÂ¼rpriz ÃƒÂ¶neri yok'**
  String get noSurpriseSuggestionNow;

  /// Auto metadata for priceVerifiedInLast48h
  ///
  /// In tr, this message translates to:
  /// **'Bu fiyat son 48 saatte doÃ„Å¸rulandÃ„Â±'**
  String get priceVerifiedInLast48h;

  /// Auto metadata for menuMayBeOutdated
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ gÃƒÂ¼ncel olmayabilir'**
  String get menuMayBeOutdated;

  /// Auto metadata for verifiedByBusiness
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã…Å¸letme tarafÃ„Â±ndan doÃ„Å¸rulandÃ„Â±'**
  String get verifiedByBusiness;

  /// Auto metadata for updatedByCommunity
  ///
  /// In tr, this message translates to:
  /// **'Topluluk tarafÃ„Â±ndan gÃƒÂ¼ncellendi'**
  String get updatedByCommunity;

  /// Auto metadata for topRankedInDistrict
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°lÃƒÂ§ede ÃƒÂ¼st sÃ„Â±ralarda'**
  String get topRankedInDistrict;

  /// Auto metadata for surpriseDiscoveryTitle
  ///
  /// In tr, this message translates to:
  /// **'SÃƒÂ¼rpriz KeÃ…Å¸if'**
  String get surpriseDiscoveryTitle;

  /// Auto metadata for surpriseDiscoverySubtitle
  ///
  /// In tr, this message translates to:
  /// **'AlÃ„Â±Ã…Å¸kanlÃ„Â±Ã„Å¸Ã„Â±nÃ„Â±n dÃ„Â±Ã…Å¸Ã„Â±na ÃƒÂ§Ã„Â±k'**
  String get surpriseDiscoverySubtitle;

  /// Auto metadata for randomButGood
  ///
  /// In tr, this message translates to:
  /// **'Rastgele ama iyi'**
  String get randomButGood;

  /// Auto metadata for outsideYourUsual
  ///
  /// In tr, this message translates to:
  /// **'Rutin dÃ„Â±Ã…Å¸Ã„Â±'**
  String get outsideYourUsual;

  /// Auto metadata for pricePerformanceSurprise
  ///
  /// In tr, this message translates to:
  /// **'Fiyat/performans sÃƒÂ¼rprizi'**
  String get pricePerformanceSurprise;

  /// Auto metadata for nearbyCampaignsAndAnnouncements
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±ndaki kampanyalar ve duyurular'**
  String get nearbyCampaignsAndAnnouncements;

  /// Auto metadata for noNearbyCampaign
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±nda kampanya yok'**
  String get noNearbyCampaign;

  /// Auto metadata for noActiveAnnouncementInArea
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¶lgede aktif duyuru yok'**
  String get noActiveAnnouncementInArea;

  /// Auto metadata for remainingLabel
  ///
  /// In tr, this message translates to:
  /// **'Kalan'**
  String get remainingLabel;

  /// Auto metadata for campaign
  ///
  /// In tr, this message translates to:
  /// **'Kampanya'**
  String get campaign;

  /// Auto metadata for active
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// Auto metadata for noLocationDataForMap
  ///
  /// In tr, this message translates to:
  /// **'Harita iÃƒÂ§in konum verisi yok'**
  String get noLocationDataForMap;

  /// Auto metadata for mapDataMissingUseList
  ///
  /// In tr, this message translates to:
  /// **'Harita verisi eksik, liste gÃƒÂ¶rÃƒÂ¼nÃƒÂ¼mÃƒÂ¼nÃƒÂ¼ kullan.'**
  String get mapDataMissingUseList;

  /// Auto metadata for openMapView
  ///
  /// In tr, this message translates to:
  /// **'Harita GÃƒÂ¶rÃƒÂ¼nÃƒÂ¼mÃƒÂ¼nÃƒÂ¼ AÃƒÂ§'**
  String get openMapView;

  /// Auto metadata for mapHintTapPins
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã„Å¸nelere dokunarak detaylarÃ„Â± gÃƒÂ¶r.'**
  String get mapHintTapPins;

  /// Auto metadata for locationPermissionRequired
  ///
  /// In tr, this message translates to:
  /// **'Konum izni gerekli.'**
  String get locationPermissionRequired;

  /// Auto metadata for noFoodFoundForCriteria
  ///
  /// In tr, this message translates to:
  /// **'Bu kriterlere uygun yemek bulunamadÃ„Â±'**
  String get noFoodFoundForCriteria;

  /// Auto metadata for whatToEatDescription
  ///
  /// In tr, this message translates to:
  /// **'Tercihlerine gÃƒÂ¶re ÃƒÂ¶neriler'**
  String get whatToEatDescription;

  /// Auto metadata for stepPeopleCount
  ///
  /// In tr, this message translates to:
  /// **'KiÃ…Å¸i sayÃ„Â±sÃ„Â±'**
  String get stepPeopleCount;

  /// Auto metadata for quickDecisionThreeOptions
  ///
  /// In tr, this message translates to:
  /// **'3 seÃƒÂ§enekle hÃ„Â±zlÃ„Â± karar'**
  String get quickDecisionThreeOptions;

  /// Auto metadata for stepBudgetTotal
  ///
  /// In tr, this message translates to:
  /// **'Toplam bÃƒÂ¼tÃƒÂ§e'**
  String get stepBudgetTotal;

  /// Auto metadata for budgetTl
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¼tÃƒÂ§e (Ã¢â€šÂº)'**
  String get budgetTl;

  /// Auto metadata for stepDistance
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get stepDistance;

  /// Auto metadata for locationNotSelected
  ///
  /// In tr, this message translates to:
  /// **'Konum seÃƒÂ§ilmedi'**
  String get locationNotSelected;

  /// Auto metadata for seeSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nerileri GÃƒÂ¶r'**
  String get seeSuggestions;

  /// Auto metadata for getSingleSuggestion
  ///
  /// In tr, this message translates to:
  /// **'Tek ÃƒÂ¶neri al'**
  String get getSingleSuggestion;

  /// Auto metadata for go
  ///
  /// In tr, this message translates to:
  /// **'Git'**
  String get go;

  /// Auto metadata for restart
  ///
  /// In tr, this message translates to:
  /// **'Yeniden BaÃ…Å¸lat'**
  String get restart;

  /// Auto metadata for quickShortcuts
  ///
  /// In tr, this message translates to:
  /// **'HÃ„Â±zlÃ„Â± KÃ„Â±sayollar'**
  String get quickShortcuts;

  /// Auto metadata for quickShortcutsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'En sÃ„Â±k kullanÃ„Â±lanlar'**
  String get quickShortcutsSubtitle;

  /// Auto metadata for savedItems
  ///
  /// In tr, this message translates to:
  /// **'Kaydettiklerim'**
  String get savedItems;

  /// Auto metadata for myFriendGroup
  ///
  /// In tr, this message translates to:
  /// **'ArkadaÃ…Å¸ Grubum'**
  String get myFriendGroup;

  /// Auto metadata for tasteExperts
  ///
  /// In tr, this message translates to:
  /// **'Lezzet UzmanlarÃ„Â±'**
  String get tasteExperts;

  /// Auto metadata for businessTools
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã…Å¸letme AraÃƒÂ§larÃ„Â±'**
  String get businessTools;

  /// Auto metadata for businessToolsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'YÃƒÂ¶netim ve iÃƒÂ§gÃƒÂ¶rÃƒÂ¼ler'**
  String get businessToolsSubtitle;

  /// Auto metadata for sponsoredLabelChip
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu etiket'**
  String get sponsoredLabelChip;

  /// Auto metadata for sponsored
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu'**
  String get sponsored;

  /// Auto metadata for ready
  ///
  /// In tr, this message translates to:
  /// **'HazÃ„Â±r'**
  String get ready;

  /// Auto metadata for plan
  ///
  /// In tr, this message translates to:
  /// **'plan'**
  String get plan;

  /// Auto metadata for sponsoredDisclosure
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu iÃƒÂ§erik'**
  String get sponsoredDisclosure;

  /// Auto metadata for sponsoredTooltip
  ///
  /// In tr, this message translates to:
  /// **'Bu iÃƒÂ§erik sponsorlu olabilir.'**
  String get sponsoredTooltip;

  /// No description provided for @localInsightsReady.
  ///
  /// In tr, this message translates to:
  /// **'Yerel iÃƒÂ§gÃƒÂ¶rÃƒÂ¼ler hazÃ„Â±r Ã¢â‚¬Â¢ {area}'**
  String localInsightsReady(String area);

  /// Auto metadata for show
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶ster'**
  String get show;

  /// Auto metadata for restaurant
  ///
  /// In tr, this message translates to:
  /// **'Restoran'**
  String get restaurant;

  /// Auto metadata for cafe
  ///
  /// In tr, this message translates to:
  /// **'Kafe'**
  String get cafe;

  /// Auto metadata for venue
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get venue;

  /// Auto metadata for notifications
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// Auto metadata for businessPackage
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã…Å¸letme Paketi'**
  String get businessPackage;

  /// Auto metadata for redirectToReservation
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyona yÃƒÂ¶nlendir'**
  String get redirectToReservation;

  /// Auto metadata for priceAlerts
  ///
  /// In tr, this message translates to:
  /// **'Fiyat UyarÃ„Â±larÃ„Â±'**
  String get priceAlerts;

  /// Auto metadata for corporateIntegration
  ///
  /// In tr, this message translates to:
  /// **'Kurumsal Entegrasyon'**
  String get corporateIntegration;

  /// Auto metadata for detailedReports
  ///
  /// In tr, this message translates to:
  /// **'DetaylÃ„Â± Raporlar'**
  String get detailedReports;

  /// Auto metadata for qrTools
  ///
  /// In tr, this message translates to:
  /// **'QR AraÃƒÂ§larÃ„Â±'**
  String get qrTools;

  /// Auto metadata for unlockNewFeatures
  ///
  /// In tr, this message translates to:
  /// **'Yeni ÃƒÂ¶zelliklerin kilidini aÃƒÂ§'**
  String get unlockNewFeatures;

  /// Auto metadata for branchManagement
  ///
  /// In tr, this message translates to:
  /// **'Ã…Âube YÃƒÂ¶netimi'**
  String get branchManagement;

  /// Auto metadata for menuWithQr
  ///
  /// In tr, this message translates to:
  /// **'QR ile MenÃƒÂ¼'**
  String get menuWithQr;

  /// Auto metadata for newFeatures
  ///
  /// In tr, this message translates to:
  /// **'Yeni Ãƒâ€“zellikler'**
  String get newFeatures;

  /// No description provided for @nearOpenSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±nda AÃƒÂ§Ã„Â±k Olanlar Ã¢â‚¬Â¢ {area}'**
  String nearOpenSectionTitle(String area);

  /// No description provided for @mostViewedThisWeekTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu HaftanÃ„Â±n En Ãƒâ€¡ok GÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼lenenleri Ã¢â‚¬Â¢ {area}'**
  String mostViewedThisWeekTitle(String area);

  /// Auto metadata for noViewDataInArea
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¶lgede gÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼leme verisi yok'**
  String get noViewDataInArea;

  /// No description provided for @viewsMetric.
  ///
  /// In tr, this message translates to:
  /// **'{count} gÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼leme'**
  String viewsMetric(int count);

  /// No description provided for @highestPriceChangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'En YÃƒÂ¼ksek Fiyat DeÃ„Å¸iÃ…Å¸imi Ã¢â‚¬Â¢ {area}'**
  String highestPriceChangeTitle(String area);

  /// Auto metadata for noPriceMovementInArea
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¶lgede fiyat hareketi yok'**
  String get noPriceMovementInArea;

  /// No description provided for @priceChangeMetric.
  ///
  /// In tr, this message translates to:
  /// **'{count} fiyat deÃ„Å¸iÃ…Å¸imi'**
  String priceChangeMetric(int count);

  /// No description provided for @nightOpenFavoritesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gece AÃƒÂ§Ã„Â±k Favoriler Ã¢â‚¬Â¢ {area}'**
  String nightOpenFavoritesTitle(String area);

  /// Auto metadata for noNightOpenFavoritesInArea
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¶lgede gece aÃƒÂ§Ã„Â±k favori yok'**
  String get noNightOpenFavoritesInArea;

  /// No description provided for @followersMetric.
  ///
  /// In tr, this message translates to:
  /// **'{count} takipÃƒÂ§i'**
  String followersMetric(int count);

  /// No description provided for @popularCategoriesTitle.
  ///
  /// In tr, this message translates to:
  /// **'PopÃƒÂ¼ler Kategoriler Ã¢â‚¬Â¢ {area}'**
  String popularCategoriesTitle(String area);

  /// No description provided for @regionalPriceIndexTitle.
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¶lgesel Fiyat Endeksi Ã¢â‚¬Â¢ {area}'**
  String regionalPriceIndexTitle(String area);

  /// Auto metadata for detailedAnalysis
  ///
  /// In tr, this message translates to:
  /// **'DetaylÃ„Â± Analiz'**
  String get detailedAnalysis;

  /// Auto metadata for loadWhenScrolledDown
  ///
  /// In tr, this message translates to:
  /// **'AÃ…Å¸aÃ„Å¸Ã„Â± kaydÃ„Â±rÃ„Â±nca yÃƒÂ¼klenir'**
  String get loadWhenScrolledDown;

  /// No description provided for @anomalyMonitoringTitle.
  ///
  /// In tr, this message translates to:
  /// **'{area} anomali izlemesi'**
  String anomalyMonitoringTitle(String area);

  /// Auto metadata for general
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get general;

  /// Auto metadata for priceIndexLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'Fiyat endeksi yÃƒÂ¼klenemedi'**
  String get priceIndexLoadFailed;

  /// Auto metadata for noPriceIndexDataInArea
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¶lgede fiyat endeksi verisi yok'**
  String get noPriceIndexDataInArea;

  /// No description provided for @medianPriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Medyan fiyat {price}'**
  String medianPriceLabel(String price);

  /// Auto metadata for anomalyListLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'Anomali listesi yÃƒÂ¼klenemedi'**
  String get anomalyListLoadFailed;

  /// Auto metadata for noPriceAnomalyLast30Days
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gÃƒÂ¼nde fiyat anomalisi yok'**
  String get noPriceAnomalyLast30Days;

  /// Auto metadata for sectionLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÂ¶lÃƒÂ¼m yÃƒÂ¼klenemedi'**
  String get sectionLoadFailed;

  /// No description provided for @rankedAt.
  ///
  /// In tr, this message translates to:
  /// **'SÃ„Â±ra: {rank}'**
  String rankedAt(int rank);

  /// No description provided for @yourScore.
  ///
  /// In tr, this message translates to:
  /// **'PuanÃ„Â±n: {score}'**
  String yourScore(String score);

  /// Auto metadata for createGroup
  ///
  /// In tr, this message translates to:
  /// **'Grup kur'**
  String get createGroup;

  /// Auto metadata for newPlaces
  ///
  /// In tr, this message translates to:
  /// **'Yeni yerler'**
  String get newPlaces;

  /// Auto metadata for campaignEnded
  ///
  /// In tr, this message translates to:
  /// **'bitti'**
  String get campaignEnded;

  /// No description provided for @timeDays.
  ///
  /// In tr, this message translates to:
  /// **'{count} gÃƒÂ¼n'**
  String timeDays(int count);

  /// No description provided for @timeHours.
  ///
  /// In tr, this message translates to:
  /// **'{count} saat'**
  String timeHours(int count);

  /// No description provided for @timeMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk'**
  String timeMinutes(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} gÃƒÂ¼n ÃƒÂ¶nce'**
  String timeDaysAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} saat ÃƒÂ¶nce'**
  String timeHoursAgo(int count);

  /// No description provided for @timeMinutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} dakika ÃƒÂ¶nce'**
  String timeMinutesAgo(int count);

  /// Auto metadata for statusVerifiedShort
  ///
  /// In tr, this message translates to:
  /// **'DoÃ„Å¸rulandÃ„Â±'**
  String get statusVerifiedShort;

  /// Auto metadata for statusMixedShort
  ///
  /// In tr, this message translates to:
  /// **'KarÃ„Â±Ã…Å¸Ã„Â±k'**
  String get statusMixedShort;

  /// Auto metadata for statusOutdatedShort
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ncel DeÃ„Å¸il'**
  String get statusOutdatedShort;

  /// Auto metadata for statusUnknownShort
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get statusUnknownShort;

  /// Auto metadata for threeMonthsShort
  ///
  /// In tr, this message translates to:
  /// **'(3 Ay)'**
  String get threeMonthsShort;

  /// No description provided for @versionAndSource.
  ///
  /// In tr, this message translates to:
  /// **'SÃƒÂ¼rÃƒÂ¼m {version} Ã¢â‚¬Â¢ Kaynak: {source}'**
  String versionAndSource(int version, String source);

  /// Auto metadata for sourceOwner
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: iÃ…Å¸letme'**
  String get sourceOwner;

  /// Auto metadata for sourceCommunity
  ///
  /// In tr, this message translates to:
  /// **'topluluk'**
  String get sourceCommunity;

  /// Auto metadata for sourceAi
  ///
  /// In tr, this message translates to:
  /// **'otomatik'**
  String get sourceAi;

  /// No description provided for @shareBusinessMessage.
  ///
  /// In tr, this message translates to:
  /// **'{name} Ã¢â‚¬Â¢ {location}\n{web}\n{deep}'**
  String shareBusinessMessage(
    String name,
    String location,
    String web,
    String deep,
  );

  /// Auto metadata for noLinkFound
  ///
  /// In tr, this message translates to:
  /// **'BaÃ„Å¸lantÃ„Â± bulunamadÃ„Â±'**
  String get noLinkFound;

  /// Auto metadata for newEmbedLinksWillAppear
  ///
  /// In tr, this message translates to:
  /// **'Yeni gÃƒÂ¶mÃƒÂ¼lÃƒÂ¼ baÃ„Å¸lantÃ„Â±lar burada gÃƒÂ¶rÃƒÂ¼necek.'**
  String get newEmbedLinksWillAppear;

  /// Auto metadata for link
  ///
  /// In tr, this message translates to:
  /// **'BaÃ„Å¸lantÃ„Â±'**
  String get link;

  /// Auto metadata for untitledLink
  ///
  /// In tr, this message translates to:
  /// **'BaÃ…Å¸lÃ„Â±ksÃ„Â±z baÃ„Å¸lantÃ„Â±'**
  String get untitledLink;

  /// No description provided for @menuShareNotFoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ bulunamadÃ„Â± Ã¢â‚¬Â¢ {appName}'**
  String menuShareNotFoundTitle(String appName);

  /// Auto metadata for menuShareNotFoundDescription
  ///
  /// In tr, this message translates to:
  /// **'PaylaÃ…Å¸Ã„Â±lan menÃƒÂ¼ iÃƒÂ§eriÃ„Å¸i bulunamadÃ„Â±.'**
  String get menuShareNotFoundDescription;

  /// Auto metadata for menuContentNotFound
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ iÃƒÂ§eriÃ„Å¸i bulunamadÃ„Â±'**
  String get menuContentNotFound;

  /// Auto metadata for openAppForBetterExperience
  ///
  /// In tr, this message translates to:
  /// **'Daha iyi deneyim iÃƒÂ§in uygulamayÃ„Â± aÃƒÂ§.'**
  String get openAppForBetterExperience;

  /// Auto metadata for openApp
  ///
  /// In tr, this message translates to:
  /// **'UygulamayÃ„Â± AÃƒÂ§'**
  String get openApp;

  /// No description provided for @nearbyPeopleViewed.
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±ndaki {count} kiÃ…Å¸i gÃƒÂ¶rÃƒÂ¼ntÃƒÂ¼ledi'**
  String nearbyPeopleViewed(int count);

  /// Auto metadata for verifiedPrices
  ///
  /// In tr, this message translates to:
  /// **'DoÃ„Å¸rulanmÃ„Â±Ã…Å¸ fiyatlar'**
  String get verifiedPrices;

  /// Auto metadata for selectRatingFirst
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nce puan seÃƒÂ§'**
  String get selectRatingFirst;

  /// Auto metadata for thankYou
  ///
  /// In tr, this message translates to:
  /// **'TeÃ…Å¸ekkÃƒÂ¼rler'**
  String get thankYou;

  /// Auto metadata for noProductsFound
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÅ“rÃƒÂ¼n bulunamadÃ„Â±'**
  String get noProductsFound;

  /// No description provided for @preparedWithApp.
  ///
  /// In tr, this message translates to:
  /// **'{appName} ile hazÃ„Â±rlandÃ„Â±'**
  String preparedWithApp(String appName);

  /// No description provided for @tableLabel.
  ///
  /// In tr, this message translates to:
  /// **'Masa {tableNo}'**
  String tableLabel(String tableNo);

  /// No description provided for @tableServiceQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Masa {tableNo} - servis var mÃ„Â±?'**
  String tableServiceQuestion(String tableNo);

  /// Auto metadata for shortNoteOptional
  ///
  /// In tr, this message translates to:
  /// **'KÃ„Â±sa not (opsiyonel)'**
  String get shortNoteOptional;

  /// Auto metadata for submit
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶nder'**
  String get submit;

  /// Auto metadata for submitted
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶nderildi'**
  String get submitted;

  /// Auto metadata for submitting
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶nderiliyor'**
  String get submitting;

  /// Auto metadata for mySuggestionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nerilerim'**
  String get mySuggestionsTitle;

  /// Auto metadata for mySuggestionsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶nderdiÃ„Å¸in fiyat ÃƒÂ¶nerileri'**
  String get mySuggestionsSubtitle;

  /// Auto metadata for viewBusiness
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°Ã…Å¸letmeyi GÃƒÂ¶r'**
  String get viewBusiness;

  /// Auto metadata for statusApproved
  ///
  /// In tr, this message translates to:
  /// **'OnaylandÃ„Â±'**
  String get statusApproved;

  /// Auto metadata for statusRejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get statusRejected;

  /// Auto metadata for statusPending
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get statusPending;

  /// Auto metadata for retry
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// Auto metadata for notNow
  ///
  /// In tr, this message translates to:
  /// **'Ã…Âimdi deÃ„Å¸il'**
  String get notNow;

  /// Auto metadata for onboardingLiveMenusTitle
  ///
  /// In tr, this message translates to:
  /// **'CanlÃ„Â± MenÃƒÂ¼ler'**
  String get onboardingLiveMenusTitle;

  /// Auto metadata for onboardingLiveMenusDescription
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ncel menÃƒÂ¼lere anÃ„Â±nda eriÃ…Å¸.'**
  String get onboardingLiveMenusDescription;

  /// Auto metadata for onboardingContributeTitle
  ///
  /// In tr, this message translates to:
  /// **'KatkÃ„Â±da Bulun'**
  String get onboardingContributeTitle;

  /// Auto metadata for onboardingContributeDescription
  ///
  /// In tr, this message translates to:
  /// **'Topluluk iÃƒÂ§in fiyatlarÃ„Â± doÃ„Å¸rula ve gÃƒÂ¼ncelle.'**
  String get onboardingContributeDescription;

  /// Auto metadata for getStarted
  ///
  /// In tr, this message translates to:
  /// **'BaÃ…Å¸layalÃ„Â±m'**
  String get getStarted;

  /// Auto metadata for continueAction
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueAction;

  /// Auto metadata for register
  ///
  /// In tr, this message translates to:
  /// **'KayÃ„Â±t Ol'**
  String get register;

  /// Auto metadata for login
  ///
  /// In tr, this message translates to:
  /// **'GiriÃ…Å¸ Yap'**
  String get login;

  /// Auto metadata for enableLocationTitle
  ///
  /// In tr, this message translates to:
  /// **'Konumu AÃƒÂ§'**
  String get enableLocationTitle;

  /// Auto metadata for enableLocationSubtitle
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±ndaki yerleri gÃƒÂ¶stermek iÃƒÂ§in konumunu aÃƒÂ§.'**
  String get enableLocationSubtitle;

  /// Auto metadata for locationPermissionGranted
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verildi'**
  String get locationPermissionGranted;

  /// Auto metadata for locationOptionalInfo
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°stersen daha sonra da aÃƒÂ§abilirsin.'**
  String get locationOptionalInfo;

  /// Auto metadata for allowLocation
  ///
  /// In tr, this message translates to:
  /// **'Konuma izin ver'**
  String get allowLocation;

  /// Auto metadata for chooseLocationManually
  ///
  /// In tr, this message translates to:
  /// **'Konumu Elle SeÃƒÂ§'**
  String get chooseLocationManually;

  /// Auto metadata for menuReading
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ okunuyor'**
  String get menuReading;

  /// Auto metadata for noPriceDetectionFound
  ///
  /// In tr, this message translates to:
  /// **'Fiyat tespiti bulunamadÃ„Â±'**
  String get noPriceDetectionFound;

  /// Auto metadata for receiptOcrNotSupportedWeb
  ///
  /// In tr, this message translates to:
  /// **'Web sÃƒÂ¼rÃƒÂ¼mÃƒÂ¼nde fiÃ…Å¸ OCR desteklenmiyor'**
  String get receiptOcrNotSupportedWeb;

  /// Auto metadata for receiptReading
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸ okunuyor'**
  String get receiptReading;

  /// Auto metadata for noPriceFoundOnReceipt
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸te fiyat bulunamadÃ„Â±'**
  String get noPriceFoundOnReceipt;

  /// Auto metadata for receiptUploading
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸ yÃƒÂ¼kleniyor'**
  String get receiptUploading;

  /// Auto metadata for receiptUploadFailed
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸ yÃƒÂ¼kleme baÃ…Å¸arÃ„Â±sÃ„Â±z'**
  String get receiptUploadFailed;

  /// Auto metadata for camera
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// Auto metadata for gallery
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get gallery;

  /// Auto metadata for matchReceipt
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸i EÃ…Å¸leÃ…Å¸tir'**
  String get matchReceipt;

  /// Auto metadata for matchPrices
  ///
  /// In tr, this message translates to:
  /// **'FiyatlarÃ„Â± EÃ…Å¸leÃ…Å¸tir'**
  String get matchPrices;

  /// No description provided for @autoMatchedRowsCheck.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik eÃ…Å¸leÃ…Å¸en {count} satÃ„Â±rÃ„Â± kontrol et.'**
  String autoMatchedRowsCheck(int count);

  /// Auto metadata for unlabeled
  ///
  /// In tr, this message translates to:
  /// **'Etiketsiz'**
  String get unlabeled;

  /// Auto metadata for priceTry
  ///
  /// In tr, this message translates to:
  /// **'Fiyat (Ã¢â€šÂº)'**
  String get priceTry;

  /// Auto metadata for selectMenuItem
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ ÃƒÂ¼rÃƒÂ¼nÃƒÂ¼ seÃƒÂ§'**
  String get selectMenuItem;

  /// Auto metadata for sendReceipt
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸i GÃƒÂ¶nder'**
  String get sendReceipt;

  /// Auto metadata for sendReceiptSuggestions
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸ Ãƒâ€“nerilerini GÃƒÂ¶nder'**
  String get sendReceiptSuggestions;

  /// Auto metadata for selectAtLeastOneItem
  ///
  /// In tr, this message translates to:
  /// **'En az bir ÃƒÂ¼rÃƒÂ¼n seÃƒÂ§'**
  String get selectAtLeastOneItem;

  /// Auto metadata for invalidPriceExists
  ///
  /// In tr, this message translates to:
  /// **'GeÃƒÂ§ersiz fiyat var'**
  String get invalidPriceExists;

  /// Auto metadata for sendingReceipt
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸ gÃƒÂ¶nderiliyor'**
  String get sendingReceipt;

  /// Auto metadata for receiptSent
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸ gÃƒÂ¶nderildi'**
  String get receiptSent;

  /// Auto metadata for sendingReceiptSuggestions
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸ ÃƒÂ¶nerileri gÃƒÂ¶nderiliyor'**
  String get sendingReceiptSuggestions;

  /// Auto metadata for priceSuggestionsSent
  ///
  /// In tr, this message translates to:
  /// **'Fiyat ÃƒÂ¶nerileri gÃƒÂ¶nderildi'**
  String get priceSuggestionsSent;

  /// Auto metadata for searchFoodHint
  ///
  /// In tr, this message translates to:
  /// **'Yemek ara...'**
  String get searchFoodHint;

  /// Auto metadata for profileActive
  ///
  /// In tr, this message translates to:
  /// **'Profil aktif'**
  String get profileActive;

  /// Auto metadata for profileLoading
  ///
  /// In tr, this message translates to:
  /// **'Profil yÃƒÂ¼kleniyor'**
  String get profileLoading;

  /// Auto metadata for dietProfileNotFound
  ///
  /// In tr, this message translates to:
  /// **'Beslenme profili bulunamadÃ„Â±'**
  String get dietProfileNotFound;

  /// Auto metadata for noResultsFound
  ///
  /// In tr, this message translates to:
  /// **'SonuÃƒÂ§ bulunamadÃ„Â±'**
  String get noResultsFound;

  /// Auto metadata for allowLocationForNearby
  ///
  /// In tr, this message translates to:
  /// **'YakÃ„Â±n sonuÃƒÂ§lar iÃƒÂ§in konum izni ver'**
  String get allowLocationForNearby;

  /// Auto metadata for setPriceAlert
  ///
  /// In tr, this message translates to:
  /// **'Fiyat uyarÃ„Â±sÃ„Â± kur'**
  String get setPriceAlert;

  /// Auto metadata for vegan
  ///
  /// In tr, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// Auto metadata for vegetarian
  ///
  /// In tr, this message translates to:
  /// **'Vejetaryen'**
  String get vegetarian;

  /// Auto metadata for lactoseFree
  ///
  /// In tr, this message translates to:
  /// **'Laktozsuz'**
  String get lactoseFree;

  /// Auto metadata for maxCalories
  ///
  /// In tr, this message translates to:
  /// **'Maksimum kalori'**
  String get maxCalories;

  /// Auto metadata for onlyVerifiedPrice
  ///
  /// In tr, this message translates to:
  /// **'Sadece teyitli fiyat'**
  String get onlyVerifiedPrice;

  /// No description provided for @votes.
  ///
  /// In tr, this message translates to:
  /// **'{count} oy'**
  String votes(int count);

  /// Auto metadata for glutenFree
  ///
  /// In tr, this message translates to:
  /// **'Glutensiz'**
  String get glutenFree;

  /// Auto metadata for menuItem
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ ÃƒÂ¼rÃƒÂ¼nÃƒÂ¼'**
  String get menuItem;

  /// Auto metadata for cataloged
  ///
  /// In tr, this message translates to:
  /// **'Kataloglu'**
  String get cataloged;

  /// Auto metadata for priceAlert
  ///
  /// In tr, this message translates to:
  /// **'Fiyat AlarmÃ„Â±'**
  String get priceAlert;

  /// Auto metadata for priceAlertSubtitle
  ///
  /// In tr, this message translates to:
  /// **'BelirlediÃ„Å¸in fiyatÃ„Â±n altÃ„Â±na dÃƒÂ¼Ã…Å¸ÃƒÂ¼nce haber verelim.'**
  String get priceAlertSubtitle;

  /// Auto metadata for addToBill
  ///
  /// In tr, this message translates to:
  /// **'Hesaba Ekle'**
  String get addToBill;

  /// Auto metadata for voteSaved
  ///
  /// In tr, this message translates to:
  /// **'Oyun kaydedildi'**
  String get voteSaved;

  /// Auto metadata for photoAdded
  ///
  /// In tr, this message translates to:
  /// **'FotoÃ„Å¸raf eklendi'**
  String get photoAdded;

  /// No description provided for @photoQualityWarning.
  ///
  /// In tr, this message translates to:
  /// **'FotoÃ„Å¸raf {warnings} gÃƒÂ¶rÃƒÂ¼nÃƒÂ¼yor. Daha net ve aydÃ„Â±nlÃ„Â±k bir fotoÃ„Å¸raf yÃƒÂ¼kleyebilirsin.'**
  String photoQualityWarning(String warnings);

  /// Auto metadata for suggestEdit
  ///
  /// In tr, this message translates to:
  /// **'DÃƒÂ¼zenleme ÃƒÂ¶ner'**
  String get suggestEdit;

  /// Auto metadata for verifyPriceWithReceipt
  ///
  /// In tr, this message translates to:
  /// **'FiÃ…Å¸ ile fiyat doÃ„Å¸rula'**
  String get verifyPriceWithReceipt;

  /// Auto metadata for cart
  ///
  /// In tr, this message translates to:
  /// **'Sepet'**
  String get cart;

  /// Auto metadata for cartEmpty
  ///
  /// In tr, this message translates to:
  /// **'Sepet boÃ…Å¸'**
  String get cartEmpty;

  /// Auto metadata for addItemToCalculate
  ///
  /// In tr, this message translates to:
  /// **'Hesaplamak iÃƒÂ§in ÃƒÂ¼rÃƒÂ¼n ekle'**
  String get addItemToCalculate;

  /// Auto metadata for tipPercentage
  ///
  /// In tr, this message translates to:
  /// **'BahÃ…Å¸iÃ…Å¸ YÃƒÂ¼zdesi'**
  String get tipPercentage;

  /// Auto metadata for serviceIncluded
  ///
  /// In tr, this message translates to:
  /// **'Servis dahil'**
  String get serviceIncluded;

  /// Auto metadata for coverIncluded
  ///
  /// In tr, this message translates to:
  /// **'Kuver dahil'**
  String get coverIncluded;

  /// Auto metadata for subtotal
  ///
  /// In tr, this message translates to:
  /// **'Ara toplam'**
  String get subtotal;

  /// Auto metadata for cover
  ///
  /// In tr, this message translates to:
  /// **'Kuver'**
  String get cover;

  /// No description provided for @serviceWithPercent.
  ///
  /// In tr, this message translates to:
  /// **'Servis ({percent}%)'**
  String serviceWithPercent(int percent);

  /// No description provided for @tipWithPercent.
  ///
  /// In tr, this message translates to:
  /// **'BahÃ…Å¸iÃ…Å¸ ({percent}%)'**
  String tipWithPercent(int percent);

  /// Auto metadata for serviceCoverMayVary
  ///
  /// In tr, this message translates to:
  /// **'Servis/kuver iÃ…Å¸letmeye gÃƒÂ¶re deÃ„Å¸iÃ…Å¸ebilir.'**
  String get serviceCoverMayVary;

  /// Auto metadata for estimatedTotal
  ///
  /// In tr, this message translates to:
  /// **'Tahmini Toplam'**
  String get estimatedTotal;

  /// Auto metadata for vatExcluded
  ///
  /// In tr, this message translates to:
  /// **'KDV hariÃƒÂ§'**
  String get vatExcluded;

  /// Auto metadata for errorOccurred
  ///
  /// In tr, this message translates to:
  /// **'Bir sorun oluÃ…Å¸tu'**
  String get errorOccurred;

  /// Auto metadata for menuItemNotFoundDescription
  ///
  /// In tr, this message translates to:
  /// **'AradÃ„Â±Ã„Å¸Ã„Â±n ÃƒÂ¼rÃƒÂ¼n henÃƒÂ¼z eklenmemiÃ…Å¸ olabilir. Ã„Â°stersen ilk sen ekle.'**
  String get menuItemNotFoundDescription;

  /// Auto metadata for trustScoreInfoNote
  ///
  /// In tr, this message translates to:
  /// **'Bu gÃƒÂ¼ven puanÃ„Â± kullanÃ„Â±cÃ„Â± oylamasÃ„Â± deÃ„Å¸il, katkÃ„Â± kalitesinden oluÃ…Å¸ur.'**
  String get trustScoreInfoNote;

  /// No description provided for @plusPoints.
  ///
  /// In tr, this message translates to:
  /// **'+{points} puan'**
  String plusPoints(int points);

  /// Auto metadata for verifyContributionRaisedScore
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doÃ„Å¸rulaman katkÃ„Â±n puanÃ„Â±nÃ„Â± yÃƒÂ¼kseltti.'**
  String get verifyContributionRaisedScore;

  /// Auto metadata for priceVerification
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doÃ„Å¸rulama'**
  String get priceVerification;

  /// Auto metadata for priceVerificationSteps
  ///
  /// In tr, this message translates to:
  /// **'1) GÃƒÂ¶rdÃƒÂ¼Ã„Å¸ÃƒÂ¼n fiyatÃ„Â± yaz  2) Gerekirse not/foto ekle  3) GÃƒÂ¶nder'**
  String get priceVerificationSteps;

  /// Auto metadata for newPriceTry
  ///
  /// In tr, this message translates to:
  /// **'Yeni fiyat (Ã¢â€šÂº)'**
  String get newPriceTry;

  /// Auto metadata for note
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get note;

  /// Auto metadata for addEvidencePhoto
  ///
  /// In tr, this message translates to:
  /// **'KanÃ„Â±t fotoÃ„Å¸rafÃ„Â± ekle'**
  String get addEvidencePhoto;

  /// Auto metadata for evidenceAdded
  ///
  /// In tr, this message translates to:
  /// **'KanÃ„Â±t eklendi'**
  String get evidenceAdded;

  /// Auto metadata for menuItemName
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÅ“rÃƒÂ¼n adÃ„Â±'**
  String get menuItemName;

  /// Auto metadata for menuItemNameRequired
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÅ“rÃƒÂ¼n adÃ„Â± boÃ…Å¸ olamaz'**
  String get menuItemNameRequired;

  /// Auto metadata for enterValidPrice
  ///
  /// In tr, this message translates to:
  /// **'GeÃƒÂ§erli bir fiyat gir'**
  String get enterValidPrice;

  /// Auto metadata for sendSuggestion
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“neri GÃƒÂ¶nder'**
  String get sendSuggestion;

  /// Auto metadata for noChanges
  ///
  /// In tr, this message translates to:
  /// **'DeÃ„Å¸iÃ…Å¸iklik yok'**
  String get noChanges;

  /// Auto metadata for priceCannotBeEmpty
  ///
  /// In tr, this message translates to:
  /// **'Fiyat boÃ…Å¸ olamaz'**
  String get priceCannotBeEmpty;

  /// Auto metadata for suggestionSentPendingApproval
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nerin gÃƒÂ¶nderildi, onay bekliyor.'**
  String get suggestionSentPendingApproval;

  /// Auto metadata for noSuggestionFound
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“neri bulunamadÃ„Â±'**
  String get noSuggestionFound;

  /// Auto metadata for suggestedFoods
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€“nerilen Yemekler'**
  String get suggestedFoods;

  /// Auto metadata for priceHistoryLast3
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geÃƒÂ§miÃ…Å¸i (son 3)'**
  String get priceHistoryLast3;

  /// Auto metadata for price
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get price;

  /// No description provided for @last30DaysVotes.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gÃƒÂ¼n oylarÃ„Â± Ã¢â‚¬Â¢ Uygun: {ok} Ã¢â‚¬Â¢ Uygunsuz: {bad}'**
  String last30DaysVotes(int ok, int bad);

  /// No description provided for @lastVerificationDate.
  ///
  /// In tr, this message translates to:
  /// **'Son doÃ„Å¸rulama: {date}'**
  String lastVerificationDate(String date);

  /// No description provided for @uniqueVerifiersIn48h.
  ///
  /// In tr, this message translates to:
  /// **'48 saatte doÃ„Å¸rulayan farklÃ„Â± kullanÃ„Â±cÃ„Â±: {count}'**
  String uniqueVerifiersIn48h(int count);

  /// Auto metadata for strongConsensusPriceSafe
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼ÃƒÂ§lÃƒÂ¼ uzlaÃ…Å¸Ã„Â± var, fiyat gÃƒÂ¼venli gÃƒÂ¶rÃƒÂ¼nÃƒÂ¼yor.'**
  String get strongConsensusPriceSafe;

  /// No description provided for @priceConfidenceScore.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat gÃƒÂ¼ven puanÃ„Â±: %{score}'**
  String priceConfidenceScore(int score);

  /// Auto metadata for seenCorrect
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶rdÃƒÂ¼m Ã¢â‚¬Â¢ DoÃ„Å¸ru'**
  String get seenCorrect;

  /// Auto metadata for seenIncorrect
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¶rdÃƒÂ¼m Ã¢â‚¬Â¢ YanlÃ„Â±Ã…Å¸'**
  String get seenIncorrect;

  /// Auto metadata for suggestNewPrice
  ///
  /// In tr, this message translates to:
  /// **'Yeni fiyat ÃƒÂ¶ner'**
  String get suggestNewPrice;

  /// Auto metadata for howCalculated
  ///
  /// In tr, this message translates to:
  /// **'NasÃ„Â±l hesaplandÃ„Â±?'**
  String get howCalculated;

  /// Auto metadata for verificationRate
  ///
  /// In tr, this message translates to:
  /// **'DoÃ„Å¸rulama oranÃ„Â±'**
  String get verificationRate;

  /// Auto metadata for recentPositiveVotes
  ///
  /// In tr, this message translates to:
  /// **'Son olumlu oylar'**
  String get recentPositiveVotes;

  /// Auto metadata for priceStability
  ///
  /// In tr, this message translates to:
  /// **'Fiyat istikrarÃ„Â±'**
  String get priceStability;

  /// No description provided for @priceChangeLast30Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gÃƒÂ¼nde fiyat deÃ„Å¸iÃ…Å¸imi: {count}'**
  String priceChangeLast30Days(int count);

  /// Auto metadata for scoreForInfoOnly
  ///
  /// In tr, this message translates to:
  /// **'Bu skor yalnÃ„Â±zca bilgilendirme amaÃƒÂ§lÃ„Â±dÃ„Â±r.'**
  String get scoreForInfoOnly;

  /// Auto metadata for pricePerformance
  ///
  /// In tr, this message translates to:
  /// **'Fiyat/Performans'**
  String get pricePerformance;

  /// Auto metadata for valueScoreFormulaHint
  ///
  /// In tr, this message translates to:
  /// **'DoÃ„Å¸rulama oranÃ„Â±, son olumlu oylar ve fiyat istikrarÃ„Â±na gÃƒÂ¶re hesaplanÃ„Â±r.'**
  String get valueScoreFormulaHint;

  /// Auto metadata for menuPhotos
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ FotoÃ„Å¸raflarÃ„Â±'**
  String get menuPhotos;

  /// No description provided for @updateMenuEarnPoints.
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ gÃƒÂ¼ncelle, {points} puan kazan'**
  String updateMenuEarnPoints(int points);

  /// Auto metadata for menuPhotosHint
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÂ¼ fotoÃ„Å¸raflarÃ„Â± ÃƒÂ¼rÃƒÂ¼nÃƒÂ¼ gÃƒÂ¶stermeli. Otomatik kÃ„Â±rpÃ„Â±lÃ„Â±r; karanlÃ„Â±k/flu olanlar uyarÃ„Â±lÃ„Â±r.'**
  String get menuPhotosHint;

  /// Auto metadata for noPhotosYet
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÂ¼z fotoÃ„Å¸raf yok.'**
  String get noPhotosYet;

  /// Auto metadata for yesterday
  ///
  /// In tr, this message translates to:
  /// **'DÃƒÂ¼n'**
  String get yesterday;

  /// No description provided for @timeMonthsAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} ay ÃƒÂ¶nce'**
  String timeMonthsAgo(int count);

  /// Auto metadata for priceInvalid
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geÃƒÂ§ersiz'**
  String get priceInvalid;

  /// Auto metadata for noteNoLinkPhone
  ///
  /// In tr, this message translates to:
  /// **'Not alanÃ„Â±na baÃ„Å¸lantÃ„Â± veya telefon eklenemez.'**
  String get noteNoLinkPhone;

  /// Auto metadata for noteContainsProfanity
  ///
  /// In tr, this message translates to:
  /// **'Notta uygunsuz ifade var.'**
  String get noteContainsProfanity;

  /// Auto metadata for noteTooManyEmoji
  ///
  /// In tr, this message translates to:
  /// **'Notta ÃƒÂ§ok fazla emoji var'**
  String get noteTooManyEmoji;

  /// Auto metadata for rateLimited24h
  ///
  /// In tr, this message translates to:
  /// **'24 saatlik sÃ„Â±nÃ„Â±r aÃ…Å¸Ã„Â±ldÃ„Â±'**
  String get rateLimited24h;

  /// Auto metadata for dailyPriceSuggestionLimitReached
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÂ¼nlÃƒÂ¼k fiyat ÃƒÂ¶neri limitine ulaÃ…Å¸Ã„Â±ldÃ„Â±'**
  String get dailyPriceSuggestionLimitReached;

  /// Auto metadata for invalidEvidenceLink
  ///
  /// In tr, this message translates to:
  /// **'KanÃ„Â±t baÃ„Å¸lantÃ„Â±sÃ„Â± geÃƒÂ§ersiz.'**
  String get invalidEvidenceLink;

  /// Auto metadata for invalidCurrency
  ///
  /// In tr, this message translates to:
  /// **'GeÃƒÂ§ersiz para birimi'**
  String get invalidCurrency;

  /// Auto metadata for loginPageTitle
  ///
  /// In tr, this message translates to:
  /// **'GiriÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ Yap'**
  String get loginPageTitle;

  /// Auto metadata for loginActionFailedTitle
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸lem tamamlanamadÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get loginActionFailedTitle;

  /// No description provided for @loginActionFailedDescription.
  ///
  /// In tr, this message translates to:
  /// **'{error}\nBaÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸lantÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± kontrol edip tekrar dene.'**
  String loginActionFailedDescription(String error);

  /// Auto metadata for loginEmailLabel
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get loginEmailLabel;

  /// Auto metadata for loginPasswordLabel
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Âifre'**
  String get loginPasswordLabel;

  /// Auto metadata for loginPrimaryAction
  ///
  /// In tr, this message translates to:
  /// **'GiriÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ Yap'**
  String get loginPrimaryAction;

  /// Auto metadata for loginSigningInAction
  ///
  /// In tr, this message translates to:
  /// **'GiriÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ yapÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±lÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±yor...'**
  String get loginSigningInAction;

  /// Auto metadata for loginSignupAction
  ///
  /// In tr, this message translates to:
  /// **'GiriÃƒâ€¦Ã…Â¸ / KayÃƒâ€Ã‚Â±t'**
  String get loginSignupAction;

  /// Auto metadata for loginSigningUpAction
  ///
  /// In tr, this message translates to:
  /// **'KayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±t oluÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸turuluyor...'**
  String get loginSigningUpAction;

  /// Auto metadata for loginSignupSuccessMessage
  ///
  /// In tr, this message translates to:
  /// **'KayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±t oluÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸turuldu. E-posta/telefon doÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸rulamasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± tamamla.'**
  String get loginSignupSuccessMessage;

  /// Auto metadata for drawerTopBusinesses
  ///
  /// In tr, this message translates to:
  /// **'Top ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letmeler'**
  String get drawerTopBusinesses;

  /// Auto metadata for drawerSocial
  ///
  /// In tr, this message translates to:
  /// **'Sosyal'**
  String get drawerSocial;

  /// Auto metadata for drawerGourmets
  ///
  /// In tr, this message translates to:
  /// **'Lezzet uzmanlarÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get drawerGourmets;

  /// Auto metadata for drawerFollowing
  ///
  /// In tr, this message translates to:
  /// **'Takip'**
  String get drawerFollowing;

  /// Auto metadata for drawerExperimental
  ///
  /// In tr, this message translates to:
  /// **'Deneysel'**
  String get drawerExperimental;

  /// Auto metadata for drawerFeed
  ///
  /// In tr, this message translates to:
  /// **'AkÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸'**
  String get drawerFeed;

  /// Auto metadata for drawerTasteTwin
  ///
  /// In tr, this message translates to:
  /// **'Tat eÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸i'**
  String get drawerTasteTwin;

  /// Auto metadata for drawerHeroes
  ///
  /// In tr, this message translates to:
  /// **'Kahramanlar'**
  String get drawerHeroes;

  /// Auto metadata for drawerGroupRequests
  ///
  /// In tr, this message translates to:
  /// **'Grup Talepleri'**
  String get drawerGroupRequests;

  /// Auto metadata for drawerCompare
  ///
  /// In tr, this message translates to:
  /// **'KarÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±laÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±r'**
  String get drawerCompare;

  /// Auto metadata for drawerQuickTools
  ///
  /// In tr, this message translates to:
  /// **'HÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±zlÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± AraÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§lar'**
  String get drawerQuickTools;

  /// Auto metadata for drawerSmartSuggestionShortcut
  ///
  /// In tr, this message translates to:
  /// **'AkÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±llÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“neri (2 kiÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸i / 600 TL)'**
  String get drawerSmartSuggestionShortcut;

  /// Auto metadata for drawerAccount
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get drawerAccount;

  /// Auto metadata for drawerMyFavorites
  ///
  /// In tr, this message translates to:
  /// **'Favorilerim'**
  String get drawerMyFavorites;

  /// Auto metadata for drawerInbox
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kutusu'**
  String get drawerInbox;

  /// No description provided for @drawerInboxWithCount.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kutusu ({count})'**
  String drawerInboxWithCount(int count);

  /// Auto metadata for drawerMySuggestions
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“nerilerim'**
  String get drawerMySuggestions;

  /// Auto metadata for drawerSuspendedMeals
  ///
  /// In tr, this message translates to:
  /// **'AskÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±da'**
  String get drawerSuspendedMeals;

  /// Auto metadata for drawerLegalAndTrust
  ///
  /// In tr, this message translates to:
  /// **'Yasal ve GÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ven'**
  String get drawerLegalAndTrust;

  /// Auto metadata for budgetComboEntryTitle
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§em ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸u kadar'**
  String get budgetComboEntryTitle;

  /// Auto metadata for budgetComboLocationNotSelected
  ///
  /// In tr, this message translates to:
  /// **'Konum seÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ilmedi'**
  String get budgetComboLocationNotSelected;

  /// Auto metadata for budgetComboBudgetLabel
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§e (TL)'**
  String get budgetComboBudgetLabel;

  /// Auto metadata for budgetComboPartySizeLabel
  ///
  /// In tr, this message translates to:
  /// **'KiÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸i'**
  String get budgetComboPartySizeLabel;

  /// Auto metadata for budgetComboCategoryOptionalLabel
  ///
  /// In tr, this message translates to:
  /// **'Kategori (opsiyonel)'**
  String get budgetComboCategoryOptionalLabel;

  /// Auto metadata for budgetComboSeeSuggestions
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“nerileri GÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶r'**
  String get budgetComboSeeSuggestions;

  /// Auto metadata for budgetComboAllCategories
  ///
  /// In tr, this message translates to:
  /// **'TÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼m kategoriler'**
  String get budgetComboAllCategories;

  /// Auto metadata for budgetComboCategoryCafe
  ///
  /// In tr, this message translates to:
  /// **'Kafe'**
  String get budgetComboCategoryCafe;

  /// Auto metadata for budgetComboCategoryRestaurant
  ///
  /// In tr, this message translates to:
  /// **'Restoran'**
  String get budgetComboCategoryRestaurant;

  /// Auto metadata for budgetComboCategoryDessert
  ///
  /// In tr, this message translates to:
  /// **'TatlÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±cÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get budgetComboCategoryDessert;

  /// Auto metadata for budgetComboCategoryBreakfast
  ///
  /// In tr, this message translates to:
  /// **'KahvaltÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get budgetComboCategoryBreakfast;

  /// Auto metadata for budgetComboCategoryFishMeat
  ///
  /// In tr, this message translates to:
  /// **'BalÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±k / Et'**
  String get budgetComboCategoryFishMeat;

  /// Auto metadata for budgetComboCategoryVenue
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get budgetComboCategoryVenue;

  /// Auto metadata for budgetComboResultsTitle
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§e Kombinleri'**
  String get budgetComboResultsTitle;

  /// Auto metadata for budgetComboMissingInfoTitle
  ///
  /// In tr, this message translates to:
  /// **'Eksik bilgi'**
  String get budgetComboMissingInfoTitle;

  /// Auto metadata for budgetComboMissingInfoDescription
  ///
  /// In tr, this message translates to:
  /// **'LÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tfen bÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§e ve konum bilgisini girin.'**
  String get budgetComboMissingInfoDescription;

  /// Auto metadata for budgetComboNoResultsTitle
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼z uygun kombin yok'**
  String get budgetComboNoResultsTitle;

  /// Auto metadata for budgetComboNoResultsDescription
  ///
  /// In tr, this message translates to:
  /// **'BÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§eyi artÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±rmayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± ya da kiÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸i sayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±sÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± azaltmayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± deneyin.'**
  String get budgetComboNoResultsDescription;

  /// Auto metadata for budgetComboAdjustCriteriaTitle
  ///
  /// In tr, this message translates to:
  /// **'Kriter deÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tir'**
  String get budgetComboAdjustCriteriaTitle;

  /// Auto metadata for budgetComboDefaultAction
  ///
  /// In tr, this message translates to:
  /// **'VarsayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±lan'**
  String get budgetComboDefaultAction;

  /// Auto metadata for budgetComboRadiusDistrictScope
  ///
  /// In tr, this message translates to:
  /// **'YakÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nlÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±k filtresi ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ehir/ilÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§e dÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼zeyinde uygulanÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±r.'**
  String get budgetComboRadiusDistrictScope;

  /// No description provided for @budgetComboRadiusTarget.
  ///
  /// In tr, this message translates to:
  /// **'YakÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nlÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±k hedefi: {km} km'**
  String budgetComboRadiusTarget(String km);

  /// Auto metadata for budgetComboWeightDistance
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get budgetComboWeightDistance;

  /// Auto metadata for budgetComboWeightPrice
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get budgetComboWeightPrice;

  /// Auto metadata for budgetComboWeightRating
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get budgetComboWeightRating;

  /// Auto metadata for budgetComboFallbackSortHint
  ///
  /// In tr, this message translates to:
  /// **'Mesafe/puan verisi yoksa sÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ralama fiyata gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶re yapÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±lÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±r.'**
  String get budgetComboFallbackSortHint;

  /// Auto metadata for budgetComboBestComboTitle
  ///
  /// In tr, this message translates to:
  /// **'En uygun kombin'**
  String get budgetComboBestComboTitle;

  /// Auto metadata for budgetComboTagTop
  ///
  /// In tr, this message translates to:
  /// **'Top'**
  String get budgetComboTagTop;

  /// Auto metadata for budgetComboOtherSuggestionsTitle
  ///
  /// In tr, this message translates to:
  /// **'DiÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸er ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶neriler'**
  String get budgetComboOtherSuggestionsTitle;

  /// No description provided for @budgetComboRatingLabelValue.
  ///
  /// In tr, this message translates to:
  /// **'Puan {rating}'**
  String budgetComboRatingLabelValue(String rating);

  /// Auto metadata for budgetComboBestTag
  ///
  /// In tr, this message translates to:
  /// **'En uygun'**
  String get budgetComboBestTag;

  /// Auto metadata for budgetComboMainItemLabel
  ///
  /// In tr, this message translates to:
  /// **'Ana'**
  String get budgetComboMainItemLabel;

  /// Auto metadata for budgetComboDrinkItemLabel
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ecek'**
  String get budgetComboDrinkItemLabel;

  /// No description provided for @budgetComboTotalLabel.
  ///
  /// In tr, this message translates to:
  /// **'{price} toplam'**
  String budgetComboTotalLabel(String price);

  /// Auto metadata for budgetComboGoToBusinessAction
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letmeye git'**
  String get budgetComboGoToBusinessAction;

  /// Auto metadata for panelAccessTitle
  ///
  /// In tr, this message translates to:
  /// **'Panel EriÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸imi'**
  String get panelAccessTitle;

  /// Auto metadata for panelWebOnlyMessage
  ///
  /// In tr, this message translates to:
  /// **'Bu panel web ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼zerinden kullanÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±labilir.'**
  String get panelWebOnlyMessage;

  /// No description provided for @panelRedirectedPath.
  ///
  /// In tr, this message translates to:
  /// **'YÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nlendirilen yol: {path}'**
  String panelRedirectedPath(String path);

  /// Auto metadata for panelBackToDiscover
  ///
  /// In tr, this message translates to:
  /// **'KeÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸fet sayfasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±na dÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶n'**
  String get panelBackToDiscover;

  /// Auto metadata for notFoundTitle
  ///
  /// In tr, this message translates to:
  /// **'Sayfa BulunamadÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get notFoundTitle;

  /// Auto metadata for businessHeaderStatusClosingLabel
  ///
  /// In tr, this message translates to:
  /// **'Durum / KapanÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸'**
  String get businessHeaderStatusClosingLabel;

  /// Auto metadata for businessHeaderAveragePriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Ortalama fiyat'**
  String get businessHeaderAveragePriceLabel;

  /// Auto metadata for businessHeaderPopularItemLabel
  ///
  /// In tr, this message translates to:
  /// **'PopÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ler ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼rÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼n'**
  String get businessHeaderPopularItemLabel;

  /// Auto metadata for businessHeaderLastVerificationLabel
  ///
  /// In tr, this message translates to:
  /// **'Son doÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸rulama'**
  String get businessHeaderLastVerificationLabel;

  /// Auto metadata for businessStatusOpen
  ///
  /// In tr, this message translates to:
  /// **'AÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±k'**
  String get businessStatusOpen;

  /// Auto metadata for businessStatusClosed
  ///
  /// In tr, this message translates to:
  /// **'KapalÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get businessStatusClosed;

  /// Auto metadata for businessHeaderDirectionsAction
  ///
  /// In tr, this message translates to:
  /// **'Yol tarifi'**
  String get businessHeaderDirectionsAction;

  /// Auto metadata for chainPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Zincir'**
  String get chainPageTitle;

  /// Auto metadata for chainPageNoBranches
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Âube bulunamadÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±.'**
  String get chainPageNoBranches;

  /// Auto metadata for chainPageNearbyBranchesTitle
  ///
  /// In tr, this message translates to:
  /// **'YakÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±n ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ubeler'**
  String get chainPageNearbyBranchesTitle;

  /// Auto metadata for chainPageBranchMenuPriceHint
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Âube menÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ ve fiyatlarÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± farklÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± olabilir.'**
  String get chainPageBranchMenuPriceHint;

  /// No description provided for @chainPageBranchMoreExpensive.
  ///
  /// In tr, this message translates to:
  /// **'Bu ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ube daha pahalÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± (%{pct})'**
  String chainPageBranchMoreExpensive(String pct);

  /// No description provided for @chainPageBranchMoreAffordable.
  ///
  /// In tr, this message translates to:
  /// **'Bu ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ube daha uygun (%{pct})'**
  String chainPageBranchMoreAffordable(String pct);

  /// Auto metadata for chainPageBranchNearAverage
  ///
  /// In tr, this message translates to:
  /// **'Zincir ortalamasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±na yakÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±n'**
  String get chainPageBranchNearAverage;

  /// Auto metadata for comparePageTitle
  ///
  /// In tr, this message translates to:
  /// **'KarÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±laÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±rma'**
  String get comparePageTitle;

  /// Auto metadata for compareEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'KarÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±laÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±rma boÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸'**
  String get compareEmptyTitle;

  /// Auto metadata for compareEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme sayfalarÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ndan karÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±laÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±rmaya ekle.'**
  String get compareEmptyDescription;

  /// Auto metadata for compareBackToDiscover
  ///
  /// In tr, this message translates to:
  /// **'KeÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸fe dÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶n'**
  String get compareBackToDiscover;

  /// Auto metadata for compareBestPickAction
  ///
  /// In tr, this message translates to:
  /// **'En mantÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±klÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± seÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§imi gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶ster'**
  String get compareBestPickAction;

  /// Auto metadata for compareSuggestedBadge
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“neri'**
  String get compareSuggestedBadge;

  /// Auto metadata for compareMedianPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Median fiyat'**
  String get compareMedianPriceLabel;

  /// Auto metadata for compareVerifiedRateLabel
  ///
  /// In tr, this message translates to:
  /// **'Verified oranÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get compareVerifiedRateLabel;

  /// Auto metadata for compareLastUpdateLabel
  ///
  /// In tr, this message translates to:
  /// **'Son gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ncelleme'**
  String get compareLastUpdateLabel;

  /// Auto metadata for compareBestItemTitle
  ///
  /// In tr, this message translates to:
  /// **'Uygun item'**
  String get compareBestItemTitle;

  /// Auto metadata for compareGoToBusinessAction
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letmeye git'**
  String get compareGoToBusinessAction;

  /// Auto metadata for compareRemoveTooltip
  ///
  /// In tr, this message translates to:
  /// **'KaldÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±r'**
  String get compareRemoveTooltip;

  /// No description provided for @compareRecommendedSnack.
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“neri: {name}'**
  String compareRecommendedSnack(String name);

  /// Auto metadata for contributeDefaultBusinessName
  ///
  /// In tr, this message translates to:
  /// **'bu iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme'**
  String get contributeDefaultBusinessName;

  /// Auto metadata for contributeOpenBusinessFirst
  ///
  /// In tr, this message translates to:
  /// **'Bu katkÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± iÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§in ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nce bir iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme sayfasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± aÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§.'**
  String get contributeOpenBusinessFirst;

  /// Auto metadata for contributeUploadingProgress
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nderiliyor...'**
  String get contributeUploadingProgress;

  /// Auto metadata for contributeUploadSentSingle
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nderildi - kontrol sonrasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± menÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ye eklenecek.'**
  String get contributeUploadSentSingle;

  /// No description provided for @contributeUploadSentMultiple.
  ///
  /// In tr, this message translates to:
  /// **'{count} sayfa gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nderildi - kontrol sonrasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± menÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ye eklenecek.'**
  String contributeUploadSentMultiple(int count);

  /// Auto metadata for contributeUploadFailed
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nderim baÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸arÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±sÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±z. LÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tfen tekrar dene.'**
  String get contributeUploadFailed;

  /// Auto metadata for contributeQrDecodingProgress
  ///
  /// In tr, this message translates to:
  /// **'QR ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶zÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼lÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼yor...'**
  String get contributeQrDecodingProgress;

  /// Auto metadata for contributeQrUnreadableSentReview
  ///
  /// In tr, this message translates to:
  /// **'QR okunamadÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±. GÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶rsel inceleme iÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§in gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nderiliyor.'**
  String get contributeQrUnreadableSentReview;

  /// Auto metadata for contributeQrVerifiedRedirecting
  ///
  /// In tr, this message translates to:
  /// **'QR doÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸rulandÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±. YÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nlendiriliyorsun.'**
  String get contributeQrVerifiedRedirecting;

  /// Auto metadata for contributeQrProcessFailed
  ///
  /// In tr, this message translates to:
  /// **'QR iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸lenemedi. LÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tfen tekrar dene.'**
  String get contributeQrProcessFailed;

  /// Auto metadata for contributeExternalQrUseBusinessPage
  ///
  /// In tr, this message translates to:
  /// **'DÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ QR kodu iÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§in iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme sayfasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nda KatkÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± yap kullan.'**
  String get contributeExternalQrUseBusinessPage;

  /// Auto metadata for contributeSendingForReviewProgress
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°nceleme iÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§in gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nderiliyor...'**
  String get contributeSendingForReviewProgress;

  /// Auto metadata for contributeQrImageSentForReview
  ///
  /// In tr, this message translates to:
  /// **'QR gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶rseli gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nderildi. ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°nceleme sonrasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸leme alÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nacak.'**
  String get contributeQrImageSentForReview;

  /// Auto metadata for contributeExternalLinkSentForReview
  ///
  /// In tr, this message translates to:
  /// **'DÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ link incelemeye gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nderildi.'**
  String get contributeExternalLinkSentForReview;

  /// Auto metadata for contributeSourceCamera
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get contributeSourceCamera;

  /// Auto metadata for contributeSourceGallery
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get contributeSourceGallery;

  /// Auto metadata for contributeSelectBusinessForPriceVerification
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸rulama iÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§in ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nce bir iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme seÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§.'**
  String get contributeSelectBusinessForPriceVerification;

  /// Auto metadata for contributeSelectMenuItemToVerifyPrice
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼den tek ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼rÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼nÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ seÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ip fiyatÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± doÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸rulayabilirsin.'**
  String get contributeSelectMenuItemToVerifyPrice;

  /// Auto metadata for discoveryFilterCafe
  ///
  /// In tr, this message translates to:
  /// **'Kafe'**
  String get discoveryFilterCafe;

  /// Auto metadata for discoveryFilterRestaurant
  ///
  /// In tr, this message translates to:
  /// **'Restoran'**
  String get discoveryFilterRestaurant;

  /// Auto metadata for discoveryFilterDessertPastry
  ///
  /// In tr, this message translates to:
  /// **'TatlÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± / Pastane'**
  String get discoveryFilterDessertPastry;

  /// Auto metadata for discoveryFilterBreakfast
  ///
  /// In tr, this message translates to:
  /// **'KahvaltÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get discoveryFilterBreakfast;

  /// Auto metadata for discoveryFilterFishMeat
  ///
  /// In tr, this message translates to:
  /// **'BalÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±k / Et'**
  String get discoveryFilterFishMeat;

  /// Auto metadata for discoveryFilterVenue
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get discoveryFilterVenue;

  /// Auto metadata for discoveryHomeCategoryDoner
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°nce DÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶ner'**
  String get discoveryHomeCategoryDoner;

  /// Auto metadata for discoveryHomeCategoryPide
  ///
  /// In tr, this message translates to:
  /// **'Pide'**
  String get discoveryHomeCategoryPide;

  /// Auto metadata for discoveryHomeCategoryLahmacun
  ///
  /// In tr, this message translates to:
  /// **'Lahmacun'**
  String get discoveryHomeCategoryLahmacun;

  /// Auto metadata for discoveryHomeCategoryBurger
  ///
  /// In tr, this message translates to:
  /// **'Burger'**
  String get discoveryHomeCategoryBurger;

  /// Auto metadata for discoveryHomeCategoryPizza
  ///
  /// In tr, this message translates to:
  /// **'Pizza'**
  String get discoveryHomeCategoryPizza;

  /// Auto metadata for discoveryHomeCategoryKebap
  ///
  /// In tr, this message translates to:
  /// **'Kebap'**
  String get discoveryHomeCategoryKebap;

  /// Auto metadata for discoveryHomeCategoryCorba
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¡orba'**
  String get discoveryHomeCategoryCorba;

  /// Auto metadata for discoveryHomeCategoryKahvalti
  ///
  /// In tr, this message translates to:
  /// **'KahvaltÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get discoveryHomeCategoryKahvalti;

  /// Auto metadata for discoveryHomeCategoryManti
  ///
  /// In tr, this message translates to:
  /// **'MantÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get discoveryHomeCategoryManti;

  /// Auto metadata for discoveryHomeCategoryTatli
  ///
  /// In tr, this message translates to:
  /// **'TatlÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get discoveryHomeCategoryTatli;

  /// Auto metadata for discoveryRecentSearches
  ///
  /// In tr, this message translates to:
  /// **'Son aramalar'**
  String get discoveryRecentSearches;

  /// Auto metadata for discoveryCatalogSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Katalog ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nerileri'**
  String get discoveryCatalogSuggestions;

  /// Auto metadata for feedEmptyMessage
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼z akÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ yok. Lezzet uzmanlarÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± takip ederek baÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸layabilirsin.'**
  String get feedEmptyMessage;

  /// Auto metadata for all
  ///
  /// In tr, this message translates to:
  /// **'TÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼mÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼'**
  String get all;

  /// Auto metadata for sil
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get sil;

  /// Auto metadata for favoritesCollectionLabel
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon'**
  String get favoritesCollectionLabel;

  /// Auto metadata for favoritesSavedHereSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Kaydettiklerin burada'**
  String get favoritesSavedHereSubtitle;

  /// No description provided for @favoritesSharedCollectionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'PaylaÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±lan koleksiyon: {name}'**
  String favoritesSharedCollectionSubtitle(String name);

  /// Auto metadata for favoritesSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Favorilerde ara'**
  String get favoritesSearchHint;

  /// Auto metadata for favoritesNearbyLoadingLocation
  ///
  /// In tr, this message translates to:
  /// **'YakÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ndakiler iÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§in konum alÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±yor...'**
  String get favoritesNearbyLoadingLocation;

  /// Auto metadata for favoritesNearbyFallbackOrdering
  ///
  /// In tr, this message translates to:
  /// **'Konum alÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±namadÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±. VarsayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±lan sÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ralama gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶steriliyor.'**
  String get favoritesNearbyFallbackOrdering;

  /// Auto metadata for favoritesNearbySortedByDistance
  ///
  /// In tr, this message translates to:
  /// **'YakÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ndakiler mesafeye gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶re sÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ralandÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±.'**
  String get favoritesNearbySortedByDistance;

  /// Auto metadata for favoritesCollectionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyonlar'**
  String get favoritesCollectionsTitle;

  /// Auto metadata for favoritesCreateCollectionTooltip
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon oluÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tur'**
  String get favoritesCreateCollectionTooltip;

  /// Auto metadata for favoritesShareCollectionTooltip
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyonu paylaÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸'**
  String get favoritesShareCollectionTooltip;

  /// Auto metadata for favoritesDeleteCollectionTooltip
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyonu sil'**
  String get favoritesDeleteCollectionTooltip;

  /// Auto metadata for favoritesCreatorSelectCollectionHint
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§erik ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼retici modu iÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§in ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nce bir koleksiyon seÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§.'**
  String get favoritesCreatorSelectCollectionHint;

  /// Auto metadata for favoritesCreatorCollectionTitle
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§erik ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼retici koleksiyonu'**
  String get favoritesCreatorCollectionTitle;

  /// Auto metadata for favoritesCreatorCollectionSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyonunu yayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nla, takipÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§i kazan. Reklam iÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§eriÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸i varsa etiket zorunludur.'**
  String get favoritesCreatorCollectionSubtitle;

  /// Auto metadata for favoritesPublishAction
  ///
  /// In tr, this message translates to:
  /// **'YayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nla'**
  String get favoritesPublishAction;

  /// Auto metadata for favoritesPublishVisibleSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Profilinde ve paylaÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±m baÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸lantÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±larÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nda gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶rÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼nÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼r.'**
  String get favoritesPublishVisibleSubtitle;

  /// Auto metadata for favoritesPublishPrivateSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Bu koleksiyonu sadece sen gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶rÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼rsÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼n.'**
  String get favoritesPublishPrivateSubtitle;

  /// Auto metadata for favoritesSharedCollectionTitle
  ///
  /// In tr, this message translates to:
  /// **'PaylaÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±lan koleksiyon'**
  String get favoritesSharedCollectionTitle;

  /// Auto metadata for favoritesFollowCollectionHint
  ///
  /// In tr, this message translates to:
  /// **'Bu koleksiyonu takip ederek gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ncellemeleri kaÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±rma.'**
  String get favoritesFollowCollectionHint;

  /// Auto metadata for favoritesFollowAction
  ///
  /// In tr, this message translates to:
  /// **'Takip et'**
  String get favoritesFollowAction;

  /// Auto metadata for favoritesFollowingAction
  ///
  /// In tr, this message translates to:
  /// **'Takiptesin'**
  String get favoritesFollowingAction;

  /// No description provided for @favoritesFollowersChip.
  ///
  /// In tr, this message translates to:
  /// **'TakipÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§i {count}'**
  String favoritesFollowersChip(int count);

  /// No description provided for @favoritesEngagementChip.
  ///
  /// In tr, this message translates to:
  /// **'EtkileÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸im {count}'**
  String favoritesEngagementChip(int count);

  /// Auto metadata for favoritesNewCollectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Yeni Koleksiyon'**
  String get favoritesNewCollectionTitle;

  /// Auto metadata for favoritesCollectionNameExample
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“rn: Gece dÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶neri'**
  String get favoritesCollectionNameExample;

  /// Auto metadata for favoritesCreateAction
  ///
  /// In tr, this message translates to:
  /// **'OluÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tur'**
  String get favoritesCreateAction;

  /// Auto metadata for favoritesDeleteCollectionConfirmTitle
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon silinsin mi?'**
  String get favoritesDeleteCollectionConfirmTitle;

  /// Auto metadata for favoritesDeleteCollectionConfirmBody
  ///
  /// In tr, this message translates to:
  /// **'Bu iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸lem geri alÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±namaz.'**
  String get favoritesDeleteCollectionConfirmBody;

  /// No description provided for @favoritesBusinessCollectionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'\"{businessName}\" koleksiyonlarÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String favoritesBusinessCollectionsTitle(String businessName);

  /// Auto metadata for favoritesNoCollectionYet
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼z koleksiyon yok. ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“nce koleksiyon oluÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tur.'**
  String get favoritesNoCollectionYet;

  /// Auto metadata for favoritesNewCollectionAction
  ///
  /// In tr, this message translates to:
  /// **'Yeni koleksiyon'**
  String get favoritesNewCollectionAction;

  /// Auto metadata for favoritesDisclosureSponsored
  ///
  /// In tr, this message translates to:
  /// **'Reklam'**
  String get favoritesDisclosureSponsored;

  /// Auto metadata for favoritesDisclosureOrganic
  ///
  /// In tr, this message translates to:
  /// **'Organik'**
  String get favoritesDisclosureOrganic;

  /// Auto metadata for favoritesDisclosurePrivate
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“zel'**
  String get favoritesDisclosurePrivate;

  /// No description provided for @favoritesShareText.
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy koleksiyonum: {name}\n{link}\n\nMod: YakÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ndakilerden ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶ner\nEtiket: {disclosure}'**
  String favoritesShareText(String name, String link, String disclosure);

  /// Auto metadata for favoritesAdDisclosureTitle
  ///
  /// In tr, this message translates to:
  /// **'Reklam bildirimi'**
  String get favoritesAdDisclosureTitle;

  /// Auto metadata for favoritesAdDisclosureBody
  ///
  /// In tr, this message translates to:
  /// **'Bu koleksiyonda iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ birliÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸i varsa \"Reklam\" olarak iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸aretlemek zorunludur.'**
  String get favoritesAdDisclosureBody;

  /// No description provided for @favoritesCacheStaleMessage.
  ///
  /// In tr, this message translates to:
  /// **'Veri {days} gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼n ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nce gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼ncellenmiÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸ olabilir.'**
  String favoritesCacheStaleMessage(int days);

  /// Auto metadata for favoritesAddToCollectionTooltip
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyona ekle'**
  String get favoritesAddToCollectionTooltip;

  /// Auto metadata for followingPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Takip Ettiklerim'**
  String get followingPageTitle;

  /// Auto metadata for followingPageEmpty
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼z kimseyi takip etmiyorsun.'**
  String get followingPageEmpty;

  /// Auto metadata for followingPageUnfollowAction
  ///
  /// In tr, this message translates to:
  /// **'Takibi bÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±rak'**
  String get followingPageUnfollowAction;

  /// Auto metadata for gourmetsPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Lezzet uzmanlarÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± keÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸fet'**
  String get gourmetsPageTitle;

  /// Auto metadata for gourmetsPageEmpty
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼z lezzet uzmanÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± yok.'**
  String get gourmetsPageEmpty;

  /// Auto metadata for groupRequestWizardTitle
  ///
  /// In tr, this message translates to:
  /// **'Grup YemeÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸i Talebi'**
  String get groupRequestWizardTitle;

  /// Auto metadata for groupRequestWizardEnterDetails
  ///
  /// In tr, this message translates to:
  /// **'DetaylarÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± gir'**
  String get groupRequestWizardEnterDetails;

  /// Auto metadata for groupRequestWizardCityLabel
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Âehir'**
  String get groupRequestWizardCityLabel;

  /// Auto metadata for groupRequestWizardDistrictLabel
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°lÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§e'**
  String get groupRequestWizardDistrictLabel;

  /// Auto metadata for groupRequestWizardCategoryHint
  ///
  /// In tr, this message translates to:
  /// **'Kategori (kahve, lokanta...)'**
  String get groupRequestWizardCategoryHint;

  /// Auto metadata for groupRequestWizardPartySizeLabel
  ///
  /// In tr, this message translates to:
  /// **'KiÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸i sayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±sÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get groupRequestWizardPartySizeLabel;

  /// Auto metadata for groupRequestWizardTotalBudgetLabel
  ///
  /// In tr, this message translates to:
  /// **'Toplam bÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼tÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§e (TL)'**
  String get groupRequestWizardTotalBudgetLabel;

  /// Auto metadata for groupRequestWizardNotesLabel
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get groupRequestWizardNotesLabel;

  /// Auto metadata for groupRequestWizardCreateAction
  ///
  /// In tr, this message translates to:
  /// **'Talep OluÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tur'**
  String get groupRequestWizardCreateAction;

  /// Auto metadata for groupRequestWizardInfoTitle
  ///
  /// In tr, this message translates to:
  /// **'Teklifler iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letmelerden gelir'**
  String get groupRequestWizardInfoTitle;

  /// Auto metadata for groupRequestWizardInfoDescription
  ///
  /// In tr, this message translates to:
  /// **'Talebin aÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ldÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ktan sonra iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letmeler teklif verebilir.'**
  String get groupRequestWizardInfoDescription;

  /// Auto metadata for groupRequestWizardMissingFields
  ///
  /// In tr, this message translates to:
  /// **'Eksik alan var'**
  String get groupRequestWizardMissingFields;

  /// Auto metadata for groupRequestWizardPickDateTime
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve saat seÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§'**
  String get groupRequestWizardPickDateTime;

  /// Auto metadata for groupRequestMyRequestsTitle
  ///
  /// In tr, this message translates to:
  /// **'Taleplerim'**
  String get groupRequestMyRequestsTitle;

  /// Auto metadata for groupRequestNewRequestAction
  ///
  /// In tr, this message translates to:
  /// **'Yeni Talep'**
  String get groupRequestNewRequestAction;

  /// Auto metadata for groupRequestNoRequestsTitle
  ///
  /// In tr, this message translates to:
  /// **'Talep yok'**
  String get groupRequestNoRequestsTitle;

  /// Auto metadata for groupRequestNoRequestsDescription
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°lk grup yemeÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸i talebini oluÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tur.'**
  String get groupRequestNoRequestsDescription;

  /// No description provided for @groupRequestPartyAndBudget.
  ///
  /// In tr, this message translates to:
  /// **'{party} kiÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸i ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ {budget}'**
  String groupRequestPartyAndBudget(int party, String budget);

  /// Auto metadata for groupRequestStatusOpen
  ///
  /// In tr, this message translates to:
  /// **'AÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±k'**
  String get groupRequestStatusOpen;

  /// Auto metadata for groupRequestStatusAwarded
  ///
  /// In tr, this message translates to:
  /// **'KazandÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±rÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±ldÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get groupRequestStatusAwarded;

  /// Auto metadata for groupRequestStatusClosed
  ///
  /// In tr, this message translates to:
  /// **'KapandÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get groupRequestStatusClosed;

  /// Auto metadata for groupRequestStatusCancelled
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ptal'**
  String get groupRequestStatusCancelled;

  /// Auto metadata for groupRequestDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Grup Talebi'**
  String get groupRequestDetailTitle;

  /// Auto metadata for groupRequestLinkCopied
  ///
  /// In tr, this message translates to:
  /// **'Grup linki kopyalandÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get groupRequestLinkCopied;

  /// Auto metadata for groupRequestNotFound
  ///
  /// In tr, this message translates to:
  /// **'Talep bulunamadÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±'**
  String get groupRequestNotFound;

  /// Auto metadata for groupRequestCreatedBannerTitle
  ///
  /// In tr, this message translates to:
  /// **'Talebin yayÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nda'**
  String get groupRequestCreatedBannerTitle;

  /// Auto metadata for groupRequestCreatedBannerDescription
  ///
  /// In tr, this message translates to:
  /// **'Grup linkini paylaÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸. Herkes ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶nerileri ekler, oylar.'**
  String get groupRequestCreatedBannerDescription;

  /// Auto metadata for groupRequestLinkTitle
  ///
  /// In tr, this message translates to:
  /// **'Grup linki'**
  String get groupRequestLinkTitle;

  /// Auto metadata for groupRequestCopyAction
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get groupRequestCopyAction;

  /// Auto metadata for groupRequestAddSuggestionTitle
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“neri ekle'**
  String get groupRequestAddSuggestionTitle;

  /// Auto metadata for groupRequestAddSuggestionDescription
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme seÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§, teklif ekle ve grup oylasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±n.'**
  String get groupRequestAddSuggestionDescription;

  /// Auto metadata for groupRequestAddSuggestionAction
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“neri ekle'**
  String get groupRequestAddSuggestionAction;

  /// Auto metadata for groupRequestOffersTitle
  ///
  /// In tr, this message translates to:
  /// **'Teklifler'**
  String get groupRequestOffersTitle;

  /// Auto metadata for groupRequestNoOffersTitle
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼z teklif yok'**
  String get groupRequestNoOffersTitle;

  /// Auto metadata for groupRequestNoOffersDescription
  ///
  /// In tr, this message translates to:
  /// **'Teklifler geldiÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸inde burada gÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶rÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼necek.'**
  String get groupRequestNoOffersDescription;

  /// Auto metadata for groupRequestBusinessFallback
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme'**
  String get groupRequestBusinessFallback;

  /// Auto metadata for groupRequestTopContributorBadge
  ///
  /// In tr, this message translates to:
  /// **'Grubu en iyi besleyen'**
  String get groupRequestTopContributorBadge;

  /// No description provided for @groupRequestOfferPriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Teklif: {price}'**
  String groupRequestOfferPriceLabel(String price);

  /// Auto metadata for groupRequestUndoVoteAction
  ///
  /// In tr, this message translates to:
  /// **'Oyunu geri al'**
  String get groupRequestUndoVoteAction;

  /// Auto metadata for groupRequestVoteAction
  ///
  /// In tr, this message translates to:
  /// **'Oy ver'**
  String get groupRequestVoteAction;

  /// Auto metadata for groupRequestProcessing
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸leniyor...'**
  String get groupRequestProcessing;

  /// Auto metadata for groupRequestAcceptOfferAction
  ///
  /// In tr, this message translates to:
  /// **'Teklifi kabul et'**
  String get groupRequestAcceptOfferAction;

  /// No description provided for @groupRequestVotesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Oy: {count}'**
  String groupRequestVotesLabel(int count);

  /// Auto metadata for groupRequestSearchMinChars
  ///
  /// In tr, this message translates to:
  /// **'En az 2 karakter yaz'**
  String get groupRequestSearchMinChars;

  /// Auto metadata for groupRequestBusinessAndPriceRequired
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme ve fiyat gerekli'**
  String get groupRequestBusinessAndPriceRequired;

  /// Auto metadata for groupRequestSuggestionAdded
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“neri eklendi'**
  String get groupRequestSuggestionAdded;

  /// Auto metadata for groupRequestSearchBusinessLabel
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme ara'**
  String get groupRequestSearchBusinessLabel;

  /// Auto metadata for groupRequestSuggestIfMissing
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸letme yoksa ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶ner'**
  String get groupRequestSuggestIfMissing;

  /// Auto metadata for groupRequestTryDifferentName
  ///
  /// In tr, this message translates to:
  /// **'FarklÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± bir isim deneyin.'**
  String get groupRequestTryDifferentName;

  /// Auto metadata for groupRequestOfferTotalPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Teklif toplam fiyat (TL)'**
  String get groupRequestOfferTotalPriceLabel;

  /// Auto metadata for groupRequestNoteLabel
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get groupRequestNoteLabel;

  /// Auto metadata for groupRequestChangeAction
  ///
  /// In tr, this message translates to:
  /// **'DeÃƒÆ’Ã¢â‚¬ÂÃƒâ€¦Ã‚Â¸iÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸tir'**
  String get groupRequestChangeAction;

  /// No description provided for @groupRequestAcceptedSummary.
  ///
  /// In tr, this message translates to:
  /// **'SonuÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ seÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ildi. Toplam: {price}'**
  String groupRequestAcceptedSummary(String price);

  /// Auto metadata for groupRequestCopyResultAction
  ///
  /// In tr, this message translates to:
  /// **'SonuÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ kopyala'**
  String get groupRequestCopyResultAction;

  /// Auto metadata for heroesPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Kahramanlar'**
  String get heroesPageTitle;

  /// Auto metadata for heroesPageSubtitle
  ///
  /// In tr, this message translates to:
  /// **'AskÃƒâ€Ã‚Â±ya yemek bÃƒâ€Ã‚Â±rakanlar'**
  String get heroesPageSubtitle;

  /// Auto metadata for heroesPageEmpty
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã‚Â¼z kahraman yok.'**
  String get heroesPageEmpty;

  /// Auto metadata for heroesPageUserFallback
  ///
  /// In tr, this message translates to:
  /// **'KullanÃƒâ€Ã‚Â±cÃƒâ€Ã‚Â±'**
  String get heroesPageUserFallback;

  /// No description provided for @heroesPageDonatedMealCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} askÃƒâ€Ã‚Â±da yemek'**
  String heroesPageDonatedMealCount(int count);

  /// Auto metadata for verifyPriceIsCorrectQuestion
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doÃƒâ€Ã…Â¸ru mu?'**
  String get verifyPriceIsCorrectQuestion;

  /// Auto metadata for verifyPriceCorrectAction
  ///
  /// In tr, this message translates to:
  /// **'DoÃƒâ€Ã…Â¸ru'**
  String get verifyPriceCorrectAction;

  /// Auto metadata for verifyPriceIncorrectAction
  ///
  /// In tr, this message translates to:
  /// **'YanlÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸'**
  String get verifyPriceIncorrectAction;

  /// Auto metadata for verifyPriceCorrectPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'DoÃƒâ€Ã…Â¸ru fiyat (TL)'**
  String get verifyPriceCorrectPriceLabel;

  /// Auto metadata for verifyPriceCorrectPriceHint
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬â€œrn: 245,50'**
  String get verifyPriceCorrectPriceHint;

  /// Auto metadata for verifyPriceChooseCorrectnessFirst
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬â€œnce doÃƒâ€Ã…Â¸ru/yanlÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ seÃƒÆ’Ã‚Â§in.'**
  String get verifyPriceChooseCorrectnessFirst;

  /// Auto metadata for verifyPriceEnterValidPrice
  ///
  /// In tr, this message translates to:
  /// **'GeÃƒÆ’Ã‚Â§erli bir fiyat girin.'**
  String get verifyPriceEnterValidPrice;

  /// No description provided for @menuItemCalories.
  ///
  /// In tr, this message translates to:
  /// **'{calories} kcal'**
  String menuItemCalories(int calories);

  /// Auto metadata for menuItemAutoApprovedMessage
  ///
  /// In tr, this message translates to:
  /// **'Fiyat otomatik onaylandÃƒâ€Ã‚Â± ve menÃƒÆ’Ã‚Â¼ gÃƒÆ’Ã‚Â¼ncellendi.'**
  String get menuItemAutoApprovedMessage;

  /// No description provided for @menuItemPendingCountMessage.
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬â€œnerin alÃƒâ€Ã‚Â±ndÃƒâ€Ã‚Â±. Bu ÃƒÆ’Ã‚Â¼rÃƒÆ’Ã‚Â¼n iÃƒÆ’Ã‚Â§in {count} ÃƒÆ’Ã‚Â¶neri sÃƒâ€Ã‚Â±rada.'**
  String menuItemPendingCountMessage(int count);

  /// Auto metadata for menuItemPendingSingleMessage
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬â€œnerin alÃƒâ€Ã‚Â±ndÃƒâ€Ã‚Â±, onay bekliyor.'**
  String get menuItemPendingSingleMessage;

  /// Auto metadata for menuItemOnsiteVerifiedPrioritizedMessage
  ///
  /// In tr, this message translates to:
  /// **'TeÃƒâ€¦Ã…Â¸ekkÃƒÆ’Ã‚Â¼rler. Mekandan doÃƒâ€Ã…Â¸rulama sinyali alÃƒâ€Ã‚Â±ndÃƒâ€Ã‚Â±, ÃƒÆ’Ã‚Â¶nerin ÃƒÆ’Ã‚Â¶nceliklendirildi.'**
  String get menuItemOnsiteVerifiedPrioritizedMessage;

  /// Auto metadata for menuPhotoWarningDark
  ///
  /// In tr, this message translates to:
  /// **'karanlÃƒâ€Ã‚Â±k'**
  String get menuPhotoWarningDark;

  /// Auto metadata for menuPhotoWarningBlurry
  ///
  /// In tr, this message translates to:
  /// **'bulanÃƒâ€Ã‚Â±k'**
  String get menuPhotoWarningBlurry;

  /// Auto metadata for menuContributionLevelLabel
  ///
  /// In tr, this message translates to:
  /// **'KatkÃƒâ€Ã‚Â± Seviyesi'**
  String get menuContributionLevelLabel;

  /// Auto metadata for menuScoreUpdated
  ///
  /// In tr, this message translates to:
  /// **'PuanÃƒâ€Ã‚Â±n gÃƒÆ’Ã‚Â¼ncellendi'**
  String get menuScoreUpdated;

  /// No description provided for @menuLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level}'**
  String menuLevel(int level);

  /// No description provided for @menuXpValue.
  ///
  /// In tr, this message translates to:
  /// **'{xp} XP'**
  String menuXpValue(int xp);

  /// No description provided for @menuSelectedVariantLabel.
  ///
  /// In tr, this message translates to:
  /// **'SeÃƒÆ’Ã‚Â§ili varyant: {label} ({price})'**
  String menuSelectedVariantLabel(String label, String price);

  /// No description provided for @menuPriceHistoryCurrent.
  ///
  /// In tr, this message translates to:
  /// **'{current} > {source}'**
  String menuPriceHistoryCurrent(String current, String source);

  /// No description provided for @menuPriceHistoryTransition.
  ///
  /// In tr, this message translates to:
  /// **'{previous} > {current} > {source}'**
  String menuPriceHistoryTransition(
    String previous,
    String current,
    String source,
  );

  /// No description provided for @menuPriceHistoryMeta.
  ///
  /// In tr, this message translates to:
  /// **'{relative} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ {date}{delta}'**
  String menuPriceHistoryMeta(String relative, String date, String delta);

  /// Auto metadata for inboxTitle
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kutusu'**
  String get inboxTitle;

  /// Auto metadata for inboxMarkAllRead
  ///
  /// In tr, this message translates to:
  /// **'TÃƒÆ’Ã‚Â¼mÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼ okundu iÃƒâ€¦Ã…Â¸aretle'**
  String get inboxMarkAllRead;

  /// Auto metadata for inboxEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Bildirim yok'**
  String get inboxEmptyTitle;

  /// Auto metadata for inboxEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Fiyat ÃƒÆ’Ã‚Â¶nerisi, claim, rapor ve yorum cevabÃƒâ€Ã‚Â± bildirimleri burada gÃƒÆ’Ã‚Â¶rÃƒÆ’Ã‚Â¼necek.'**
  String get inboxEmptyDescription;

  /// No description provided for @inboxXpGain.
  ///
  /// In tr, this message translates to:
  /// **'+{xp} XP'**
  String inboxXpGain(int xp);

  /// No description provided for @inboxNewLevel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni seviye: {level}'**
  String inboxNewLevel(int level);

  /// No description provided for @inboxLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye: {level}'**
  String inboxLevel(int level);

  /// Auto metadata for inboxNow
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€¦Ã‚Âimdi'**
  String get inboxNow;

  /// Auto metadata for inboxReengagementTitle
  ///
  /// In tr, this message translates to:
  /// **'Seni ÃƒÆ’Ã‚Â¶zledik'**
  String get inboxReengagementTitle;

  /// Auto metadata for inboxReengagementSubtitle
  ///
  /// In tr, this message translates to:
  /// **'YakÃƒâ€Ã‚Â±ndaki yeni menÃƒÆ’Ã‚Â¼lere gÃƒÆ’Ã‚Â¶z at.'**
  String get inboxReengagementSubtitle;

  /// Auto metadata for inboxRecentBusinessClosedTitle
  ///
  /// In tr, this message translates to:
  /// **'Son baktÃƒâ€Ã‚Â±Ãƒâ€Ã…Â¸Ãƒâ€Ã‚Â±n iÃƒâ€¦Ã…Â¸letme kapandÃƒâ€Ã‚Â± gÃƒÆ’Ã‚Â¶rÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼yor'**
  String get inboxRecentBusinessClosedTitle;

  /// Auto metadata for inboxRecentBusinessPriceChangedTitle
  ///
  /// In tr, this message translates to:
  /// **'Son baktÃƒâ€Ã‚Â±Ãƒâ€Ã…Â¸Ãƒâ€Ã‚Â±n yerde fiyat deÃƒâ€Ã…Â¸iÃƒâ€¦Ã…Â¸ti'**
  String get inboxRecentBusinessPriceChangedTitle;

  /// Auto metadata for inboxRecentBusinessNearbyTitle
  ///
  /// In tr, this message translates to:
  /// **'Son baktÃƒâ€Ã‚Â±Ãƒâ€Ã…Â¸Ãƒâ€Ã‚Â±n yer yakÃƒâ€Ã‚Â±nda'**
  String get inboxRecentBusinessNearbyTitle;

  /// Auto metadata for inboxRecentBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'Son baktÃƒâ€Ã‚Â±Ãƒâ€Ã…Â¸Ãƒâ€Ã‚Â±n yer'**
  String get inboxRecentBusinessTitle;

  /// Auto metadata for inboxRecentBusinessNearbyReason
  ///
  /// In tr, this message translates to:
  /// **'Sana yakÃƒâ€Ã‚Â±n olduÃƒâ€Ã…Â¸u iÃƒÆ’Ã‚Â§in ÃƒÆ’Ã‚Â¶ne alÃƒâ€Ã‚Â±ndÃƒâ€Ã‚Â±'**
  String get inboxRecentBusinessNearbyReason;

  /// Auto metadata for inboxFavoritesPriceChangedTitle
  ///
  /// In tr, this message translates to:
  /// **'Favorilerinde fiyat deÃƒâ€Ã…Â¸iÃƒâ€¦Ã…Â¸ti'**
  String get inboxFavoritesPriceChangedTitle;

  /// No description provided for @inboxFavoritesPriceChangedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Son {count} doÃƒâ€Ã…Â¸rulama'**
  String inboxFavoritesPriceChangedSubtitle(String name, int count);

  /// Auto metadata for inboxDailyTaskTitle
  ///
  /// In tr, this message translates to:
  /// **'Sana uygun bugÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼n gÃƒÆ’Ã‚Â¶revi'**
  String get inboxDailyTaskTitle;

  /// Auto metadata for inboxSegmentPriceHunter
  ///
  /// In tr, this message translates to:
  /// **'BugÃƒÆ’Ã‚Â¼n 1 fiyat doÃƒâ€Ã…Â¸rula; gÃƒÆ’Ã‚Â¼ven skorun daha hÃƒâ€Ã‚Â±zlÃƒâ€Ã‚Â± artsÃƒâ€Ã‚Â±n.'**
  String get inboxSegmentPriceHunter;

  /// Auto metadata for inboxSegmentPhotoProof
  ///
  /// In tr, this message translates to:
  /// **'BugÃƒÆ’Ã‚Â¼n 1 net menÃƒÆ’Ã‚Â¼/fotoÃƒâ€Ã…Â¸raf kanÃƒâ€Ã‚Â±tÃƒâ€Ã‚Â± ekle.'**
  String get inboxSegmentPhotoProof;

  /// Auto metadata for inboxSegmentExplorer
  ///
  /// In tr, this message translates to:
  /// **'BugÃƒÆ’Ã‚Â¼n yeni bir mekan aÃƒÆ’Ã‚Â§ ve fiyat durumunu kontrol et.'**
  String get inboxSegmentExplorer;

  /// Auto metadata for inboxSegmentSilentQuality
  ///
  /// In tr, this message translates to:
  /// **'Sessiz kalite katkÃƒâ€Ã‚Â±n gÃƒÆ’Ã‚Â¼ÃƒÆ’Ã‚Â§lÃƒÆ’Ã‚Â¼, doÃƒâ€Ã…Â¸ru veriyi sÃƒÆ’Ã‚Â¼rdÃƒÆ’Ã‚Â¼r.'**
  String get inboxSegmentSilentQuality;

  /// Auto metadata for inboxSegmentDefault
  ///
  /// In tr, this message translates to:
  /// **'BugÃƒÆ’Ã‚Â¼n kÃƒÆ’Ã‚Â¼ÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â¼k bir katkÃƒâ€Ã‚Â±yla grafiÃƒâ€Ã…Â¸ini gÃƒÆ’Ã‚Â¼ÃƒÆ’Ã‚Â§lendir.'**
  String get inboxSegmentDefault;

  /// No description provided for @inboxAlertPriceUp.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat %{pct} ÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±ktÃƒâ€Ã‚Â±'**
  String inboxAlertPriceUp(String pct);

  /// No description provided for @inboxAlertPriceDown.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat %{pct} dÃƒÆ’Ã‚Â¼Ãƒâ€¦Ã…Â¸tÃƒÆ’Ã‚Â¼'**
  String inboxAlertPriceDown(String pct);

  /// No description provided for @inboxAlertCheaperNow.
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€¦Ã‚Âuan %{pct} daha ucuz'**
  String inboxAlertCheaperNow(String pct);

  /// Auto metadata for inboxAlertAboveDistrictAverage
  ///
  /// In tr, this message translates to:
  /// **'Bu semtte ortalamanÃƒâ€Ã‚Â±n ÃƒÆ’Ã‚Â¼stÃƒÆ’Ã‚Â¼ne ÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±ktÃƒâ€Ã‚Â±'**
  String get inboxAlertAboveDistrictAverage;

  /// Auto metadata for inboxAlertBelowDistrictAverage
  ///
  /// In tr, this message translates to:
  /// **'Bu semtte ortalamanÃƒâ€Ã‚Â±n altÃƒâ€Ã‚Â±na indi'**
  String get inboxAlertBelowDistrictAverage;

  /// Auto metadata for inboxAlertTriggered
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alarmÃƒâ€Ã‚Â± tetiklendi'**
  String get inboxAlertTriggered;

  /// Auto metadata for inboxBusinessClosedArchived
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme kapandÃƒâ€Ã‚Â± (arÃƒâ€¦Ã…Â¸iv).'**
  String get inboxBusinessClosedArchived;

  /// Auto metadata for inboxBusinessMoved
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme taÃƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±ndÃƒâ€Ã‚Â±.'**
  String get inboxBusinessMoved;

  /// Auto metadata for inboxBusinessTemporarilyClosed
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme geÃƒÆ’Ã‚Â§ici kapalÃƒâ€Ã‚Â±.'**
  String get inboxBusinessTemporarilyClosed;

  /// Auto metadata for inboxBusinessStatusUpdated
  ///
  /// In tr, this message translates to:
  /// **'Durum gÃƒÆ’Ã‚Â¼ncellendi'**
  String get inboxBusinessStatusUpdated;

  /// Auto metadata for priceAlertSheetTitle
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alarmÃƒâ€Ã‚Â± oluÃƒâ€¦Ã…Â¸tur'**
  String get priceAlertSheetTitle;

  /// Auto metadata for priceAlertSheetQueryLabel
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã…â€œrÃƒÆ’Ã‚Â¼n veya arama metni'**
  String get priceAlertSheetQueryLabel;

  /// Auto metadata for priceAlertSheetMaxPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Maksimum fiyat (TL)'**
  String get priceAlertSheetMaxPriceLabel;

  /// Auto metadata for priceAlertSheetCategoryLabel
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get priceAlertSheetCategoryLabel;

  /// Auto metadata for priceAlertSheetValidationError
  ///
  /// In tr, this message translates to:
  /// **'Arama metni ve geÃƒÆ’Ã‚Â§erli bir fiyat girin.'**
  String get priceAlertSheetValidationError;

  /// Auto metadata for priceAlertSheetSaved
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alarmÃƒâ€Ã‚Â± kaydedildi.'**
  String get priceAlertSheetSaved;

  /// Auto metadata for achievementStatusUnlocked
  ///
  /// In tr, this message translates to:
  /// **'Durum: AÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±k'**
  String get achievementStatusUnlocked;

  /// Auto metadata for achievementStatusLocked
  ///
  /// In tr, this message translates to:
  /// **'Durum: Kilitli'**
  String get achievementStatusLocked;

  /// Auto metadata for profileGuestUser
  ///
  /// In tr, this message translates to:
  /// **'Misafir'**
  String get profileGuestUser;

  /// Auto metadata for profileIdentitySupportMessage
  ///
  /// In tr, this message translates to:
  /// **'TopluluÃƒâ€Ã…Â¸a katkÃƒâ€Ã‚Â± yaparak profilini gÃƒÆ’Ã‚Â¼ÃƒÆ’Ã‚Â§lendirebilirsin.'**
  String get profileIdentitySupportMessage;

  /// Auto metadata for profileAlertsTab
  ///
  /// In tr, this message translates to:
  /// **'Alarmlar'**
  String get profileAlertsTab;

  /// Auto metadata for profileFeedTab
  ///
  /// In tr, this message translates to:
  /// **'AkÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸'**
  String get profileFeedTab;

  /// Auto metadata for profileLoginToSeeContributions
  ///
  /// In tr, this message translates to:
  /// **'KatkÃƒâ€Ã‚Â±larÃƒâ€Ã‚Â±nÃƒâ€Ã‚Â± ve istatistiklerini gÃƒÆ’Ã‚Â¶rmek iÃƒÆ’Ã‚Â§in giriÃƒâ€¦Ã…Â¸ yap.'**
  String get profileLoginToSeeContributions;

  /// Auto metadata for profileCreatorBadgeTitle
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°ÃƒÆ’Ã‚Â§erik ÃƒÆ’Ã‚Â¼retici rozeti'**
  String get profileCreatorBadgeTitle;

  /// Auto metadata for profileCreatorBadgeEnabled
  ///
  /// In tr, this message translates to:
  /// **'Profilin iÃƒÆ’Ã‚Â§erik ÃƒÆ’Ã‚Â¼retici olarak gÃƒÆ’Ã‚Â¶rÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼yor.'**
  String get profileCreatorBadgeEnabled;

  /// Auto metadata for profileCreatorBadgeDisabled
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°stersen iÃƒÆ’Ã‚Â§erik ÃƒÆ’Ã‚Â¼retici rozetini aÃƒÆ’Ã‚Â§abilirsin.'**
  String get profileCreatorBadgeDisabled;

  /// Auto metadata for profileAddSocialLinkTitle
  ///
  /// In tr, this message translates to:
  /// **'Sosyal baÃƒâ€Ã…Â¸lantÃƒâ€Ã‚Â± ekle'**
  String get profileAddSocialLinkTitle;

  /// Auto metadata for linkLabel
  ///
  /// In tr, this message translates to:
  /// **'BaÃƒâ€Ã…Â¸lantÃƒâ€Ã‚Â±'**
  String get linkLabel;

  /// Auto metadata for profileSocialLinksHint
  ///
  /// In tr, this message translates to:
  /// **'YouTube / Instagram / Facebook'**
  String get profileSocialLinksHint;

  /// Auto metadata for profileSocialSaveComingSoon
  ///
  /// In tr, this message translates to:
  /// **'Sosyal baÃƒâ€Ã…Â¸lantÃƒâ€Ã‚Â± kaydetme ÃƒÆ’Ã‚Â¶zelliÃƒâ€Ã…Â¸i yakÃƒâ€Ã‚Â±nda.'**
  String get profileSocialSaveComingSoon;

  /// Auto metadata for profileStatsTitle
  ///
  /// In tr, this message translates to:
  /// **'Profil istatistikleri'**
  String get profileStatsTitle;

  /// Auto metadata for profileCommunityTrustTitle
  ///
  /// In tr, this message translates to:
  /// **'Topluluk gÃƒÆ’Ã‚Â¼veni'**
  String get profileCommunityTrustTitle;

  /// Auto metadata for profileCalculating
  ///
  /// In tr, this message translates to:
  /// **'HesaplanÃƒâ€Ã‚Â±yor...'**
  String get profileCalculating;

  /// No description provided for @profileTrustScorePercent.
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã‚Â¼ven skoru: %{score}'**
  String profileTrustScorePercent(int score);

  /// No description provided for @profileLevelXp.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Toplam {xp} XP'**
  String profileLevelXp(int level, int xp);

  /// Auto metadata for profileMyAchievementsTitle
  ///
  /// In tr, this message translates to:
  /// **'BaÃƒâ€¦Ã…Â¸arÃƒâ€Ã‚Â± rozetlerim'**
  String get profileMyAchievementsTitle;

  /// Auto metadata for profileNoAchievementYet
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã‚Â¼z rozet kazanmadÃƒâ€Ã‚Â±n.'**
  String get profileNoAchievementYet;

  /// Auto metadata for profileAlertsLoginRequired
  ///
  /// In tr, this message translates to:
  /// **'AlarmlarÃƒâ€Ã‚Â± gÃƒÆ’Ã‚Â¶rmek iÃƒÆ’Ã‚Â§in giriÃƒâ€¦Ã…Â¸ yap.'**
  String get profileAlertsLoginRequired;

  /// Auto metadata for profileAlertsEmpty
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã‚Â¼z alarm bildirimi yok.'**
  String get profileAlertsEmpty;

  /// Auto metadata for profileFeedLoginRequired
  ///
  /// In tr, this message translates to:
  /// **'AkÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â± gÃƒÆ’Ã‚Â¶rmek iÃƒÆ’Ã‚Â§in giriÃƒâ€¦Ã…Â¸ yap.'**
  String get profileFeedLoginRequired;

  /// Auto metadata for profileFeedEmpty
  ///
  /// In tr, this message translates to:
  /// **'AkÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ta henÃƒÆ’Ã‚Â¼z iÃƒÆ’Ã‚Â§erik yok.'**
  String get profileFeedEmpty;

  /// Auto metadata for profileFeedEventPriceVerified
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doÃƒâ€Ã…Â¸rulandÃƒâ€Ã‚Â±'**
  String get profileFeedEventPriceVerified;

  /// Auto metadata for profileFeedEventMenuUpdated
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÆ’Ã‚Â¼ gÃƒÆ’Ã‚Â¼ncellendi'**
  String get profileFeedEventMenuUpdated;

  /// Auto metadata for profileFeedEventSponsored
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu gÃƒÆ’Ã‚Â¼ncelleme'**
  String get profileFeedEventSponsored;

  /// Auto metadata for profileDailyTaskTitle
  ///
  /// In tr, this message translates to:
  /// **'BugÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼n gÃƒÆ’Ã‚Â¶revi'**
  String get profileDailyTaskTitle;

  /// Auto metadata for profileDailyTaskCompleted
  ///
  /// In tr, this message translates to:
  /// **'TamamlandÃƒâ€Ã‚Â±'**
  String get profileDailyTaskCompleted;

  /// Auto metadata for profileSegmentHintPriceHunter
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doÃƒâ€Ã…Â¸rulama tarafÃƒâ€Ã‚Â±nda gÃƒÆ’Ã‚Â¼ÃƒÆ’Ã‚Â§lÃƒÆ’Ã‚Â¼sÃƒÆ’Ã‚Â¼n; bugÃƒÆ’Ã‚Â¼n tek bir ÃƒÆ’Ã‚Â¼rÃƒÆ’Ã‚Â¼n doÃƒâ€Ã…Â¸rulamasÃƒâ€Ã‚Â± yeterli.'**
  String get profileSegmentHintPriceHunter;

  /// Auto metadata for profileSegmentHintPhotoProof
  ///
  /// In tr, this message translates to:
  /// **'KanÃƒâ€Ã‚Â±t odaklÃƒâ€Ã‚Â± gidiyorsun; net bir menÃƒÆ’Ã‚Â¼ fotoÃƒâ€Ã…Â¸rafÃƒâ€Ã‚Â± etkiyi artÃƒâ€Ã‚Â±rÃƒâ€Ã‚Â±r.'**
  String get profileSegmentHintPhotoProof;

  /// Auto metadata for profileSegmentHintExplorer
  ///
  /// In tr, this message translates to:
  /// **'KeÃƒâ€¦Ã…Â¸if odaklÃƒâ€Ã‚Â±sÃƒâ€Ã‚Â±n; yeni bir iÃƒâ€¦Ã…Â¸letmeyi kontrol etmek gÃƒÆ’Ã‚Â¶revi hÃƒâ€Ã‚Â±zlandÃƒâ€Ã‚Â±rÃƒâ€Ã‚Â±r.'**
  String get profileSegmentHintExplorer;

  /// Auto metadata for profileSegmentHintDefault
  ///
  /// In tr, this message translates to:
  /// **'KÃƒÆ’Ã‚Â¼ÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â¼k ama doÃƒâ€Ã…Â¸ru katkÃƒâ€Ã‚Â±lar gÃƒÆ’Ã‚Â¼ven grafiÃƒâ€Ã…Â¸ini en hÃƒâ€Ã‚Â±zlÃƒâ€Ã‚Â± bÃƒÆ’Ã‚Â¼yÃƒÆ’Ã‚Â¼tÃƒÆ’Ã‚Â¼r.'**
  String get profileSegmentHintDefault;

  /// Auto metadata for profileStatReviews
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get profileStatReviews;

  /// Auto metadata for profileStatHelpfulVotes
  ///
  /// In tr, this message translates to:
  /// **'FaydalÃƒâ€Ã‚Â± oy'**
  String get profileStatHelpfulVotes;

  /// Auto metadata for profileStatFavorites
  ///
  /// In tr, this message translates to:
  /// **'Favori'**
  String get profileStatFavorites;

  /// Auto metadata for profileStatContributions
  ///
  /// In tr, this message translates to:
  /// **'KatkÃƒâ€Ã‚Â±'**
  String get profileStatContributions;

  /// Auto metadata for profileStatVisits
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret'**
  String get profileStatVisits;

  /// Auto metadata for profileLatestAchievementTitle
  ///
  /// In tr, this message translates to:
  /// **'Son kazanÃƒâ€Ã‚Â±lan baÃƒâ€¦Ã…Â¸arÃƒâ€Ã‚Â±'**
  String get profileLatestAchievementTitle;

  /// No description provided for @profileAlertCurrentPrice.
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã‚Â¼ncel fiyat: {price} TL'**
  String profileAlertCurrentPrice(String price);

  /// No description provided for @profileAlertPriceChanged.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat deÃƒâ€Ã…Â¸iÃƒâ€¦Ã…Â¸ti: {previous} ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ {current} TL'**
  String profileAlertPriceChanged(String previous, String current);

  /// Auto metadata for profileSegmentPriceHunter
  ///
  /// In tr, this message translates to:
  /// **'Fiyat avcÃƒâ€Ã‚Â±sÃƒâ€Ã‚Â±'**
  String get profileSegmentPriceHunter;

  /// Auto metadata for profileSegmentExplorer
  ///
  /// In tr, this message translates to:
  /// **'KaÃƒâ€¦Ã…Â¸if'**
  String get profileSegmentExplorer;

  /// Auto metadata for profileSegmentPhotoProof
  ///
  /// In tr, this message translates to:
  /// **'FotoÃƒâ€Ã…Â¸raf kanÃƒâ€Ã‚Â±tÃƒâ€Ã‚Â±'**
  String get profileSegmentPhotoProof;

  /// Auto metadata for profileSegmentBalanced
  ///
  /// In tr, this message translates to:
  /// **'Dengeli'**
  String get profileSegmentBalanced;

  /// Auto metadata for profileMoatSignalsTitle
  ///
  /// In tr, this message translates to:
  /// **'DavranÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ sinyalleri'**
  String get profileMoatSignalsTitle;

  /// Auto metadata for profileSignalTrust
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã‚Â¼ven'**
  String get profileSignalTrust;

  /// Auto metadata for profileSignalAccuracy
  ///
  /// In tr, this message translates to:
  /// **'DoÃƒâ€Ã…Â¸ruluk'**
  String get profileSignalAccuracy;

  /// Auto metadata for profileSignalSegment
  ///
  /// In tr, this message translates to:
  /// **'Segment'**
  String get profileSignalSegment;

  /// Auto metadata for profileSignalSilentQuality
  ///
  /// In tr, this message translates to:
  /// **'Sessiz kalite'**
  String get profileSignalSilentQuality;

  /// No description provided for @profileMoatTrustedRejectedSpam.
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã‚Â¼venilen katkÃƒâ€Ã‚Â±: {trusted} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Reddedilen: {rejected} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Spam sinyali: {spam}'**
  String profileMoatTrustedRejectedSpam(int trusted, int rejected, int spam);

  /// No description provided for @profileMoatBehaviorSummary.
  ///
  /// In tr, this message translates to:
  /// **'DavranÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸: fiyat {price}, keÃƒâ€¦Ã…Â¸if {discovery}, fotoÃƒâ€Ã…Â¸raf {photo}'**
  String profileMoatBehaviorSummary(int price, int discovery, int photo);

  /// Auto metadata for profileMoatSilentQualityHint
  ///
  /// In tr, this message translates to:
  /// **'Sessiz kalite katkÃƒâ€Ã‚Â±cÃƒâ€Ã‚Â±sÃƒâ€Ã‚Â±: Az konuÃƒâ€¦Ã…Â¸up doÃƒâ€Ã…Â¸ru katkÃƒâ€Ã‚Â± yapÃƒâ€Ã‚Â±yorsun.'**
  String get profileMoatSilentQualityHint;

  /// Auto metadata for businessReviewsCommunityExperiences
  ///
  /// In tr, this message translates to:
  /// **'TopluluÃƒâ€Ã…Â¸un deneyimleri'**
  String get businessReviewsCommunityExperiences;

  /// Auto metadata for businessReviewsOwnerCanModerate
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme sahibi uygun olmayan yorumlarÃƒâ€Ã‚Â± yÃƒÆ’Ã‚Â¶netebilir.'**
  String get businessReviewsOwnerCanModerate;

  /// Auto metadata for businessReviewsOwnersCanOnlyReply
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme sahipleri yalnÃƒâ€Ã‚Â±zca yorumlara cevap verebilir.'**
  String get businessReviewsOwnersCanOnlyReply;

  /// Auto metadata for sortNewest
  ///
  /// In tr, this message translates to:
  /// **'En yeni'**
  String get sortNewest;

  /// Auto metadata for sortMostHelpful
  ///
  /// In tr, this message translates to:
  /// **'En faydalÃƒâ€Ã‚Â±'**
  String get sortMostHelpful;

  /// No description provided for @businessReviewsQualityLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kalite skoru: {score}'**
  String businessReviewsQualityLabel(String score);

  /// No description provided for @helpfulCount.
  ///
  /// In tr, this message translates to:
  /// **'FaydalÃƒâ€Ã‚Â± ({count})'**
  String helpfulCount(int count);

  /// Auto metadata for businessReviewsEmpty
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã‚Â¼z yorum yok.'**
  String get businessReviewsEmpty;

  /// Auto metadata for reviewCreateRatingLabel
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get reviewCreateRatingLabel;

  /// Auto metadata for reviewCreateOptionalTitleLabel
  ///
  /// In tr, this message translates to:
  /// **'BaÃƒâ€¦Ã…Â¸lÃƒâ€Ã‚Â±k (isteÃƒâ€Ã…Â¸e baÃƒâ€Ã…Â¸lÃƒâ€Ã‚Â±)'**
  String get reviewCreateOptionalTitleLabel;

  /// Auto metadata for reviewCreateContentRequired
  ///
  /// In tr, this message translates to:
  /// **'Yorum boÃƒâ€¦Ã…Â¸ olamaz.'**
  String get reviewCreateContentRequired;

  /// Auto metadata for reviewCreateSubmitted
  ///
  /// In tr, this message translates to:
  /// **'Yorum gÃƒÆ’Ã‚Â¶nderildi.'**
  String get reviewCreateSubmitted;

  /// Auto metadata for reviewCreateErrorNewAccountRateLimited
  ///
  /// In tr, this message translates to:
  /// **'Yeni hesaplar iÃƒÆ’Ã‚Â§in gÃƒÆ’Ã‚Â¼nlÃƒÆ’Ã‚Â¼k yorum limiti doldu.'**
  String get reviewCreateErrorNewAccountRateLimited;

  /// Auto metadata for reviewCreateErrorSameBusinessCooldown
  ///
  /// In tr, this message translates to:
  /// **'AynÃƒâ€Ã‚Â± iÃƒâ€¦Ã…Â¸letme iÃƒÆ’Ã‚Â§in kÃƒâ€Ã‚Â±sa sÃƒÆ’Ã‚Â¼rede tekrar yorum gÃƒÆ’Ã‚Â¶nderemezsin.'**
  String get reviewCreateErrorSameBusinessCooldown;

  /// Auto metadata for reviewCreateErrorContainsLinkOrPhone
  ///
  /// In tr, this message translates to:
  /// **'Yorumda link veya telefon bilgisi paylaÃƒâ€¦Ã…Â¸amazsÃƒâ€Ã‚Â±n.'**
  String get reviewCreateErrorContainsLinkOrPhone;

  /// Auto metadata for reviewCreateErrorContainsProfanity
  ///
  /// In tr, this message translates to:
  /// **'Yorumda uygunsuz ifade var.'**
  String get reviewCreateErrorContainsProfanity;

  /// Auto metadata for reviewCreateErrorEmojiSpam
  ///
  /// In tr, this message translates to:
  /// **'Yorumda ÃƒÆ’Ã‚Â§ok fazla emoji var.'**
  String get reviewCreateErrorEmojiSpam;

  /// Auto metadata for quality
  ///
  /// In tr, this message translates to:
  /// **'Kalite'**
  String get quality;

  /// Auto metadata for smartFeedEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã‚Â¼z akÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ yok'**
  String get smartFeedEmptyTitle;

  /// Auto metadata for smartFeedEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri gevÃƒâ€¦Ã…Â¸etebilir ya da ilk katkÃƒâ€Ã‚Â±yÃƒâ€Ã‚Â± sen ekleyebilirsin.'**
  String get smartFeedEmptyDescription;

  /// Auto metadata for smartFeedCurationTitle
  ///
  /// In tr, this message translates to:
  /// **'KÃƒÆ’Ã‚Â¼rasyon'**
  String get smartFeedCurationTitle;

  /// Auto metadata for smartFeedCategoriesLabel
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get smartFeedCategoriesLabel;

  /// Auto metadata for smartFeedScenarioLabel
  ///
  /// In tr, this message translates to:
  /// **'Senaryo'**
  String get smartFeedScenarioLabel;

  /// No description provided for @smartFeedBudgetMax.
  ///
  /// In tr, this message translates to:
  /// **'En fazla ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Âº{amount}'**
  String smartFeedBudgetMax(String amount);

  /// Auto metadata for smartFeedUnlimited
  ///
  /// In tr, this message translates to:
  /// **'SÃƒâ€Ã‚Â±nÃƒâ€Ã‚Â±rsÃƒâ€Ã‚Â±z'**
  String get smartFeedUnlimited;

  /// No description provided for @smartFeedPreferenceHint.
  ///
  /// In tr, this message translates to:
  /// **'Tercih: {label}'**
  String smartFeedPreferenceHint(String label);

  /// No description provided for @smartFeedScenarioHint.
  ///
  /// In tr, this message translates to:
  /// **'Senaryo: {label}'**
  String smartFeedScenarioHint(String label);

  /// Auto metadata for smartFeedContextDefault
  ///
  /// In tr, this message translates to:
  /// **'BugÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼n akÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±nÃƒâ€Ã‚Â± senin ritmine gÃƒÆ’Ã‚Â¶re hazÃƒâ€Ã‚Â±rlÃƒâ€Ã‚Â±yoruz.'**
  String get smartFeedContextDefault;

  /// Auto metadata for smartFeedCategoryMeyhane
  ///
  /// In tr, this message translates to:
  /// **'Meyhane'**
  String get smartFeedCategoryMeyhane;

  /// Auto metadata for smartFeedCategoryAffordable
  ///
  /// In tr, this message translates to:
  /// **'Uygun fiyatlÃƒâ€Ã‚Â±'**
  String get smartFeedCategoryAffordable;

  /// Auto metadata for smartFeedBundleStudentFriendly
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬â€œÃƒâ€Ã…Â¸renci dostu'**
  String get smartFeedBundleStudentFriendly;

  /// Auto metadata for smartFeedBundleFirstDate
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°lk randevu'**
  String get smartFeedBundleFirstDate;

  /// Auto metadata for smartFeedBundleNightSoup
  ///
  /// In tr, this message translates to:
  /// **'Gece ÃƒÆ’Ã‚Â§orbasÃƒâ€Ã‚Â±'**
  String get smartFeedBundleNightSoup;

  /// No description provided for @smartFeedMinutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk ÃƒÆ’Ã‚Â¶nce'**
  String smartFeedMinutesAgo(int count);

  /// No description provided for @smartFeedHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} saat ÃƒÆ’Ã‚Â¶nce'**
  String smartFeedHoursAgo(int count);

  /// No description provided for @smartFeedDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} gÃƒÆ’Ã‚Â¼n ÃƒÆ’Ã‚Â¶nce'**
  String smartFeedDaysAgo(int count);

  /// Auto metadata for smartFeedEventMenu
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÆ’Ã‚Â¼'**
  String get smartFeedEventMenu;

  /// Auto metadata for smartFeedEventPrice
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get smartFeedEventPrice;

  /// Auto metadata for smartFeedEventPhoto
  ///
  /// In tr, this message translates to:
  /// **'FotoÃƒâ€Ã…Â¸raf'**
  String get smartFeedEventPhoto;

  /// Auto metadata for smartFeedEventDaily
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã‚Â¼nlÃƒÆ’Ã‚Â¼k'**
  String get smartFeedEventDaily;

  /// Auto metadata for smartFeedEventSponsor
  ///
  /// In tr, this message translates to:
  /// **'Sponsor'**
  String get smartFeedEventSponsor;

  /// Auto metadata for smartFeedFallbackPriceChanged
  ///
  /// In tr, this message translates to:
  /// **'Fiyat gÃƒÆ’Ã‚Â¼ncellendi'**
  String get smartFeedFallbackPriceChanged;

  /// Auto metadata for smartFeedFallbackPhotoAdded
  ///
  /// In tr, this message translates to:
  /// **'Yeni fotoÃƒâ€Ã…Â¸raf eklendi'**
  String get smartFeedFallbackPhotoAdded;

  /// Auto metadata for smartFeedFallbackDailyMenu
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼n menÃƒÆ’Ã‚Â¼sÃƒÆ’Ã‚Â¼'**
  String get smartFeedFallbackDailyMenu;

  /// Auto metadata for smartFeedFallbackNewContent
  ///
  /// In tr, this message translates to:
  /// **'Yeni iÃƒÆ’Ã‚Â§erik'**
  String get smartFeedFallbackNewContent;

  /// Auto metadata for smartFeedCtaGoToMenu
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÆ’Ã‚Â¼ye git'**
  String get smartFeedCtaGoToMenu;

  /// Auto metadata for smartFeedCtaOpenItem
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã…â€œrÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼ aÃƒÆ’Ã‚Â§'**
  String get smartFeedCtaOpenItem;

  /// Auto metadata for smartFeedCtaViewPhoto
  ///
  /// In tr, this message translates to:
  /// **'FotoÃƒâ€Ã…Â¸rafa bak'**
  String get smartFeedCtaViewPhoto;

  /// Auto metadata for smartFeedCtaGoToBusiness
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letmeye git'**
  String get smartFeedCtaGoToBusiness;

  /// No description provided for @smartFeedNearbyKm.
  ///
  /// In tr, this message translates to:
  /// **'YakÃƒâ€Ã‚Â±nÃƒâ€Ã‚Â±nda {km} km'**
  String smartFeedNearbyKm(String km);

  /// Auto metadata for smartFeedReasonCategoryMatch
  ///
  /// In tr, this message translates to:
  /// **'Sana uygun kategori'**
  String get smartFeedReasonCategoryMatch;

  /// Auto metadata for smartFeedReasonScenarioMatch
  ///
  /// In tr, this message translates to:
  /// **'Senin senaryon'**
  String get smartFeedReasonScenarioMatch;

  /// Auto metadata for smartFeedReasonSimilarUsers
  ///
  /// In tr, this message translates to:
  /// **'Benzer kullanÃƒâ€Ã‚Â±cÃƒâ€Ã‚Â±lar seviyor'**
  String get smartFeedReasonSimilarUsers;

  /// Auto metadata for smartFeedDayWeekend
  ///
  /// In tr, this message translates to:
  /// **'Hafta sonu'**
  String get smartFeedDayWeekend;

  /// Auto metadata for smartFeedDayWeekday
  ///
  /// In tr, this message translates to:
  /// **'Hafta iÃƒÆ’Ã‚Â§i'**
  String get smartFeedDayWeekday;

  /// Auto metadata for smartFeedTimeMorning
  ///
  /// In tr, this message translates to:
  /// **'Sabah'**
  String get smartFeedTimeMorning;

  /// Auto metadata for smartFeedTimeNoon
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬â€œÃƒâ€Ã…Â¸le'**
  String get smartFeedTimeNoon;

  /// Auto metadata for smartFeedTimeEvening
  ///
  /// In tr, this message translates to:
  /// **'AkÃƒâ€¦Ã…Â¸am'**
  String get smartFeedTimeEvening;

  /// Auto metadata for smartFeedTimeNight
  ///
  /// In tr, this message translates to:
  /// **'Gece'**
  String get smartFeedTimeNight;

  /// Auto metadata for suggestBusinessSubmitDialogTitle
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬â€œnerin alÃƒâ€Ã‚Â±ndÃƒâ€Ã‚Â± mÃƒâ€Ã‚Â±?'**
  String get suggestBusinessSubmitDialogTitle;

  /// No description provided for @suggestBusinessSubmitDialogContent.
  ///
  /// In tr, this message translates to:
  /// **'TeÃƒâ€¦Ã…Â¸ekkÃƒÆ’Ã‚Â¼rler! Ãƒâ€Ã‚Â°nceleme sonucunda iÃƒâ€¦Ã…Â¸letme yayÃƒâ€Ã‚Â±nlanacak.\n\nTakip Kodu: {code}'**
  String suggestBusinessSubmitDialogContent(String code);

  /// Auto metadata for ok
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// Auto metadata for suggestBusinessPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme Ekle'**
  String get suggestBusinessPageTitle;

  /// Auto metadata for suggestBusinessPageSubtitle
  ///
  /// In tr, this message translates to:
  /// **'BulduÃƒâ€Ã…Â¸un iÃƒâ€¦Ã…Â¸letmeyi ekle, topluluÃƒâ€Ã…Â¸a katkÃƒâ€Ã‚Â± yap. Ãƒâ€Ã‚Â°nceleme sonucunda yayÃƒâ€Ã‚Â±nlarÃƒâ€Ã‚Â±z.'**
  String get suggestBusinessPageSubtitle;

  /// Auto metadata for suggestBusinessNameLabel
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme adÃƒâ€Ã‚Â±'**
  String get suggestBusinessNameLabel;

  /// Auto metadata for requiredField
  ///
  /// In tr, this message translates to:
  /// **'Zorunlu'**
  String get requiredField;

  /// Auto metadata for suggestBusinessCategoryLabel
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get suggestBusinessCategoryLabel;

  /// Auto metadata for suggestBusinessAddressLabel
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get suggestBusinessAddressLabel;

  /// Auto metadata for suggestBusinessPhoneLabel
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get suggestBusinessPhoneLabel;

  /// Auto metadata for suggestBusinessWebsiteLabel
  ///
  /// In tr, this message translates to:
  /// **'Web sitesi'**
  String get suggestBusinessWebsiteLabel;

  /// Auto metadata for suggestBusinessDuplicateTitle
  ///
  /// In tr, this message translates to:
  /// **'Bu iÃƒâ€¦Ã…Â¸letme zaten var olabilir'**
  String get suggestBusinessDuplicateTitle;

  /// Auto metadata for suggestBusinessDuplicateFound
  ///
  /// In tr, this message translates to:
  /// **'Arama sonucunda benzer iÃƒâ€¦Ã…Â¸letmeler bulundu:'**
  String get suggestBusinessDuplicateFound;

  /// Auto metadata for suggestBusinessDuplicateConfirm
  ///
  /// In tr, this message translates to:
  /// **'Yine de yeni ÃƒÆ’Ã‚Â¶neri gÃƒÆ’Ã‚Â¶ndermek istiyor musun?'**
  String get suggestBusinessDuplicateConfirm;

  /// Auto metadata for suggestBusinessSendAnyway
  ///
  /// In tr, this message translates to:
  /// **'Yine de GÃƒÆ’Ã‚Â¶nder'**
  String get suggestBusinessSendAnyway;

  /// Auto metadata for suggestBusinessOpenAction
  ///
  /// In tr, this message translates to:
  /// **'AÃƒÆ’Ã‚Â§'**
  String get suggestBusinessOpenAction;

  /// Auto metadata for copy
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// Auto metadata for topBusinessesNotEnoughData
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã‚Â¼z yeterli veri yok.'**
  String get topBusinessesNotEnoughData;

  /// Auto metadata for topBusinessesBadgeMonth
  ///
  /// In tr, this message translates to:
  /// **'Ay'**
  String get topBusinessesBadgeMonth;

  /// Auto metadata for topBusinessesBadgeWeek
  ///
  /// In tr, this message translates to:
  /// **'Hafta'**
  String get topBusinessesBadgeWeek;

  /// Auto metadata for suspendedMealsMyClaimsTitle
  ///
  /// In tr, this message translates to:
  /// **'AskÃƒâ€Ã‚Â±da Yemeklerim'**
  String get suspendedMealsMyClaimsTitle;

  /// Auto metadata for suspendedMealsStatusCodeReady
  ///
  /// In tr, this message translates to:
  /// **'Kod hazÃƒâ€Ã‚Â±r'**
  String get suspendedMealsStatusCodeReady;

  /// Auto metadata for suspendedMealsStatusFulfilled
  ///
  /// In tr, this message translates to:
  /// **'Teslim alÃƒâ€Ã‚Â±ndÃƒâ€Ã‚Â±'**
  String get suspendedMealsStatusFulfilled;

  /// Auto metadata for suspendedMealsNoRecords
  ///
  /// In tr, this message translates to:
  /// **'KayÃƒâ€Ã‚Â±t yok.'**
  String get suspendedMealsNoRecords;

  /// Auto metadata for suspendedMealsDeliveryCode
  ///
  /// In tr, this message translates to:
  /// **'Teslim kodu'**
  String get suspendedMealsDeliveryCode;

  /// Auto metadata for suspendedMealsCodeCopied
  ///
  /// In tr, this message translates to:
  /// **'Kod kopyalandÃƒâ€Ã‚Â±'**
  String get suspendedMealsCodeCopied;

  /// Auto metadata for suspendedMealsCodeHint
  ///
  /// In tr, this message translates to:
  /// **'Restorana gidip bu kodu sÃƒÆ’Ã‚Â¶yle.'**
  String get suspendedMealsCodeHint;

  /// Auto metadata for suspendedMealsPendingReview
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°nceleniyor'**
  String get suspendedMealsPendingReview;

  /// No description provided for @suspendedMealsMonthsAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} ay ÃƒÆ’Ã‚Â¶nce'**
  String suspendedMealsMonthsAgo(int count);

  /// Auto metadata for tasteTwinTitle
  ///
  /// In tr, this message translates to:
  /// **'Damak TadÃƒâ€Ã‚Â± Ãƒâ€Ã‚Â°kizi'**
  String get tasteTwinTitle;

  /// Auto metadata for tasteTwinLoginRequired
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfayÃƒâ€Ã‚Â± gÃƒÆ’Ã‚Â¶rmek iÃƒÆ’Ã‚Â§in giriÃƒâ€¦Ã…Â¸ yapmalÃƒâ€Ã‚Â±sÃƒâ€Ã‚Â±n.'**
  String get tasteTwinLoginRequired;

  /// Auto metadata for tasteTwinSubtitle
  ///
  /// In tr, this message translates to:
  /// **'PuanlamalarÃƒâ€Ã‚Â±na gÃƒÆ’Ã‚Â¶re sana benzeyen kiÃƒâ€¦Ã…Â¸iler'**
  String get tasteTwinSubtitle;

  /// Auto metadata for tasteTwinNoMatches
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã‚Â¼z eÃƒâ€¦Ã…Â¸leÃƒâ€¦Ã…Â¸me yok.'**
  String get tasteTwinNoMatches;

  /// No description provided for @tasteTwinMatchSummary.
  ///
  /// In tr, this message translates to:
  /// **'%{similarity} uyum ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Ortak {places} yer'**
  String tasteTwinMatchSummary(int similarity, int places);

  /// Auto metadata for tasteTwinSignalHint
  ///
  /// In tr, this message translates to:
  /// **'Yorum + menÃƒÆ’Ã‚Â¼ sinyali'**
  String get tasteTwinSignalHint;

  /// Auto metadata for tasteTwinViewSuggestions
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬â€œnerileri gÃƒÆ’Ã‚Â¶r'**
  String get tasteTwinViewSuggestions;

  /// No description provided for @tasteTwinRecommendationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} ÃƒÆ’Ã‚Â¶nerileri'**
  String tasteTwinRecommendationsTitle(String name);

  /// Auto metadata for tasteTwinFollowGourmet
  ///
  /// In tr, this message translates to:
  /// **'Bu gurmeyi takip et'**
  String get tasteTwinFollowGourmet;

  /// Auto metadata for tasteTwinNoSuggestionsYet
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€¦Ã‚Âimdilik ÃƒÆ’Ã‚Â¶neri yok.'**
  String get tasteTwinNoSuggestionsYet;

  /// Auto metadata for tasteTwinWhyMatchedTitle
  ///
  /// In tr, this message translates to:
  /// **'Neden eÃƒâ€¦Ã…Â¸leÃƒâ€¦Ã…Â¸tiniz?'**
  String get tasteTwinWhyMatchedTitle;

  /// Auto metadata for tasteTwinReviewOverlapTitle
  ///
  /// In tr, this message translates to:
  /// **'Yorum ortaklÃƒâ€Ã‚Â±Ãƒâ€Ã…Â¸Ãƒâ€Ã‚Â±'**
  String get tasteTwinReviewOverlapTitle;

  /// Auto metadata for tasteTwinNoSampleYet
  ///
  /// In tr, this message translates to:
  /// **'HenÃƒÆ’Ã‚Â¼z ÃƒÆ’Ã‚Â¶rnek yok.'**
  String get tasteTwinNoSampleYet;

  /// Auto metadata for tasteTwinMenuSignalOverlapTitle
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÆ’Ã‚Â¼ sinyali ortaklÃƒâ€Ã‚Â±Ãƒâ€Ã…Â¸Ãƒâ€Ã‚Â±'**
  String get tasteTwinMenuSignalOverlapTitle;

  /// Auto metadata for tasteTwinMenuSignalOverlapHint
  ///
  /// In tr, this message translates to:
  /// **'Fiyat teyidi / fotoÃƒâ€Ã…Â¸raf beÃƒâ€Ã…Â¸enisi / fotoÃƒâ€Ã…Â¸raf ekleme sinyalleri'**
  String get tasteTwinMenuSignalOverlapHint;

  /// Auto metadata for tasteTwinDivergenceTitle
  ///
  /// In tr, this message translates to:
  /// **'Burada anlaÃƒâ€¦Ã…Â¸amadÃƒâ€Ã‚Â±nÃƒâ€Ã‚Â±z :)'**
  String get tasteTwinDivergenceTitle;

  /// No description provided for @tasteTwinRatingComparison.
  ///
  /// In tr, this message translates to:
  /// **'Sen: {myRating} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ O: {otherRating}'**
  String tasteTwinRatingComparison(int myRating, int otherRating);

  /// No description provided for @tasteTwinYouAt.
  ///
  /// In tr, this message translates to:
  /// **'Sen {value}'**
  String tasteTwinYouAt(String value);

  /// No description provided for @tasteTwinSignalComparison.
  ///
  /// In tr, this message translates to:
  /// **'Sen: +{mySignal} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ O: +{otherSignal}'**
  String tasteTwinSignalComparison(int mySignal, int otherSignal);

  /// No description provided for @tasteTwinMatchRated.
  ///
  /// In tr, this message translates to:
  /// **'EÃƒâ€¦Ã…Â¸leÃƒâ€¦Ã…Â¸men {rating} puan verdi'**
  String tasteTwinMatchRated(int rating);

  /// No description provided for @tasteTwinRatedAt.
  ///
  /// In tr, this message translates to:
  /// **'{when} {text}'**
  String tasteTwinRatedAt(String when, String text);

  /// No description provided for @tasteTwinDebugReviewAndSignal.
  ///
  /// In tr, this message translates to:
  /// **'Yorum {review}% + sinyal {signal}%'**
  String tasteTwinDebugReviewAndSignal(int review, int signal);

  /// No description provided for @tasteTwinDebugReviewOnly.
  ///
  /// In tr, this message translates to:
  /// **'Yorum {review}%'**
  String tasteTwinDebugReviewOnly(int review);

  /// No description provided for @tasteTwinDebugSignalOnly.
  ///
  /// In tr, this message translates to:
  /// **'Sinyal {signal}%'**
  String tasteTwinDebugSignalOnly(int signal);

  /// Auto metadata for tasteTwinTodayLower
  ///
  /// In tr, this message translates to:
  /// **'bugÃƒÆ’Ã‚Â¼n'**
  String get tasteTwinTodayLower;

  /// Auto metadata for tasteTwinYesterdayLower
  ///
  /// In tr, this message translates to:
  /// **'dÃƒÆ’Ã‚Â¼n'**
  String get tasteTwinYesterdayLower;

  /// Auto metadata for use
  ///
  /// In tr, this message translates to:
  /// **'Kullan'**
  String get use;

  /// Auto metadata for quickLoginTitle
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek iÃƒÆ’Ã‚Â§in giriÃƒâ€¦Ã…Â¸ yap'**
  String get quickLoginTitle;

  /// Auto metadata for quickLoginDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu iÃƒâ€¦Ã…Â¸lem iÃƒÆ’Ã‚Â§in hesap gerekiyor. GiriÃƒâ€¦Ã…Â¸ yapabilir veya Ãƒâ€¦Ã…Â¸imdi geÃƒÆ’Ã‚Â§ebilirsin.'**
  String get quickLoginDescription;

  /// Auto metadata for quickLoginAction
  ///
  /// In tr, this message translates to:
  /// **'HÃƒâ€Ã‚Â±zlÃƒâ€Ã‚Â± giriÃƒâ€¦Ã…Â¸'**
  String get quickLoginAction;

  /// Auto metadata for statusBadgeVerified
  ///
  /// In tr, this message translates to:
  /// **'DoÃƒâ€Ã…Â¸rulandÃƒâ€Ã‚Â±'**
  String get statusBadgeVerified;

  /// Auto metadata for statusBadgePending
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get statusBadgePending;

  /// Auto metadata for statusBadgeOutdated
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã‚Â¼ncel deÃƒâ€Ã…Â¸il'**
  String get statusBadgeOutdated;

  /// Auto metadata for locationPickerManualHint
  ///
  /// In tr, this message translates to:
  /// **'Manuel seÃƒÆ’Ã‚Â§imde il/ilÃƒÆ’Ã‚Â§e bazlÃƒâ€Ã‚Â± arama yapÃƒâ€Ã‚Â±lÃƒâ€Ã‚Â±r. YakÃƒâ€Ã‚Â±nÃƒâ€Ã‚Â±mdaki kalite iÃƒÆ’Ã‚Â§in yarÃƒâ€Ã‚Â±ÃƒÆ’Ã‚Â§ap (5/10/20 km) ve konum izni daha iyi sonuÃƒÆ’Ã‚Â§ verir.'**
  String get locationPickerManualHint;

  /// Auto metadata for locationPickerUseAuto
  ///
  /// In tr, this message translates to:
  /// **'Otomatik konumu kullan'**
  String get locationPickerUseAuto;

  /// Auto metadata for locationPickerMakeDefault
  ///
  /// In tr, this message translates to:
  /// **'VarsayÃƒâ€Ã‚Â±lan yap'**
  String get locationPickerMakeDefault;

  /// Auto metadata for locationPickerMakeDefaultHint
  ///
  /// In tr, this message translates to:
  /// **'SeÃƒÆ’Ã‚Â§tiÃƒâ€Ã…Â¸in konum bir sonraki aÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±lÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ta da kullanÃƒâ€Ã‚Â±lsÃƒâ€Ã‚Â±n.'**
  String get locationPickerMakeDefaultHint;

  /// Auto metadata for locationPickerRecent
  ///
  /// In tr, this message translates to:
  /// **'Son seÃƒÆ’Ã‚Â§ilenler'**
  String get locationPickerRecent;

  /// Auto metadata for locationPickerSearchDistrict
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°lÃƒÆ’Ã‚Â§e ara'**
  String get locationPickerSearchDistrict;

  /// Auto metadata for locationPickerPopularDistricts
  ///
  /// In tr, this message translates to:
  /// **'PopÃƒÆ’Ã‚Â¼ler ilÃƒÆ’Ã‚Â§eler'**
  String get locationPickerPopularDistricts;

  /// No description provided for @locationPickerBusinessCount.
  ///
  /// In tr, this message translates to:
  /// **'{city} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ {count} iÃƒâ€¦Ã…Â¸letme'**
  String locationPickerBusinessCount(String city, int count);

  /// Auto metadata for legalPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Yasal ve GÃƒÆ’Ã‚Â¼ven'**
  String get legalPageTitle;

  /// Auto metadata for legalKvkkSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'KVKK / GDPR'**
  String get legalKvkkSectionTitle;

  /// Auto metadata for legalKvkkIntro
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy kiÃƒâ€¦Ã…Â¸isel verileri yalnÃƒâ€Ã‚Â±zca hizmeti sunmak iÃƒÆ’Ã‚Â§in iÃƒâ€¦Ã…Â¸ler. AÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±k rÃƒâ€Ã‚Â±za gerektiren iÃƒâ€¦Ã…Â¸lemler iÃƒÆ’Ã‚Â§in onay alÃƒâ€Ã‚Â±nÃƒâ€Ã‚Â±r, talep halinde veriler silinir veya taÃƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±nabilir Ãƒâ€¦Ã…Â¸ekilde paylaÃƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±lÃƒâ€Ã‚Â±r.'**
  String get legalKvkkIntro;

  /// Auto metadata for legalKvkkCategoriesAndRights
  ///
  /// In tr, this message translates to:
  /// **'Veri kategorileri: profil, konum, cihaz bilgisi, kullanÃƒâ€Ã‚Â±m analitiÃƒâ€Ã…Â¸i. Haklar: eriÃƒâ€¦Ã…Â¸im, dÃƒÆ’Ã‚Â¼zeltme, silme, itiraz, taÃƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±nabilirlik.'**
  String get legalKvkkCategoriesAndRights;

  /// Auto metadata for legalPrivacyPolicy
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik PolitikasÃƒâ€Ã‚Â±'**
  String get legalPrivacyPolicy;

  /// Auto metadata for legalKvkkText
  ///
  /// In tr, this message translates to:
  /// **'KVKK Metni'**
  String get legalKvkkText;

  /// Auto metadata for legalGdprText
  ///
  /// In tr, this message translates to:
  /// **'GDPR Metni'**
  String get legalGdprText;

  /// Auto metadata for legalApplicationByEmail
  ///
  /// In tr, this message translates to:
  /// **'BaÃƒâ€¦Ã…Â¸vuru: e-posta ile talep oluÃƒâ€¦Ã…Â¸tur.'**
  String get legalApplicationByEmail;

  /// Auto metadata for legalCopyrightSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Foto Telif Bildirimi'**
  String get legalCopyrightSectionTitle;

  /// Auto metadata for legalCopyrightIntro
  ///
  /// In tr, this message translates to:
  /// **'MenÃƒÆ’Ã‚Â¼ ve mekan fotoÃƒâ€Ã…Â¸raflarÃƒâ€Ã‚Â± telif hakkÃƒâ€Ã‚Â±na tabi olabilir. Ãƒâ€Ã‚Â°hlal gÃƒÆ’Ã‚Â¶rdÃƒÆ’Ã‚Â¼Ãƒâ€Ã…Â¸ÃƒÆ’Ã‚Â¼nde Bildir > Telif ile iletebilirsin.'**
  String get legalCopyrightIntro;

  /// Auto metadata for legalCopyrightDetails
  ///
  /// In tr, this message translates to:
  /// **'Telif bildirimi iÃƒÆ’Ã‚Â§in iÃƒÆ’Ã‚Â§erik baÃƒâ€Ã…Â¸lantÃƒâ€Ã‚Â±sÃƒâ€Ã‚Â±, kanÃƒâ€Ã‚Â±t ve kÃƒâ€Ã‚Â±sa aÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±klama yeterlidir. DoÃƒâ€Ã…Â¸rulanan ihlaller iÃƒÆ’Ã‚Â§erikten kaldÃƒâ€Ã‚Â±rÃƒâ€Ã‚Â±lÃƒâ€Ã‚Â±r.'**
  String get legalCopyrightDetails;

  /// Auto metadata for legalCopyrightPolicy
  ///
  /// In tr, this message translates to:
  /// **'Telif PolitikasÃƒâ€Ã‚Â±'**
  String get legalCopyrightPolicy;

  /// Auto metadata for legalOwnershipAppealSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme SahipliÃƒâ€Ã…Â¸i Ãƒâ€Ã‚Â°tirazÃƒâ€Ã‚Â±'**
  String get legalOwnershipAppealSectionTitle;

  /// Auto metadata for legalOwnershipAppealIntro
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talebi reddedildiyse itiraz edebilirsin. Belgelerin tekrar incelenir.'**
  String get legalOwnershipAppealIntro;

  /// Auto metadata for legalOwnershipAppealRequiredInfo
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°tiraz iÃƒÆ’Ã‚Â§in gerekli bilgiler:'**
  String get legalOwnershipAppealRequiredInfo;

  /// Auto metadata for legalOwnershipAppealRequiredList
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸yeri ÃƒÆ’Ã‚Â¼nvanÃƒâ€Ã‚Â± ve vergi/ruhsat bilgisi\nÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Yetkilendirme belgesi\nÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Ãƒâ€Ã‚Â°letiÃƒâ€¦Ã…Â¸im telefonu'**
  String get legalOwnershipAppealRequiredList;

  /// Auto metadata for legalSendAppealEmail
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°tiraz e-postasÃƒâ€Ã‚Â± gÃƒÆ’Ã‚Â¶nder'**
  String get legalSendAppealEmail;

  /// Auto metadata for legalProductPrinciplesSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã…â€œrÃƒÆ’Ã‚Â¼n Ãƒâ€Ã‚Â°lkeleri'**
  String get legalProductPrinciplesSectionTitle;

  /// Auto metadata for legalDontsTitle
  ///
  /// In tr, this message translates to:
  /// **'YapÃƒâ€Ã‚Â±lmamasÃƒâ€Ã‚Â± gerekenler:'**
  String get legalDontsTitle;

  /// Auto metadata for legalDontsList
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Herkese her Ãƒâ€¦Ã…Â¸eyi aÃƒÆ’Ã‚Â§mak\nÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Sponsorlu iÃƒÆ’Ã‚Â§eriÃƒâ€Ã…Â¸i gizlemek\nÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Owner hesaba yorum silme yetkisi vermek\nÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ BÃƒÆ’Ã‚Â¼yÃƒÆ’Ã‚Â¼me iÃƒÆ’Ã‚Â§in kalite eÃƒâ€¦Ã…Â¸iÃƒâ€Ã…Â¸ini gevÃƒâ€¦Ã…Â¸etmek'**
  String get legalDontsList;

  /// No description provided for @legalPolicySummary.
  ///
  /// In tr, this message translates to:
  /// **'Politika: sponsor etiketi zorunlu={requireSponsoredLabel}, minimum sponsor gÃƒÂ¼ven={minSponsoredTrust}, owner yorum silme={ownerCanDeleteReviews}.'**
  String legalPolicySummary(
    Object requireSponsoredLabel,
    String minSponsoredTrust,
    Object ownerCanDeleteReviews,
  );

  /// Auto metadata for legalFooter
  ///
  /// In tr, this message translates to:
  /// **'GÃƒÆ’Ã‚Â¼ncel politika metinleri ve detaylar web sitesinde yayÃƒâ€Ã‚Â±mlanÃƒâ€Ã‚Â±r.'**
  String get legalFooter;

  /// No description provided for @topBusinessReviews.
  ///
  /// In tr, this message translates to:
  /// **'Yorum: {count}'**
  String topBusinessReviews(int count);

  /// Auto metadata for reportRateLimitBusiness
  ///
  /// In tr, this message translates to:
  /// **'Bu iÃƒâ€¦Ã…Â¸letme iÃƒÆ’Ã‚Â§in bugÃƒÆ’Ã‚Â¼n zaten bildirim gÃƒÆ’Ã‚Â¶nderdin.'**
  String get reportRateLimitBusiness;

  /// Auto metadata for reportRateLimitReview
  ///
  /// In tr, this message translates to:
  /// **'Bu yorum iÃƒÆ’Ã‚Â§in son 24 saatte zaten bildirim gÃƒÆ’Ã‚Â¶nderdin.'**
  String get reportRateLimitReview;

  /// Auto metadata for reportRateLimitPhoto
  ///
  /// In tr, this message translates to:
  /// **'Bu fotoÃƒâ€Ã…Â¸raf iÃƒÆ’Ã‚Â§in son 24 saatte zaten bildirim gÃƒÆ’Ã‚Â¶nderdin.'**
  String get reportRateLimitPhoto;

  /// Auto metadata for reportReasonSpam
  ///
  /// In tr, this message translates to:
  /// **'Spam / reklam'**
  String get reportReasonSpam;

  /// Auto metadata for reportReasonAbuse
  ///
  /// In tr, this message translates to:
  /// **'Hakaret / uygunsuz'**
  String get reportReasonAbuse;

  /// Auto metadata for reportReasonWrongInfo
  ///
  /// In tr, this message translates to:
  /// **'YanlÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ bilgi'**
  String get reportReasonWrongInfo;

  /// Auto metadata for reportReasonCopyright
  ///
  /// In tr, this message translates to:
  /// **'Telif ihlali'**
  String get reportReasonCopyright;

  /// Auto metadata for reportReasonIllegal
  ///
  /// In tr, this message translates to:
  /// **'Yasa dÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±'**
  String get reportReasonIllegal;

  /// Auto metadata for reportReasonWrongImage
  ///
  /// In tr, this message translates to:
  /// **'YanlÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ gÃƒÆ’Ã‚Â¶rsel'**
  String get reportReasonWrongImage;

  /// Auto metadata for reportReasonClosed
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme kapandÃƒâ€Ã‚Â±'**
  String get reportReasonClosed;

  /// Auto metadata for reportReasonMoved
  ///
  /// In tr, this message translates to:
  /// **'TaÃƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±ndÃƒâ€Ã‚Â±'**
  String get reportReasonMoved;

  /// Auto metadata for reportReasonWrongPrice
  ///
  /// In tr, this message translates to:
  /// **'Fiyat yanlÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸'**
  String get reportReasonWrongPrice;

  /// Auto metadata for reportBusinessHint
  ///
  /// In tr, this message translates to:
  /// **'ÃƒÆ’Ã¢â‚¬Â¡ok sayÃƒâ€Ã‚Â±da yanlÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ bilgi bildirimi gÃƒÆ’Ã‚Â¶rÃƒÆ’Ã‚Â¼nÃƒÆ’Ã‚Â¼rlÃƒÆ’Ã‚Â¼Ãƒâ€Ã…Â¸ÃƒÆ’Ã‚Â¼ dÃƒÆ’Ã‚Â¼Ãƒâ€¦Ã…Â¸ÃƒÆ’Ã‚Â¼rÃƒÆ’Ã‚Â¼r. Ãƒâ€Ã‚Â°Ãƒâ€¦Ã…Â¸letme sahibi doÃƒâ€Ã…Â¸ruladÃƒâ€Ã‚Â±ktan sonra tekrar yÃƒÆ’Ã‚Â¼kselir.'**
  String get reportBusinessHint;

  /// Auto metadata for reportReasonLabel
  ///
  /// In tr, this message translates to:
  /// **'Sebep'**
  String get reportReasonLabel;

  /// Auto metadata for reportCopyrightUrlLabel
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°hlal URL (fotoÃƒâ€Ã…Â¸raf baÃƒâ€Ã…Â¸lantÃƒâ€Ã‚Â±sÃƒâ€Ã‚Â±)'**
  String get reportCopyrightUrlLabel;

  /// Auto metadata for reportCopyrightOwnerLabel
  ///
  /// In tr, this message translates to:
  /// **'Hak sahibi adÃƒâ€Ã‚Â± (opsiyonel)'**
  String get reportCopyrightOwnerLabel;

  /// Auto metadata for reportCopyrightEmailLabel
  ///
  /// In tr, this message translates to:
  /// **'Hak sahibi e-posta (opsiyonel)'**
  String get reportCopyrightEmailLabel;

  /// Auto metadata for reportDetailsLabel
  ///
  /// In tr, this message translates to:
  /// **'Detaylar (opsiyonel)'**
  String get reportDetailsLabel;

  /// Auto metadata for reportSubmittedThanks
  ///
  /// In tr, this message translates to:
  /// **'TeÃƒâ€¦Ã…Â¸ekkÃƒÆ’Ã‚Â¼rler, incelenecek.'**
  String get reportSubmittedThanks;

  /// Auto metadata for reportCopyrightUrlPrefix
  ///
  /// In tr, this message translates to:
  /// **'Ãƒâ€Ã‚Â°hlal URL'**
  String get reportCopyrightUrlPrefix;

  /// Auto metadata for reportCopyrightOwnerPrefix
  ///
  /// In tr, this message translates to:
  /// **'Hak sahibi'**
  String get reportCopyrightOwnerPrefix;

  /// Auto metadata for reportCopyrightEmailPrefix
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get reportCopyrightEmailPrefix;

  /// Auto metadata for unexpectedError
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluÃƒâ€¦Ã…Â¸tu.'**
  String get unexpectedError;

  /// Auto metadata for weatherHeadlineRainy
  ///
  /// In tr, this message translates to:
  /// **'YaÃƒâ€Ã…Â¸murlu hava'**
  String get weatherHeadlineRainy;

  /// Auto metadata for weatherHeadlineSnowy
  ///
  /// In tr, this message translates to:
  /// **'SoÃƒâ€Ã…Â¸uk hava'**
  String get weatherHeadlineSnowy;

  /// Auto metadata for weatherHeadlineHot
  ///
  /// In tr, this message translates to:
  /// **'SÃƒâ€Ã‚Â±cak hava'**
  String get weatherHeadlineHot;

  /// Auto metadata for weatherHeadlineClear
  ///
  /// In tr, this message translates to:
  /// **'Hava aÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±k'**
  String get weatherHeadlineClear;

  /// Auto metadata for weatherHintRainy
  ///
  /// In tr, this message translates to:
  /// **'SÃƒâ€Ã‚Â±cak bir Ãƒâ€¦Ã…Â¸ey iyi gider'**
  String get weatherHintRainy;

  /// Auto metadata for weatherHintSnowy
  ///
  /// In tr, this message translates to:
  /// **'SÃƒâ€Ã‚Â±cak ÃƒÆ’Ã‚Â§orba iyi gider'**
  String get weatherHintSnowy;

  /// Auto metadata for weatherHintHot
  ///
  /// In tr, this message translates to:
  /// **'Serin bir Ãƒâ€¦Ã…Â¸ey iyi gider'**
  String get weatherHintHot;

  /// Auto metadata for weatherHintClear
  ///
  /// In tr, this message translates to:
  /// **'DÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸ mekan keyifli'**
  String get weatherHintClear;

  /// Auto metadata for paste
  ///
  /// In tr, this message translates to:
  /// **'YapÃ„Â±Ã…Å¸tÃ„Â±r'**
  String get paste;

  /// Auto metadata for addFirstMenuCta
  ///
  /// In tr, this message translates to:
  /// **'Ã„Â°lk menÃƒÂ¼yÃƒÂ¼ ekle'**
  String get addFirstMenuCta;

  /// Auto metadata for vatIncluded
  ///
  /// In tr, this message translates to:
  /// **'KDV dahil'**
  String get vatIncluded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
