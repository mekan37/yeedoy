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
  /// **'Canlı menüler, doğrulanmış fiyatlar'**
  String get appTagline;

  /// Auto metadata for appTaglineLine1
  ///
  /// In tr, this message translates to:
  /// **'Canlı menüler'**
  String get appTaglineLine1;

  /// Auto metadata for appTaglineLine2
  ///
  /// In tr, this message translates to:
  /// **'Dogrulanmis fiyatlar'**
  String get appTaglineLine2;

  /// Auto metadata for emptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz eklenmemis'**
  String get emptyTitle;

  /// Auto metadata for emptyRegionDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy\'da bu bölgede henüz veri yok. İstersen ilk katkıyı sen ekle.'**
  String get emptyRegionDescription;

  /// Auto metadata for webDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy - Canlı menüler, doğrulanmış fiyatlar ve akıllı keşif.'**
  String get webDescription;

  /// Auto metadata for discover
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
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
  /// **'İptal'**
  String get cancel;

  /// Auto metadata for privacy
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get privacy;

  /// Auto metadata for socialLinks
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Bağlantılar'**
  String get socialLinks;

  /// Auto metadata for logout
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// Auto metadata for contribute
  ///
  /// In tr, this message translates to:
  /// **'Katkı Yap'**
  String get contribute;

  /// Auto metadata for uploadPhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Yükle'**
  String get uploadPhoto;

  /// Auto metadata for scanQr
  ///
  /// In tr, this message translates to:
  /// **'QR Tara'**
  String get scanQr;

  /// Auto metadata for verifyPrice
  ///
  /// In tr, this message translates to:
  /// **'Fiyatı Doğrula'**
  String get verifyPrice;

  /// Auto metadata for openInBrowser
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda Aç'**
  String get openInBrowser;

  /// Auto metadata for linkPreview
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı Önizleme'**
  String get linkPreview;

  /// Auto metadata for profileSettings
  ///
  /// In tr, this message translates to:
  /// **'Profil Ayarları'**
  String get profileSettings;

  /// Auto metadata for saving
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get saving;

  /// Auto metadata for loginRequired
  ///
  /// In tr, this message translates to:
  /// **'Önce giris yapmalisin.'**
  String get loginRequired;

  /// Auto metadata for profileSaved
  ///
  /// In tr, this message translates to:
  /// **'Profil ayarları kaydedildi.'**
  String get profileSaved;

  /// Auto metadata for saveError
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme hatasi: {error}'**
  String saveError(String error);

  /// Auto metadata for namePrivacy
  ///
  /// In tr, this message translates to:
  /// **'İsim Gizliliği'**
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
  /// **'Ad Soyad Görünsün'**
  String get showFullName;

  /// Auto metadata for hideLastName
  ///
  /// In tr, this message translates to:
  /// **'Sadece Soyadı Gizle'**
  String get hideLastName;

  /// Auto metadata for hideBothNames
  ///
  /// In tr, this message translates to:
  /// **'Ad ve Soyadı Gizle'**
  String get hideBothNames;

  /// Auto metadata for preview
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
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
  /// **'Sistem (Varsayılan)'**
  String get systemDefault;

  /// Auto metadata for turkish
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// Auto metadata for english
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get english;

  /// Auto metadata for account
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get account;

  /// Auto metadata for invalidLink
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir bağlantı gir.'**
  String get invalidLink;

  /// Auto metadata for socialPreview
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Önizleme'**
  String get socialPreview;

  /// Auto metadata for pasteLinkHelper
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı yapıştır (https://...)'**
  String get pasteLinkHelper;

  /// Auto metadata for privacySocialSubtitle
  ///
  /// In tr, this message translates to:
  /// **'İsim gizliliği ve sosyal medya bağlantıları'**
  String get privacySocialSubtitle;

  /// Auto metadata for updateBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'{businessName} güncelle'**
  String updateBusinessTitle(String businessName);

  /// Auto metadata for contributeSheetSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Topluluğun menü fiyatlarını doğrulamasına yardımcı ol.'**
  String get contributeSheetSubtitle;

  /// Auto metadata for scanMenuQr
  ///
  /// In tr, this message translates to:
  /// **'Menü QR tara'**
  String get scanMenuQr;

  /// Auto metadata for scanMenuQrSubtitle
  ///
  /// In tr, this message translates to:
  /// **'QR ile anında doğrulama'**
  String get scanMenuQrSubtitle;

  /// Auto metadata for uploadPhotoSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Menünün fotoğrafını çek'**
  String get uploadPhotoSubtitle;

  /// Auto metadata for confirmPriceChange
  ///
  /// In tr, this message translates to:
  /// **'Fiyat değişimini doğrula'**
  String get confirmPriceChange;

  /// Auto metadata for confirmPriceChangeSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Güncel olmayan bir fiyatı bildir'**
  String get confirmPriceChangeSubtitle;

  /// Auto metadata for qrAction
  ///
  /// In tr, this message translates to:
  /// **'QR Aksiyonu'**
  String get qrAction;

  /// Auto metadata for embed
  ///
  /// In tr, this message translates to:
  /// **'Gömülü'**
  String get embed;

  /// Auto metadata for share
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// Share as image card button
  ///
  /// In tr, this message translates to:
  /// **'Görsel Paylaş'**
  String get shareAsImage;

  /// Share as plain link button
  ///
  /// In tr, this message translates to:
  /// **'Link Paylaş'**
  String get shareLink;

  /// Auto metadata for invalidLinkMessage
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz bağlantı'**
  String get invalidLinkMessage;

  /// Auto metadata for browserOpened
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda açıldı'**
  String get browserOpened;

  /// Auto metadata for embedFailed
  ///
  /// In tr, this message translates to:
  /// **'İçerik görüntülenemedi, tarayıcıya yönlendirdik.'**
  String get embedFailed;

  /// Auto metadata for back
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// Auto metadata for updatedDaysAgo
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce güncellendi'**
  String updatedDaysAgo(int days);

  /// Auto metadata for verifiedDaysAgo
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce doğrulandı'**
  String verifiedDaysAgo(int days);

  /// Auto metadata for distanceKm
  ///
  /// In tr, this message translates to:
  /// **'{km} km'**
  String distanceKm(num km);

  /// Estimated walking time range shown on business cards
  ///
  /// In tr, this message translates to:
  /// **'{min}-{max} dk'**
  String etaRangeMinutes(int min, int max);

  /// Auto metadata for avgSpendPerPerson
  ///
  /// In tr, this message translates to:
  /// **'Kişi başı {amount}'**
  String avgSpendPerPerson(String amount);

  /// Auto metadata for reviewsCount
  ///
  /// In tr, this message translates to:
  /// **'Yorum ({count})'**
  String reviewsCount(int count);

  /// Auto metadata for openNow
  ///
  /// In tr, this message translates to:
  /// **'Şuan açık'**
  String get openNow;

  /// Auto metadata for closedNow
  ///
  /// In tr, this message translates to:
  /// **'Şuan kapalı'**
  String get closedNow;

  /// Auto metadata for livePrices
  ///
  /// In tr, this message translates to:
  /// **'Canlı Fiyatlar'**
  String get livePrices;

  /// Auto metadata for trustScore
  ///
  /// In tr, this message translates to:
  /// **'Güven Skoru'**
  String get trustScore;

  /// Auto metadata for lastUpdated
  ///
  /// In tr, this message translates to:
  /// **'Son Güncelleme'**
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
  /// **'Doğrulandı'**
  String get verified;

  /// Auto metadata for priceVerified
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Doğrulandı'**
  String get priceVerified;

  /// Auto metadata for communityVerified
  ///
  /// In tr, this message translates to:
  /// **'Toplulukça Doğrulandı'**
  String get communityVerified;

  /// Auto metadata for confirmedByUsersToday
  ///
  /// In tr, this message translates to:
  /// **'Bugün {users} kullanıcı tarafından doğrulandı'**
  String confirmedByUsersToday(int users);

  /// Auto metadata for priceHistory
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Geçmişi'**
  String get priceHistory;

  /// Auto metadata for contributeMenuPhoto
  ///
  /// In tr, this message translates to:
  /// **'Menü Fotoğrafı Katkısı Yap'**
  String get contributeMenuPhoto;

  /// Auto metadata for verify
  ///
  /// In tr, this message translates to:
  /// **'Doğrula'**
  String get verify;

  /// Auto metadata for signatureSteaks
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkan Steakler'**
  String get signatureSteaks;

  /// Auto metadata for signatureSection
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkan {section}'**
  String signatureSection(String section);

  /// Auto metadata for spottedPriceChange
  ///
  /// In tr, this message translates to:
  /// **'Fiyat değişikliği mi fark ettin?'**
  String get spottedPriceChange;

  /// Auto metadata for spottedPriceChangeSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Bu menüyü güncelleyerek katkı sağla.'**
  String get spottedPriceChangeSubtitle;

  /// Auto metadata for updateDateUnavailable
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme tarihi yok'**
  String get updateDateUnavailable;

  /// Auto metadata for currentLocation
  ///
  /// In tr, this message translates to:
  /// **'MEVCUT KONUM'**
  String get currentLocation;

  /// Auto metadata for changeLocation
  ///
  /// In tr, this message translates to:
  /// **'Konumu Değiştir'**
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
  /// **'Bütçe'**
  String get budget;

  /// Auto metadata for freshMenuUpdates
  ///
  /// In tr, this message translates to:
  /// **'Taze Menü Güncellemeleri'**
  String get freshMenuUpdates;

  /// Auto metadata for seeAll
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get seeAll;

  /// Auto metadata for freshLinks
  ///
  /// In tr, this message translates to:
  /// **'Yeni Bağlantılar'**
  String get freshLinks;

  /// Auto metadata for discoveryNearbyTitle
  ///
  /// In tr, this message translates to:
  /// **'Yakınımda'**
  String get discoveryNearbyTitle;

  /// Auto metadata for discoveryNearbySubtitle
  ///
  /// In tr, this message translates to:
  /// **'Konumuna göre en iyi sonuçlar'**
  String get discoveryNearbySubtitle;

  /// Auto metadata for discoveryLocationSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Şehir/ilçeye göre keşfet'**
  String get discoveryLocationSubtitle;

  /// Auto metadata for nearbyVerifiedSpots
  ///
  /// In tr, this message translates to:
  /// **'Yakınındaki Mekanlar'**
  String get nearbyVerifiedSpots;

  /// Auto metadata for discoverForYou
  ///
  /// In tr, this message translates to:
  /// **'Senin için keşfet'**
  String get discoverForYou;

  /// Auto metadata for discoveryGreetingHello
  ///
  /// In tr, this message translates to:
  /// **'Merhaba {name} 👋'**
  String discoveryGreetingHello(String name);

  /// Auto metadata for discoveryGreetingHelloAnon
  ///
  /// In tr, this message translates to:
  /// **'Merhaba 👋'**
  String get discoveryGreetingHelloAnon;

  /// Short greeting shown above page titles on favorites/profile home headers
  ///
  /// In tr, this message translates to:
  /// **'Merhaba! 👋'**
  String get homeGreetingHelloExclaim;

  /// Auto metadata for discoveryGreetingSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Bugün ne yemek istersin?'**
  String get discoveryGreetingSubtitle;

  /// Auto metadata for discoveryFeaturedCategory
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkanlar'**
  String get discoveryFeaturedCategory;

  /// Auto metadata for discoveryCampaignPromoTitle
  ///
  /// In tr, this message translates to:
  /// **'Lezzetli fırsatları kaçırma! 🎉'**
  String get discoveryCampaignPromoTitle;

  /// Auto metadata for discoveryCampaignPromoSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Sana özel indirimleri keşfet.'**
  String get discoveryCampaignPromoSubtitle;

  /// Auto metadata for noNearbyVerifiedSpots
  ///
  /// In tr, this message translates to:
  /// **'Yakında doğrulanmış mekan bulunamadı'**
  String get noNearbyVerifiedSpots;

  /// Auto metadata for changeFiltersTryAgain
  ///
  /// In tr, this message translates to:
  /// **'Konumu veya filtreleri değiştirip tekrar dene.'**
  String get changeFiltersTryAgain;

  /// Auto metadata for noFreshData
  ///
  /// In tr, this message translates to:
  /// **'Henüz taze veri yok'**
  String get noFreshData;

  /// Auto metadata for freshDataWillAppear
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki menü güncellemeleri burada görünecek.'**
  String get freshDataWillAppear;

  /// Auto metadata for businessLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
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
  /// **'Diğer'**
  String get other;

  /// Auto metadata for itemsCount
  ///
  /// In tr, this message translates to:
  /// **'{count} ürün'**
  String itemsCount(int count);

  /// Auto metadata for weakConnectionQueueNotice
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı zayıf. Doğrulama sıraya alındı, çevrimiçi olunca otomatik gönderilecek.'**
  String get weakConnectionQueueNotice;

  /// Auto metadata for pendingVerificationsSent
  ///
  /// In tr, this message translates to:
  /// **'{count} bekleyen doğrulama gönderildi.'**
  String pendingVerificationsSent(int count);

  /// Auto metadata for loadMenuItemsFirst
  ///
  /// In tr, this message translates to:
  /// **'Önce menü ürünlerini yükle.'**
  String get loadMenuItemsFirst;

  /// Auto metadata for menuNotAddedYet
  ///
  /// In tr, this message translates to:
  /// **'Henüz eklenmedi'**
  String get menuNotAddedYet;

  /// Auto metadata for menuNotAddedYetDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu işletme için henüz menü eklenmemiş.'**
  String get menuNotAddedYetDescription;

  /// Auto metadata for weakConnection
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı zayıf'**
  String get weakConnection;

  /// Auto metadata for contentLoadFailedCheckInternet
  ///
  /// In tr, this message translates to:
  /// **'İçerik şu anda yüklenemedi. Varsa önbellek verisi gösterilecek. İnterneti kontrol edip tekrar dene.'**
  String get contentLoadFailedCheckInternet;

  /// Auto metadata for trustDataUnavailable
  ///
  /// In tr, this message translates to:
  /// **'Veri güveni verisi yok'**
  String get trustDataUnavailable;

  /// Auto metadata for freshnessAndTrust
  ///
  /// In tr, this message translates to:
  /// **'Veri güveni dökümü'**
  String get freshnessAndTrust;

  /// Auto metadata for menuUpdatedLabel
  ///
  /// In tr, this message translates to:
  /// **'Menü Güncellendi'**
  String get menuUpdatedLabel;

  /// Auto metadata for lastPriceVerification
  ///
  /// In tr, this message translates to:
  /// **'Son Fiyat Doğrulaması'**
  String get lastPriceVerification;

  /// Auto metadata for trustScoreLabel
  ///
  /// In tr, this message translates to:
  /// **'Güven Skoru'**
  String get trustScoreLabel;

  /// No description provided for @communityScoreDataTrustLabel.
  ///
  /// In tr, this message translates to:
  /// **'Veri güveni'**
  String get communityScoreDataTrustLabel;

  /// No description provided for @communityScoreMenuFreshnessLabel.
  ///
  /// In tr, this message translates to:
  /// **'Menü güncelliği'**
  String get communityScoreMenuFreshnessLabel;

  /// Auto metadata for last3MonthsPriceChange
  ///
  /// In tr, this message translates to:
  /// **'Son 3 Ay Fiyat Değişimi'**
  String get last3MonthsPriceChange;

  /// Auto metadata for hoursInfoUnavailable
  ///
  /// In tr, this message translates to:
  /// **'Çalışma saatleri bilgisi yok'**
  String get hoursInfoUnavailable;

  /// Auto metadata for hoursInfoMissing
  ///
  /// In tr, this message translates to:
  /// **'Saat bilgisi yok'**
  String get hoursInfoMissing;

  /// Auto metadata for addHoursHelp
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılara yardımcı olmak için çalışma saatlerini ekle.'**
  String get addHoursHelp;

  /// Auto metadata for reportHoursInfo
  ///
  /// In tr, this message translates to:
  /// **'Saat bilgisi bildir'**
  String get reportHoursInfo;

  /// Auto metadata for menus
  ///
  /// In tr, this message translates to:
  /// **'Menüler'**
  String get menus;

  /// Auto metadata for menusLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'Menüler yüklenemedi'**
  String get menusLoadFailed;

  /// Auto metadata for noMenu
  ///
  /// In tr, this message translates to:
  /// **'Menü yok'**
  String get noMenu;

  /// Auto metadata for addFirstMenuHelp
  ///
  /// In tr, this message translates to:
  /// **'İlk menüyü ekleyerek kullanıcılara yardımcı ol.'**
  String get addFirstMenuHelp;

  /// Auto metadata for crowdInfoUnavailable
  ///
  /// In tr, this message translates to:
  /// **'Yoğunluk bilgisi yok'**
  String get crowdInfoUnavailable;

  /// Auto metadata for liveCrowdLabel
  ///
  /// In tr, this message translates to:
  /// **'Anlık yoğunluk: {state}'**
  String liveCrowdLabel(String state);

  /// Auto metadata for reviewsLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar yüklenemedi'**
  String get reviewsLoadFailed;

  /// Auto metadata for noReviews
  ///
  /// In tr, this message translates to:
  /// **'Yorum yok'**
  String get noReviews;

  /// Auto metadata for leaveFirstReviewHelp
  ///
  /// In tr, this message translates to:
  /// **'İlk yorumu sen yaz.'**
  String get leaveFirstReviewHelp;

  /// Auto metadata for writeFirstReview
  ///
  /// In tr, this message translates to:
  /// **'İlk yorumu yaz'**
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
  /// **'Menü verisi yok'**
  String get menuDataUnavailable;

  /// Auto metadata for noMenuProductsYet
  ///
  /// In tr, this message translates to:
  /// **'Henüz menü ürünü yok'**
  String get noMenuProductsYet;

  /// Auto metadata for menu
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get menu;

  /// Auto metadata for featuredFromCuisine
  ///
  /// In tr, this message translates to:
  /// **'{cuisine} mutfağından öne çıkanlar'**
  String featuredFromCuisine(String cuisine);

  /// Auto metadata for weeklyPriceChange
  ///
  /// In tr, this message translates to:
  /// **'+₺50 bu hafta'**
  String get weeklyPriceChange;

  /// Auto metadata for chartPlaceholderSoon
  ///
  /// In tr, this message translates to:
  /// **'Grafik alanı (yakında)'**
  String get chartPlaceholderSoon;

  /// No description provided for @noPriceDataYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz fiyat verisi yok'**
  String get noPriceDataYet;

  /// Auto metadata for featuredCuisineSuffix
  ///
  /// In tr, this message translates to:
  /// **'mutfağından öne çıkan lezzetler'**
  String get featuredCuisineSuffix;

  /// Auto metadata for connectionProblemTryAgain
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı sorunu var, tekrar dene.'**
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
  /// **'İmkan bilgisi yok'**
  String get noAmenityInfo;

  /// Auto metadata for amenityCountLabel
  ///
  /// In tr, this message translates to:
  /// **'{count} imkan'**
  String amenityCountLabel(int count);

  /// Auto metadata for noLocationVerificationData
  ///
  /// In tr, this message translates to:
  /// **'Konum doğrulama verisi yok'**
  String get noLocationVerificationData;

  /// Auto metadata for lastLocationVerification
  ///
  /// In tr, this message translates to:
  /// **'Son konum doğrulaması'**
  String get lastLocationVerification;

  /// Auto metadata for noNewProductRecord
  ///
  /// In tr, this message translates to:
  /// **'Yeni ürün kaydı yok'**
  String get noNewProductRecord;

  /// Auto metadata for newProduct
  ///
  /// In tr, this message translates to:
  /// **'Yeni ürün'**
  String get newProduct;

  /// Auto metadata for reportInfoErrorPrefix
  ///
  /// In tr, this message translates to:
  /// **'Bildirim bilgisi hatası:'**
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
  /// **'Yan Ürünler'**
  String get tabSides;

  /// Auto metadata for tabBeverages
  ///
  /// In tr, this message translates to:
  /// **'İçecekler'**
  String get tabBeverages;

  /// Auto metadata for locationNotAvailable
  ///
  /// In tr, this message translates to:
  /// **'Konum kullanılamıyor'**
  String get locationNotAvailable;

  /// Auto metadata for sortRecommended
  ///
  /// In tr, this message translates to:
  /// **'Önerilen'**
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
  /// **'Yeni Doğrulanan'**
  String get sortNewlyVerified;

  /// Auto metadata for rankingFormulaTitle
  ///
  /// In tr, this message translates to:
  /// **'Sıralama Formülü'**
  String get rankingFormulaTitle;

  /// Auto metadata for rankingFormulaIntro
  ///
  /// In tr, this message translates to:
  /// **'Sıralama puanı şu bileşenlerden oluşur:'**
  String get rankingFormulaIntro;

  /// Auto metadata for rankingWeightDistance
  ///
  /// In tr, this message translates to:
  /// **'%30 Mesafe'**
  String get rankingWeightDistance;

  /// Auto metadata for rankingWeightAccuracy
  ///
  /// In tr, this message translates to:
  /// **'Doğruluk ağırlığı'**
  String get rankingWeightAccuracy;

  /// Auto metadata for rankingWeightEngagement
  ///
  /// In tr, this message translates to:
  /// **'Etkileşim ağırlığı'**
  String get rankingWeightEngagement;

  /// Auto metadata for rankingWeightQuality
  ///
  /// In tr, this message translates to:
  /// **'%20 Kalite (kalite skoru)'**
  String get rankingWeightQuality;

  /// Auto metadata for rankingFormulaNote
  ///
  /// In tr, this message translates to:
  /// **'Not: Puanlar düzenli olarak güncellenir.'**
  String get rankingFormulaNote;

  /// Auto metadata for minRatingLabel
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
  /// **'Şu an açık olanları öne çıkar'**
  String get prioritizeOpenNow;

  /// Auto metadata for prioritizeNewlyVerified
  ///
  /// In tr, this message translates to:
  /// **'Yeni doğrulananları öne çıkar'**
  String get prioritizeNewlyVerified;

  /// Auto metadata for reset
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
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
  /// **'Üst Seviye'**
  String get priceTierPremium;

  /// Auto metadata for tabAllItems
  ///
  /// In tr, this message translates to:
  /// **'Tüm Ürünler'**
  String get tabAllItems;

  /// Auto metadata for tabStarters
  ///
  /// In tr, this message translates to:
  /// **'Başlangıçlar'**
  String get tabStarters;

  /// Auto metadata for usersLabel
  ///
  /// In tr, this message translates to:
  /// **'kullanıcı'**
  String get usersLabel;

  /// Auto metadata for unknown
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknown;

  /// Auto metadata for today
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// Auto metadata for dayUnit
  ///
  /// In tr, this message translates to:
  /// **'gün'**
  String get dayUnit;

  /// Auto metadata for tekrarDene
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get tekrarDene;

  /// Auto metadata for vazgec
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
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
  /// **'İşleniyor...'**
  String get isleniyor;

  /// Auto metadata for onayla
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get onayla;

  /// Auto metadata for approved
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get approved;

  /// Auto metadata for tumu
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get tumu;

  /// Auto metadata for kayitBulunamadi
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı.'**
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
  /// **'Satır seç'**
  String get satirSec;

  /// Auto metadata for gonder
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
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
  /// **'Düzenle'**
  String get duzenle;

  /// Auto metadata for eminMisin
  ///
  /// In tr, this message translates to:
  /// **'Emin misin?'**
  String get eminMisin;

  /// Auto metadata for guncellendi
  ///
  /// In tr, this message translates to:
  /// **'Güncellendi.'**
  String get guncellendi;

  /// Auto metadata for reddedildi_2
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi.'**
  String get reddedildi_2;

  /// Auto metadata for sla
  ///
  /// In tr, this message translates to:
  /// **'Geri Dönüş Süresi'**
  String get sla;

  /// Auto metadata for csvDisaAktar
  ///
  /// In tr, this message translates to:
  /// **'CSV Dışa Aktar'**
  String get csvDisaAktar;

  /// Auto metadata for onaylandi
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get onaylandi;

  /// Auto metadata for yenile
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get yenile;

  /// No description provided for @decreaseQuantity.
  ///
  /// In tr, this message translates to:
  /// **'Azalt'**
  String get decreaseQuantity;

  /// No description provided for @increaseQuantity.
  ///
  /// In tr, this message translates to:
  /// **'Artır'**
  String get increaseQuantity;

  /// No description provided for @kapat.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get kapat;

  /// No description provided for @suspendedMealsEmptyDescription.
  ///
  /// In tr, this message translates to:
  /// **'Askıya aldığınız yemek planları burada görünecek.'**
  String get suspendedMealsEmptyDescription;

  /// No description provided for @ara.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get ara;

  /// Star rating tooltip label
  ///
  /// In tr, this message translates to:
  /// **'{count} yıldız'**
  String ratingLabel(int count);

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
  /// **'Önerilenler'**
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
  /// **'Neden üstte?'**
  String get whyTop;

  /// Auto metadata for quickSuggestionTitle
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Öneri'**
  String get quickSuggestionTitle;

  /// Auto metadata for quickSuggestionSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Dakikalar içinde karar ver'**
  String get quickSuggestionSubtitle;

  /// Auto metadata for quickSuggestionPreset
  ///
  /// In tr, this message translates to:
  /// **'2 kişi / ₺600'**
  String get quickSuggestionPreset;

  /// Auto metadata for whatToEatTitle
  ///
  /// In tr, this message translates to:
  /// **'Ne yesek?'**
  String get whatToEatTitle;

  /// Auto metadata for whatToEatSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Hızlı öneriler'**
  String get whatToEatSubtitle;

  /// Auto metadata for nearbyShort
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get nearbyShort;

  /// Auto metadata for affordableShort
  ///
  /// In tr, this message translates to:
  /// **'Uygun fiyat'**
  String get affordableShort;

  /// Auto metadata for quickDecisionShort
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Karar'**
  String get quickDecisionShort;

  /// Auto metadata for start
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get start;

  /// Auto metadata for friendGroupTitle
  ///
  /// In tr, this message translates to:
  /// **'Arkadaş Grubu'**
  String get friendGroupTitle;

  /// Auto metadata for friendGroupSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Birlikte karar verin'**
  String get friendGroupSubtitle;

  /// Auto metadata for openGroup
  ///
  /// In tr, this message translates to:
  /// **'Grubu Aç'**
  String get openGroup;

  /// Auto metadata for myGroups
  ///
  /// In tr, this message translates to:
  /// **'Gruplarım'**
  String get myGroups;

  /// Auto metadata for onTheRoadTitle
  ///
  /// In tr, this message translates to:
  /// **'Yoldayım'**
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
  /// **'Öne çıkan keşifler'**
  String get heroesSubtitle;

  /// Auto metadata for view
  ///
  /// In tr, this message translates to:
  /// **'Görüntüle'**
  String get view;

  /// Auto metadata for bestBusinessesThisWeek
  ///
  /// In tr, this message translates to:
  /// **'Bu Haftanın En İyi İşletmeleri'**
  String get bestBusinessesThisWeek;

  /// Auto metadata for bestBusinessesThisMonth
  ///
  /// In tr, this message translates to:
  /// **'Bu Ayın En İyi İşletmeleri'**
  String get bestBusinessesThisMonth;

  /// Auto metadata for onTheRoad20km
  ///
  /// In tr, this message translates to:
  /// **'Yolda • 20 km'**
  String get onTheRoad20km;

  /// Auto metadata for nearbyKm
  ///
  /// In tr, this message translates to:
  /// **'Yakında • {km} km'**
  String nearbyKm(int km);

  /// Auto metadata for liveResultsUpdating
  ///
  /// In tr, this message translates to:
  /// **'Canlı sonuçlar güncelleniyor'**
  String get liveResultsUpdating;

  /// Auto metadata for businessApprovedData
  ///
  /// In tr, this message translates to:
  /// **'İşletme onaylı verisi'**
  String get businessApprovedData;

  /// Auto metadata for communityData
  ///
  /// In tr, this message translates to:
  /// **'Topluluk verisi'**
  String get communityData;

  /// Auto metadata for removeFromFavorites
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get removeFromFavorites;

  /// Auto metadata for locationPermissionTitle
  ///
  /// In tr, this message translates to:
  /// **'Konum izni ver'**
  String get locationPermissionTitle;

  /// Auto metadata for locationPermissionDescription
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki yerleri göstermek için konum izni gerekli.'**
  String get locationPermissionDescription;

  /// Auto metadata for allow
  ///
  /// In tr, this message translates to:
  /// **'İzin Ver'**
  String get allow;

  /// Auto metadata for selectLocation
  ///
  /// In tr, this message translates to:
  /// **'Konum Seç'**
  String get selectLocation;

  /// Auto metadata for manualLocationHint
  ///
  /// In tr, this message translates to:
  /// **'Konumu manuel seçebilirsin.'**
  String get manualLocationHint;

  /// Auto metadata for noResultsYet
  ///
  /// In tr, this message translates to:
  /// **'Henüz sonuç yok'**
  String get noResultsYet;

  /// Auto metadata for lowDataInArea
  ///
  /// In tr, this message translates to:
  /// **'Bu bölgede veri az'**
  String get lowDataInArea;

  /// Auto metadata for tryDifferentSearchOrFilter
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir arama ya da filtre dene.'**
  String get tryDifferentSearchOrFilter;

  /// Auto metadata for beFirstContributorInArea
  ///
  /// In tr, this message translates to:
  /// **'Bölgede ilk katkıyı sen yap.'**
  String get beFirstContributorInArea;

  /// Auto metadata for topVerifiedMenus
  ///
  /// In tr, this message translates to:
  /// **'En Çok Doğrulanan Menüler'**
  String get topVerifiedMenus;

  /// Auto metadata for mostTrustedMenusInCity
  ///
  /// In tr, this message translates to:
  /// **'Şehirde En Güvenilen Menüler'**
  String get mostTrustedMenusInCity;

  /// Auto metadata for seeList
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Gör'**
  String get seeList;

  /// Auto metadata for localContributionCall
  ///
  /// In tr, this message translates to:
  /// **'Yerel katkı çağrısı'**
  String get localContributionCall;

  /// Auto metadata for addFirstMenu
  ///
  /// In tr, this message translates to:
  /// **'İlk Menüyü Ekle'**
  String get addFirstMenu;

  /// Auto metadata for suggestBusiness
  ///
  /// In tr, this message translates to:
  /// **'İşletme Öner'**
  String get suggestBusiness;

  /// Auto metadata for noSurpriseSuggestionNow
  ///
  /// In tr, this message translates to:
  /// **'Şu an sürpriz öneri yok'**
  String get noSurpriseSuggestionNow;

  /// Auto metadata for priceVerifiedInLast48h
  ///
  /// In tr, this message translates to:
  /// **'Bu fiyat son 48 saatte doğrulandı'**
  String get priceVerifiedInLast48h;

  /// Auto metadata for menuMayBeOutdated
  ///
  /// In tr, this message translates to:
  /// **'Menü güncel olmayabilir'**
  String get menuMayBeOutdated;

  /// Auto metadata for verifiedByBusiness
  ///
  /// In tr, this message translates to:
  /// **'İşletme tarafından doğrulandı'**
  String get verifiedByBusiness;

  /// Auto metadata for updatedByCommunity
  ///
  /// In tr, this message translates to:
  /// **'Topluluk tarafından güncellendi'**
  String get updatedByCommunity;

  /// Auto metadata for topRankedInDistrict
  ///
  /// In tr, this message translates to:
  /// **'İlçede üst sıralarda'**
  String get topRankedInDistrict;

  /// Auto metadata for surpriseDiscoveryTitle
  ///
  /// In tr, this message translates to:
  /// **'Sürpriz Keşif'**
  String get surpriseDiscoveryTitle;

  /// Auto metadata for surpriseDiscoverySubtitle
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlığının dışına çık'**
  String get surpriseDiscoverySubtitle;

  /// Auto metadata for randomButGood
  ///
  /// In tr, this message translates to:
  /// **'Rastgele ama iyi'**
  String get randomButGood;

  /// Auto metadata for outsideYourUsual
  ///
  /// In tr, this message translates to:
  /// **'Rutin dışı'**
  String get outsideYourUsual;

  /// Auto metadata for pricePerformanceSurprise
  ///
  /// In tr, this message translates to:
  /// **'Fiyat/performans sürprizi'**
  String get pricePerformanceSurprise;

  /// Auto metadata for nearbyCampaignsAndAnnouncements
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki kampanyalar ve duyurular'**
  String get nearbyCampaignsAndAnnouncements;

  /// Auto metadata for campaignsGreeting
  ///
  /// In tr, this message translates to:
  /// **'Merhaba! 👋'**
  String get campaignsGreeting;

  /// Auto metadata for campaignsSearchPlaceholder
  ///
  /// In tr, this message translates to:
  /// **'Kampanya veya işletme ara...'**
  String get campaignsSearchPlaceholder;

  /// Auto metadata for campaignFilterAll
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get campaignFilterAll;

  /// Auto metadata for campaignFilterSoon
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get campaignFilterSoon;

  /// Auto metadata for campaignFilterToday
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get campaignFilterToday;

  /// Auto metadata for campaignFilterFood
  ///
  /// In tr, this message translates to:
  /// **'Yemek'**
  String get campaignFilterFood;

  /// Auto metadata for campaignFilterDessert
  ///
  /// In tr, this message translates to:
  /// **'Tatlı'**
  String get campaignFilterDessert;

  /// Auto metadata for campaignFilterDiscount20
  ///
  /// In tr, this message translates to:
  /// **'%20+'**
  String get campaignFilterDiscount20;

  /// Auto metadata for campaignsNearbyHeader
  ///
  /// In tr, this message translates to:
  /// **'Yakınındaki kampanyalar'**
  String get campaignsNearbyHeader;

  /// Auto metadata for campaignsFeaturedBadge
  ///
  /// In tr, this message translates to:
  /// **'Lezzet Fırsatları'**
  String get campaignsFeaturedBadge;

  /// Auto metadata for campaignDiscountLabel
  ///
  /// In tr, this message translates to:
  /// **'%{percent} indirim'**
  String campaignDiscountLabel(int percent);

  /// Auto metadata for noNearbyCampaign
  ///
  /// In tr, this message translates to:
  /// **'Yakında kampanya yok'**
  String get noNearbyCampaign;

  /// Auto metadata for noActiveAnnouncementInArea
  ///
  /// In tr, this message translates to:
  /// **'Bölgede aktif duyuru yok'**
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
  /// **'Harita için konum verisi yok'**
  String get noLocationDataForMap;

  /// Auto metadata for mapDataMissingUseList
  ///
  /// In tr, this message translates to:
  /// **'Harita verisi eksik, liste görünümünü kullan.'**
  String get mapDataMissingUseList;

  /// Auto metadata for openMapView
  ///
  /// In tr, this message translates to:
  /// **'Harita Görünümünü Aç'**
  String get openMapView;

  /// Auto metadata for mapHintTapPins
  ///
  /// In tr, this message translates to:
  /// **'İğnelere dokunarak detayları gör.'**
  String get mapHintTapPins;

  /// No description provided for @mapGreetingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakınında ne var?'**
  String get mapGreetingSubtitle;

  /// No description provided for @mapSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Mekan veya bölge ara...'**
  String get mapSearchHint;

  /// No description provided for @mapFilterOpen.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get mapFilterOpen;

  /// No description provided for @mapFilterPrice.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get mapFilterPrice;

  /// No description provided for @mapAttribution.
  ///
  /// In tr, this message translates to:
  /// **'© OpenStreetMap katkıda bulunanlar'**
  String get mapAttribution;

  /// No description provided for @mapRecenterTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Konumuma git'**
  String get mapRecenterTooltip;

  /// No description provided for @mapLayersTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Katmanlar'**
  String get mapLayersTooltip;

  /// Auto metadata for locationPermissionRequired
  ///
  /// In tr, this message translates to:
  /// **'Konum izni gerekli.'**
  String get locationPermissionRequired;

  /// Auto metadata for noFoodFoundForCriteria
  ///
  /// In tr, this message translates to:
  /// **'Bu kriterlere uygun yemek bulunamadı'**
  String get noFoodFoundForCriteria;

  /// Auto metadata for whatToEatDescription
  ///
  /// In tr, this message translates to:
  /// **'Tercihlerine göre öneriler'**
  String get whatToEatDescription;

  /// Auto metadata for stepPeopleCount
  ///
  /// In tr, this message translates to:
  /// **'Kişi sayısı'**
  String get stepPeopleCount;

  /// Auto metadata for quickDecisionThreeOptions
  ///
  /// In tr, this message translates to:
  /// **'3 seçenekle hızlı karar'**
  String get quickDecisionThreeOptions;

  /// Auto metadata for stepBudgetTotal
  ///
  /// In tr, this message translates to:
  /// **'Toplam bütçe'**
  String get stepBudgetTotal;

  /// Auto metadata for budgetTl
  ///
  /// In tr, this message translates to:
  /// **'Bütçe (₺)'**
  String get budgetTl;

  /// Auto metadata for stepDistance
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get stepDistance;

  /// Auto metadata for locationNotSelected
  ///
  /// In tr, this message translates to:
  /// **'Konum seçilmedi'**
  String get locationNotSelected;

  /// Auto metadata for seeSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Önerileri Gör'**
  String get seeSuggestions;

  /// Auto metadata for getSingleSuggestion
  ///
  /// In tr, this message translates to:
  /// **'Tek öneri al'**
  String get getSingleSuggestion;

  /// Auto metadata for go
  ///
  /// In tr, this message translates to:
  /// **'Git'**
  String get go;

  /// Auto metadata for restart
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Başlat'**
  String get restart;

  /// Auto metadata for quickShortcuts
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Kısayollar'**
  String get quickShortcuts;

  /// Auto metadata for quickShortcutsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'En sık kullanılanlar'**
  String get quickShortcutsSubtitle;

  /// Auto metadata for savedItems
  ///
  /// In tr, this message translates to:
  /// **'Kaydettiklerim'**
  String get savedItems;

  /// Auto metadata for myFriendGroup
  ///
  /// In tr, this message translates to:
  /// **'Arkadaş Grubum'**
  String get myFriendGroup;

  /// Auto metadata for tasteExperts
  ///
  /// In tr, this message translates to:
  /// **'Lezzet Uzmanları'**
  String get tasteExperts;

  /// Auto metadata for businessTools
  ///
  /// In tr, this message translates to:
  /// **'İşletme Araçları'**
  String get businessTools;

  /// Auto metadata for businessToolsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Yönetim ve içgörüler'**
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
  /// **'Hazır'**
  String get ready;

  /// Auto metadata for plan
  ///
  /// In tr, this message translates to:
  /// **'plan'**
  String get plan;

  /// Auto metadata for sponsoredDisclosure
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu içerik'**
  String get sponsoredDisclosure;

  /// Auto metadata for sponsoredTooltip
  ///
  /// In tr, this message translates to:
  /// **'Bu içerik sponsorlu olabilir.'**
  String get sponsoredTooltip;

  /// Auto metadata for localInsightsReady
  ///
  /// In tr, this message translates to:
  /// **'Yerel içgörüler hazır • {area}'**
  String localInsightsReady(String area);

  /// Auto metadata for show
  ///
  /// In tr, this message translates to:
  /// **'Göster'**
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
  /// **'İşletme Paketi'**
  String get businessPackage;

  /// Auto metadata for redirectToReservation
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyona yönlendir'**
  String get redirectToReservation;

  /// Auto metadata for priceAlerts
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Uyarıları'**
  String get priceAlerts;

  /// Auto metadata for corporateIntegration
  ///
  /// In tr, this message translates to:
  /// **'Kurumsal Entegrasyon'**
  String get corporateIntegration;

  /// Auto metadata for detailedReports
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Raporlar'**
  String get detailedReports;

  /// Auto metadata for qrTools
  ///
  /// In tr, this message translates to:
  /// **'QR Araçları'**
  String get qrTools;

  /// Auto metadata for unlockNewFeatures
  ///
  /// In tr, this message translates to:
  /// **'Yeni özelliklerin kilidini aç'**
  String get unlockNewFeatures;

  /// Auto metadata for branchManagement
  ///
  /// In tr, this message translates to:
  /// **'Şube Yönetimi'**
  String get branchManagement;

  /// Auto metadata for menuWithQr
  ///
  /// In tr, this message translates to:
  /// **'QR ile Menü'**
  String get menuWithQr;

  /// Auto metadata for newFeatures
  ///
  /// In tr, this message translates to:
  /// **'Yeni Özellikler'**
  String get newFeatures;

  /// Auto metadata for nearOpenSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Yakında Açık Olanlar • {area}'**
  String nearOpenSectionTitle(String area);

  /// Auto metadata for mostViewedThisWeekTitle
  ///
  /// In tr, this message translates to:
  /// **'Bu Haftanın En Çok Görüntülenenleri • {area}'**
  String mostViewedThisWeekTitle(String area);

  /// Auto metadata for noViewDataInArea
  ///
  /// In tr, this message translates to:
  /// **'Bölgede görüntüleme verisi yok'**
  String get noViewDataInArea;

  /// Auto metadata for viewsMetric
  ///
  /// In tr, this message translates to:
  /// **'{count} görüntüleme'**
  String viewsMetric(int count);

  /// Auto metadata for highestPriceChangeTitle
  ///
  /// In tr, this message translates to:
  /// **'En Yüksek Fiyat Değişimi • {area}'**
  String highestPriceChangeTitle(String area);

  /// Auto metadata for noPriceMovementInArea
  ///
  /// In tr, this message translates to:
  /// **'Bölgede fiyat hareketi yok'**
  String get noPriceMovementInArea;

  /// Auto metadata for priceChangeMetric
  ///
  /// In tr, this message translates to:
  /// **'{count} fiyat değişimi'**
  String priceChangeMetric(int count);

  /// Auto metadata for nightOpenFavoritesTitle
  ///
  /// In tr, this message translates to:
  /// **'Gece Açık Favoriler • {area}'**
  String nightOpenFavoritesTitle(String area);

  /// Auto metadata for noNightOpenFavoritesInArea
  ///
  /// In tr, this message translates to:
  /// **'Bölgede gece açık favori yok'**
  String get noNightOpenFavoritesInArea;

  /// Auto metadata for followersMetric
  ///
  /// In tr, this message translates to:
  /// **'{count} takipçi'**
  String followersMetric(int count);

  /// Auto metadata for popularCategoriesTitle
  ///
  /// In tr, this message translates to:
  /// **'Popüler Kategoriler • {area}'**
  String popularCategoriesTitle(String area);

  /// Auto metadata for regionalPriceIndexTitle
  ///
  /// In tr, this message translates to:
  /// **'Bölgesel Fiyat Endeksi • {area}'**
  String regionalPriceIndexTitle(String area);

  /// Auto metadata for detailedAnalysis
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Analiz'**
  String get detailedAnalysis;

  /// Auto metadata for loadWhenScrolledDown
  ///
  /// In tr, this message translates to:
  /// **'Aşağı kaydırınca yüklenir'**
  String get loadWhenScrolledDown;

  /// Auto metadata for anomalyMonitoringTitle
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
  /// **'Fiyat endeksi yüklenemedi'**
  String get priceIndexLoadFailed;

  /// Auto metadata for noPriceIndexDataInArea
  ///
  /// In tr, this message translates to:
  /// **'Bölgede fiyat endeksi verisi yok'**
  String get noPriceIndexDataInArea;

  /// Auto metadata for medianPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Medyan fiyat {price}'**
  String medianPriceLabel(String price);

  /// Auto metadata for anomalyListLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'Anomali listesi yüklenemedi'**
  String get anomalyListLoadFailed;

  /// Auto metadata for noPriceAnomalyLast30Days
  ///
  /// In tr, this message translates to:
  /// **'Son 30 günde fiyat anomalisi yok'**
  String get noPriceAnomalyLast30Days;

  /// Auto metadata for sectionLoadFailed
  ///
  /// In tr, this message translates to:
  /// **'Bölüm yüklenemedi'**
  String get sectionLoadFailed;

  /// Auto metadata for rankedAt
  ///
  /// In tr, this message translates to:
  /// **'Sıra: {rank}'**
  String rankedAt(int rank);

  /// Auto metadata for yourScore
  ///
  /// In tr, this message translates to:
  /// **'Puanın: {score}'**
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

  /// Auto metadata for timeDays
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String timeDays(int count);

  /// Auto metadata for timeHours
  ///
  /// In tr, this message translates to:
  /// **'{count} saat'**
  String timeHours(int count);

  /// Auto metadata for timeMinutes
  ///
  /// In tr, this message translates to:
  /// **'{count} dk'**
  String timeMinutes(int count);

  /// Auto metadata for timeDaysAgo
  ///
  /// In tr, this message translates to:
  /// **'{count} gün önce'**
  String timeDaysAgo(int count);

  /// Auto metadata for timeHoursAgo
  ///
  /// In tr, this message translates to:
  /// **'{count} saat önce'**
  String timeHoursAgo(int count);

  /// Auto metadata for timeMinutesAgo
  ///
  /// In tr, this message translates to:
  /// **'{count} dakika önce'**
  String timeMinutesAgo(int count);

  /// Auto metadata for statusVerifiedShort
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get statusVerifiedShort;

  /// Auto metadata for statusMixedShort
  ///
  /// In tr, this message translates to:
  /// **'Karışık'**
  String get statusMixedShort;

  /// Auto metadata for statusOutdatedShort
  ///
  /// In tr, this message translates to:
  /// **'Güncel Değil'**
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

  /// Auto metadata for versionAndSource
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {version} • Kaynak: {source}'**
  String versionAndSource(int version, String source);

  /// Auto metadata for sourceOwner
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: işletme'**
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

  /// Auto metadata for shareBusinessMessage
  ///
  /// In tr, this message translates to:
  /// **'{name} • {location}\n{web}\n{deep}'**
  String shareBusinessMessage(
    String name,
    String location,
    String web,
    String deep,
  );

  /// Auto metadata for noLinkFound
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı bulunamadı'**
  String get noLinkFound;

  /// Auto metadata for newEmbedLinksWillAppear
  ///
  /// In tr, this message translates to:
  /// **'Yeni gömülü bağlantılar burada görünecek.'**
  String get newEmbedLinksWillAppear;

  /// Auto metadata for link
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı'**
  String get link;

  /// Auto metadata for untitledLink
  ///
  /// In tr, this message translates to:
  /// **'Başlıksız bağlantı'**
  String get untitledLink;

  /// Auto metadata for menuShareNotFoundTitle
  ///
  /// In tr, this message translates to:
  /// **'Menü bulunamadı • {appName}'**
  String menuShareNotFoundTitle(String appName);

  /// Auto metadata for menuShareNotFoundDescription
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan menü içeriği bulunamadı.'**
  String get menuShareNotFoundDescription;

  /// Auto metadata for menuContentNotFound
  ///
  /// In tr, this message translates to:
  /// **'Menü içeriği bulunamadı'**
  String get menuContentNotFound;

  /// Auto metadata for openAppForBetterExperience
  ///
  /// In tr, this message translates to:
  /// **'Daha iyi deneyim için uygulamayı aç.'**
  String get openAppForBetterExperience;

  /// Auto metadata for openApp
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Aç'**
  String get openApp;

  /// Auto metadata for nearbyPeopleViewed
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki {count} kişi görüntüledi'**
  String nearbyPeopleViewed(int count);

  /// Auto metadata for verifiedPrices
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış fiyatlar'**
  String get verifiedPrices;

  /// Auto metadata for selectRatingFirst
  ///
  /// In tr, this message translates to:
  /// **'Önce puan seç'**
  String get selectRatingFirst;

  /// Auto metadata for thankYou
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler'**
  String get thankYou;

  /// Auto metadata for noProductsFound
  ///
  /// In tr, this message translates to:
  /// **'Ürün bulunamadı'**
  String get noProductsFound;

  /// Auto metadata for preparedWithApp
  ///
  /// In tr, this message translates to:
  /// **'{appName} ile hazırlandı'**
  String preparedWithApp(String appName);

  /// Auto metadata for tableLabel
  ///
  /// In tr, this message translates to:
  /// **'Masa {tableNo}'**
  String tableLabel(String tableNo);

  /// Auto metadata for tableServiceQuestion
  ///
  /// In tr, this message translates to:
  /// **'Masa {tableNo} - servis var mı?'**
  String tableServiceQuestion(String tableNo);

  /// Auto metadata for shortNoteOptional
  ///
  /// In tr, this message translates to:
  /// **'Kısa not (opsiyonel)'**
  String get shortNoteOptional;

  /// Auto metadata for submit
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get submit;

  /// Auto metadata for submitted
  ///
  /// In tr, this message translates to:
  /// **'Gönderildi'**
  String get submitted;

  /// Auto metadata for submitting
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor'**
  String get submitting;

  /// Auto metadata for mySuggestionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Önerilerim'**
  String get mySuggestionsTitle;

  /// Auto metadata for mySuggestionsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Gönderdiğin fiyat önerileri'**
  String get mySuggestionsSubtitle;

  /// Auto metadata for viewBusiness
  ///
  /// In tr, this message translates to:
  /// **'İşletmeyi Gör'**
  String get viewBusiness;

  /// Auto metadata for statusApproved
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
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
  /// **'Şimdi değil'**
  String get notNow;

  /// Auto metadata for onboardingLiveMenusTitle
  ///
  /// In tr, this message translates to:
  /// **'Canlı Menüler'**
  String get onboardingLiveMenusTitle;

  /// Auto metadata for onboardingLiveMenusDescription
  ///
  /// In tr, this message translates to:
  /// **'Güncel menülere anında eriş.'**
  String get onboardingLiveMenusDescription;

  /// Auto metadata for onboardingContributeTitle
  ///
  /// In tr, this message translates to:
  /// **'Katkıda Bulun'**
  String get onboardingContributeTitle;

  /// Auto metadata for onboardingContributeDescription
  ///
  /// In tr, this message translates to:
  /// **'Topluluk için fiyatları doğrula ve güncelle.'**
  String get onboardingContributeDescription;

  /// No description provided for @onboardingPriceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şehrin Fiyatlarını\nSen Belirle'**
  String get onboardingPriceTitle;

  /// No description provided for @onboardingPriceBody1.
  ///
  /// In tr, this message translates to:
  /// **'Restoranları gerçek fiyatlarıyla keşfet'**
  String get onboardingPriceBody1;

  /// No description provided for @onboardingPriceBody2.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geçmişini ve şehir ortalamasını gör'**
  String get onboardingPriceBody2;

  /// No description provided for @onboardingPriceBody3.
  ///
  /// In tr, this message translates to:
  /// **'Bütçene göre filtrele, tasarruf et'**
  String get onboardingPriceBody3;

  /// No description provided for @onboardingCommunityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Topluluğun Gücü'**
  String get onboardingCommunityTitle;

  /// No description provided for @onboardingCommunitySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her fiyat doğrulaması herkese yardım eder'**
  String get onboardingCommunitySubtitle;

  /// No description provided for @onboardingCommunityBody1.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek kullanıcılar menüleri güncel tutar'**
  String get onboardingCommunityBody1;

  /// No description provided for @onboardingCommunityBody2.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat sapmaları anında tespit edilir'**
  String get onboardingCommunityBody2;

  /// No description provided for @onboardingCommunityBody3.
  ///
  /// In tr, this message translates to:
  /// **'Katkın için XP ve rozetler kazan'**
  String get onboardingCommunityBody3;

  /// No description provided for @onboardingNotificationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Anlık Bildirimler'**
  String get onboardingNotificationTitle;

  /// No description provided for @onboardingNotificationDescription.
  ///
  /// In tr, this message translates to:
  /// **'Favori mekanlarındaki fiyat değişikliklerini, kampanyaları ve grup taleplerini anında öğren.'**
  String get onboardingNotificationDescription;

  /// No description provided for @onboardingNotificationsEnabled.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler etkinleştirildi'**
  String get onboardingNotificationsEnabled;

  /// No description provided for @onboardingAllowNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimlere İzin Ver'**
  String get onboardingAllowNotifications;

  /// No description provided for @onboardingSkipNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get onboardingSkipNotifications;

  /// Auto metadata for getStarted
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get getStarted;

  /// Auto metadata for continueAction
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueAction;

  /// Auto metadata for register
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// Auto metadata for login
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// Auto metadata for enableLocationTitle
  ///
  /// In tr, this message translates to:
  /// **'Konumu Aç'**
  String get enableLocationTitle;

  /// Auto metadata for enableLocationSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki yerleri göstermek için konumunu aç.'**
  String get enableLocationSubtitle;

  /// Auto metadata for locationPermissionGranted
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verildi'**
  String get locationPermissionGranted;

  /// Auto metadata for locationOptionalInfo
  ///
  /// In tr, this message translates to:
  /// **'İstersen daha sonra da açabilirsin.'**
  String get locationOptionalInfo;

  /// Auto metadata for allowLocation
  ///
  /// In tr, this message translates to:
  /// **'Konuma izin ver'**
  String get allowLocation;

  /// Auto metadata for chooseLocationManually
  ///
  /// In tr, this message translates to:
  /// **'Konumu Elle Seç'**
  String get chooseLocationManually;

  /// Auto metadata for menuReading
  ///
  /// In tr, this message translates to:
  /// **'Menü okunuyor'**
  String get menuReading;

  /// Auto metadata for noPriceDetectionFound
  ///
  /// In tr, this message translates to:
  /// **'Fiyat tespiti bulunamadı'**
  String get noPriceDetectionFound;

  /// Auto metadata for receiptOcrNotSupportedWeb
  ///
  /// In tr, this message translates to:
  /// **'Web sürümünde fiş OCR desteklenmiyor'**
  String get receiptOcrNotSupportedWeb;

  /// Auto metadata for receiptReading
  ///
  /// In tr, this message translates to:
  /// **'Fiş okunuyor'**
  String get receiptReading;

  /// Auto metadata for noPriceFoundOnReceipt
  ///
  /// In tr, this message translates to:
  /// **'Fişte fiyat bulunamadı'**
  String get noPriceFoundOnReceipt;

  /// Auto metadata for receiptUploading
  ///
  /// In tr, this message translates to:
  /// **'Fiş yükleniyor'**
  String get receiptUploading;

  /// Auto metadata for receiptUploadFailed
  ///
  /// In tr, this message translates to:
  /// **'Fiş yükleme başarısız'**
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
  /// **'Fişi Eşleştir'**
  String get matchReceipt;

  /// Auto metadata for matchPrices
  ///
  /// In tr, this message translates to:
  /// **'Fiyatları Eşleştir'**
  String get matchPrices;

  /// Auto metadata for autoMatchedRowsCheck
  ///
  /// In tr, this message translates to:
  /// **'Otomatik eşleşen {count} satırı kontrol et.'**
  String autoMatchedRowsCheck(int count);

  /// Auto metadata for unlabeled
  ///
  /// In tr, this message translates to:
  /// **'Etiketsiz'**
  String get unlabeled;

  /// Auto metadata for priceTry
  ///
  /// In tr, this message translates to:
  /// **'Fiyat (₺)'**
  String get priceTry;

  /// Auto metadata for selectMenuItem
  ///
  /// In tr, this message translates to:
  /// **'Menü ürünü seç'**
  String get selectMenuItem;

  /// Auto metadata for sendReceipt
  ///
  /// In tr, this message translates to:
  /// **'Fişi Gönder'**
  String get sendReceipt;

  /// Auto metadata for sendReceiptSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Fiş Önerilerini Gönder'**
  String get sendReceiptSuggestions;

  /// Auto metadata for selectAtLeastOneItem
  ///
  /// In tr, this message translates to:
  /// **'En az bir ürün seç'**
  String get selectAtLeastOneItem;

  /// Auto metadata for invalidPriceExists
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz fiyat var'**
  String get invalidPriceExists;

  /// Auto metadata for sendingReceipt
  ///
  /// In tr, this message translates to:
  /// **'Fiş gönderiliyor'**
  String get sendingReceipt;

  /// Auto metadata for receiptSent
  ///
  /// In tr, this message translates to:
  /// **'Fiş gönderildi'**
  String get receiptSent;

  /// Auto metadata for sendingReceiptSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Fiş önerileri gönderiliyor'**
  String get sendingReceiptSuggestions;

  /// Auto metadata for priceSuggestionsSent
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerileri gönderildi'**
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
  /// **'Profil yükleniyor'**
  String get profileLoading;

  /// Auto metadata for dietProfileNotFound
  ///
  /// In tr, this message translates to:
  /// **'Beslenme profili bulunamadı'**
  String get dietProfileNotFound;

  /// Auto metadata for noResultsFound
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get noResultsFound;

  /// Auto metadata for allowLocationForNearby
  ///
  /// In tr, this message translates to:
  /// **'Yakın sonuçlar için konum izni ver'**
  String get allowLocationForNearby;

  /// Auto metadata for setPriceAlert
  ///
  /// In tr, this message translates to:
  /// **'Fiyat uyarısı kur'**
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

  /// Auto metadata for votes
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
  /// **'Menü ürünü'**
  String get menuItem;

  /// Auto metadata for cataloged
  ///
  /// In tr, this message translates to:
  /// **'Kataloglu'**
  String get cataloged;

  /// Auto metadata for priceAlert
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Alarmı'**
  String get priceAlert;

  /// Auto metadata for priceAlertSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Belirlediğin fiyatın altına düşünce haber verelim.'**
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
  /// **'Fotoğraf eklendi'**
  String get photoAdded;

  /// Auto metadata for photoQualityWarning
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf {warnings} görünüyor. Daha net ve aydınlık bir fotoğraf yükleyebilirsin.'**
  String photoQualityWarning(String warnings);

  /// Auto metadata for suggestEdit
  ///
  /// In tr, this message translates to:
  /// **'Düzenleme öner'**
  String get suggestEdit;

  /// Auto metadata for verifyPriceWithReceipt
  ///
  /// In tr, this message translates to:
  /// **'Fiş ile fiyat doğrula'**
  String get verifyPriceWithReceipt;

  /// Auto metadata for cart
  ///
  /// In tr, this message translates to:
  /// **'Sepet'**
  String get cart;

  /// Auto metadata for cartEmpty
  ///
  /// In tr, this message translates to:
  /// **'Sepet boş'**
  String get cartEmpty;

  /// Auto metadata for addItemToCalculate
  ///
  /// In tr, this message translates to:
  /// **'Hesaplamak için ürün ekle'**
  String get addItemToCalculate;

  /// Auto metadata for tipPercentage
  ///
  /// In tr, this message translates to:
  /// **'Bahşiş Yüzdesi'**
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

  /// Auto metadata for serviceWithPercent
  ///
  /// In tr, this message translates to:
  /// **'Servis ({percent}%)'**
  String serviceWithPercent(int percent);

  /// Auto metadata for tipWithPercent
  ///
  /// In tr, this message translates to:
  /// **'Bahşiş ({percent}%)'**
  String tipWithPercent(int percent);

  /// Auto metadata for serviceCoverMayVary
  ///
  /// In tr, this message translates to:
  /// **'Servis/kuver işletmeye göre değişebilir.'**
  String get serviceCoverMayVary;

  /// Auto metadata for estimatedTotal
  ///
  /// In tr, this message translates to:
  /// **'Tahmini Toplam'**
  String get estimatedTotal;

  /// Auto metadata for vatExcluded
  ///
  /// In tr, this message translates to:
  /// **'KDV hariç'**
  String get vatExcluded;

  /// Auto metadata for errorOccurred
  ///
  /// In tr, this message translates to:
  /// **'Bir sorun oluştu'**
  String get errorOccurred;

  /// Auto metadata for menuItemNotFoundDescription
  ///
  /// In tr, this message translates to:
  /// **'Aradığın ürün henüz eklenmemiş olabilir. İstersen ilk sen ekle.'**
  String get menuItemNotFoundDescription;

  /// Auto metadata for trustScoreInfoNote
  ///
  /// In tr, this message translates to:
  /// **'Bu puan kullanıcı oylaması değil, toplulukta ne kadar güvenilir katkı verdiğini gösterir.'**
  String get trustScoreInfoNote;

  /// Auto metadata for plusPoints
  ///
  /// In tr, this message translates to:
  /// **'+{points} puan'**
  String plusPoints(int points);

  /// Auto metadata for verifyContributionRaisedScore
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulaman topluluk güvenini destekledi.'**
  String get verifyContributionRaisedScore;

  /// Auto metadata for priceVerification
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulama'**
  String get priceVerification;

  /// Auto metadata for priceVerificationSteps
  ///
  /// In tr, this message translates to:
  /// **'1) Gördüğün fiyatı yaz  2) Gerekirse not/foto ekle  3) Gönder'**
  String get priceVerificationSteps;

  /// Auto metadata for newPriceTry
  ///
  /// In tr, this message translates to:
  /// **'Yeni fiyat (₺)'**
  String get newPriceTry;

  /// Auto metadata for note
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get note;

  /// Auto metadata for addEvidencePhoto
  ///
  /// In tr, this message translates to:
  /// **'Kanıt fotoğrafı ekle'**
  String get addEvidencePhoto;

  /// Auto metadata for evidenceAdded
  ///
  /// In tr, this message translates to:
  /// **'Kanıt eklendi'**
  String get evidenceAdded;

  /// Auto metadata for menuItemName
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı'**
  String get menuItemName;

  /// Auto metadata for menuItemNameRequired
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı boş olamaz'**
  String get menuItemNameRequired;

  /// Auto metadata for enterValidPrice
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir fiyat gir'**
  String get enterValidPrice;

  /// Auto metadata for sendSuggestion
  ///
  /// In tr, this message translates to:
  /// **'Öneri Gönder'**
  String get sendSuggestion;

  /// Auto metadata for noChanges
  ///
  /// In tr, this message translates to:
  /// **'Değişiklik yok'**
  String get noChanges;

  /// Auto metadata for priceCannotBeEmpty
  ///
  /// In tr, this message translates to:
  /// **'Fiyat boş olamaz'**
  String get priceCannotBeEmpty;

  /// Auto metadata for suggestionSentPendingApproval
  ///
  /// In tr, this message translates to:
  /// **'Önerin gönderildi, onay bekliyor.'**
  String get suggestionSentPendingApproval;

  /// Auto metadata for noSuggestionFound
  ///
  /// In tr, this message translates to:
  /// **'Öneri bulunamadı'**
  String get noSuggestionFound;

  /// Auto metadata for suggestedFoods
  ///
  /// In tr, this message translates to:
  /// **'Önerilen Yemekler'**
  String get suggestedFoods;

  /// Auto metadata for priceHistoryLast3
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geçmişi (son 3)'**
  String get priceHistoryLast3;

  /// Auto metadata for price
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get price;

  /// Auto metadata for last30DaysVotes
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün oyları • Uygun: {ok} • Uygunsuz: {bad}'**
  String last30DaysVotes(int ok, int bad);

  /// Auto metadata for lastVerificationDate
  ///
  /// In tr, this message translates to:
  /// **'Son doğrulama: {date}'**
  String lastVerificationDate(String date);

  /// Auto metadata for uniqueVerifiersIn48h
  ///
  /// In tr, this message translates to:
  /// **'48 saatte doğrulayan farklı kullanıcı: {count}'**
  String uniqueVerifiersIn48h(int count);

  /// Auto metadata for strongConsensusPriceSafe
  ///
  /// In tr, this message translates to:
  /// **'Güçlü uzlaşı var, fiyat güvenli görünüyor.'**
  String get strongConsensusPriceSafe;

  /// Auto metadata for priceConfidenceScore
  ///
  /// In tr, this message translates to:
  /// **'Fiyat güven puanı: %{score}'**
  String priceConfidenceScore(int score);

  /// No description provided for @priceConfidenceDataTrustHint.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat güveni, veri güveninin bir parçasıdır; son doğrulama ve uzlaşıya bakar.'**
  String get priceConfidenceDataTrustHint;

  /// Auto metadata for seenCorrect
  ///
  /// In tr, this message translates to:
  /// **'Gördüm • Doğru'**
  String get seenCorrect;

  /// Auto metadata for seenIncorrect
  ///
  /// In tr, this message translates to:
  /// **'Gördüm • Yanlış'**
  String get seenIncorrect;

  /// Auto metadata for suggestNewPrice
  ///
  /// In tr, this message translates to:
  /// **'Yeni fiyat öner'**
  String get suggestNewPrice;

  /// Auto metadata for howCalculated
  ///
  /// In tr, this message translates to:
  /// **'Nasıl hesaplandı?'**
  String get howCalculated;

  /// Auto metadata for verificationRate
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama oranı'**
  String get verificationRate;

  /// Auto metadata for recentPositiveVotes
  ///
  /// In tr, this message translates to:
  /// **'Son olumlu oylar'**
  String get recentPositiveVotes;

  /// Auto metadata for priceStability
  ///
  /// In tr, this message translates to:
  /// **'Fiyat istikrarı'**
  String get priceStability;

  /// Auto metadata for priceChangeLast30Days
  ///
  /// In tr, this message translates to:
  /// **'Son 30 günde fiyat değişimi: {count}'**
  String priceChangeLast30Days(int count);

  /// Auto metadata for scoreForInfoOnly
  ///
  /// In tr, this message translates to:
  /// **'Bu skor yalnızca bilgilendirme amaçlıdır.'**
  String get scoreForInfoOnly;

  /// Auto metadata for pricePerformance
  ///
  /// In tr, this message translates to:
  /// **'Fiyat/Performans'**
  String get pricePerformance;

  /// Auto metadata for valueScoreFormulaHint
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama oranı, son olumlu oylar ve fiyat istikrarına göre hesaplanır.'**
  String get valueScoreFormulaHint;

  /// No description provided for @communityScoreExplainAction.
  ///
  /// In tr, this message translates to:
  /// **'Skorlar ne anlama geliyor?'**
  String get communityScoreExplainAction;

  /// No description provided for @communityScoreWhatImproves.
  ///
  /// In tr, this message translates to:
  /// **'Neler etkiler?'**
  String get communityScoreWhatImproves;

  /// No description provided for @communityScoreHowUsed.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamada nasıl kullanılır?'**
  String get communityScoreHowUsed;

  /// No description provided for @communityScoreUserTrustCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı güveni'**
  String get communityScoreUserTrustCategory;

  /// No description provided for @communityScoreDataTrustCategory.
  ///
  /// In tr, this message translates to:
  /// **'Veri güveni'**
  String get communityScoreDataTrustCategory;

  /// No description provided for @communityScoreInfoOnlyCategory.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi skoru'**
  String get communityScoreInfoOnlyCategory;

  /// No description provided for @communityScoreUserTrustSummary.
  ///
  /// In tr, this message translates to:
  /// **'Topluluğun katkılarını ne kadar güvenilir bulduğunu gösterir. Popülerlik değil, doğruluk ve onay kalitesi bu puanı büyütür.'**
  String get communityScoreUserTrustSummary;

  /// No description provided for @communityScoreUserTrustSignalAccuracy.
  ///
  /// In tr, this message translates to:
  /// **'Doğru çıkan katkılar ve isabetli doğrulamalar'**
  String get communityScoreUserTrustSignalAccuracy;

  /// No description provided for @communityScoreUserTrustSignalApproval.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanan katkı oranı'**
  String get communityScoreUserTrustSignalApproval;

  /// No description provided for @communityScoreUserTrustSignalSafety.
  ///
  /// In tr, this message translates to:
  /// **'Düşük spam, suistimal ve red sinyali'**
  String get communityScoreUserTrustSignalSafety;

  /// No description provided for @communityScoreUserTrustUsage.
  ///
  /// In tr, this message translates to:
  /// **'Daha güvenilir katkılar topluluk akışında ve doğrulama kararlarında daha hızlı öne çıkar.'**
  String get communityScoreUserTrustUsage;

  /// No description provided for @communityScoreDataTrustSummary.
  ///
  /// In tr, this message translates to:
  /// **'Bir menü veya fiyat bilgisinin şu anda ne kadar güvenilir olduğunu gösterir.'**
  String get communityScoreDataTrustSummary;

  /// No description provided for @communityScoreDataTrustSignalFreshness.
  ///
  /// In tr, this message translates to:
  /// **'Menünün güncelliği ve son denetim tarihi'**
  String get communityScoreDataTrustSignalFreshness;

  /// No description provided for @communityScoreDataTrustSignalConsensus.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla doğrulayıcı ve güçlü uzlaşı'**
  String get communityScoreDataTrustSignalConsensus;

  /// No description provided for @communityScoreDataTrustSignalStability.
  ///
  /// In tr, this message translates to:
  /// **'Düşük çelişki ve tutarlı değişim geçmişi'**
  String get communityScoreDataTrustSignalStability;

  /// No description provided for @communityScoreDataTrustUsage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama, fiyat veya menü bilgisini güvenle göstermek için bu sinyali kullanır.'**
  String get communityScoreDataTrustUsage;

  /// No description provided for @communityScoreValueInsightSummary.
  ///
  /// In tr, this message translates to:
  /// **'Bu bir güven puanı değildir; doğrulama, oy ve fiyat istikrarından üretilen bilgi skorudur.'**
  String get communityScoreValueInsightSummary;

  /// No description provided for @communityScoreValueSignalVerification.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama oranı'**
  String get communityScoreValueSignalVerification;

  /// No description provided for @communityScoreValueSignalVotes.
  ///
  /// In tr, this message translates to:
  /// **'Son olumlu oylar'**
  String get communityScoreValueSignalVotes;

  /// No description provided for @communityScoreValueSignalStability.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat istikrarı'**
  String get communityScoreValueSignalStability;

  /// No description provided for @communityScoreValueUsage.
  ///
  /// In tr, this message translates to:
  /// **'Karar yardımcısıdır; tek başına kanıt yerine kullanılmaz.'**
  String get communityScoreValueUsage;

  /// Auto metadata for menuPhotos
  ///
  /// In tr, this message translates to:
  /// **'Menü Fotoğrafları'**
  String get menuPhotos;

  /// Auto metadata for updateMenuEarnPoints
  ///
  /// In tr, this message translates to:
  /// **'Menü güncelle, {points} puan kazan'**
  String updateMenuEarnPoints(int points);

  /// Auto metadata for menuPhotosHint
  ///
  /// In tr, this message translates to:
  /// **'Menü fotoğrafları ürünü göstermeli. Otomatik kırpılır; karanlık/flu olanlar uyarılır.'**
  String get menuPhotosHint;

  /// Auto metadata for noPhotosYet
  ///
  /// In tr, this message translates to:
  /// **'Henüz fotoğraf yok.'**
  String get noPhotosYet;

  /// Auto metadata for yesterday
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// Auto metadata for timeMonthsAgo
  ///
  /// In tr, this message translates to:
  /// **'{count} ay önce'**
  String timeMonthsAgo(int count);

  /// Auto metadata for priceInvalid
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geçersiz'**
  String get priceInvalid;

  /// Auto metadata for noteNoLinkPhone
  ///
  /// In tr, this message translates to:
  /// **'Not alanına bağlantı veya telefon eklenemez.'**
  String get noteNoLinkPhone;

  /// Auto metadata for noteContainsProfanity
  ///
  /// In tr, this message translates to:
  /// **'Notta uygunsuz ifade var.'**
  String get noteContainsProfanity;

  /// Auto metadata for noteTooManyEmoji
  ///
  /// In tr, this message translates to:
  /// **'Notta çok fazla emoji var'**
  String get noteTooManyEmoji;

  /// Auto metadata for rateLimited24h
  ///
  /// In tr, this message translates to:
  /// **'24 saatlik sınır aşıldı'**
  String get rateLimited24h;

  /// Auto metadata for dailyPriceSuggestionLimitReached
  ///
  /// In tr, this message translates to:
  /// **'Günlük fiyat öneri limitine ulaşıldı'**
  String get dailyPriceSuggestionLimitReached;

  /// Auto metadata for invalidEvidenceLink
  ///
  /// In tr, this message translates to:
  /// **'Kanıt bağlantısı geçersiz.'**
  String get invalidEvidenceLink;

  /// Auto metadata for invalidCurrency
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz para birimi'**
  String get invalidCurrency;

  /// Auto metadata for loginPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get loginPageTitle;

  /// Auto metadata for loginActionFailedTitle
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlanamadı'**
  String get loginActionFailedTitle;

  /// Auto metadata for loginActionFailedDescription
  ///
  /// In tr, this message translates to:
  /// **'{error}\nBağlantıyı kontrol edip tekrar dene.'**
  String loginActionFailedDescription(String error);

  /// Auto metadata for loginEmailLabel
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get loginEmailLabel;

  /// Auto metadata for loginPasswordLabel
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get loginPasswordLabel;

  /// Auto metadata for loginPrimaryAction
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get loginPrimaryAction;

  /// Auto metadata for loginSigningInAction
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılıyor...'**
  String get loginSigningInAction;

  /// Auto metadata for loginSignupAction
  ///
  /// In tr, this message translates to:
  /// **'Giriş / Kayıt'**
  String get loginSignupAction;

  /// Auto metadata for loginSigningUpAction
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuluyor...'**
  String get loginSigningUpAction;

  /// Auto metadata for loginSignupSuccessMessage
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuldu. E-posta/telefon doğrulamasını tamamla.'**
  String get loginSignupSuccessMessage;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya şifre hatalı. Tekrar deneyin.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresinizi doğrulayın.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme. Lütfen kısa süre bekleyin.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta ile hesap bulunamadı.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Giriş başarısız. Lütfen tekrar deneyin.'**
  String get authErrorGeneric;

  /// Auto metadata for drawerTopBusinesses
  ///
  /// In tr, this message translates to:
  /// **'Top İşletmeler'**
  String get drawerTopBusinesses;

  /// Auto metadata for drawerSocial
  ///
  /// In tr, this message translates to:
  /// **'Sosyal'**
  String get drawerSocial;

  /// Auto metadata for drawerGourmets
  ///
  /// In tr, this message translates to:
  /// **'Lezzet uzmanları'**
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
  /// **'Akış'**
  String get drawerFeed;

  /// Auto metadata for drawerTasteTwin
  ///
  /// In tr, this message translates to:
  /// **'Tat eşleri'**
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
  /// **'Karşılaştır'**
  String get drawerCompare;

  /// Auto metadata for drawerQuickTools
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Araçlar'**
  String get drawerQuickTools;

  /// Auto metadata for drawerSmartSuggestionShortcut
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Öneri (2 kişi / 600 TL)'**
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

  /// Auto metadata for drawerInboxWithCount
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kutusu ({count})'**
  String drawerInboxWithCount(int count);

  /// Auto metadata for drawerMySuggestions
  ///
  /// In tr, this message translates to:
  /// **'Önerilerim'**
  String get drawerMySuggestions;

  /// Auto metadata for drawerSuspendedMeals
  ///
  /// In tr, this message translates to:
  /// **'Askıda'**
  String get drawerSuspendedMeals;

  /// Auto metadata for drawerLegalAndTrust
  ///
  /// In tr, this message translates to:
  /// **'Yasal ve Güven'**
  String get drawerLegalAndTrust;

  /// Auto metadata for budgetComboEntryTitle
  ///
  /// In tr, this message translates to:
  /// **'Bütçem şu kadar'**
  String get budgetComboEntryTitle;

  /// Auto metadata for budgetComboLocationNotSelected
  ///
  /// In tr, this message translates to:
  /// **'Konum seçilmedi'**
  String get budgetComboLocationNotSelected;

  /// Auto metadata for budgetComboBudgetLabel
  ///
  /// In tr, this message translates to:
  /// **'Bütçe (TL)'**
  String get budgetComboBudgetLabel;

  /// Auto metadata for budgetComboPartySizeLabel
  ///
  /// In tr, this message translates to:
  /// **'Kişi'**
  String get budgetComboPartySizeLabel;

  /// Auto metadata for budgetComboCategoryOptionalLabel
  ///
  /// In tr, this message translates to:
  /// **'Kategori (opsiyonel)'**
  String get budgetComboCategoryOptionalLabel;

  /// Auto metadata for budgetComboSeeSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Önerileri Gör'**
  String get budgetComboSeeSuggestions;

  /// Auto metadata for budgetComboAllCategories
  ///
  /// In tr, this message translates to:
  /// **'Tüm kategoriler'**
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
  /// **'Tatlıcı'**
  String get budgetComboCategoryDessert;

  /// Auto metadata for budgetComboCategoryBreakfast
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get budgetComboCategoryBreakfast;

  /// Auto metadata for budgetComboCategoryFishMeat
  ///
  /// In tr, this message translates to:
  /// **'Balık / Et'**
  String get budgetComboCategoryFishMeat;

  /// Auto metadata for budgetComboCategoryVenue
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get budgetComboCategoryVenue;

  /// Auto metadata for smartRecoTitle
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Öneri'**
  String get smartRecoTitle;

  /// Auto metadata for smartRecoSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Bütçene ve kişi sayısına göre en iyi seçenekler'**
  String get smartRecoSubtitle;

  /// Auto metadata for smartRecoEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Uygun işletme bulunamadı'**
  String get smartRecoEmptyTitle;

  /// Auto metadata for smartRecoEmptyDesc
  ///
  /// In tr, this message translates to:
  /// **'Bütçeni artırarak veya kişi sayısını azaltarak tekrar dene'**
  String get smartRecoEmptyDesc;

  /// Auto metadata for smartRecoShuffleLabel
  ///
  /// In tr, this message translates to:
  /// **'Şansını Dene!'**
  String get smartRecoShuffleLabel;

  /// Auto metadata for smartRecoShuffleDesc
  ///
  /// In tr, this message translates to:
  /// **'Farklı öneriler göster'**
  String get smartRecoShuffleDesc;

  /// Auto metadata for budgetComboResultsTitle
  ///
  /// In tr, this message translates to:
  /// **'Bütçe Kombinleri'**
  String get budgetComboResultsTitle;

  /// Auto metadata for budgetComboMissingInfoTitle
  ///
  /// In tr, this message translates to:
  /// **'Eksik bilgi'**
  String get budgetComboMissingInfoTitle;

  /// Auto metadata for budgetComboMissingInfoDescription
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bütçe ve konum bilgisini girin.'**
  String get budgetComboMissingInfoDescription;

  /// Auto metadata for budgetComboNoResultsTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz uygun kombin yok'**
  String get budgetComboNoResultsTitle;

  /// Auto metadata for budgetComboNoResultsDescription
  ///
  /// In tr, this message translates to:
  /// **'Bütçeyi artırmayı ya da kişi sayısını azaltmayı deneyin.'**
  String get budgetComboNoResultsDescription;

  /// Auto metadata for budgetComboAdjustCriteriaTitle
  ///
  /// In tr, this message translates to:
  /// **'Kriter değiştir'**
  String get budgetComboAdjustCriteriaTitle;

  /// Auto metadata for budgetComboDefaultAction
  ///
  /// In tr, this message translates to:
  /// **'Varsayılıan'**
  String get budgetComboDefaultAction;

  /// Auto metadata for budgetComboRadiusDistrictScope
  ///
  /// In tr, this message translates to:
  /// **'Yakınlık filtresi şehir/ilçe düzeyinde uygulanır.'**
  String get budgetComboRadiusDistrictScope;

  /// Auto metadata for budgetComboRadiusTarget
  ///
  /// In tr, this message translates to:
  /// **'Yakınlık hedefi: {km} km'**
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
  /// **'Mesafe/puan verisi yoksa sıralama fiyata göre yapılır.'**
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
  /// **'Diğer öneriler'**
  String get budgetComboOtherSuggestionsTitle;

  /// Auto metadata for budgetComboRatingLabelValue
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
  /// **'İçecek'**
  String get budgetComboDrinkItemLabel;

  /// Auto metadata for budgetComboTotalLabel
  ///
  /// In tr, this message translates to:
  /// **'{price} toplam'**
  String budgetComboTotalLabel(String price);

  /// Auto metadata for budgetComboGoToBusinessAction
  ///
  /// In tr, this message translates to:
  /// **'İşletmeye git'**
  String get budgetComboGoToBusinessAction;

  /// Auto metadata for panelAccessTitle
  ///
  /// In tr, this message translates to:
  /// **'Panel Erişimi'**
  String get panelAccessTitle;

  /// Auto metadata for panelWebOnlyMessage
  ///
  /// In tr, this message translates to:
  /// **'Bu panel web üzerinden kullanılır.'**
  String get panelWebOnlyMessage;

  /// Auto metadata for panelRedirectedPath
  ///
  /// In tr, this message translates to:
  /// **'Yönlendirilen yol: {path}'**
  String panelRedirectedPath(String path);

  /// Auto metadata for panelBackToDiscover
  ///
  /// In tr, this message translates to:
  /// **'Keşfet sayfasına dön'**
  String get panelBackToDiscover;

  /// Auto metadata for notFoundTitle
  ///
  /// In tr, this message translates to:
  /// **'Sayfa Bulunamadı'**
  String get notFoundTitle;

  /// Auto metadata for businessHeaderStatusClosingLabel
  ///
  /// In tr, this message translates to:
  /// **'Durum / Kapanış'**
  String get businessHeaderStatusClosingLabel;

  /// Auto metadata for businessHeaderAveragePriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Ortalama fiyat'**
  String get businessHeaderAveragePriceLabel;

  /// Auto metadata for businessHeaderPopularItemLabel
  ///
  /// In tr, this message translates to:
  /// **'Popüler ürün'**
  String get businessHeaderPopularItemLabel;

  /// Auto metadata for businessHeaderLastVerificationLabel
  ///
  /// In tr, this message translates to:
  /// **'Son doğrulama'**
  String get businessHeaderLastVerificationLabel;

  /// Auto metadata for businessStatusOpen
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get businessStatusOpen;

  /// Auto metadata for businessStatusClosed
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
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
  /// **'Şube bulunamadı.'**
  String get chainPageNoBranches;

  /// Auto metadata for chainPageNearbyBranchesTitle
  ///
  /// In tr, this message translates to:
  /// **'Yakın şubeler'**
  String get chainPageNearbyBranchesTitle;

  /// Auto metadata for chainPageBranchMenuPriceHint
  ///
  /// In tr, this message translates to:
  /// **'Şube menü ve fiyatları farklı olabilir.'**
  String get chainPageBranchMenuPriceHint;

  /// Auto metadata for chainPageBranchMoreExpensive
  ///
  /// In tr, this message translates to:
  /// **'Bu şube daha pahalı (%{pct})'**
  String chainPageBranchMoreExpensive(String pct);

  /// Auto metadata for chainPageBranchMoreAffordable
  ///
  /// In tr, this message translates to:
  /// **'Bu şube daha uygun (%{pct})'**
  String chainPageBranchMoreAffordable(String pct);

  /// Auto metadata for chainPageBranchNearAverage
  ///
  /// In tr, this message translates to:
  /// **'Zincir ortalamasına yakınlık'**
  String get chainPageBranchNearAverage;

  /// Auto metadata for comparePageTitle
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma'**
  String get comparePageTitle;

  /// Auto metadata for compareEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma boş'**
  String get compareEmptyTitle;

  /// Auto metadata for compareEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme sayfalarından karşılaştırmaya ekle.'**
  String get compareEmptyDescription;

  /// Auto metadata for compareBackToDiscover
  ///
  /// In tr, this message translates to:
  /// **'Keşfet sayfasına dön'**
  String get compareBackToDiscover;

  /// Auto metadata for compareBestPickAction
  ///
  /// In tr, this message translates to:
  /// **'En mantıklı seçimi göster'**
  String get compareBestPickAction;

  /// Auto metadata for compareSuggestedBadge
  ///
  /// In tr, this message translates to:
  /// **'Öneri'**
  String get compareSuggestedBadge;

  /// Auto metadata for compareMedianPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Median fiyat'**
  String get compareMedianPriceLabel;

  /// Auto metadata for compareVerifiedRateLabel
  ///
  /// In tr, this message translates to:
  /// **'Verified oranı'**
  String get compareVerifiedRateLabel;

  /// Auto metadata for compareLastUpdateLabel
  ///
  /// In tr, this message translates to:
  /// **'Son güncelleme'**
  String get compareLastUpdateLabel;

  /// Auto metadata for compareBestItemTitle
  ///
  /// In tr, this message translates to:
  /// **'Uygun item'**
  String get compareBestItemTitle;

  /// Auto metadata for compareGoToBusinessAction
  ///
  /// In tr, this message translates to:
  /// **'İşletmeye git'**
  String get compareGoToBusinessAction;

  /// Auto metadata for compareRemoveTooltip
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get compareRemoveTooltip;

  /// Auto metadata for compareRecommendedSnack
  ///
  /// In tr, this message translates to:
  /// **'Öneri: {name}'**
  String compareRecommendedSnack(String name);

  /// Auto metadata for contributeDefaultBusinessName
  ///
  /// In tr, this message translates to:
  /// **'bu işletme'**
  String get contributeDefaultBusinessName;

  /// Auto metadata for contributeOpenBusinessFirst
  ///
  /// In tr, this message translates to:
  /// **'Bu katkı için önce bir işletme sayfası aç.'**
  String get contributeOpenBusinessFirst;

  /// Auto metadata for contributeUploadingProgress
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor...'**
  String get contributeUploadingProgress;

  /// Auto metadata for contributeUploadSentSingle
  ///
  /// In tr, this message translates to:
  /// **'Gönderildi - kontrol sonrası menüye eklenecek.'**
  String get contributeUploadSentSingle;

  /// Auto metadata for contributeUploadSentMultiple
  ///
  /// In tr, this message translates to:
  /// **'{count} sayfa gönderildi - kontrol sonrası menüye eklenecek.'**
  String contributeUploadSentMultiple(int count);

  /// Auto metadata for contributeUploadFailed
  ///
  /// In tr, this message translates to:
  /// **'Gönderim başarısız. Lütfen tekrar dene.'**
  String get contributeUploadFailed;

  /// Auto metadata for contributeQrDecodingProgress
  ///
  /// In tr, this message translates to:
  /// **'QR çözülüyor...'**
  String get contributeQrDecodingProgress;

  /// Auto metadata for contributeQrUnreadableSentReview
  ///
  /// In tr, this message translates to:
  /// **'QR okunamadı. Görsel inceleme için gönderiliyor.'**
  String get contributeQrUnreadableSentReview;

  /// Auto metadata for contributeQrVerifiedRedirecting
  ///
  /// In tr, this message translates to:
  /// **'QR doğrulandı. Yönlendiriliyorsun.'**
  String get contributeQrVerifiedRedirecting;

  /// Auto metadata for contributeQrProcessFailed
  ///
  /// In tr, this message translates to:
  /// **'QR işlenemedi. Lütfen tekrar dene.'**
  String get contributeQrProcessFailed;

  /// Auto metadata for contributeExternalQrUseBusinessPage
  ///
  /// In tr, this message translates to:
  /// **'Dış QR kodu için işletme sayfasında Katkı yap kullan.'**
  String get contributeExternalQrUseBusinessPage;

  /// Auto metadata for contributeSendingForReviewProgress
  ///
  /// In tr, this message translates to:
  /// **'İnceleme için gönderiliyor...'**
  String get contributeSendingForReviewProgress;

  /// Auto metadata for contributeQrImageSentForReview
  ///
  /// In tr, this message translates to:
  /// **'QR görüntüsü gönderildi. İnceleme sonrası işleme alınacak.'**
  String get contributeQrImageSentForReview;

  /// Auto metadata for contributeExternalLinkSentForReview
  ///
  /// In tr, this message translates to:
  /// **'Dış link incelemeye gönderildi.'**
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
  /// **'Fiyat doğrulama için önce bir işletme seç.'**
  String get contributeSelectBusinessForPriceVerification;

  /// Auto metadata for contributeSelectMenuItemToVerifyPrice
  ///
  /// In tr, this message translates to:
  /// **'Menüden tek ürün seçip fiyatını doğrulayabilirsin.'**
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
  /// **'Tatlı / Pastane'**
  String get discoveryFilterDessertPastry;

  /// Auto metadata for discoveryFilterBreakfast
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get discoveryFilterBreakfast;

  /// Auto metadata for discoveryFilterFishMeat
  ///
  /// In tr, this message translates to:
  /// **'Balık / Et'**
  String get discoveryFilterFishMeat;

  /// Auto metadata for discoveryFilterVenue
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get discoveryFilterVenue;

  /// Auto metadata for discoveryHomeCategoryDoner
  ///
  /// In tr, this message translates to:
  /// **'İnce Döner'**
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
  /// **'Çorba'**
  String get discoveryHomeCategoryCorba;

  /// Auto metadata for discoveryHomeCategoryKahvalti
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get discoveryHomeCategoryKahvalti;

  /// Auto metadata for discoveryHomeCategoryManti
  ///
  /// In tr, this message translates to:
  /// **'Mantı'**
  String get discoveryHomeCategoryManti;

  /// Auto metadata for discoveryHomeCategoryTatli
  ///
  /// In tr, this message translates to:
  /// **'Tatlı'**
  String get discoveryHomeCategoryTatli;

  /// Auto metadata for discoveryRecentSearches
  ///
  /// In tr, this message translates to:
  /// **'Son aramalar'**
  String get discoveryRecentSearches;

  /// Auto metadata for discoveryCatalogSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Katalog önerileri'**
  String get discoveryCatalogSuggestions;

  /// Auto metadata for discoveryFoodsGreeting
  ///
  /// In tr, this message translates to:
  /// **'Merhaba! 👋'**
  String get discoveryFoodsGreeting;

  /// Auto metadata for discoveryFoodsSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Yemek veya kategori ara...'**
  String get discoveryFoodsSearchHint;

  /// Auto metadata for todaysPickTitle
  ///
  /// In tr, this message translates to:
  /// **'Günün lezzeti'**
  String get todaysPickTitle;

  /// Auto metadata for popularFoodsTitle
  ///
  /// In tr, this message translates to:
  /// **'Popüler yemekler'**
  String get popularFoodsTitle;

  /// Auto metadata for feedEmptyMessage
  ///
  /// In tr, this message translates to:
  /// **'Henüz akış yok. Lezzet uzmanlarını takip ederek başlayabilirsin.'**
  String get feedEmptyMessage;

  /// Auto metadata for all
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
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

  /// Auto metadata for favoritesSharedCollectionSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan koleksiyon: {name}'**
  String favoritesSharedCollectionSubtitle(String name);

  /// Auto metadata for favoritesSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Favorilerde ara'**
  String get favoritesSearchHint;

  /// Auto metadata for favoritesNearbyLoadingLocation
  ///
  /// In tr, this message translates to:
  /// **'Yakınındakiler için konum alınıyor...'**
  String get favoritesNearbyLoadingLocation;

  /// Auto metadata for favoritesNearbyFallbackOrdering
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Varsaylan sıralama gösteriliyor.'**
  String get favoritesNearbyFallbackOrdering;

  /// Auto metadata for favoritesNearbySortedByDistance
  ///
  /// In tr, this message translates to:
  /// **'Yakınındakiler mesafeye göre sıralandı.'**
  String get favoritesNearbySortedByDistance;

  /// Auto metadata for favoritesCollectionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyonlar'**
  String get favoritesCollectionsTitle;

  /// Auto metadata for favoritesCreateCollectionTooltip
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon oluştur'**
  String get favoritesCreateCollectionTooltip;

  /// Auto metadata for favoritesShareCollectionTooltip
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyonu paylaş'**
  String get favoritesShareCollectionTooltip;

  /// Auto metadata for favoritesDeleteCollectionTooltip
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyonu sil'**
  String get favoritesDeleteCollectionTooltip;

  /// Auto metadata for favoritesCreatorSelectCollectionHint
  ///
  /// In tr, this message translates to:
  /// **'İçerik üretici modu için önce bir koleksiyon seç.'**
  String get favoritesCreatorSelectCollectionHint;

  /// Auto metadata for favoritesCreatorCollectionTitle
  ///
  /// In tr, this message translates to:
  /// **'İçerik üretici koleksiyonu'**
  String get favoritesCreatorCollectionTitle;

  /// Auto metadata for favoritesCreatorCollectionSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyonunu yayınla, takipçi kazan. Reklam içeriği varsa etiket zorunludur.'**
  String get favoritesCreatorCollectionSubtitle;

  /// Auto metadata for favoritesPublishAction
  ///
  /// In tr, this message translates to:
  /// **'Yayınla'**
  String get favoritesPublishAction;

  /// Auto metadata for favoritesPublishVisibleSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Profilinde ve paylaşım bağlantılarında görünür.'**
  String get favoritesPublishVisibleSubtitle;

  /// Auto metadata for favoritesPublishPrivateSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Bu koleksiyonu sadece sen görürsün.'**
  String get favoritesPublishPrivateSubtitle;

  /// Auto metadata for favoritesSharedCollectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan koleksiyon'**
  String get favoritesSharedCollectionTitle;

  /// Auto metadata for favoritesFollowCollectionHint
  ///
  /// In tr, this message translates to:
  /// **'Bu koleksiyonu takip ederek güncellemeleri kaçırmama.'**
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

  /// Auto metadata for favoritesFollowersChip
  ///
  /// In tr, this message translates to:
  /// **'Takipçi {count}'**
  String favoritesFollowersChip(int count);

  /// Auto metadata for favoritesEngagementChip
  ///
  /// In tr, this message translates to:
  /// **'Etkileşim {count}'**
  String favoritesEngagementChip(int count);

  /// Auto metadata for favoritesCountBanner
  ///
  /// In tr, this message translates to:
  /// **'{count} mekan favorilerinde'**
  String favoritesCountBanner(int count);

  /// Auto metadata for favoritesNewCollectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Yeni Koleksiyon'**
  String get favoritesNewCollectionTitle;

  /// Auto metadata for favoritesCollectionNameExample
  ///
  /// In tr, this message translates to:
  /// **'Örn: Gece döneri'**
  String get favoritesCollectionNameExample;

  /// Auto metadata for favoritesCreateAction
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get favoritesCreateAction;

  /// Auto metadata for favoritesDeleteCollectionConfirmTitle
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon silinsin mi?'**
  String get favoritesDeleteCollectionConfirmTitle;

  /// Auto metadata for favoritesDeleteCollectionConfirmBody
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz.'**
  String get favoritesDeleteCollectionConfirmBody;

  /// Auto metadata for favoritesBusinessCollectionsTitle
  ///
  /// In tr, this message translates to:
  /// **'\"{businessName}\" koleksiyonları'**
  String favoritesBusinessCollectionsTitle(String businessName);

  /// Auto metadata for favoritesNoCollectionYet
  ///
  /// In tr, this message translates to:
  /// **'Henüz koleksiyon yok. Önce koleksiyon oluştur.'**
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
  /// **'Özel'**
  String get favoritesDisclosurePrivate;

  /// Auto metadata for favoritesShareText
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy koleksiyonum: {name}\n{link}\n\nMod: Yakınındakilerden öner\nEtiket: {disclosure}'**
  String favoritesShareText(String name, String link, String disclosure);

  /// Auto metadata for favoritesAdDisclosureTitle
  ///
  /// In tr, this message translates to:
  /// **'Reklam bildirimi'**
  String get favoritesAdDisclosureTitle;

  /// Auto metadata for favoritesAdDisclosureBody
  ///
  /// In tr, this message translates to:
  /// **'Bu koleksiyonda iş birliği varsa \"Reklam\" olarak işaretlemek zorunludur.'**
  String get favoritesAdDisclosureBody;

  /// Auto metadata for favoritesCacheStaleMessage
  ///
  /// In tr, this message translates to:
  /// **'Veri {days} gün önce güncellenmiş¸ olabilir.'**
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
  /// **'Henüz kimseyi takip etmiyorsun.'**
  String get followingPageEmpty;

  /// Auto metadata for followingPageUnfollowAction
  ///
  /// In tr, this message translates to:
  /// **'Takibi bırak'**
  String get followingPageUnfollowAction;

  /// Auto metadata for gourmetsPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Lezzet uzmanlarının keşfet'**
  String get gourmetsPageTitle;

  /// Auto metadata for gourmetsPageEmpty
  ///
  /// In tr, this message translates to:
  /// **'Henüz lezzet uzmanı yok.'**
  String get gourmetsPageEmpty;

  /// Auto metadata for groupRequestWizardTitle
  ///
  /// In tr, this message translates to:
  /// **'Grup Yemeği Talebi'**
  String get groupRequestWizardTitle;

  /// Auto metadata for groupRequestWizardEnterDetails
  ///
  /// In tr, this message translates to:
  /// **'Detayları gir'**
  String get groupRequestWizardEnterDetails;

  /// Auto metadata for groupRequestWizardCityLabel
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get groupRequestWizardCityLabel;

  /// Auto metadata for groupRequestWizardDistrictLabel
  ///
  /// In tr, this message translates to:
  /// **'İlçe'**
  String get groupRequestWizardDistrictLabel;

  /// Auto metadata for groupRequestWizardCategoryHint
  ///
  /// In tr, this message translates to:
  /// **'Kategori (kahve, lokanta...)'**
  String get groupRequestWizardCategoryHint;

  /// Auto metadata for groupRequestWizardPartySizeLabel
  ///
  /// In tr, this message translates to:
  /// **'Kişi sayısı'**
  String get groupRequestWizardPartySizeLabel;

  /// Auto metadata for groupRequestWizardTotalBudgetLabel
  ///
  /// In tr, this message translates to:
  /// **'Toplam bütçe (TL)'**
  String get groupRequestWizardTotalBudgetLabel;

  /// Auto metadata for groupRequestWizardNotesLabel
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get groupRequestWizardNotesLabel;

  /// Auto metadata for groupRequestWizardCreateAction
  ///
  /// In tr, this message translates to:
  /// **'Talep Oluştur'**
  String get groupRequestWizardCreateAction;

  /// Auto metadata for groupRequestWizardInfoTitle
  ///
  /// In tr, this message translates to:
  /// **'Teklifler işletmelerden gelir'**
  String get groupRequestWizardInfoTitle;

  /// Auto metadata for groupRequestWizardInfoDescription
  ///
  /// In tr, this message translates to:
  /// **'Talebin açıldığında işletmeler teklif verebilir.'**
  String get groupRequestWizardInfoDescription;

  /// Auto metadata for groupRequestWizardMissingFields
  ///
  /// In tr, this message translates to:
  /// **'Eksik alan var'**
  String get groupRequestWizardMissingFields;

  /// Auto metadata for groupRequestWizardPickDateTime
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve saat seç'**
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
  /// **'İlk grup yemeği talebini oluştur.'**
  String get groupRequestNoRequestsDescription;

  /// Auto metadata for groupRequestPartyAndBudget
  ///
  /// In tr, this message translates to:
  /// **'{party} kişi · {budget}'**
  String groupRequestPartyAndBudget(int party, String budget);

  /// Auto metadata for groupRequestStatusOpen
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get groupRequestStatusOpen;

  /// Auto metadata for groupRequestStatusAwarded
  ///
  /// In tr, this message translates to:
  /// **'Kazandırıldı'**
  String get groupRequestStatusAwarded;

  /// Auto metadata for groupRequestStatusClosed
  ///
  /// In tr, this message translates to:
  /// **'Kapandı'**
  String get groupRequestStatusClosed;

  /// Auto metadata for groupRequestStatusCancelled
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get groupRequestStatusCancelled;

  /// Auto metadata for groupRequestDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Grup Talebi'**
  String get groupRequestDetailTitle;

  /// Auto metadata for groupRequestLinkCopied
  ///
  /// In tr, this message translates to:
  /// **'Grup linki kopyalandı'**
  String get groupRequestLinkCopied;

  /// Auto metadata for groupRequestNotFound
  ///
  /// In tr, this message translates to:
  /// **'Talep bulunamadı'**
  String get groupRequestNotFound;

  /// Auto metadata for groupRequestCreatedBannerTitle
  ///
  /// In tr, this message translates to:
  /// **'Talebin yayında'**
  String get groupRequestCreatedBannerTitle;

  /// Auto metadata for groupRequestCreatedBannerDescription
  ///
  /// In tr, this message translates to:
  /// **'Grup linkini paylaş. Herkes önerileri ekler, oylar.'**
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
  /// **'Öneri ekle'**
  String get groupRequestAddSuggestionTitle;

  /// Auto metadata for groupRequestAddSuggestionDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme seç, teklif ekle ve grup oylasın.'**
  String get groupRequestAddSuggestionDescription;

  /// Auto metadata for groupRequestAddSuggestionAction
  ///
  /// In tr, this message translates to:
  /// **'Öneri ekle'**
  String get groupRequestAddSuggestionAction;

  /// Auto metadata for groupRequestOffersTitle
  ///
  /// In tr, this message translates to:
  /// **'Teklifler'**
  String get groupRequestOffersTitle;

  /// Auto metadata for groupRequestNoOffersTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz teklif yok'**
  String get groupRequestNoOffersTitle;

  /// Auto metadata for groupRequestNoOffersDescription
  ///
  /// In tr, this message translates to:
  /// **'Teklifler geldiğinde burada görünecek.'**
  String get groupRequestNoOffersDescription;

  /// Auto metadata for groupRequestBusinessFallback
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get groupRequestBusinessFallback;

  /// Auto metadata for groupRequestTopContributorBadge
  ///
  /// In tr, this message translates to:
  /// **'Grubu en iyi besleyen'**
  String get groupRequestTopContributorBadge;

  /// Auto metadata for groupRequestOfferPriceLabel
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
  /// **'İşleniyor...'**
  String get groupRequestProcessing;

  /// Auto metadata for groupRequestAcceptOfferAction
  ///
  /// In tr, this message translates to:
  /// **'Teklifi kabul et'**
  String get groupRequestAcceptOfferAction;

  /// Auto metadata for groupRequestVotesLabel
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
  /// **'İşletme ve fiyat gerekli'**
  String get groupRequestBusinessAndPriceRequired;

  /// Auto metadata for groupRequestSuggestionAdded
  ///
  /// In tr, this message translates to:
  /// **'Öneri eklendi'**
  String get groupRequestSuggestionAdded;

  /// Auto metadata for groupRequestSearchBusinessLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme ara'**
  String get groupRequestSearchBusinessLabel;

  /// Auto metadata for groupRequestSuggestIfMissing
  ///
  /// In tr, this message translates to:
  /// **'İşletme yoksa öner'**
  String get groupRequestSuggestIfMissing;

  /// Auto metadata for groupRequestTryDifferentName
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir isim deneyin.'**
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
  /// **'Değiştir'**
  String get groupRequestChangeAction;

  /// Auto metadata for groupRequestAcceptedSummary
  ///
  /// In tr, this message translates to:
  /// **'Sonuç seçildi. Toplam: {price}'**
  String groupRequestAcceptedSummary(String price);

  /// Auto metadata for groupRequestCopyResultAction
  ///
  /// In tr, this message translates to:
  /// **'Sonuç kopyala'**
  String get groupRequestCopyResultAction;

  /// Auto metadata for heroesPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Kahramanlar'**
  String get heroesPageTitle;

  /// Auto metadata for heroesPageSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Askıya yemek bırakanlar'**
  String get heroesPageSubtitle;

  /// Auto metadata for heroesPageEmpty
  ///
  /// In tr, this message translates to:
  /// **'Henüz kahraman yok.'**
  String get heroesPageEmpty;

  /// Auto metadata for heroesPageUserFallback
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get heroesPageUserFallback;

  /// Auto metadata for heroesPageDonatedMealCount
  ///
  /// In tr, this message translates to:
  /// **'{count} askıda yemek'**
  String heroesPageDonatedMealCount(int count);

  /// Auto metadata for verifyPriceIsCorrectQuestion
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğru mu?'**
  String get verifyPriceIsCorrectQuestion;

  /// Auto metadata for verifyPriceCorrectAction
  ///
  /// In tr, this message translates to:
  /// **'Doğru'**
  String get verifyPriceCorrectAction;

  /// Auto metadata for verifyPriceIncorrectAction
  ///
  /// In tr, this message translates to:
  /// **'Yanlış'**
  String get verifyPriceIncorrectAction;

  /// Auto metadata for verifyPriceCorrectPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Doğru fiyat (TL)'**
  String get verifyPriceCorrectPriceLabel;

  /// Auto metadata for verifyPriceCorrectPriceHint
  ///
  /// In tr, this message translates to:
  /// **'Örn: 245,50'**
  String get verifyPriceCorrectPriceHint;

  /// Auto metadata for verifyPriceChooseCorrectnessFirst
  ///
  /// In tr, this message translates to:
  /// **'Önce doğru/yanlış seçin.'**
  String get verifyPriceChooseCorrectnessFirst;

  /// Auto metadata for verifyPriceEnterValidPrice
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir fiyat girin.'**
  String get verifyPriceEnterValidPrice;

  /// Auto metadata for menuItemCalories
  ///
  /// In tr, this message translates to:
  /// **'{calories} kcal'**
  String menuItemCalories(int calories);

  /// Auto metadata for menuItemAutoApprovedMessage
  ///
  /// In tr, this message translates to:
  /// **'Fiyat otomatik onaylandı ve menü güncellendi.'**
  String get menuItemAutoApprovedMessage;

  /// Auto metadata for menuItemPendingCountMessage
  ///
  /// In tr, this message translates to:
  /// **'Önerin alındı. Bu ürün için {count} öneri sırada.'**
  String menuItemPendingCountMessage(int count);

  /// Auto metadata for menuItemPendingSingleMessage
  ///
  /// In tr, this message translates to:
  /// **'Önerin alındı, onay bekliyor.'**
  String get menuItemPendingSingleMessage;

  /// Auto metadata for menuItemOnsiteVerifiedPrioritizedMessage
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler. Mekandan doğrulama sinyali alındı, önerin önceliklendirildi.'**
  String get menuItemOnsiteVerifiedPrioritizedMessage;

  /// Auto metadata for menuPhotoWarningDark
  ///
  /// In tr, this message translates to:
  /// **'karanlık'**
  String get menuPhotoWarningDark;

  /// Auto metadata for menuPhotoWarningBlurry
  ///
  /// In tr, this message translates to:
  /// **'bulanık'**
  String get menuPhotoWarningBlurry;

  /// Auto metadata for menuContributionLevelLabel
  ///
  /// In tr, this message translates to:
  /// **'Katkı Seviyesi'**
  String get menuContributionLevelLabel;

  /// Auto metadata for menuScoreUpdated
  ///
  /// In tr, this message translates to:
  /// **'Puanın güncellendi'**
  String get menuScoreUpdated;

  /// Auto metadata for menuLevel
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level}'**
  String menuLevel(int level);

  /// Auto metadata for menuXpValue
  ///
  /// In tr, this message translates to:
  /// **'{xp} XP'**
  String menuXpValue(int xp);

  /// Auto metadata for menuSelectedVariantLabel
  ///
  /// In tr, this message translates to:
  /// **'Seçili varyant: {label} ({price})'**
  String menuSelectedVariantLabel(String label, String price);

  /// Auto metadata for menuPriceHistoryCurrent
  ///
  /// In tr, this message translates to:
  /// **'{current} > {source}'**
  String menuPriceHistoryCurrent(String current, String source);

  /// Auto metadata for menuPriceHistoryTransition
  ///
  /// In tr, this message translates to:
  /// **'{previous} > {current} > {source}'**
  String menuPriceHistoryTransition(
    String previous,
    String current,
    String source,
  );

  /// Auto metadata for menuPriceHistoryMeta
  ///
  /// In tr, this message translates to:
  /// **'{relative} • {date}{delta}'**
  String menuPriceHistoryMeta(String relative, String date, String delta);

  /// Auto metadata for inboxTitle
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kutusu'**
  String get inboxTitle;

  /// Auto metadata for inboxMarkAllRead
  ///
  /// In tr, this message translates to:
  /// **'Tümünü okundu işaretle'**
  String get inboxMarkAllRead;

  /// Auto metadata for inboxEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Bildirim yok'**
  String get inboxEmptyTitle;

  /// Auto metadata for inboxEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi, claim, rapor ve yorum cevabı bildirimleri burada görünecek.'**
  String get inboxEmptyDescription;

  /// Auto metadata for inboxXpGain
  ///
  /// In tr, this message translates to:
  /// **'+{xp} XP'**
  String inboxXpGain(int xp);

  /// Auto metadata for inboxNewLevel
  ///
  /// In tr, this message translates to:
  /// **'Yeni seviye: {level}'**
  String inboxNewLevel(int level);

  /// Auto metadata for inboxLevel
  ///
  /// In tr, this message translates to:
  /// **'Seviye: {level}'**
  String inboxLevel(int level);

  /// Auto metadata for inboxNow
  ///
  /// In tr, this message translates to:
  /// **'Şimdi'**
  String get inboxNow;

  /// Auto metadata for inboxReengagementTitle
  ///
  /// In tr, this message translates to:
  /// **'Seni özledik'**
  String get inboxReengagementTitle;

  /// Auto metadata for inboxReengagementSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki yeni menülere göz at.'**
  String get inboxReengagementSubtitle;

  /// Auto metadata for inboxRecentBusinessClosedTitle
  ///
  /// In tr, this message translates to:
  /// **'Son baktığın işletme kapandı görünüyor'**
  String get inboxRecentBusinessClosedTitle;

  /// Auto metadata for inboxRecentBusinessPriceChangedTitle
  ///
  /// In tr, this message translates to:
  /// **'Son baktığın yerde fiyat değişti'**
  String get inboxRecentBusinessPriceChangedTitle;

  /// Auto metadata for inboxRecentBusinessNearbyTitle
  ///
  /// In tr, this message translates to:
  /// **'Son baktığın yer yakında'**
  String get inboxRecentBusinessNearbyTitle;

  /// Auto metadata for inboxRecentBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'Son baktığın yer'**
  String get inboxRecentBusinessTitle;

  /// Auto metadata for inboxRecentBusinessNearbyReason
  ///
  /// In tr, this message translates to:
  /// **'Sana yakın olduğu için öne alındı'**
  String get inboxRecentBusinessNearbyReason;

  /// Auto metadata for inboxFavoritesPriceChangedTitle
  ///
  /// In tr, this message translates to:
  /// **'Favorilerinde fiyat değişti'**
  String get inboxFavoritesPriceChangedTitle;

  /// Auto metadata for inboxFavoritesPriceChangedSubtitle
  ///
  /// In tr, this message translates to:
  /// **'{name} • Son {count} doğrulama'**
  String inboxFavoritesPriceChangedSubtitle(String name, int count);

  /// Auto metadata for inboxDailyTaskTitle
  ///
  /// In tr, this message translates to:
  /// **'Sana uygun bugünün görevi'**
  String get inboxDailyTaskTitle;

  /// Auto metadata for inboxSegmentPriceHunter
  ///
  /// In tr, this message translates to:
  /// **'Bugün 1 fiyat doğrula; güven skorun daha hızlı artsın.'**
  String get inboxSegmentPriceHunter;

  /// Auto metadata for inboxSegmentPhotoProof
  ///
  /// In tr, this message translates to:
  /// **'Bugün 1 net menü/fotoğraf kanıtı ekle.'**
  String get inboxSegmentPhotoProof;

  /// Auto metadata for inboxSegmentExplorer
  ///
  /// In tr, this message translates to:
  /// **'Bugün yeni bir mekan aç ve fiyat durumunu kontrol et.'**
  String get inboxSegmentExplorer;

  /// Auto metadata for inboxSegmentSilentQuality
  ///
  /// In tr, this message translates to:
  /// **'Sessiz kalite katkın güçlü, doğru veriyi sürdür.'**
  String get inboxSegmentSilentQuality;

  /// Auto metadata for inboxSegmentDefault
  ///
  /// In tr, this message translates to:
  /// **'Bugün küçük bir katkıyla grafiğini güçlendir.'**
  String get inboxSegmentDefault;

  /// Auto metadata for inboxAlertPriceUp
  ///
  /// In tr, this message translates to:
  /// **'Fiyat %{pct} çıktığında'**
  String inboxAlertPriceUp(String pct);

  /// Auto metadata for inboxAlertPriceDown
  ///
  /// In tr, this message translates to:
  /// **'Fiyat %{pct} düştü'**
  String inboxAlertPriceDown(String pct);

  /// Auto metadata for inboxAlertCheaperNow
  ///
  /// In tr, this message translates to:
  /// **'Şuan %{pct} daha ucuz'**
  String inboxAlertCheaperNow(String pct);

  /// Auto metadata for inboxAlertAboveDistrictAverage
  ///
  /// In tr, this message translates to:
  /// **'Bu semtte ortalamanın üstüne çıktığında'**
  String get inboxAlertAboveDistrictAverage;

  /// Auto metadata for inboxAlertBelowDistrictAverage
  ///
  /// In tr, this message translates to:
  /// **'Bu semtte ortalamanın altına indi'**
  String get inboxAlertBelowDistrictAverage;

  /// Auto metadata for inboxAlertTriggered
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alarmı tetiklendi'**
  String get inboxAlertTriggered;

  /// Auto metadata for inboxBusinessClosedArchived
  ///
  /// In tr, this message translates to:
  /// **'İşletme kapandı (arşiv).'**
  String get inboxBusinessClosedArchived;

  /// Auto metadata for inboxBusinessMoved
  ///
  /// In tr, this message translates to:
  /// **'İşletme taşındı.'**
  String get inboxBusinessMoved;

  /// Auto metadata for inboxBusinessTemporarilyClosed
  ///
  /// In tr, this message translates to:
  /// **'İşletme geçici kapalı.'**
  String get inboxBusinessTemporarilyClosed;

  /// Auto metadata for inboxBusinessStatusUpdated
  ///
  /// In tr, this message translates to:
  /// **'Durum güncellendi'**
  String get inboxBusinessStatusUpdated;

  /// Auto metadata for priceAlertSheetTitle
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alarmı oluşturma'**
  String get priceAlertSheetTitle;

  /// Auto metadata for priceAlertSheetQueryLabel
  ///
  /// In tr, this message translates to:
  /// **'Ürün veya arama metni'**
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
  /// **'Arama metni ve geçerli bir fiyat girin.'**
  String get priceAlertSheetValidationError;

  /// Auto metadata for priceAlertSheetSaved
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alarmı kaydedildi.'**
  String get priceAlertSheetSaved;

  /// Auto metadata for achievementStatusUnlocked
  ///
  /// In tr, this message translates to:
  /// **'Durum: Açık'**
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

  /// No description provided for @profileHomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profilin'**
  String get profileHomeTitle;

  /// No description provided for @profileStatFavoritesShort.
  ///
  /// In tr, this message translates to:
  /// **'Favori'**
  String get profileStatFavoritesShort;

  /// No description provided for @profileStatReviewsShort.
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get profileStatReviewsShort;

  /// No description provided for @profileStatListsShort.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get profileStatListsShort;

  /// No description provided for @profileQuickActionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı işlemler'**
  String get profileQuickActionsTitle;

  /// No description provided for @profileQuickActionFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerim'**
  String get profileQuickActionFavorites;

  /// No description provided for @profileQuickActionPriceAlerts.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Alarmları'**
  String get profileQuickActionPriceAlerts;

  /// No description provided for @profileQuickActionFeed.
  ///
  /// In tr, this message translates to:
  /// **'Akışım'**
  String get profileQuickActionFeed;

  /// No description provided for @profileAccountSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get profileAccountSectionTitle;

  /// No description provided for @profileAccountSecurityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Güvenliği'**
  String get profileAccountSecurityTitle;

  /// No description provided for @profileAccountSecuritySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre ve e-posta değiştir'**
  String get profileAccountSecuritySubtitle;

  /// No description provided for @profileBadgesBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rozet Koleksiyonun'**
  String get profileBadgesBannerTitle;

  /// No description provided for @profileBadgesBannerCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} rozetin var!'**
  String profileBadgesBannerCount(int count);

  /// No description provided for @profileBadgesBannerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Keşfetmeye devam et, yeni rozetler kazan! 🚀'**
  String get profileBadgesBannerSubtitle;

  /// Auto metadata for profileIdentitySupportMessage
  ///
  /// In tr, this message translates to:
  /// **'Topluluğa katkılı yaparak profilini güçlendirebilirsin.'**
  String get profileIdentitySupportMessage;

  /// Auto metadata for profileAlertsTab
  ///
  /// In tr, this message translates to:
  /// **'Alarmlar'**
  String get profileAlertsTab;

  /// Auto metadata for profileFeedTab
  ///
  /// In tr, this message translates to:
  /// **'Akış'**
  String get profileFeedTab;

  /// Auto metadata for profileLoginToSeeContributions
  ///
  /// In tr, this message translates to:
  /// **'Katkılarını ve istatistiklerini görmek için giriş yap.'**
  String get profileLoginToSeeContributions;

  /// Auto metadata for profileCreatorBadgeTitle
  ///
  /// In tr, this message translates to:
  /// **'İçerik üretici rozeti'**
  String get profileCreatorBadgeTitle;

  /// Auto metadata for profileCreatorBadgeEnabled
  ///
  /// In tr, this message translates to:
  /// **'Profilin içerik üretici olarak görünüyor.'**
  String get profileCreatorBadgeEnabled;

  /// Auto metadata for profileCreatorBadgeDisabled
  ///
  /// In tr, this message translates to:
  /// **'İstersen içerik üretici rozetini açabilirsin.'**
  String get profileCreatorBadgeDisabled;

  /// Auto metadata for profileAddSocialLinkTitle
  ///
  /// In tr, this message translates to:
  /// **'Sosyal bağlantı ekle'**
  String get profileAddSocialLinkTitle;

  /// Auto metadata for linkLabel
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı'**
  String get linkLabel;

  /// Auto metadata for profileSocialLinksHint
  ///
  /// In tr, this message translates to:
  /// **'YouTube / Instagram / Facebook'**
  String get profileSocialLinksHint;

  /// Auto metadata for profileSocialSaveComingSoon
  ///
  /// In tr, this message translates to:
  /// **'Sosyal bağlantı kaydetme özelliği yakında.'**
  String get profileSocialSaveComingSoon;

  /// No description provided for @profileSocialSaved.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal bağlantı kaydedildi.'**
  String get profileSocialSaved;

  /// No description provided for @profileSocialSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemedi. Lütfen tekrar deneyin.'**
  String get profileSocialSaveError;

  /// Auto metadata for profileStatsTitle
  ///
  /// In tr, this message translates to:
  /// **'Profil istatistikleri'**
  String get profileStatsTitle;

  /// Auto metadata for profileCommunityTrustTitle
  ///
  /// In tr, this message translates to:
  /// **'Topluluk güveni'**
  String get profileCommunityTrustTitle;

  /// Auto metadata for profileCalculating
  ///
  /// In tr, this message translates to:
  /// **'Hesaplanıyor...'**
  String get profileCalculating;

  /// Auto metadata for profileTrustScorePercent
  ///
  /// In tr, this message translates to:
  /// **'Topluluk güveni: %{score}'**
  String profileTrustScorePercent(int score);

  /// Auto metadata for profileLevelXp
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level} • Toplam {xp} XP'**
  String profileLevelXp(int level, int xp);

  /// Auto metadata for profileMyAchievementsTitle
  ///
  /// In tr, this message translates to:
  /// **'Başarı rozetlerim'**
  String get profileMyAchievementsTitle;

  /// Auto metadata for profileNoAchievementYet
  ///
  /// In tr, this message translates to:
  /// **'Henüz rozet kazanmadın.'**
  String get profileNoAchievementYet;

  /// Auto metadata for profileAlertsLoginRequired
  ///
  /// In tr, this message translates to:
  /// **'Alarmları görmek için giriş yap.'**
  String get profileAlertsLoginRequired;

  /// Auto metadata for profileAlertsEmpty
  ///
  /// In tr, this message translates to:
  /// **'Henüz alarm bildirimi yok.'**
  String get profileAlertsEmpty;

  /// Auto metadata for profileFeedLoginRequired
  ///
  /// In tr, this message translates to:
  /// **'Akışı görmek için giriş yap.'**
  String get profileFeedLoginRequired;

  /// Auto metadata for profileFeedEmpty
  ///
  /// In tr, this message translates to:
  /// **'Akışta henüz içerik yok.'**
  String get profileFeedEmpty;

  /// Auto metadata for profileFeedEventPriceVerified
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulandı'**
  String get profileFeedEventPriceVerified;

  /// Auto metadata for profileFeedEventMenuUpdated
  ///
  /// In tr, this message translates to:
  /// **'Menü güncellendi'**
  String get profileFeedEventMenuUpdated;

  /// Auto metadata for profileFeedEventSponsored
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu güncelleme'**
  String get profileFeedEventSponsored;

  /// Auto metadata for profileDailyTaskTitle
  ///
  /// In tr, this message translates to:
  /// **'Bugünün görevi'**
  String get profileDailyTaskTitle;

  /// Auto metadata for profileDailyTaskCompleted
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get profileDailyTaskCompleted;

  /// Auto metadata for profileSegmentHintPriceHunter
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulama tarafında güçlüsün; bugün tek bir ürün doğrulaması yeterli.'**
  String get profileSegmentHintPriceHunter;

  /// Auto metadata for profileSegmentHintPhotoProof
  ///
  /// In tr, this message translates to:
  /// **'Kanıt odaklı gidiyorsun; net bir menü fotoğrafı etkiyi artırır.'**
  String get profileSegmentHintPhotoProof;

  /// Auto metadata for profileSegmentHintExplorer
  ///
  /// In tr, this message translates to:
  /// **'Keşif odaklısın; yeni bir işletmeyi kontrol etmek görevi hızlandırır.'**
  String get profileSegmentHintExplorer;

  /// Auto metadata for profileSegmentHintDefault
  ///
  /// In tr, this message translates to:
  /// **'Küçük ama doğru katkılar güven grafiğini en hızlı büyütür.'**
  String get profileSegmentHintDefault;

  /// Auto metadata for profileStatReviews
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get profileStatReviews;

  /// Auto metadata for profileStatHelpfulVotes
  ///
  /// In tr, this message translates to:
  /// **'Faydalı oy'**
  String get profileStatHelpfulVotes;

  /// Auto metadata for profileStatFavorites
  ///
  /// In tr, this message translates to:
  /// **'Favori'**
  String get profileStatFavorites;

  /// Auto metadata for profileStatContributions
  ///
  /// In tr, this message translates to:
  /// **'Katkı'**
  String get profileStatContributions;

  /// Auto metadata for profileStatVisits
  ///
  /// In tr, this message translates to:
  /// **'Ziyaret'**
  String get profileStatVisits;

  /// Auto metadata for profileLatestAchievementTitle
  ///
  /// In tr, this message translates to:
  /// **'Son kazanılan başarı'**
  String get profileLatestAchievementTitle;

  /// Auto metadata for profileAlertCurrentPrice
  ///
  /// In tr, this message translates to:
  /// **'Güncel fiyat: {price} TL'**
  String profileAlertCurrentPrice(String price);

  /// Auto metadata for profileAlertPriceChanged
  ///
  /// In tr, this message translates to:
  /// **'Fiyat değişti: {previous} → {current} TL'**
  String profileAlertPriceChanged(String previous, String current);

  /// Auto metadata for profileSegmentPriceHunter
  ///
  /// In tr, this message translates to:
  /// **'Fiyat avcısı'**
  String get profileSegmentPriceHunter;

  /// Auto metadata for profileSegmentExplorer
  ///
  /// In tr, this message translates to:
  /// **'Keşif'**
  String get profileSegmentExplorer;

  /// Auto metadata for profileSegmentPhotoProof
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf kanıtı'**
  String get profileSegmentPhotoProof;

  /// Auto metadata for profileSegmentBalanced
  ///
  /// In tr, this message translates to:
  /// **'Dengeli'**
  String get profileSegmentBalanced;

  /// Auto metadata for profileMoatSignalsTitle
  ///
  /// In tr, this message translates to:
  /// **'Destek sinyalleri'**
  String get profileMoatSignalsTitle;

  /// Auto metadata for profileSignalTrust
  ///
  /// In tr, this message translates to:
  /// **'Güven'**
  String get profileSignalTrust;

  /// Auto metadata for profileSignalAccuracy
  ///
  /// In tr, this message translates to:
  /// **'Doğruluk'**
  String get profileSignalAccuracy;

  /// Auto metadata for profileSignalSegment
  ///
  /// In tr, this message translates to:
  /// **'Katkı stili'**
  String get profileSignalSegment;

  /// Auto metadata for profileSignalSilentQuality
  ///
  /// In tr, this message translates to:
  /// **'Kalite serisi'**
  String get profileSignalSilentQuality;

  /// No description provided for @profileSignalApprovalRate.
  ///
  /// In tr, this message translates to:
  /// **'Onay oranı'**
  String get profileSignalApprovalRate;

  /// No description provided for @profileSupportSignalsSummary.
  ///
  /// In tr, this message translates to:
  /// **'Bu sinyaller topluluk güvenini besler; ayrı ana skorlar değildir.'**
  String get profileSupportSignalsSummary;

  /// Auto metadata for profileMoatTrustedRejectedSpam
  ///
  /// In tr, this message translates to:
  /// **'Güvenilen katkı: {trusted} • Reddedilen: {rejected} • Spam sinyali: {spam}'**
  String profileMoatTrustedRejectedSpam(int trusted, int rejected, int spam);

  /// Auto metadata for profileMoatBehaviorSummary
  ///
  /// In tr, this message translates to:
  /// **'Davranış: fiyat {price}, keşif {discovery}, fotoğraf {photo}'**
  String profileMoatBehaviorSummary(int price, int discovery, int photo);

  /// Auto metadata for profileMoatSilentQualityHint
  ///
  /// In tr, this message translates to:
  /// **'Kalite serin güçlü; az ama doğru katkıların öne çıkıyor.'**
  String get profileMoatSilentQualityHint;

  /// Auto metadata for businessReviewsCommunityExperiences
  ///
  /// In tr, this message translates to:
  /// **'Topluluğun deneyimleri'**
  String get businessReviewsCommunityExperiences;

  /// Auto metadata for businessReviewsOwnerCanModerate
  ///
  /// In tr, this message translates to:
  /// **'İşletme sahibi uygun olmayan yorumları yönetebilir.'**
  String get businessReviewsOwnerCanModerate;

  /// Auto metadata for businessReviewsOwnersCanOnlyReply
  ///
  /// In tr, this message translates to:
  /// **'İşletme sahipleri yalnızca yorumlara cevap verebilir.'**
  String get businessReviewsOwnersCanOnlyReply;

  /// Auto metadata for sortNewest
  ///
  /// In tr, this message translates to:
  /// **'En yeni'**
  String get sortNewest;

  /// Auto metadata for sortMostHelpful
  ///
  /// In tr, this message translates to:
  /// **'En faydalı'**
  String get sortMostHelpful;

  /// No description provided for @sortVerified.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış'**
  String get sortVerified;

  /// Auto metadata for businessReviewsQualityLabel
  ///
  /// In tr, this message translates to:
  /// **'Kalite skoru: {score}'**
  String businessReviewsQualityLabel(String score);

  /// Auto metadata for helpfulCount
  ///
  /// In tr, this message translates to:
  /// **'Faydalı ({count})'**
  String helpfulCount(int count);

  /// Auto metadata for businessReviewsEmpty
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yok.'**
  String get businessReviewsEmpty;

  /// Auto metadata for reviewCreateRatingLabel
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get reviewCreateRatingLabel;

  /// Auto metadata for reviewCreateOptionalTitleLabel
  ///
  /// In tr, this message translates to:
  /// **'Başlık (isteğe bağlı)'**
  String get reviewCreateOptionalTitleLabel;

  /// Auto metadata for reviewCreateContentRequired
  ///
  /// In tr, this message translates to:
  /// **'Yorum boş olamaz.'**
  String get reviewCreateContentRequired;

  /// Auto metadata for reviewCreateSubmitted
  ///
  /// In tr, this message translates to:
  /// **'Yorum gönderildi.'**
  String get reviewCreateSubmitted;

  /// Auto metadata for reviewCreatePhotoUploadFailed
  ///
  /// In tr, this message translates to:
  /// **'Yorum gönderildi ama fotoğraf yüklenemedi. Daha sonra tekrar deneyebilirsin.'**
  String get reviewCreatePhotoUploadFailed;

  /// Auto metadata for reviewCreateErrorNewAccountRateLimited
  ///
  /// In tr, this message translates to:
  /// **'Yeni hesaplar için günlük yorum limiti doldu.'**
  String get reviewCreateErrorNewAccountRateLimited;

  /// Auto metadata for reviewCreateErrorSameBusinessCooldown
  ///
  /// In tr, this message translates to:
  /// **'Aynı işletme için kısa sürede tekrar yorum gönderemezsin.'**
  String get reviewCreateErrorSameBusinessCooldown;

  /// Auto metadata for reviewCreateErrorContainsLinkOrPhone
  ///
  /// In tr, this message translates to:
  /// **'Yorumda link veya telefon bilgisi paylaşılamaz.'**
  String get reviewCreateErrorContainsLinkOrPhone;

  /// Auto metadata for reviewCreateErrorContainsProfanity
  ///
  /// In tr, this message translates to:
  /// **'Yorumda uygunsuz ifade var.'**
  String get reviewCreateErrorContainsProfanity;

  /// Auto metadata for reviewCreateErrorEmojiSpam
  ///
  /// In tr, this message translates to:
  /// **'Yorumda çok fazla emoji var.'**
  String get reviewCreateErrorEmojiSpam;

  /// Auto metadata for reviewCreateHeroTitle
  ///
  /// In tr, this message translates to:
  /// **'Yorum Yap ve Puan Ver'**
  String get reviewCreateHeroTitle;

  /// Auto metadata for reviewCreateHeroSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Deneyimini paylaş, topluluğa yardımcı ol'**
  String get reviewCreateHeroSubtitle;

  /// Auto metadata for reviewCreateRatingHintLow
  ///
  /// In tr, this message translates to:
  /// **'Kötü'**
  String get reviewCreateRatingHintLow;

  /// Auto metadata for reviewCreateRatingHintHigh
  ///
  /// In tr, this message translates to:
  /// **'Mükemmel'**
  String get reviewCreateRatingHintHigh;

  /// Auto metadata for reviewCreateContentLabel
  ///
  /// In tr, this message translates to:
  /// **'Yorumun (isteğe bağlı)'**
  String get reviewCreateContentLabel;

  /// Auto metadata for reviewCreateContentPlaceholder
  ///
  /// In tr, this message translates to:
  /// **'Deneyimini buraya yazabilirsin...'**
  String get reviewCreateContentPlaceholder;

  /// Auto metadata for reviewCreatePhotosLabel
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Ekle'**
  String get reviewCreatePhotosLabel;

  /// Auto metadata for reviewCreateAddPhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf ekle'**
  String get reviewCreateAddPhoto;

  /// Auto metadata for reviewCreateAddPhotoHint
  ///
  /// In tr, this message translates to:
  /// **'En fazla {max} foto'**
  String reviewCreateAddPhotoHint(int max);

  /// Auto metadata for reviewCreateExperienceLabel
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Değerlendirme (isteğe bağlı)'**
  String get reviewCreateExperienceLabel;

  /// Auto metadata for reviewCreateAddToFavorites
  ///
  /// In tr, this message translates to:
  /// **'Bu işletmeyi favorilerime ekle'**
  String get reviewCreateAddToFavorites;

  /// Auto metadata for reviewCreateSubmitCta
  ///
  /// In tr, this message translates to:
  /// **'Yorumu Gönder'**
  String get reviewCreateSubmitCta;

  /// Auto metadata for reviewRatingCriterionTaste
  ///
  /// In tr, this message translates to:
  /// **'Lezzet'**
  String get reviewRatingCriterionTaste;

  /// Auto metadata for reviewRatingCriterionServiceSpeed
  ///
  /// In tr, this message translates to:
  /// **'Servis Hızı'**
  String get reviewRatingCriterionServiceSpeed;

  /// Auto metadata for reviewRatingCriterionPricePerformance
  ///
  /// In tr, this message translates to:
  /// **'Fiyat performans'**
  String get reviewRatingCriterionPricePerformance;

  /// Auto metadata for reviewRatingCriterionCleanliness
  ///
  /// In tr, this message translates to:
  /// **'Temizlik'**
  String get reviewRatingCriterionCleanliness;

  /// Auto metadata for reviewRatingCriterionAtmosphere
  ///
  /// In tr, this message translates to:
  /// **'Atmosfer'**
  String get reviewRatingCriterionAtmosphere;

  /// Auto metadata for appShellExitOnBackPress
  ///
  /// In tr, this message translates to:
  /// **'Çıkmak için tekrar basın'**
  String get appShellExitOnBackPress;

  /// Auto metadata for businessMenuPreviewConfirmedByCount
  ///
  /// In tr, this message translates to:
  /// **'{count} kullanıcı onayladı'**
  String businessMenuPreviewConfirmedByCount(int count);

  /// Auto metadata for discoveryBudgetPerPersonUnlimited
  ///
  /// In tr, this message translates to:
  /// **'Kişi başı bütçe: Sınırsız'**
  String get discoveryBudgetPerPersonUnlimited;

  /// Auto metadata for discoveryBudgetPerPersonMax
  ///
  /// In tr, this message translates to:
  /// **'Kişi başı max bütçe: {amount}₺'**
  String discoveryBudgetPerPersonMax(int amount);

  /// Auto metadata for discoveryBudgetSliderUnlimited
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız'**
  String get discoveryBudgetSliderUnlimited;

  /// Auto metadata for discoveryMaxBudgetChipLabel
  ///
  /// In tr, this message translates to:
  /// **'Max {amount}₺'**
  String discoveryMaxBudgetChipLabel(int amount);

  /// Auto metadata for discoveryTasteTwinChipLabel
  ///
  /// In tr, this message translates to:
  /// **'Taste Twin'**
  String get discoveryTasteTwinChipLabel;

  /// Auto metadata for heroesWeeklyLeaderboardTitle
  ///
  /// In tr, this message translates to:
  /// **'Haftalık En İyi Katkıcılar'**
  String get heroesWeeklyLeaderboardTitle;

  /// Auto metadata for heroesWeeklyLeaderboardSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günde en çok fiyat doğrulayan, yorum yazan ve fotoğraf ekleyenler'**
  String get heroesWeeklyLeaderboardSubtitle;

  /// Auto metadata for heroesWeeklyLeaderboardEmpty
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta henüz katkı yok.'**
  String get heroesWeeklyLeaderboardEmpty;

  /// Auto metadata for heroesAllTimeTitle
  ///
  /// In tr, this message translates to:
  /// **'Tüm Zamanlar Kahramanları'**
  String get heroesAllTimeTitle;

  /// Auto metadata for heroesWeeklyStatsLine
  ///
  /// In tr, this message translates to:
  /// **'{verifyCount} doğrulama · {reviewCount} yorum · {photoCount} fotoğraf'**
  String heroesWeeklyStatsLine(
    int verifyCount,
    int reviewCount,
    int photoCount,
  );

  /// Auto metadata for menuItemsConfirmedByCount
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi onayladı'**
  String menuItemsConfirmedByCount(int count);

  /// Auto metadata for menuOfflineSaveTooltipSaved
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı kaydedildi'**
  String get menuOfflineSaveTooltipSaved;

  /// Auto metadata for menuOfflineSaveTooltipUnsaved
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı kaydet'**
  String get menuOfflineSaveTooltipUnsaved;

  /// Auto metadata for menuOfflineSavedSnackbar
  ///
  /// In tr, this message translates to:
  /// **'Menü çevrimdışı için kaydedildi'**
  String get menuOfflineSavedSnackbar;

  /// Auto metadata for priceOnRequest
  ///
  /// In tr, this message translates to:
  /// **'Fiyata sorunuz'**
  String get priceOnRequest;

  /// Auto metadata for menuTimeWindowNowDiscount
  ///
  /// In tr, this message translates to:
  /// **'Şu an: {label} • %{pct} indirimli ({timeRange})'**
  String menuTimeWindowNowDiscount(String label, String timeRange, int pct);

  /// Auto metadata for menuTimeWindowUpcomingDiscount
  ///
  /// In tr, this message translates to:
  /// **'{label} daha uygun ({timeRange}) • %{pct} indirim'**
  String menuTimeWindowUpcomingDiscount(
    String label,
    String timeRange,
    int pct,
  );

  /// Auto metadata for menuTimeWindowNowPrice
  ///
  /// In tr, this message translates to:
  /// **'Şu an: {label} {priceText} ({timeRange})'**
  String menuTimeWindowNowPrice(
    String label,
    String timeRange,
    String priceText,
  );

  /// Auto metadata for menuTimeWindowUpcomingPrice
  ///
  /// In tr, this message translates to:
  /// **'{label} fiyatı {priceText} ({timeRange})'**
  String menuTimeWindowUpcomingPrice(
    String label,
    String timeRange,
    String priceText,
  );

  /// Auto metadata for menuTimeWindowNowPlain
  ///
  /// In tr, this message translates to:
  /// **'Şu an: {label} ({timeRange})'**
  String menuTimeWindowNowPlain(String label, String timeRange);

  /// Auto metadata for menuTimeWindowUpcomingPlain
  ///
  /// In tr, this message translates to:
  /// **'{label} ({timeRange})'**
  String menuTimeWindowUpcomingPlain(String label, String timeRange);

  /// Auto metadata for menuDataTrustLabel
  ///
  /// In tr, this message translates to:
  /// **'Veri güveni'**
  String get menuDataTrustLabel;

  /// Auto metadata for menuPriceMetaToday
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get menuPriceMetaToday;

  /// Auto metadata for menuPriceMetaYesterday
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get menuPriceMetaYesterday;

  /// Auto metadata for menuPriceMetaDaysAgo
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce'**
  String menuPriceMetaDaysAgo(int days);

  /// Auto metadata for menuPriceMetaMonthsAgo
  ///
  /// In tr, this message translates to:
  /// **'{months} ay önce'**
  String menuPriceMetaMonthsAgo(int months);

  /// Auto metadata for menuPriceMetaUpdated
  ///
  /// In tr, this message translates to:
  /// **'Son güncelleme: {timeStr}'**
  String menuPriceMetaUpdated(String timeStr);

  /// Auto metadata for menuPriceMetaVerifierCount
  ///
  /// In tr, this message translates to:
  /// **'{count} doğrulayıcı'**
  String menuPriceMetaVerifierCount(int count);

  /// Auto metadata for menuPriceMetaVoteCount
  ///
  /// In tr, this message translates to:
  /// **'{count} oylama'**
  String menuPriceMetaVoteCount(int count);

  /// Auto metadata for menuPriceBenchmarkSame
  ///
  /// In tr, this message translates to:
  /// **'Şehir ort: {avgText} (benzer fiyat)'**
  String menuPriceBenchmarkSame(String avgText);

  /// Auto metadata for menuPriceBenchmarkCheaper
  ///
  /// In tr, this message translates to:
  /// **'Şehir ort: {avgText} • %{pct} daha ucuz'**
  String menuPriceBenchmarkCheaper(String avgText, int pct);

  /// Auto metadata for menuPriceBenchmarkPricier
  ///
  /// In tr, this message translates to:
  /// **'Şehir ort: {avgText} • %{pct} daha pahalı'**
  String menuPriceBenchmarkPricier(String avgText, int pct);

  /// Auto metadata for menuNutritionDisclaimer
  ///
  /// In tr, this message translates to:
  /// **'Değerler tahmini olabilir. Alerji durumunuz için lütfen personele bilgi veriniz.'**
  String get menuNutritionDisclaimer;

  /// Auto metadata for menuTransparentMenuTitle
  ///
  /// In tr, this message translates to:
  /// **'Şeffaf Menü'**
  String get menuTransparentMenuTitle;

  /// Auto metadata for menuIngredientsLabel
  ///
  /// In tr, this message translates to:
  /// **'İçindekiler'**
  String get menuIngredientsLabel;

  /// Auto metadata for quality
  ///
  /// In tr, this message translates to:
  /// **'Kalite'**
  String get quality;

  /// Auto metadata for smartFeedEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz akış yok'**
  String get smartFeedEmptyTitle;

  /// Auto metadata for smartFeedEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri gevşetebilir ya da ilk katkıyı sen ekleyebilirsin.'**
  String get smartFeedEmptyDescription;

  /// Auto metadata for smartFeedCurationTitle
  ///
  /// In tr, this message translates to:
  /// **'Kürasyon'**
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

  /// Auto metadata for smartFeedBudgetMax
  ///
  /// In tr, this message translates to:
  /// **'En fazla â‚º{amount}'**
  String smartFeedBudgetMax(String amount);

  /// Auto metadata for smartFeedUnlimited
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız'**
  String get smartFeedUnlimited;

  /// Auto metadata for smartFeedPreferenceHint
  ///
  /// In tr, this message translates to:
  /// **'Tercih: {label}'**
  String smartFeedPreferenceHint(String label);

  /// Auto metadata for smartFeedScenarioHint
  ///
  /// In tr, this message translates to:
  /// **'Senaryo: {label}'**
  String smartFeedScenarioHint(String label);

  /// Auto metadata for smartFeedContextDefault
  ///
  /// In tr, this message translates to:
  /// **'Bugünün akışını senin ritmine göre hazırlıyoruz.'**
  String get smartFeedContextDefault;

  /// Auto metadata for smartFeedCategoryMeyhane
  ///
  /// In tr, this message translates to:
  /// **'Meyhane'**
  String get smartFeedCategoryMeyhane;

  /// Auto metadata for smartFeedCategoryAffordable
  ///
  /// In tr, this message translates to:
  /// **'Uygun fiyatlı'**
  String get smartFeedCategoryAffordable;

  /// Auto metadata for smartFeedBundleStudentFriendly
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci dostu'**
  String get smartFeedBundleStudentFriendly;

  /// Auto metadata for smartFeedBundleFirstDate
  ///
  /// In tr, this message translates to:
  /// **'İlk randevu'**
  String get smartFeedBundleFirstDate;

  /// Auto metadata for smartFeedBundleNightSoup
  ///
  /// In tr, this message translates to:
  /// **'Gece çorbası'**
  String get smartFeedBundleNightSoup;

  /// Auto metadata for smartFeedMinutesAgo
  ///
  /// In tr, this message translates to:
  /// **'{count} dk önce'**
  String smartFeedMinutesAgo(int count);

  /// Auto metadata for smartFeedHoursAgo
  ///
  /// In tr, this message translates to:
  /// **'{count} saat önce'**
  String smartFeedHoursAgo(int count);

  /// Auto metadata for smartFeedDaysAgo
  ///
  /// In tr, this message translates to:
  /// **'{count} gün önce'**
  String smartFeedDaysAgo(int count);

  /// Auto metadata for smartFeedEventMenu
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get smartFeedEventMenu;

  /// Auto metadata for smartFeedEventPrice
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get smartFeedEventPrice;

  /// Auto metadata for smartFeedEventPhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf'**
  String get smartFeedEventPhoto;

  /// Auto metadata for smartFeedEventDaily
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get smartFeedEventDaily;

  /// Auto metadata for smartFeedEventSponsor
  ///
  /// In tr, this message translates to:
  /// **'Sponsor'**
  String get smartFeedEventSponsor;

  /// Auto metadata for smartFeedFallbackPriceChanged
  ///
  /// In tr, this message translates to:
  /// **'Fiyat güncellendi'**
  String get smartFeedFallbackPriceChanged;

  /// Auto metadata for smartFeedFallbackPhotoAdded
  ///
  /// In tr, this message translates to:
  /// **'Yeni fotoğraf eklendi'**
  String get smartFeedFallbackPhotoAdded;

  /// Auto metadata for smartFeedFallbackDailyMenu
  ///
  /// In tr, this message translates to:
  /// **'Günün menüsü'**
  String get smartFeedFallbackDailyMenu;

  /// Auto metadata for smartFeedFallbackNewContent
  ///
  /// In tr, this message translates to:
  /// **'Yeni içerik'**
  String get smartFeedFallbackNewContent;

  /// Auto metadata for smartFeedCtaGoToMenu
  ///
  /// In tr, this message translates to:
  /// **'Menüye git'**
  String get smartFeedCtaGoToMenu;

  /// Auto metadata for smartFeedCtaOpenItem
  ///
  /// In tr, this message translates to:
  /// **'Ürünü aç'**
  String get smartFeedCtaOpenItem;

  /// Auto metadata for smartFeedCtaViewPhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafa bak'**
  String get smartFeedCtaViewPhoto;

  /// Auto metadata for smartFeedCtaGoToBusiness
  ///
  /// In tr, this message translates to:
  /// **'İşletmeye git'**
  String get smartFeedCtaGoToBusiness;

  /// Auto metadata for smartFeedNearbyKm
  ///
  /// In tr, this message translates to:
  /// **'Yakınında {km} km'**
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
  /// **'Benzer kullanıcılar seviyor'**
  String get smartFeedReasonSimilarUsers;

  /// Auto metadata for smartFeedDayWeekend
  ///
  /// In tr, this message translates to:
  /// **'Hafta sonu'**
  String get smartFeedDayWeekend;

  /// Auto metadata for smartFeedDayWeekday
  ///
  /// In tr, this message translates to:
  /// **'Hafta içi'**
  String get smartFeedDayWeekday;

  /// Auto metadata for smartFeedTimeMorning
  ///
  /// In tr, this message translates to:
  /// **'Sabah'**
  String get smartFeedTimeMorning;

  /// Auto metadata for smartFeedTimeNoon
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get smartFeedTimeNoon;

  /// Auto metadata for smartFeedTimeEvening
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get smartFeedTimeEvening;

  /// Auto metadata for smartFeedTimeNight
  ///
  /// In tr, this message translates to:
  /// **'Gece'**
  String get smartFeedTimeNight;

  /// Auto metadata for suggestBusinessSubmitDialogTitle
  ///
  /// In tr, this message translates to:
  /// **'Önerin alındı mı?'**
  String get suggestBusinessSubmitDialogTitle;

  /// Auto metadata for suggestBusinessSubmitDialogContent
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler! İnceleme sonucunda işletme yayına alınacak.\n\nTakip Kodu: {code}'**
  String suggestBusinessSubmitDialogContent(String code);

  /// Auto metadata for ok
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// Auto metadata for suggestBusinessPageTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme Öner'**
  String get suggestBusinessPageTitle;

  /// Auto metadata for suggestBusinessPageSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Bulduğun işletmeyi ekle, topluluğa katkı yap. İnceleme sonucunda yayınlarız.'**
  String get suggestBusinessPageSubtitle;

  /// Auto metadata for suggestBusinessNameLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme adı'**
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
  /// **'Bu işletme zaten var olabilir'**
  String get suggestBusinessDuplicateTitle;

  /// Auto metadata for suggestBusinessDuplicateFound
  ///
  /// In tr, this message translates to:
  /// **'Arama sonucunda benzer işletmeler bulundu:'**
  String get suggestBusinessDuplicateFound;

  /// Auto metadata for suggestBusinessDuplicateConfirm
  ///
  /// In tr, this message translates to:
  /// **'Yine de yeni öneriyi göndermek istiyor musun?'**
  String get suggestBusinessDuplicateConfirm;

  /// Auto metadata for suggestBusinessSendAnyway
  ///
  /// In tr, this message translates to:
  /// **'Yine de Gönder'**
  String get suggestBusinessSendAnyway;

  /// Auto metadata for suggestBusinessOpenAction
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get suggestBusinessOpenAction;

  /// Auto metadata for copy
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// Auto metadata for topBusinessesNotEnoughData
  ///
  /// In tr, this message translates to:
  /// **'Henüz yeterli veri yok.'**
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
  /// **'Askıda Yemeklerim'**
  String get suspendedMealsMyClaimsTitle;

  /// Auto metadata for suspendedMealsStatusCodeReady
  ///
  /// In tr, this message translates to:
  /// **'Kod hazır'**
  String get suspendedMealsStatusCodeReady;

  /// Auto metadata for suspendedMealsStatusFulfilled
  ///
  /// In tr, this message translates to:
  /// **'Teslim alındı'**
  String get suspendedMealsStatusFulfilled;

  /// Auto metadata for suspendedMealsNoRecords
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok.'**
  String get suspendedMealsNoRecords;

  /// Auto metadata for suspendedMealsDeliveryCode
  ///
  /// In tr, this message translates to:
  /// **'Teslim kodu'**
  String get suspendedMealsDeliveryCode;

  /// Auto metadata for suspendedMealsCodeCopied
  ///
  /// In tr, this message translates to:
  /// **'Kod kopyalandı'**
  String get suspendedMealsCodeCopied;

  /// Auto metadata for suspendedMealsCodeHint
  ///
  /// In tr, this message translates to:
  /// **'Restorana gidip bu kodu söyle.'**
  String get suspendedMealsCodeHint;

  /// Auto metadata for suspendedMealsPendingReview
  ///
  /// In tr, this message translates to:
  /// **'İnceleniyor'**
  String get suspendedMealsPendingReview;

  /// Auto metadata for suspendedMealsMonthsAgo
  ///
  /// In tr, this message translates to:
  /// **'{count} ay önce'**
  String suspendedMealsMonthsAgo(int count);

  /// Auto metadata for tasteTwinTitle
  ///
  /// In tr, this message translates to:
  /// **'Damak Tadı İkizi'**
  String get tasteTwinTitle;

  /// Auto metadata for tasteTwinLoginRequired
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfayı görmek için giriş yapmalısın.'**
  String get tasteTwinLoginRequired;

  /// Auto metadata for tasteTwinSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Puanlamalarına göre sana benzeyen kişiler'**
  String get tasteTwinSubtitle;

  /// Auto metadata for tasteTwinNoMatches
  ///
  /// In tr, this message translates to:
  /// **'Henüz eşleşme yok.'**
  String get tasteTwinNoMatches;

  /// Auto metadata for tasteTwinMatchSummary
  ///
  /// In tr, this message translates to:
  /// **'%{similarity} uyum • Ortak {places} yer'**
  String tasteTwinMatchSummary(int similarity, int places);

  /// Auto metadata for tasteTwinSignalHint
  ///
  /// In tr, this message translates to:
  /// **'Yorum + menü sinyali'**
  String get tasteTwinSignalHint;

  /// Auto metadata for tasteTwinViewSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Önerileri gör'**
  String get tasteTwinViewSuggestions;

  /// Auto metadata for tasteTwinRecommendationsTitle
  ///
  /// In tr, this message translates to:
  /// **'{name} önerileri'**
  String tasteTwinRecommendationsTitle(String name);

  /// Auto metadata for tasteTwinFollowGourmet
  ///
  /// In tr, this message translates to:
  /// **'Bu gurmeyi takip et'**
  String get tasteTwinFollowGourmet;

  /// Auto metadata for tasteTwinNoSuggestionsYet
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik öneri yok.'**
  String get tasteTwinNoSuggestionsYet;

  /// Auto metadata for tasteTwinWhyMatchedTitle
  ///
  /// In tr, this message translates to:
  /// **'Neden eşleştiniz?'**
  String get tasteTwinWhyMatchedTitle;

  /// Auto metadata for tasteTwinReviewOverlapTitle
  ///
  /// In tr, this message translates to:
  /// **'Yorum ortaklığı'**
  String get tasteTwinReviewOverlapTitle;

  /// Auto metadata for tasteTwinNoSampleYet
  ///
  /// In tr, this message translates to:
  /// **'Henüz örnek yok.'**
  String get tasteTwinNoSampleYet;

  /// Auto metadata for tasteTwinMenuSignalOverlapTitle
  ///
  /// In tr, this message translates to:
  /// **'Menü sinyali ortaklığı'**
  String get tasteTwinMenuSignalOverlapTitle;

  /// Auto metadata for tasteTwinMenuSignalOverlapHint
  ///
  /// In tr, this message translates to:
  /// **'Fiyat teyidi / fotoğraf beğenisi / fotoğraf ekleme sinyalleri'**
  String get tasteTwinMenuSignalOverlapHint;

  /// Auto metadata for tasteTwinDivergenceTitle
  ///
  /// In tr, this message translates to:
  /// **'Burada anlaşılmadınız :)'**
  String get tasteTwinDivergenceTitle;

  /// Auto metadata for tasteTwinRatingComparison
  ///
  /// In tr, this message translates to:
  /// **'Sen: {myRating} • O: {otherRating}'**
  String tasteTwinRatingComparison(int myRating, int otherRating);

  /// Auto metadata for tasteTwinYouAt
  ///
  /// In tr, this message translates to:
  /// **'Sen {value}'**
  String tasteTwinYouAt(String value);

  /// Auto metadata for tasteTwinSignalComparison
  ///
  /// In tr, this message translates to:
  /// **'Sen: +{mySignal} • O: +{otherSignal}'**
  String tasteTwinSignalComparison(int mySignal, int otherSignal);

  /// Auto metadata for tasteTwinMatchRated
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmen {rating} puan verdi'**
  String tasteTwinMatchRated(int rating);

  /// Auto metadata for tasteTwinRatedAt
  ///
  /// In tr, this message translates to:
  /// **'{when} {text}'**
  String tasteTwinRatedAt(String when, String text);

  /// Auto metadata for tasteTwinDebugReviewAndSignal
  ///
  /// In tr, this message translates to:
  /// **'Yorum {review}% + sinyal {signal}%'**
  String tasteTwinDebugReviewAndSignal(int review, int signal);

  /// Auto metadata for tasteTwinDebugReviewOnly
  ///
  /// In tr, this message translates to:
  /// **'Yorum {review}%'**
  String tasteTwinDebugReviewOnly(int review);

  /// Auto metadata for tasteTwinDebugSignalOnly
  ///
  /// In tr, this message translates to:
  /// **'Sinyal {signal}%'**
  String tasteTwinDebugSignalOnly(int signal);

  /// Auto metadata for tasteTwinTodayLower
  ///
  /// In tr, this message translates to:
  /// **'bugün'**
  String get tasteTwinTodayLower;

  /// Auto metadata for tasteTwinYesterdayLower
  ///
  /// In tr, this message translates to:
  /// **'dün'**
  String get tasteTwinYesterdayLower;

  /// Auto metadata for use
  ///
  /// In tr, this message translates to:
  /// **'Kullan'**
  String get use;

  /// Auto metadata for quickLoginTitle
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için giriş yap'**
  String get quickLoginTitle;

  /// Auto metadata for quickLoginDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için hesap gerekiyor. Giriş yapabilir veya Şimdi geçebilirsin.'**
  String get quickLoginDescription;

  /// Auto metadata for quickLoginAction
  ///
  /// In tr, this message translates to:
  /// **'Hızlı giriş'**
  String get quickLoginAction;

  /// Auto metadata for statusBadgeVerified
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get statusBadgeVerified;

  /// Auto metadata for statusBadgePending
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get statusBadgePending;

  /// Auto metadata for statusBadgeOutdated
  ///
  /// In tr, this message translates to:
  /// **'Güncel değil'**
  String get statusBadgeOutdated;

  /// Auto metadata for locationPickerManualHint
  ///
  /// In tr, this message translates to:
  /// **'Manuel seçimde il/ilçe bazlı arama yapılır. Yakınlardaki kalite için yarıçap (5/10/20 km) ve konum izni daha iyi sonuç verir.'**
  String get locationPickerManualHint;

  /// Auto metadata for locationPickerUseAuto
  ///
  /// In tr, this message translates to:
  /// **'Otomatik konumu kullan'**
  String get locationPickerUseAuto;

  /// Auto metadata for locationPickerMakeDefault
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan yap'**
  String get locationPickerMakeDefault;

  /// Auto metadata for locationPickerMakeDefaultHint
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin konum bir sonraki açılışta da kullanılsın.'**
  String get locationPickerMakeDefaultHint;

  /// Auto metadata for locationPickerRecent
  ///
  /// In tr, this message translates to:
  /// **'Son seçilenler'**
  String get locationPickerRecent;

  /// Auto metadata for locationPickerSearchDistrict
  ///
  /// In tr, this message translates to:
  /// **'İlçe ara'**
  String get locationPickerSearchDistrict;

  /// Auto metadata for locationPickerPopularDistricts
  ///
  /// In tr, this message translates to:
  /// **'Popüler ilçeler'**
  String get locationPickerPopularDistricts;

  /// Auto metadata for locationPickerBusinessCount
  ///
  /// In tr, this message translates to:
  /// **'{city} • {count} işletme'**
  String locationPickerBusinessCount(String city, int count);

  /// Auto metadata for legalPageTitle
  ///
  /// In tr, this message translates to:
  /// **'Yasal ve Güven'**
  String get legalPageTitle;

  /// Auto metadata for legalKvkkSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'KVKK / GDPR'**
  String get legalKvkkSectionTitle;

  /// Auto metadata for legalKvkkIntro
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy kişisel verileri yalnızca hizmeti sunmak için işler. Açık rızası gerektiren işlemler için onay alınır, talep halinde veriler silinir veya taşınabilir şekilde paylaşılr.'**
  String get legalKvkkIntro;

  /// Auto metadata for legalKvkkCategoriesAndRights
  ///
  /// In tr, this message translates to:
  /// **'Veri kategorileri: profil, konum, cihaz bilgisi, kullanım analitiği. Haklar: erişim, düzeltme, silme, itiraz, taşınabilirlik.'**
  String get legalKvkkCategoriesAndRights;

  /// Auto metadata for legalPrivacyPolicy
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
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
  /// **'Başvuru: e-posta ile talep oluştur.'**
  String get legalApplicationByEmail;

  /// Auto metadata for legalCopyrightSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Foto Telif Bildirimi'**
  String get legalCopyrightSectionTitle;

  /// Auto metadata for legalCopyrightIntro
  ///
  /// In tr, this message translates to:
  /// **'Menü ve mekan fotoğrafları telif hakkına tabi olabilir. İhlal gördüğünde Bildir > Telif ile iletebilirsin.'**
  String get legalCopyrightIntro;

  /// Auto metadata for legalCopyrightDetails
  ///
  /// In tr, this message translates to:
  /// **'Telif bildirimi için içerik bağlantısı, kanıt ve kısa açıklama yeterlidir. Doğrulanan ihlaller içerikten kaldırılır.'**
  String get legalCopyrightDetails;

  /// Auto metadata for legalCopyrightPolicy
  ///
  /// In tr, this message translates to:
  /// **'Telif Politikası'**
  String get legalCopyrightPolicy;

  /// Auto metadata for legalOwnershipAppealSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme Sahipliği İtirazı'**
  String get legalOwnershipAppealSectionTitle;

  /// Auto metadata for legalOwnershipAppealIntro
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talebi reddedildiyse itiraz edebilirsin. Belgelerin tekrar incelenir.'**
  String get legalOwnershipAppealIntro;

  /// Auto metadata for legalOwnershipAppealRequiredInfo
  ///
  /// In tr, this message translates to:
  /// **'İtiraz için gerekli bilgiler:'**
  String get legalOwnershipAppealRequiredInfo;

  /// Auto metadata for legalOwnershipAppealRequiredList
  ///
  /// In tr, this message translates to:
  /// **'• İşyeri ünvanı ve vergi/ruhsat bilgisi\n• Yetkilendirme belgesi\n• İletişim telefonu'**
  String get legalOwnershipAppealRequiredList;

  /// Auto metadata for legalSendAppealEmail
  ///
  /// In tr, this message translates to:
  /// **'İtiraz e-postası gönder'**
  String get legalSendAppealEmail;

  /// Auto metadata for legalProductPrinciplesSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Ürün İlkeleri'**
  String get legalProductPrinciplesSectionTitle;

  /// Auto metadata for legalDontsTitle
  ///
  /// In tr, this message translates to:
  /// **'Yapılmaması gerekenler:'**
  String get legalDontsTitle;

  /// Auto metadata for legalDontsList
  ///
  /// In tr, this message translates to:
  /// **'• Herkese her şeyi açmak\n• Sponsorlu içeriği gizlemek\n• Owner hesaba yorum silme yetkisi vermek\n• Büyüme için kalite eşeğini gevşetmek'**
  String get legalDontsList;

  /// Auto metadata for legalPolicySummary
  ///
  /// In tr, this message translates to:
  /// **'Politika: sponsor etiketi zorunlu={requireSponsoredLabel}, minimum sponsor güven={minSponsoredTrust}, owner yorum silme={ownerCanDeleteReviews}.'**
  String legalPolicySummary(
    String requireSponsoredLabel,
    String minSponsoredTrust,
    String ownerCanDeleteReviews,
  );

  /// Auto metadata for legalFooter
  ///
  /// In tr, this message translates to:
  /// **'Güncel politika metinleri ve detaylar web sitesinde yayımlanır.'**
  String get legalFooter;

  /// Auto metadata for topBusinessReviews
  ///
  /// In tr, this message translates to:
  /// **'Yorum: {count}'**
  String topBusinessReviews(int count);

  /// Auto metadata for reportRateLimitBusiness
  ///
  /// In tr, this message translates to:
  /// **'Bu işletme için bugün zaten bildirim gönderdin.'**
  String get reportRateLimitBusiness;

  /// Auto metadata for reportRateLimitReview
  ///
  /// In tr, this message translates to:
  /// **'Bu yorum için son 24 saatte zaten bildirim gönderdin.'**
  String get reportRateLimitReview;

  /// Auto metadata for reportRateLimitPhoto
  ///
  /// In tr, this message translates to:
  /// **'Bu fotoğraf için son 24 saatte zaten bildirim gönderdin.'**
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
  /// **'Yanlış bilgi'**
  String get reportReasonWrongInfo;

  /// Auto metadata for reportReasonCopyright
  ///
  /// In tr, this message translates to:
  /// **'Telif ihlali'**
  String get reportReasonCopyright;

  /// Auto metadata for reportReasonIllegal
  ///
  /// In tr, this message translates to:
  /// **'Yasa dışı'**
  String get reportReasonIllegal;

  /// Auto metadata for reportReasonWrongImage
  ///
  /// In tr, this message translates to:
  /// **'Yanlış görsel'**
  String get reportReasonWrongImage;

  /// Auto metadata for reportReasonClosed
  ///
  /// In tr, this message translates to:
  /// **'İşletme kapandı'**
  String get reportReasonClosed;

  /// Auto metadata for reportReasonMoved
  ///
  /// In tr, this message translates to:
  /// **'Taşındı'**
  String get reportReasonMoved;

  /// Auto metadata for reportReasonWrongPrice
  ///
  /// In tr, this message translates to:
  /// **'Fiyat yanlış'**
  String get reportReasonWrongPrice;

  /// Auto metadata for reportBusinessHint
  ///
  /// In tr, this message translates to:
  /// **'Çok sayıda yanlış bilgi bildirimi görünürliği düşürür. İşletme sahibi doğruladıktan sonra tekrar yükselir.'**
  String get reportBusinessHint;

  /// Auto metadata for reportReasonLabel
  ///
  /// In tr, this message translates to:
  /// **'Sebep'**
  String get reportReasonLabel;

  /// Auto metadata for reportCopyrightUrlLabel
  ///
  /// In tr, this message translates to:
  /// **'İhlal URL (fotoğraf bağlantısı)'**
  String get reportCopyrightUrlLabel;

  /// Auto metadata for reportCopyrightOwnerLabel
  ///
  /// In tr, this message translates to:
  /// **'Hak sahibi adı (opsiyonel)'**
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
  /// **'Teşekkürler, incelenecek.'**
  String get reportSubmittedThanks;

  /// Auto metadata for reportCopyrightUrlPrefix
  ///
  /// In tr, this message translates to:
  /// **'İhlal URL'**
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
  /// **'Bir hata oluştu.'**
  String get unexpectedError;

  /// Auto metadata for weatherHeadlineRainy
  ///
  /// In tr, this message translates to:
  /// **'Yağmurlu hava'**
  String get weatherHeadlineRainy;

  /// Auto metadata for weatherHeadlineSnowy
  ///
  /// In tr, this message translates to:
  /// **'Soğuk hava'**
  String get weatherHeadlineSnowy;

  /// Auto metadata for weatherHeadlineHot
  ///
  /// In tr, this message translates to:
  /// **'Sıcak hava'**
  String get weatherHeadlineHot;

  /// Auto metadata for weatherHeadlineClear
  ///
  /// In tr, this message translates to:
  /// **'Hava açık'**
  String get weatherHeadlineClear;

  /// Auto metadata for weatherHintRainy
  ///
  /// In tr, this message translates to:
  /// **'Sıcak bir şey iyi gider'**
  String get weatherHintRainy;

  /// Auto metadata for weatherHintSnowy
  ///
  /// In tr, this message translates to:
  /// **'Sıcak çorba iyi gider'**
  String get weatherHintSnowy;

  /// Auto metadata for weatherHintHot
  ///
  /// In tr, this message translates to:
  /// **'Serin bir şey iyi gider'**
  String get weatherHintHot;

  /// Auto metadata for weatherHintClear
  ///
  /// In tr, this message translates to:
  /// **'Dış mekan keyifli'**
  String get weatherHintClear;

  /// Auto metadata for paste
  ///
  /// In tr, this message translates to:
  /// **'Yapıştır'**
  String get paste;

  /// Auto metadata for addFirstMenuCta
  ///
  /// In tr, this message translates to:
  /// **'İlk menüyü ekle'**
  String get addFirstMenuCta;

  /// Auto metadata for vatIncluded
  ///
  /// In tr, this message translates to:
  /// **'KDV dahil'**
  String get vatIncluded;

  /// Number of people currently viewing this business page
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi şu an bakıyor'**
  String businessViewingNow(int count);

  /// Generic delete action
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// Generic remove action
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get remove;

  /// Generic create action
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get create;

  /// Validation error for required field
  ///
  /// In tr, this message translates to:
  /// **'Bu alan zorunludur'**
  String get required;

  /// Collab lists page title
  ///
  /// In tr, this message translates to:
  /// **'Ortak Listelerim'**
  String get collabListsTitle;

  /// Create collab list button
  ///
  /// In tr, this message translates to:
  /// **'Liste Oluştur'**
  String get collabListCreate;

  /// Empty state title for collab lists
  ///
  /// In tr, this message translates to:
  /// **'Henüz liste yok'**
  String get collabListsEmpty;

  /// Empty state description for collab lists
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlarınla ortak listeler oluştur ve favori mekanları birlikte oylayın.'**
  String get collabListsEmptyDesc;

  /// Collab list name field label
  ///
  /// In tr, this message translates to:
  /// **'Liste adı'**
  String get collabListNameLabel;

  /// Collab list description field label
  ///
  /// In tr, this message translates to:
  /// **'Açıklama (isteğe bağlı)'**
  String get collabListDescLabel;

  /// Empty state for items inside a collab list
  ///
  /// In tr, this message translates to:
  /// **'Liste boş'**
  String get collabListItemsEmpty;

  /// Empty state description for collab list items
  ///
  /// In tr, this message translates to:
  /// **'İşletme sayfasından bu listeye ekleyebilirsin.'**
  String get collabListItemsEmptyDesc;

  /// Share collab list action
  ///
  /// In tr, this message translates to:
  /// **'Davet Bağlantısını Kopyala'**
  String get collabListShare;

  /// Delete collab list action
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Sil'**
  String get collabListDelete;

  /// Delete collab list confirmation
  ///
  /// In tr, this message translates to:
  /// **'Bu listeyi ve tüm içeriğini silmek istediğinden emin misin?'**
  String get collabListDeleteConfirm;

  /// Leave collab list action
  ///
  /// In tr, this message translates to:
  /// **'Listeden Ayrıl'**
  String get collabListLeave;

  /// Leave collab list confirmation
  ///
  /// In tr, this message translates to:
  /// **'Bu listeden ayrılmak istediğinden emin misin?'**
  String get collabListLeaveConfirm;

  /// Snackbar when invite link is copied
  ///
  /// In tr, this message translates to:
  /// **'Davet bağlantısı kopyalandı'**
  String get collabListLinkCopied;

  /// Joining a collab list via invite token
  ///
  /// In tr, this message translates to:
  /// **'Listeye katılınıyor...'**
  String get collabListJoining;

  /// Error when invite token is invalid
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz davet bağlantısı.'**
  String get collabListInvalidInvite;

  /// Navigate to collab lists page
  ///
  /// In tr, this message translates to:
  /// **'Listelerime Git'**
  String get goToMyLists;

  /// Business detail page tab: general
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get businessTabGeneral;

  /// Business detail page tab: menu
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get businessTabMenu;

  /// Business detail page tab: reviews
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar'**
  String get businessTabReviews;

  /// Badge shown when the menu source is owner-verified
  ///
  /// In tr, this message translates to:
  /// **'Menü Onaylı'**
  String get businessBadgeMenuVerified;

  /// Badge shown when the business has trending items
  ///
  /// In tr, this message translates to:
  /// **'Popüler'**
  String get businessBadgePopular;

  /// Badge shown when business offers delivery
  ///
  /// In tr, this message translates to:
  /// **'Paket Servis'**
  String get businessBadgeDelivery;

  /// Badge shown when business offers dine-in seating
  ///
  /// In tr, this message translates to:
  /// **'Yerinde Yeme'**
  String get businessBadgeDineIn;

  /// Business detail Genel tab featured section title
  ///
  /// In tr, this message translates to:
  /// **'Öne çıkanlar'**
  String get featuredSectionTitle;

  /// Label under the rating value in the featured section
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get featuredRatingLabel;

  /// Subtitle for the verified-menu featured card
  ///
  /// In tr, this message translates to:
  /// **'Sahibi tarafından güncellendi'**
  String get featuredMenuVerifiedSubtitle;

  /// Business detail Genel tab popular dishes section title
  ///
  /// In tr, this message translates to:
  /// **'Popüler lezzetler'**
  String get popularDishesTitle;

  /// Business detail Genel tab location and hours section title
  ///
  /// In tr, this message translates to:
  /// **'Konum ve saatler'**
  String get locationHoursTitle;

  /// Bottom action bar directions button
  ///
  /// In tr, this message translates to:
  /// **'Yol Tarifi'**
  String get directions;

  /// Bottom action bar view menu button
  ///
  /// In tr, this message translates to:
  /// **'Menüyü Gör'**
  String get viewMenu;

  /// Check-in button label on business detail page
  ///
  /// In tr, this message translates to:
  /// **'Gerçekten Buradayım'**
  String get checkInButton;

  /// Check-in confirmation badge shown when user has already checked in today
  ///
  /// In tr, this message translates to:
  /// **'Bugün ziyaret edildi'**
  String get checkedInToday;

  /// Snackbar message shown after successful check-in
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretiniz kaydedildi!'**
  String get checkInSuccess;

  /// Snackbar message when user tries to check in again on the same day
  ///
  /// In tr, this message translates to:
  /// **'Bugün zaten ziyaret kaydettiniz.'**
  String get checkInAlreadyDone;

  /// No description provided for @profileSettingsPrivacyPendingRequest.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen bir gizlilik başvurunuz zaten var.'**
  String get profileSettingsPrivacyPendingRequest;

  /// No description provided for @profileSettingsDetailsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar'**
  String get profileSettingsDetailsLabel;

  /// No description provided for @profileSettingsDetailsHint.
  ///
  /// In tr, this message translates to:
  /// **'Talebinizi kısaca açıklayın'**
  String get profileSettingsDetailsHint;

  /// No description provided for @profileSettingsCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get profileSettingsCancel;

  /// No description provided for @profileSettingsSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get profileSettingsSubmit;

  /// No description provided for @profileSettingsRequestSaved.
  ///
  /// In tr, this message translates to:
  /// **'Başvurunuz kaydedildi.'**
  String get profileSettingsRequestSaved;

  /// No description provided for @profileSettingsPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get profileSettingsPageTitle;

  /// No description provided for @profileSettingsPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama tercihlerini yönet.'**
  String get profileSettingsPageSubtitle;

  /// No description provided for @profileSettingsPromoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanı kişiselleştir!'**
  String get profileSettingsPromoTitle;

  /// No description provided for @profileSettingsPromoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimlerden gizliliğe, favori mutfaklardan para birimine kadar her şeyi buradan ayarla.'**
  String get profileSettingsPromoSubtitle;

  /// No description provided for @profileSettingsAccountSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get profileSettingsAccountSectionTitle;

  /// No description provided for @profileSettingsAccountInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Bilgileri'**
  String get profileSettingsAccountInfoTitle;

  /// No description provided for @profileSettingsAccountInfoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel bilgilerini düzenle'**
  String get profileSettingsAccountInfoSubtitle;

  /// No description provided for @profileSettingsSocialAccountsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Medya Hesaplarım'**
  String get profileSettingsSocialAccountsTitle;

  /// No description provided for @profileSettingsSocialAccountsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Instagram, TikTok, YouTube ve daha fazlası'**
  String get profileSettingsSocialAccountsSubtitle;

  /// No description provided for @profileSettingsPrivacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get profileSettingsPrivacyTitle;

  /// No description provided for @profileSettingsPrivacySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Verilerini ve gizlilik ayarlarını yönet'**
  String get profileSettingsPrivacySubtitle;

  /// No description provided for @profileSettingsPrivacyDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Başvurusu'**
  String get profileSettingsPrivacyDialogTitle;

  /// No description provided for @profileSettingsPrivacyDialogHelper.
  ///
  /// In tr, this message translates to:
  /// **'Düzeltme, itiraz veya kısıtlama gibi taleplerinizi gönderin.'**
  String get profileSettingsPrivacyDialogHelper;

  /// No description provided for @profileSettingsSecurityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get profileSettingsSecurityTitle;

  /// No description provided for @profileSettingsSecuritySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre, giriş ve güvenlik ayarları'**
  String get profileSettingsSecuritySubtitle;

  /// No description provided for @profileSettingsAppPrefsSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Tercihleri'**
  String get profileSettingsAppPrefsSectionTitle;

  /// No description provided for @profileSettingsNotificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Ayarları'**
  String get profileSettingsNotificationsTitle;

  /// No description provided for @profileSettingsNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim tercihlerini yönet'**
  String get profileSettingsNotificationsSubtitle;

  /// No description provided for @profileSettingsLocationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum Ayarları'**
  String get profileSettingsLocationTitle;

  /// No description provided for @profileSettingsLocationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum erişimi ve tercihlerini düzenle'**
  String get profileSettingsLocationSubtitle;

  /// No description provided for @profileSettingsFavoritesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Favori Tercihlerim'**
  String get profileSettingsFavoritesTitle;

  /// No description provided for @profileSettingsFavoritesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Favori mutfaklar, yemekler ve filtreler'**
  String get profileSettingsFavoritesSubtitle;

  /// No description provided for @profileSettingsLanguageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get profileSettingsLanguageTitle;

  /// No description provided for @profileSettingsLanguageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dilini seç'**
  String get profileSettingsLanguageSubtitle;

  /// No description provided for @profileSettingsLanguageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get profileSettingsLanguageTurkish;

  /// No description provided for @profileSettingsLanguageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get profileSettingsLanguageEnglish;

  /// No description provided for @profileSettingsOtherSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get profileSettingsOtherSectionTitle;

  /// No description provided for @profileSettingsHelpTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yardım ve Destek'**
  String get profileSettingsHelpTitle;

  /// No description provided for @profileSettingsHelpSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sık sorulan sorular ve destek'**
  String get profileSettingsHelpSubtitle;

  /// No description provided for @profileSettingsLegalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yasal İşlemler'**
  String get profileSettingsLegalTitle;

  /// No description provided for @profileSettingsLegalSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım şartları, gizlilik ve KVKK'**
  String get profileSettingsLegalSubtitle;

  /// No description provided for @profileSettingsLogoutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get profileSettingsLogoutTitle;

  /// No description provided for @profileSettingsLogoutSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabından çıkış yap'**
  String get profileSettingsLogoutSubtitle;

  /// No description provided for @registerErrorAcceptTerms.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmelisiniz.'**
  String get registerErrorAcceptTerms;

  /// No description provided for @registerErrorPasswordMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get registerErrorPasswordMismatch;

  /// No description provided for @registerPasswordRequirementsHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifreniz en az 8 karakter olmalı ve harf, rakam içermelidir.'**
  String get registerPasswordRequirementsHint;

  /// No description provided for @registerSuccessMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız oluşturuldu! E-postanızı doğrulayın.'**
  String get registerSuccessMessage;

  /// No description provided for @registerBirthDatePickerHelp.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihinizi seçin'**
  String get registerBirthDatePickerHelp;

  /// No description provided for @registerCitySheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaşadığın Şehir'**
  String get registerCitySheetTitle;

  /// No description provided for @registerCitySearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Şehir ara...'**
  String get registerCitySearchHint;

  /// No description provided for @registerPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluşturun'**
  String get registerPageTitle;

  /// No description provided for @registerPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hemen kaydolun, tüm özelliklerden yararlanmaya başlayın.'**
  String get registerPageSubtitle;

  /// No description provided for @registerFirstNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get registerFirstNameHint;

  /// No description provided for @registerLastNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get registerLastNameHint;

  /// No description provided for @registerEmailHint.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi'**
  String get registerEmailHint;

  /// No description provided for @registerPhoneHint.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası'**
  String get registerPhoneHint;

  /// No description provided for @registerPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get registerPasswordHint;

  /// No description provided for @registerPasswordConfirmHint.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (Tekrar)'**
  String get registerPasswordConfirmHint;

  /// No description provided for @registerBirthDatePlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihi'**
  String get registerBirthDatePlaceholder;

  /// No description provided for @registerCityPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Yaşadığın şehir (opsiyonel)'**
  String get registerCityPlaceholder;

  /// No description provided for @registerTermsLinkLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Şartları'**
  String get registerTermsLinkLabel;

  /// No description provided for @registerTermsAndConnector.
  ///
  /// In tr, this message translates to:
  /// **' ve '**
  String get registerTermsAndConnector;

  /// No description provided for @registerPrivacyLinkLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get registerPrivacyLinkLabel;

  /// No description provided for @registerTermsAcceptSuffix.
  ///
  /// In tr, this message translates to:
  /// **'\'nı okudum, kabul ediyorum.'**
  String get registerTermsAcceptSuffix;

  /// No description provided for @registerSubmitButton.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get registerSubmitButton;

  /// No description provided for @registerOrDivider.
  ///
  /// In tr, this message translates to:
  /// **'veya'**
  String get registerOrDivider;

  /// No description provided for @registerGoogleSignupLabel.
  ///
  /// In tr, this message translates to:
  /// **'Google ile\nkaydol'**
  String get registerGoogleSignupLabel;

  /// No description provided for @registerAppleSignupLabel.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile\nkaydol'**
  String get registerAppleSignupLabel;

  /// No description provided for @registerFacebookSignupLabel.
  ///
  /// In tr, this message translates to:
  /// **'Facebook ile\nkaydol'**
  String get registerFacebookSignupLabel;

  /// No description provided for @registerSecureBadgeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli Kayıt'**
  String get registerSecureBadgeTitle;

  /// No description provided for @registerSecureBadgeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileriniz 256-bit SSL ile korunmaktadır.'**
  String get registerSecureBadgeSubtitle;

  /// No description provided for @registerCountryCodeSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ülke Kodu'**
  String get registerCountryCodeSheetTitle;

  /// No description provided for @registerCountryTurkey.
  ///
  /// In tr, this message translates to:
  /// **'🇹🇷 Türkiye'**
  String get registerCountryTurkey;

  /// No description provided for @registerCountryUsa.
  ///
  /// In tr, this message translates to:
  /// **'🇺🇸 ABD'**
  String get registerCountryUsa;

  /// No description provided for @registerCountryUk.
  ///
  /// In tr, this message translates to:
  /// **'🇬🇧 Birleşik Krallık'**
  String get registerCountryUk;

  /// No description provided for @registerCountryGermany.
  ///
  /// In tr, this message translates to:
  /// **'🇩🇪 Almanya'**
  String get registerCountryGermany;

  /// No description provided for @registerCountryFrance.
  ///
  /// In tr, this message translates to:
  /// **'🇫🇷 Fransa'**
  String get registerCountryFrance;

  /// No description provided for @registerCountryNetherlands.
  ///
  /// In tr, this message translates to:
  /// **'🇳🇱 Hollanda'**
  String get registerCountryNetherlands;

  /// No description provided for @registerCountryAustria.
  ///
  /// In tr, this message translates to:
  /// **'🇦🇹 Avusturya'**
  String get registerCountryAustria;

  /// No description provided for @registerCountrySwitzerland.
  ///
  /// In tr, this message translates to:
  /// **'🇨🇭 İsviçre'**
  String get registerCountrySwitzerland;

  /// No description provided for @loginOtpPhoneLabel.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası'**
  String get loginOtpPhoneLabel;

  /// No description provided for @loginOtpCodeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodu'**
  String get loginOtpCodeLabel;

  /// No description provided for @loginOtpUseDifferentNumber.
  ///
  /// In tr, this message translates to:
  /// **'Farklı numara kullan'**
  String get loginOtpUseDifferentNumber;

  /// No description provided for @forgotPasswordPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Sıfırla'**
  String get forgotPasswordPageTitle;

  /// No description provided for @forgotPasswordErrorInvalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi girin.'**
  String get forgotPasswordErrorInvalidEmail;

  /// No description provided for @forgotPasswordFormTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi sıfırlamak için\ne-posta adresinizi girin'**
  String get forgotPasswordFormTitle;

  /// No description provided for @forgotPasswordFormSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Size sıfırlama bağlantısı içeren bir e-posta göndereceğiz.'**
  String get forgotPasswordFormSubtitle;

  /// No description provided for @forgotPasswordEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi'**
  String get forgotPasswordEmailLabel;

  /// No description provided for @forgotPasswordSendingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor…'**
  String get forgotPasswordSendingLabel;

  /// No description provided for @forgotPasswordSendButton.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırlama Linki Gönder'**
  String get forgotPasswordSendButton;

  /// No description provided for @forgotPasswordBackButton.
  ///
  /// In tr, this message translates to:
  /// **'Geri dön'**
  String get forgotPasswordBackButton;

  /// No description provided for @forgotPasswordSuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Gönderildi!'**
  String get forgotPasswordSuccessTitle;

  /// No description provided for @forgotPasswordSuccessBody.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine şifre sıfırlama bağlantısı gönderildi.\nLütfen gelen kutunuzu kontrol edin.'**
  String forgotPasswordSuccessBody(String email);

  /// No description provided for @forgotPasswordBackToLoginButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş sayfasına dön'**
  String get forgotPasswordBackToLoginButton;

  /// No description provided for @profileMenuAccountSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel bilgilerini düzenle'**
  String get profileMenuAccountSubtitle;

  /// No description provided for @profileMenuDietTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Profilim'**
  String get profileMenuDietTitle;

  /// No description provided for @profileMenuDietSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme tercih ve alerjilerini belirt'**
  String get profileMenuDietSubtitle;

  /// No description provided for @profileMenuLoyaltyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sadakat Kartlarım'**
  String get profileMenuLoyaltyTitle;

  /// No description provided for @profileMenuLoyaltySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kartlarını ve QR kodunu gör'**
  String get profileMenuLoyaltySubtitle;

  /// No description provided for @profileMenuNotificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Tercihleri'**
  String get profileMenuNotificationsTitle;

  /// No description provided for @profileMenuNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim ayarlarını düzenle'**
  String get profileMenuNotificationsSubtitle;

  /// No description provided for @profileMenuHelpTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yardım ve Destek'**
  String get profileMenuHelpTitle;

  /// No description provided for @profileMenuHelpSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sık sorulan sorular ve destek'**
  String get profileMenuHelpSubtitle;

  /// No description provided for @accountSecurityScoreLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get accountSecurityScoreLow;

  /// No description provided for @accountSecurityScoreMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get accountSecurityScoreMedium;

  /// No description provided for @accountSecurityScoreHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get accountSecurityScoreHigh;

  /// No description provided for @accountSecurityPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Güvenliği'**
  String get accountSecurityPageTitle;

  /// No description provided for @accountSecurityPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı koruyun, güvende kalın.'**
  String get accountSecurityPageSubtitle;

  /// No description provided for @accountSecuritySettingsSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Ayarları'**
  String get accountSecuritySettingsSectionTitle;

  /// No description provided for @accountSecurityPasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get accountSecurityPasswordTitle;

  /// No description provided for @accountSecurityPasswordSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi düzenleyin'**
  String get accountSecurityPasswordSubtitle;

  /// No description provided for @accountSecurityPasswordLastChanged.
  ///
  /// In tr, this message translates to:
  /// **'Son değişiklik: 15.05.2024'**
  String get accountSecurityPasswordLastChanged;

  /// No description provided for @accountSecurity2faTitle.
  ///
  /// In tr, this message translates to:
  /// **'İki Adımlı Doğrulama'**
  String get accountSecurity2faTitle;

  /// No description provided for @accountSecurity2faSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza ekstra güvenlik katın'**
  String get accountSecurity2faSubtitle;

  /// No description provided for @accountSecurityActiveBadge.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get accountSecurityActiveBadge;

  /// No description provided for @accountSecurityEmailTitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Adresi'**
  String get accountSecurityEmailTitle;

  /// No description provided for @accountSecurityEmailSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresinizi yönetin'**
  String get accountSecurityEmailSubtitle;

  /// No description provided for @accountSecurityTrustedDevicesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilen Cihazlar'**
  String get accountSecurityTrustedDevicesTitle;

  /// No description provided for @accountSecurityTrustedDevicesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza giriş yapan cihazları yönetin'**
  String get accountSecurityTrustedDevicesSubtitle;

  /// No description provided for @accountSecuritySessionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oturum Yönetimi'**
  String get accountSecuritySessionsTitle;

  /// No description provided for @accountSecuritySessionsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Açık oturumlarınızı görüntüleyin'**
  String get accountSecuritySessionsSubtitle;

  /// No description provided for @accountSecurityTipsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenliğinizi Artırın'**
  String get accountSecurityTipsTitle;

  /// No description provided for @accountSecurityTipsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki önerileri uygulayarak hesabınızı daha da güvenli hale getirin.'**
  String get accountSecurityTipsSubtitle;

  /// No description provided for @accountSecurityTipStrongPasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güçlü bir şifre kullanın'**
  String get accountSecurityTipStrongPasswordTitle;

  /// No description provided for @accountSecurityTipStrongPasswordSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tahmin edilmesi zor, güçlü bir şifre seçin.'**
  String get accountSecurityTipStrongPasswordSubtitle;

  /// No description provided for @accountSecurityTip2faTitle.
  ///
  /// In tr, this message translates to:
  /// **'İki adımlı doğrulamayı etkinleştirin'**
  String get accountSecurityTip2faTitle;

  /// No description provided for @accountSecurityTip2faSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza ekstra koruma ekleyin.'**
  String get accountSecurityTip2faSubtitle;

  /// No description provided for @accountSecurityActionsSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap İşlemleri'**
  String get accountSecurityActionsSectionTitle;

  /// No description provided for @accountSecurityDownloadDataTitle.
  ///
  /// In tr, this message translates to:
  /// **'Verilerinizi İndirin'**
  String get accountSecurityDownloadDataTitle;

  /// No description provided for @accountSecurityDownloadDataSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza ait verilerin bir kopyasını indirin.'**
  String get accountSecurityDownloadDataSubtitle;

  /// No description provided for @accountSecurityDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı Sil'**
  String get accountSecurityDeleteTitle;

  /// No description provided for @accountSecurityDeleteSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı kalıcı olarak silin.'**
  String get accountSecurityDeleteSubtitle;

  /// No description provided for @accountSecuritySupportBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yardıma mı ihtiyacınız var?'**
  String get accountSecuritySupportBannerTitle;

  /// No description provided for @accountSecuritySupportBannerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik ile ilgili sorularınız için destek ekibimizle iletişim geçin.'**
  String get accountSecuritySupportBannerSubtitle;

  /// No description provided for @accountSecuritySupportBannerButton.
  ///
  /// In tr, this message translates to:
  /// **'Destek Al'**
  String get accountSecuritySupportBannerButton;

  /// No description provided for @accountSecurityScorePrefix.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Skorunuz: '**
  String get accountSecurityScorePrefix;

  /// No description provided for @accountSecurityScoreDescription.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı korumak için tüm güvenlik önerilerini tamamlayın.'**
  String get accountSecurityScoreDescription;

  /// No description provided for @accountSecurityDataExportRequested.
  ///
  /// In tr, this message translates to:
  /// **'Veri export talebiniz alındı. En kısa sürede e-postanıza iletilecektir.'**
  String get accountSecurityDataExportRequested;

  /// No description provided for @accountSecurityRequestFailedGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Talep gönderilemedi. Lütfen tekrar deneyin.'**
  String get accountSecurityRequestFailedGeneric;

  /// No description provided for @accountSecurityMailAppUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'E-posta uygulaması açılamadı. destek@yeedoy.com adresine yazın.'**
  String get accountSecurityMailAppUnavailable;

  /// No description provided for @accountSecurityDeleteDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem hesabınıza erişimi kapatır ve silinebilir veriler için silme sürecini başlatır.'**
  String get accountSecurityDeleteDialogBody;

  /// No description provided for @accountSecurityDeleteReasonLabel.
  ///
  /// In tr, this message translates to:
  /// **'Silme nedeni'**
  String get accountSecurityDeleteReasonLabel;

  /// No description provided for @accountSecurityDeleteReasonHint.
  ///
  /// In tr, this message translates to:
  /// **'İsterseniz nedeninizi paylaşın'**
  String get accountSecurityDeleteReasonHint;

  /// No description provided for @accountSecurityDeleteConfirmLabel.
  ///
  /// In tr, this message translates to:
  /// **'Onay'**
  String get accountSecurityDeleteConfirmLabel;

  /// No description provided for @accountSecurityDeleteConfirmHint.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için SIL yazın'**
  String get accountSecurityDeleteConfirmHint;

  /// No description provided for @accountSecurityDeleteCreateRequestButton.
  ///
  /// In tr, this message translates to:
  /// **'Silme Talebi Oluştur'**
  String get accountSecurityDeleteCreateRequestButton;

  /// No description provided for @accountSecurityCancelButton.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get accountSecurityCancelButton;

  /// No description provided for @accountSecurityDeleteRequestSubmitted.
  ///
  /// In tr, this message translates to:
  /// **'Silme talebiniz iletildi.'**
  String get accountSecurityDeleteRequestSubmitted;

  /// No description provided for @accountSecurityDeleteRequestFailed.
  ///
  /// In tr, this message translates to:
  /// **'Talep gönderilemedi.'**
  String get accountSecurityDeleteRequestFailed;

  /// No description provided for @accountSecurity2faSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik doğrulama uygulaması (TOTP)'**
  String get accountSecurity2faSheetSubtitle;

  /// No description provided for @accountSecurity2faNotEnrolledBody.
  ///
  /// In tr, this message translates to:
  /// **'Google Authenticator, Authy veya benzeri bir kimlik doğrulama uygulamasını kullanarak hesabınıza ekstra güvenlik katmanı ekleyebilirsiniz.'**
  String get accountSecurity2faNotEnrolledBody;

  /// No description provided for @accountSecurity2faStartingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlatılıyor…'**
  String get accountSecurity2faStartingLabel;

  /// No description provided for @accountSecurity2faStartSetupButton.
  ///
  /// In tr, this message translates to:
  /// **'Kurulumu Başlat'**
  String get accountSecurity2faStartSetupButton;

  /// No description provided for @accountSecurity2faEnrollStartError.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik doğrulama uygulaması kurulumu başlatılamadı.'**
  String get accountSecurity2faEnrollStartError;

  /// No description provided for @accountSecurity2faCodeRequiredError.
  ///
  /// In tr, this message translates to:
  /// **'6 haneli doğrulama kodunu girin.'**
  String get accountSecurity2faCodeRequiredError;

  /// No description provided for @accountSecurity2faStep1.
  ///
  /// In tr, this message translates to:
  /// **'1. Kimlik doğrulama uygulamanızı açın ve QR kodu okutun.'**
  String get accountSecurity2faStep1;

  /// No description provided for @accountSecurity2faSecretLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gizli anahtar (manuel giriş):'**
  String get accountSecurity2faSecretLabel;

  /// No description provided for @accountSecurity2faSecretCopied.
  ///
  /// In tr, this message translates to:
  /// **'Anahtar kopyalandı.'**
  String get accountSecurity2faSecretCopied;

  /// No description provided for @accountSecurity2faStep2.
  ///
  /// In tr, this message translates to:
  /// **'2. Uygulamanın gösterdiği 6 haneli kodu girin:'**
  String get accountSecurity2faStep2;

  /// No description provided for @accountSecurity2faVerifyingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanıyor…'**
  String get accountSecurity2faVerifyingLabel;

  /// No description provided for @accountSecurity2faVerifyButton.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula ve Aktifleştir'**
  String get accountSecurity2faVerifyButton;

  /// No description provided for @accountSecurity2faVerifyCodeInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Kod hatalı veya süresi dolmuş. Yeni kod deneyin.'**
  String get accountSecurity2faVerifyCodeInvalid;

  /// No description provided for @accountSecurity2faDisableCodeInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Kod hatalı veya süresi dolmuş.'**
  String get accountSecurity2faDisableCodeInvalid;

  /// No description provided for @accountSecurity2faEnabledBanner.
  ///
  /// In tr, this message translates to:
  /// **'İki adımlı doğrulama aktif. Hesabınız ek güvenlik katmanıyla korunuyor.'**
  String get accountSecurity2faEnabledBanner;

  /// No description provided for @accountSecurity2faDisableButton.
  ///
  /// In tr, this message translates to:
  /// **'Devre Dışı Bırak'**
  String get accountSecurity2faDisableButton;

  /// No description provided for @accountSecurity2faDisablePrompt.
  ///
  /// In tr, this message translates to:
  /// **'Devre dışı bırakmak için kimlik doğrulama uygulamanızdaki kodu girin.'**
  String get accountSecurity2faDisablePrompt;

  /// No description provided for @accountSecurity2faProcessingLabel.
  ///
  /// In tr, this message translates to:
  /// **'İşleniyor…'**
  String get accountSecurity2faProcessingLabel;

  /// No description provided for @accountSecurityTrustedDevicesSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın kurulu olduğu cihazlar'**
  String get accountSecurityTrustedDevicesSheetSubtitle;

  /// No description provided for @accountSecurityDeviceRemoveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz kaldırılamadı.'**
  String get accountSecurityDeviceRemoveFailed;

  /// No description provided for @accountSecurityUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get accountSecurityUnknown;

  /// No description provided for @accountSecurityTimeJustNow.
  ///
  /// In tr, this message translates to:
  /// **'Az önce'**
  String get accountSecurityTimeJustNow;

  /// No description provided for @accountSecurityTimeMinutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk önce'**
  String accountSecurityTimeMinutesAgo(int minutes);

  /// No description provided for @accountSecurityTimeHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat önce'**
  String accountSecurityTimeHoursAgo(int hours);

  /// No description provided for @accountSecurityTimeDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce'**
  String accountSecurityTimeDaysAgo(int days);

  /// No description provided for @accountSecurityTimeMonthsAgo.
  ///
  /// In tr, this message translates to:
  /// **'{months} ay önce'**
  String accountSecurityTimeMonthsAgo(int months);

  /// No description provided for @accountSecurityNoDevicesFound.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı cihaz bulunamadı.'**
  String get accountSecurityNoDevicesFound;

  /// No description provided for @accountSecurityAndroidDevice.
  ///
  /// In tr, this message translates to:
  /// **'Android Cihaz'**
  String get accountSecurityAndroidDevice;

  /// No description provided for @accountSecurityIosDevice.
  ///
  /// In tr, this message translates to:
  /// **'iOS Cihaz'**
  String get accountSecurityIosDevice;

  /// No description provided for @accountSecurityRemoveDeviceDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cihazı Kaldır'**
  String get accountSecurityRemoveDeviceDialogTitle;

  /// No description provided for @accountSecurityRemoveDeviceDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihaz için bildirimler devre dışı bırakılacak. Devam edilsin mi?'**
  String get accountSecurityRemoveDeviceDialogBody;

  /// No description provided for @accountSecurityRemoveButton.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get accountSecurityRemoveButton;

  /// No description provided for @accountSecuritySessionsSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktif oturumunuzu yönetin'**
  String get accountSecuritySessionsSheetSubtitle;

  /// No description provided for @accountSecurityActiveSessionBadge.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Oturum'**
  String get accountSecurityActiveSessionBadge;

  /// No description provided for @accountSecuritySessionEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get accountSecuritySessionEmailLabel;

  /// No description provided for @accountSecuritySessionLastLoginLabel.
  ///
  /// In tr, this message translates to:
  /// **'Son giriş'**
  String get accountSecuritySessionLastLoginLabel;

  /// No description provided for @accountSecuritySessionCreatedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluşturuldu'**
  String get accountSecuritySessionCreatedLabel;

  /// No description provided for @accountSecuritySessionWarning.
  ///
  /// In tr, this message translates to:
  /// **'Tanımadığınız bir cihazdan giriş yapıldıysa tüm oturumları sonlandırın ve şifrenizi değiştirin.'**
  String get accountSecuritySessionWarning;

  /// No description provided for @accountSecurityLogoutAllDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Oturumları Kapat'**
  String get accountSecurityLogoutAllDialogTitle;

  /// No description provided for @accountSecurityLogoutAllDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Tüm cihazlardaki aktif oturumlarınız sonlandırılacak ve yeniden giriş yapmanız gerekecek.'**
  String get accountSecurityLogoutAllDialogBody;

  /// No description provided for @accountSecurityLogoutAllCloseButton.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get accountSecurityLogoutAllCloseButton;

  /// No description provided for @accountSecurityLogoutAllButton.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Cihazlarda Oturumu Kapat'**
  String get accountSecurityLogoutAllButton;

  /// No description provided for @accountSecurityChangePasswordErrorTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalıdır.'**
  String get accountSecurityChangePasswordErrorTooShort;

  /// No description provided for @accountSecurityChangePasswordErrorMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get accountSecurityChangePasswordErrorMismatch;

  /// No description provided for @accountSecurityChangePasswordErrorReauthRequired.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için mevcut şifrenizi girin.'**
  String get accountSecurityChangePasswordErrorReauthRequired;

  /// No description provided for @accountSecurityChangePasswordErrorReauthFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre yanlış.'**
  String get accountSecurityChangePasswordErrorReauthFailed;

  /// No description provided for @accountSecurityPasswordUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Şifre başarıyla güncellendi.'**
  String get accountSecurityPasswordUpdated;

  /// No description provided for @accountSecurityChangePasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get accountSecurityChangePasswordTitle;

  /// No description provided for @accountSecurityCurrentPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre'**
  String get accountSecurityCurrentPasswordLabel;

  /// No description provided for @accountSecurityNewPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre'**
  String get accountSecurityNewPasswordLabel;

  /// No description provided for @accountSecurityNewPasswordConfirmLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre (tekrar)'**
  String get accountSecurityNewPasswordConfirmLabel;

  /// No description provided for @accountSecuritySavingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor…'**
  String get accountSecuritySavingLabel;

  /// No description provided for @accountSecurityUpdatePasswordButton.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Güncelle'**
  String get accountSecurityUpdatePasswordButton;

  /// No description provided for @accountSecurityChangeEmailErrorInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta girin.'**
  String get accountSecurityChangeEmailErrorInvalid;

  /// No description provided for @accountSecurityChangeEmailErrorReauthRequired.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için mevcut şifrenizi girin.'**
  String get accountSecurityChangeEmailErrorReauthRequired;

  /// No description provided for @accountSecurityChangeEmailErrorReauthFailed.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut şifre yanlış.'**
  String get accountSecurityChangeEmailErrorReauthFailed;

  /// No description provided for @accountSecurityChangeEmailSentBody.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine doğrulama e-postası gönderildi. Bağlantıya tıkladıktan sonra e-postanız güncellenecektir.'**
  String accountSecurityChangeEmailSentBody(String email);

  /// No description provided for @accountSecurityOkButton.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get accountSecurityOkButton;

  /// No description provided for @accountSecurityChangeEmailTitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Değiştir'**
  String get accountSecurityChangeEmailTitle;

  /// No description provided for @accountSecurityChangeEmailSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni e-posta adresinize doğrulama bağlantısı gönderilecektir.'**
  String get accountSecurityChangeEmailSubtitle;

  /// No description provided for @accountSecurityNewEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni e-posta adresi'**
  String get accountSecurityNewEmailLabel;

  /// No description provided for @accountSecuritySendingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor…'**
  String get accountSecuritySendingLabel;

  /// No description provided for @accountSecuritySendVerificationLinkButton.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Bağlantısı Gönder'**
  String get accountSecuritySendVerificationLinkButton;

  /// No description provided for @accountInfoPhotoUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf güncellenemedi.'**
  String get accountInfoPhotoUpdateError;

  /// No description provided for @accountInfoGenderMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get accountInfoGenderMale;

  /// No description provided for @accountInfoGenderFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get accountInfoGenderFemale;

  /// No description provided for @accountInfoGenderOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get accountInfoGenderOther;

  /// No description provided for @accountInfoGenderPreferNotToSay.
  ///
  /// In tr, this message translates to:
  /// **'Belirtmek İstemiyorum'**
  String get accountInfoGenderPreferNotToSay;

  /// No description provided for @accountInfoAddPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get accountInfoAddPlaceholder;

  /// No description provided for @accountInfoDeleteAccountDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı sil'**
  String get accountInfoDeleteAccountDialogTitle;

  /// No description provided for @accountInfoDeleteAccountDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem hesabınıza erişimi kapatır ve silinebilir veriler için silme sürecini başlatır.'**
  String get accountInfoDeleteAccountDialogBody;

  /// No description provided for @accountInfoDeleteReasonLabel.
  ///
  /// In tr, this message translates to:
  /// **'Silme nedeni'**
  String get accountInfoDeleteReasonLabel;

  /// No description provided for @accountInfoDeleteReasonHint.
  ///
  /// In tr, this message translates to:
  /// **'İsterseniz nedeninizi paylaşın'**
  String get accountInfoDeleteReasonHint;

  /// No description provided for @accountInfoDeleteConfirmLabel.
  ///
  /// In tr, this message translates to:
  /// **'Onay'**
  String get accountInfoDeleteConfirmLabel;

  /// No description provided for @accountInfoDeleteConfirmHint.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için SIL yazın'**
  String get accountInfoDeleteConfirmHint;

  /// No description provided for @accountInfoDeleteCreateRequestButton.
  ///
  /// In tr, this message translates to:
  /// **'Silme Talebi Oluştur'**
  String get accountInfoDeleteCreateRequestButton;

  /// No description provided for @accountInfoCancelButton.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get accountInfoCancelButton;

  /// No description provided for @accountInfoDeleteRequestSubmitted.
  ///
  /// In tr, this message translates to:
  /// **'Silme talebiniz iletildi.'**
  String get accountInfoDeleteRequestSubmitted;

  /// No description provided for @accountInfoDeleteRequestFailed.
  ///
  /// In tr, this message translates to:
  /// **'Talep gönderilemedi.'**
  String get accountInfoDeleteRequestFailed;

  /// No description provided for @accountInfoPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Bilgileri'**
  String get accountInfoPageTitle;

  /// No description provided for @accountInfoPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap bilgilerinizi görüntüleyin ve güncelleyin.'**
  String get accountInfoPageSubtitle;

  /// No description provided for @accountInfoDefaultUserName.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get accountInfoDefaultUserName;

  /// No description provided for @accountInfoChangePhotoButton.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Değiştir'**
  String get accountInfoChangePhotoButton;

  /// No description provided for @accountInfoPersonalInfoSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Bilgiler'**
  String get accountInfoPersonalInfoSectionTitle;

  /// No description provided for @accountInfoFullNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get accountInfoFullNameLabel;

  /// No description provided for @accountInfoEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Adresi'**
  String get accountInfoEmailLabel;

  /// No description provided for @accountInfoPhoneLabel.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get accountInfoPhoneLabel;

  /// No description provided for @accountInfoBirthDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Doğum Tarihi'**
  String get accountInfoBirthDateLabel;

  /// No description provided for @accountInfoCityLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yaşadığın Şehir'**
  String get accountInfoCityLabel;

  /// No description provided for @accountInfoGenderLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get accountInfoGenderLabel;

  /// No description provided for @accountInfoAccountSettingsSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Ayarları'**
  String get accountInfoAccountSettingsSectionTitle;

  /// No description provided for @accountInfoChangePasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get accountInfoChangePasswordTitle;

  /// No description provided for @accountInfoChangePasswordSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap şifrenizi düzenleyin'**
  String get accountInfoChangePasswordSubtitle;

  /// No description provided for @accountInfoNotificationPreferencesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Tercihleri'**
  String get accountInfoNotificationPreferencesTitle;

  /// No description provided for @accountInfoNotificationPreferencesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim ayarlarınızı yönetin'**
  String get accountInfoNotificationPreferencesSubtitle;

  /// No description provided for @accountInfoSecuritySettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Ayarları'**
  String get accountInfoSecuritySettingsTitle;

  /// No description provided for @accountInfoSecuritySettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızın güvenliğini artırın'**
  String get accountInfoSecuritySettingsSubtitle;

  /// No description provided for @accountInfoLanguagePreferenceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil Tercihi'**
  String get accountInfoLanguagePreferenceTitle;

  /// No description provided for @accountInfoChangeBadge.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get accountInfoChangeBadge;

  /// No description provided for @accountInfoDeleteAccountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Sil'**
  String get accountInfoDeleteAccountTitle;

  /// No description provided for @accountInfoDeleteAccountSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı kalıcı olarak silmek isterseniz buradan işlem yapabilirsiniz.'**
  String get accountInfoDeleteAccountSubtitle;

  /// No description provided for @accountInfoLanguageSystemDefault.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Varsayılanı'**
  String get accountInfoLanguageSystemDefault;

  /// No description provided for @accountInfoLanguageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get accountInfoLanguageTurkish;

  /// No description provided for @accountInfoLanguageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get accountInfoLanguageEnglish;

  /// No description provided for @accountInfoGenericSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemedi.'**
  String get accountInfoGenericSaveError;

  /// No description provided for @accountInfoEditNameSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad Düzenle'**
  String get accountInfoEditNameSheetTitle;

  /// No description provided for @accountInfoFirstNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get accountInfoFirstNameLabel;

  /// No description provided for @accountInfoFirstNameRequiredError.
  ///
  /// In tr, this message translates to:
  /// **'Zorunlu'**
  String get accountInfoFirstNameRequiredError;

  /// No description provided for @accountInfoLastNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get accountInfoLastNameLabel;

  /// No description provided for @accountInfoSavingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor…'**
  String get accountInfoSavingLabel;

  /// No description provided for @accountInfoSaveButton.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get accountInfoSaveButton;

  /// No description provided for @accountInfoPhoneInvalidError.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir telefon numarası girin (ör: +905XXXXXXXXX).'**
  String get accountInfoPhoneInvalidError;

  /// No description provided for @accountInfoOtpSendError.
  ///
  /// In tr, this message translates to:
  /// **'OTP gönderilemedi. Telefon numarasını ve SMS ayarlarını kontrol edin.'**
  String get accountInfoOtpSendError;

  /// No description provided for @accountInfoOtpCodeLengthError.
  ///
  /// In tr, this message translates to:
  /// **'6 haneli kodu girin.'**
  String get accountInfoOtpCodeLengthError;

  /// No description provided for @accountInfoOtpInvalidError.
  ///
  /// In tr, this message translates to:
  /// **'Kod hatalı veya süresi dolmuş.'**
  String get accountInfoOtpInvalidError;

  /// No description provided for @accountInfoPhoneSheetOtpSentSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaranıza gönderilen 6 haneli kodu girin.'**
  String get accountInfoPhoneSheetOtpSentSubtitle;

  /// No description provided for @accountInfoPhoneSheetEnterNumberSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni telefon numaranızı E.164 formatında girin (ör: +905XXXXXXXXX).'**
  String get accountInfoPhoneSheetEnterNumberSubtitle;

  /// No description provided for @accountInfoPhoneHint.
  ///
  /// In tr, this message translates to:
  /// **'+905XXXXXXXXX'**
  String get accountInfoPhoneHint;

  /// No description provided for @accountInfoOtpHint.
  ///
  /// In tr, this message translates to:
  /// **'000000'**
  String get accountInfoOtpHint;

  /// No description provided for @accountInfoSendOtpButton.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Kodu Gönder'**
  String get accountInfoSendOtpButton;

  /// No description provided for @accountInfoSendingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor…'**
  String get accountInfoSendingLabel;

  /// No description provided for @accountInfoVerifyingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanıyor…'**
  String get accountInfoVerifyingLabel;

  /// No description provided for @accountInfoConfirmButton.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get accountInfoConfirmButton;

  /// No description provided for @accountInfoChangeNumberButton.
  ///
  /// In tr, this message translates to:
  /// **'Numarayı Değiştir'**
  String get accountInfoChangeNumberButton;

  /// No description provided for @accountInfoBirthDatePickerHelpText.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihinizi seçin'**
  String get accountInfoBirthDatePickerHelpText;

  /// No description provided for @accountInfoBirthDateNotSelected.
  ///
  /// In tr, this message translates to:
  /// **'Seçilmedi'**
  String get accountInfoBirthDateNotSelected;

  /// No description provided for @accountInfoRemoveDateButton.
  ///
  /// In tr, this message translates to:
  /// **'Tarihi Kaldır'**
  String get accountInfoRemoveDateButton;

  /// No description provided for @accountInfoGenderSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgi yalnızca size özel içerik önerileri için kullanılır.'**
  String get accountInfoGenderSheetSubtitle;

  /// No description provided for @accountInfoCitySheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir şehirdeyken sana o şehrin yöresel lezzetlerini önerebilmemiz için kullanılır.'**
  String get accountInfoCitySheetSubtitle;

  /// No description provided for @accountInfoCitySearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Şehir ara...'**
  String get accountInfoCitySearchHint;

  /// No description provided for @socialAccountsSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemedi, tekrar deneyin.'**
  String get socialAccountsSaveError;

  /// No description provided for @socialAccountsDisconnectDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'{platform} bağlantısını kaldır'**
  String socialAccountsDisconnectDialogTitle(String platform);

  /// No description provided for @socialAccountsDisconnectDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesabın bağlantısını kaldırmak istiyor musunuz?'**
  String get socialAccountsDisconnectDialogBody;

  /// No description provided for @socialAccountsCancelButton.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get socialAccountsCancelButton;

  /// No description provided for @socialAccountsRemoveButton.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get socialAccountsRemoveButton;

  /// No description provided for @socialAccountsPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Medya Hesapları'**
  String get socialAccountsPageTitle;

  /// No description provided for @socialAccountsPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza sosyal medya hesaplarınızı\nekleyin ve kolayca yönetin.'**
  String get socialAccountsPageSubtitle;

  /// No description provided for @socialAccountsSecureConnectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli Bağlantı'**
  String get socialAccountsSecureConnectionTitle;

  /// No description provided for @socialAccountsSecureConnectionBody.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal medya hesaplarınız 256-bit SSL ile korunur. Bilgileriniz bizimle paylaşılmaz.'**
  String get socialAccountsSecureConnectionBody;

  /// No description provided for @socialAccountsAddAccountSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Ekle'**
  String get socialAccountsAddAccountSectionTitle;

  /// No description provided for @socialAccountsConnectedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız başarıyla bağlandı.'**
  String get socialAccountsConnectedLabel;

  /// No description provided for @socialAccountsWhyAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neden hesap eklemelisiniz?'**
  String get socialAccountsWhyAddTitle;

  /// No description provided for @socialAccountsWhyAddBody.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal medya hesaplarınızı bağlayarak içerikleri kolayca paylaşabilir ve etkileşimlerinizi tek yerden yönetebilirsiniz.'**
  String get socialAccountsWhyAddBody;

  /// No description provided for @socialAccountsInfoSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neden Sosyal Hesap Eklemeliyim?'**
  String get socialAccountsInfoSheetTitle;

  /// No description provided for @socialAccountsInfoSheetBody.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal medya hesaplarınızı Yeedoy\'a bağlayarak:\n\n• Yorum ve fotoğraflarınızı tek tıkla sosyal medyada paylaşabilirsiniz.\n• Profiliniz daha güvenilir görünür ve topluluk puanınız artar.\n• Hesabınız 256-bit SSL şifrelemesi ile korunur.\n• Bilgileriniz asla üçüncü taraflarla paylaşılmaz.'**
  String get socialAccountsInfoSheetBody;

  /// No description provided for @socialAccountsConnectedBadge.
  ///
  /// In tr, this message translates to:
  /// **'Bağlandı'**
  String get socialAccountsConnectedBadge;

  /// No description provided for @socialAccountsConnectButton.
  ///
  /// In tr, this message translates to:
  /// **'Bağla'**
  String get socialAccountsConnectButton;

  /// No description provided for @socialAccountsEditUrlAction.
  ///
  /// In tr, this message translates to:
  /// **'URL\'yi Düzenle'**
  String get socialAccountsEditUrlAction;

  /// No description provided for @socialAccountsRemoveLinkAction.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı Kaldır'**
  String get socialAccountsRemoveLinkAction;

  /// No description provided for @socialAccountsLinkDialogPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Profil URL\'nizi veya kullanıcı adınızı girin:'**
  String get socialAccountsLinkDialogPrompt;

  /// No description provided for @socialAccountsInstagramLabel.
  ///
  /// In tr, this message translates to:
  /// **'Instagram'**
  String get socialAccountsInstagramLabel;

  /// No description provided for @socialAccountsInstagramDescription.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf ve video paylaşımlarınızı bağlayın.'**
  String get socialAccountsInstagramDescription;

  /// No description provided for @socialAccountsInstagramHint.
  ///
  /// In tr, this message translates to:
  /// **'https://instagram.com/kullanici_adi'**
  String get socialAccountsInstagramHint;

  /// No description provided for @socialAccountsFacebookLabel.
  ///
  /// In tr, this message translates to:
  /// **'Facebook'**
  String get socialAccountsFacebookLabel;

  /// No description provided for @socialAccountsFacebookDescription.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı bağlayarak içeriklerinizi paylaşın.'**
  String get socialAccountsFacebookDescription;

  /// No description provided for @socialAccountsFacebookHint.
  ///
  /// In tr, this message translates to:
  /// **'https://facebook.com/kullanici_adi'**
  String get socialAccountsFacebookHint;

  /// No description provided for @socialAccountsXLabel.
  ///
  /// In tr, this message translates to:
  /// **'X (Twitter)'**
  String get socialAccountsXLabel;

  /// No description provided for @socialAccountsXDescription.
  ///
  /// In tr, this message translates to:
  /// **'Tweetlerinizi ve etkileşimlerinizi senkronize edin.'**
  String get socialAccountsXDescription;

  /// No description provided for @socialAccountsXHint.
  ///
  /// In tr, this message translates to:
  /// **'https://x.com/kullanici_adi'**
  String get socialAccountsXHint;

  /// No description provided for @socialAccountsLinkedinLabel.
  ///
  /// In tr, this message translates to:
  /// **'LinkedIn'**
  String get socialAccountsLinkedinLabel;

  /// No description provided for @socialAccountsLinkedinDescription.
  ///
  /// In tr, this message translates to:
  /// **'Profesyonel profilinizi bağlayın.'**
  String get socialAccountsLinkedinDescription;

  /// No description provided for @socialAccountsLinkedinHint.
  ///
  /// In tr, this message translates to:
  /// **'https://linkedin.com/in/kullanici_adi'**
  String get socialAccountsLinkedinHint;

  /// No description provided for @socialAccountsYoutubeLabel.
  ///
  /// In tr, this message translates to:
  /// **'YouTube'**
  String get socialAccountsYoutubeLabel;

  /// No description provided for @socialAccountsYoutubeDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kanalınızı bağlayın ve içeriklerinizi yönetin.'**
  String get socialAccountsYoutubeDescription;

  /// No description provided for @socialAccountsYoutubeHint.
  ///
  /// In tr, this message translates to:
  /// **'https://youtube.com/@kanal_adi'**
  String get socialAccountsYoutubeHint;

  /// No description provided for @socialAccountsTiktokLabel.
  ///
  /// In tr, this message translates to:
  /// **'TikTok'**
  String get socialAccountsTiktokLabel;

  /// No description provided for @socialAccountsTiktokDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kısa video içeriklerinizi bağlayın.'**
  String get socialAccountsTiktokDescription;

  /// No description provided for @socialAccountsTiktokHint.
  ///
  /// In tr, this message translates to:
  /// **'https://tiktok.com/@kullanici_adi'**
  String get socialAccountsTiktokHint;

  /// No description provided for @suggestBusinessCategoryRestaurant.
  ///
  /// In tr, this message translates to:
  /// **'Restoran'**
  String get suggestBusinessCategoryRestaurant;

  /// No description provided for @suggestBusinessCategoryCafe.
  ///
  /// In tr, this message translates to:
  /// **'Kafe'**
  String get suggestBusinessCategoryCafe;

  /// No description provided for @suggestBusinessCategoryFish.
  ///
  /// In tr, this message translates to:
  /// **'Balık & Et'**
  String get suggestBusinessCategoryFish;

  /// No description provided for @suggestBusinessCategoryBakery.
  ///
  /// In tr, this message translates to:
  /// **'Pastane & Fırın'**
  String get suggestBusinessCategoryBakery;

  /// No description provided for @suggestBusinessCategoryFastfood.
  ///
  /// In tr, this message translates to:
  /// **'Fast Food'**
  String get suggestBusinessCategoryFastfood;

  /// No description provided for @suggestBusinessCategoryOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get suggestBusinessCategoryOther;

  /// No description provided for @suggestBusinessReasonTasty.
  ///
  /// In tr, this message translates to:
  /// **'Lezzetli yemekleri var'**
  String get suggestBusinessReasonTasty;

  /// No description provided for @suggestBusinessReasonAtmosphere.
  ///
  /// In tr, this message translates to:
  /// **'Harika atmosferi var'**
  String get suggestBusinessReasonAtmosphere;

  /// No description provided for @suggestBusinessReasonAffordable.
  ///
  /// In tr, this message translates to:
  /// **'Uygun fiyatlı'**
  String get suggestBusinessReasonAffordable;

  /// No description provided for @suggestBusinessReasonRecommend.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlarıma tavsiye etmek istiyorum'**
  String get suggestBusinessReasonRecommend;

  /// No description provided for @suggestBusinessReasonNotOnYeedoy.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Yeedoy\'da yok'**
  String get suggestBusinessReasonNotOnYeedoy;

  /// No description provided for @suggestBusinessReasonOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get suggestBusinessReasonOther;

  /// No description provided for @suggestBusinessLoginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Öneri göndermek için giriş yapmanız gerekiyor.'**
  String get suggestBusinessLoginRequired;

  /// No description provided for @suggestBusinessNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'İşletme adı zorunludur.'**
  String get suggestBusinessNameRequired;

  /// No description provided for @suggestBusinessCategoryRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir kategori seçin.'**
  String get suggestBusinessCategoryRequired;

  /// No description provided for @suggestBusinessInfoSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Bilgileri'**
  String get suggestBusinessInfoSectionTitle;

  /// No description provided for @suggestBusinessReasonSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öneri Nedeni'**
  String get suggestBusinessReasonSectionTitle;

  /// No description provided for @suggestBusinessPhotoSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf'**
  String get suggestBusinessPhotoSectionTitle;

  /// No description provided for @suggestBusinessOptionalSuffix.
  ///
  /// In tr, this message translates to:
  /// **'(İsteğe Bağlı)'**
  String get suggestBusinessOptionalSuffix;

  /// No description provided for @suggestBusinessContactSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'İletişim Bilgileri'**
  String get suggestBusinessContactSectionTitle;

  /// No description provided for @suggestBusinessPhotoSectionBody.
  ///
  /// In tr, this message translates to:
  /// **'İşletmeye ait fotoğraflar ekleyerek önerinizi güçlendirin.'**
  String get suggestBusinessPhotoSectionBody;

  /// No description provided for @suggestBusinessContactSectionBody.
  ///
  /// In tr, this message translates to:
  /// **'Sizinle iletişime geçebilmemiz için bilgilerinizi bırakabilirsiniz.'**
  String get suggestBusinessContactSectionBody;

  /// No description provided for @suggestBusinessNameHint.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Adı'**
  String get suggestBusinessNameHint;

  /// No description provided for @suggestBusinessEmailHint.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresiniz'**
  String get suggestBusinessEmailHint;

  /// No description provided for @suggestBusinessPhoneHint.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaranız'**
  String get suggestBusinessPhoneHint;

  /// No description provided for @suggestBusinessCategoryHint.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Kategorisi'**
  String get suggestBusinessCategoryHint;

  /// No description provided for @suggestBusinessAddressHint.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Adresi'**
  String get suggestBusinessAddressHint;

  /// No description provided for @suggestBusinessNotesHint.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Hakkında'**
  String get suggestBusinessNotesHint;

  /// No description provided for @suggestBusinessReasonHint.
  ///
  /// In tr, this message translates to:
  /// **'Neden bu işletmeyi öneriyorsunuz?'**
  String get suggestBusinessReasonHint;

  /// No description provided for @suggestBusinessSubmitButton.
  ///
  /// In tr, this message translates to:
  /// **'Öneriyi Gönder'**
  String get suggestBusinessSubmitButton;

  /// No description provided for @suggestBusinessHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şehrine değer kat!'**
  String get suggestBusinessHeroTitle;

  /// No description provided for @suggestBusinessHeroBody.
  ///
  /// In tr, this message translates to:
  /// **'Beğendiğin bir işletmeyi mi bulamıyorsun? Bize öner, değerlendirelim. Topluluğumuzun önerileriyle daha iyi bir deneyim sunalım.'**
  String get suggestBusinessHeroBody;

  /// No description provided for @suggestBusinessPhotoAddLabel.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Ekle'**
  String get suggestBusinessPhotoAddLabel;

  /// No description provided for @suggestBusinessPhotoFormatHint.
  ///
  /// In tr, this message translates to:
  /// **'PNG, JPG (Maks. 5MB)'**
  String get suggestBusinessPhotoFormatHint;

  /// No description provided for @suggestBusinessFeedbackNotice.
  ///
  /// In tr, this message translates to:
  /// **'Öneriniz değerlendirildikten sonra size geri dönüş sağlayacağız.'**
  String get suggestBusinessFeedbackNotice;

  /// No description provided for @suggestBusinessSimilarBusinessesFound.
  ///
  /// In tr, this message translates to:
  /// **'Benzer işletmeler mevcut'**
  String get suggestBusinessSimilarBusinessesFound;

  /// No description provided for @suggestBusinessReviewButton.
  ///
  /// In tr, this message translates to:
  /// **'İncele'**
  String get suggestBusinessReviewButton;

  /// No description provided for @suggestBusinessHelpSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öneri Süreci Nasıl İşler?'**
  String get suggestBusinessHelpSheetTitle;

  /// No description provided for @suggestBusinessHelpStep1Title.
  ///
  /// In tr, this message translates to:
  /// **'Öneriyi gönderiyorsunuz'**
  String get suggestBusinessHelpStep1Title;

  /// No description provided for @suggestBusinessHelpStep1Body.
  ///
  /// In tr, this message translates to:
  /// **'İşletme adı ve kategori zorunlu. Adres, not ve öneri nedeninizi eklerseniz değerlendirme daha hızlı olur.'**
  String get suggestBusinessHelpStep1Body;

  /// No description provided for @suggestBusinessHelpStep2Title.
  ///
  /// In tr, this message translates to:
  /// **'Ekibimiz inceliyor'**
  String get suggestBusinessHelpStep2Title;

  /// No description provided for @suggestBusinessHelpStep2Body.
  ///
  /// In tr, this message translates to:
  /// **'Gönderdiğiniz öneri yönetim paneline düşer. Ekibimiz tekrar eden ya da uygunsuz önerileri ayıklar.'**
  String get suggestBusinessHelpStep2Body;

  /// No description provided for @suggestBusinessHelpStep3Title.
  ///
  /// In tr, this message translates to:
  /// **'İşletme platforma eklenir'**
  String get suggestBusinessHelpStep3Title;

  /// No description provided for @suggestBusinessHelpStep3Body.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanan işletme Yeedoy\'a eklenir. Öneri durumunu \"Önerilerim\" ekranından takip edebilirsiniz.'**
  String get suggestBusinessHelpStep3Body;

  /// No description provided for @suggestBusinessHelpLoginNotice.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapmış olmanız gerekiyor. Önerilerinizi takip etmek için hesabınıza giriş yapın.'**
  String get suggestBusinessHelpLoginNotice;

  /// No description provided for @suggestBusinessPickLocationHint.
  ///
  /// In tr, this message translates to:
  /// **'Haritadan Konum Seç (İsteğe Bağlı)'**
  String get suggestBusinessPickLocationHint;

  /// No description provided for @suggestBusinessLocationSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum Seç'**
  String get suggestBusinessLocationSheetTitle;

  /// No description provided for @suggestBusinessCurrentLocationTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut konumum'**
  String get suggestBusinessCurrentLocationTooltip;

  /// No description provided for @suggestBusinessLocationSheetHint.
  ///
  /// In tr, this message translates to:
  /// **'Haritaya dokunarak işletmenin konumunu işaretleyin.'**
  String get suggestBusinessLocationSheetHint;

  /// No description provided for @suggestBusinessPickLocationButton.
  ///
  /// In tr, this message translates to:
  /// **'Haritadan Konum Seçin'**
  String get suggestBusinessPickLocationButton;

  /// No description provided for @suggestBusinessUseThisLocationButton.
  ///
  /// In tr, this message translates to:
  /// **'Bu Konumu Kullan'**
  String get suggestBusinessUseThisLocationButton;

  /// No description provided for @helpSupportTopic1Question.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat değişikliği nasıl bildirilir?'**
  String get helpSupportTopic1Question;

  /// No description provided for @helpSupportTopic1Answer.
  ///
  /// In tr, this message translates to:
  /// **'Bir işletmeyi ziyaret ettikten sonra \"Fiyat Bildir\" butonuna tıklayarak güncel fiyatı girebilirsiniz. Katkınız için puan kazanırsınız.'**
  String get helpSupportTopic1Answer;

  /// No description provided for @helpSupportTopic2Question.
  ///
  /// In tr, this message translates to:
  /// **'QR Menü nasıl taranır?'**
  String get helpSupportTopic2Question;

  /// No description provided for @helpSupportTopic2Answer.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranda sağ üstteki QR simgesine dokunun ve kamerayı masadaki QR koda tutun. Menü otomatik açılır.'**
  String get helpSupportTopic2Answer;

  /// No description provided for @helpSupportTopic3Question.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı nasıl güvene alırım?'**
  String get helpSupportTopic3Question;

  /// No description provided for @helpSupportTopic3Answer.
  ///
  /// In tr, this message translates to:
  /// **'Güçlü bir şifre kullanın ve iki adımlı doğrulamayı etkinleştirin. Hesap Güvenliği sayfasından tüm ayarları yönetebilirsiniz.'**
  String get helpSupportTopic3Answer;

  /// No description provided for @helpSupportTopic4Question.
  ///
  /// In tr, this message translates to:
  /// **'Katkı yap ve puan kazanma nasıl çalışır?'**
  String get helpSupportTopic4Question;

  /// No description provided for @helpSupportTopic4Answer.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat bildirimi, yorum ve fotoğraf ekleme gibi katkılarla puan kazanırsınız. Puanlarınızı profilinizden takip edebilirsiniz.'**
  String get helpSupportTopic4Answer;

  /// No description provided for @helpSupportTopic5Question.
  ///
  /// In tr, this message translates to:
  /// **'Konum ve bölge ayarlarını nasıl değiştiririm?'**
  String get helpSupportTopic5Question;

  /// No description provided for @helpSupportTopic5Answer.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar → Uygulama Tercihleri → Konum Ayarları yolunu izleyerek konumunuzu ve bölgenizi güncelleyebilirsiniz.'**
  String get helpSupportTopic5Answer;

  /// No description provided for @helpSupportPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yardım & Destek'**
  String get helpSupportPageTitle;

  /// No description provided for @helpSupportHeaderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Size nasıl yardımcı olabiliriz?'**
  String get helpSupportHeaderSubtitle;

  /// No description provided for @helpSupportSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Sorununuzu yazın, çözüme birlikte ulaşalım...'**
  String get helpSupportSearchHint;

  /// No description provided for @helpSupportLiveChatTitle.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Destek'**
  String get helpSupportLiveChatTitle;

  /// No description provided for @helpSupportLiveChatSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekibimizle anında görüşün'**
  String get helpSupportLiveChatSubtitle;

  /// No description provided for @helpSupportLiveChatBadge.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi'**
  String get helpSupportLiveChatBadge;

  /// No description provided for @helpSupportEmailTitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Gönder'**
  String get helpSupportEmailTitle;

  /// No description provided for @helpSupportEmailSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bize e-posta ile ulaşın'**
  String get helpSupportEmailSubtitle;

  /// No description provided for @helpSupportEmailBadge.
  ///
  /// In tr, this message translates to:
  /// **'24 Saat İçinde Yanıt'**
  String get helpSupportEmailBadge;

  /// No description provided for @helpSupportMailtoSubject.
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy Destek Talebi'**
  String get helpSupportMailtoSubject;

  /// No description provided for @helpSupportFaqTitle.
  ///
  /// In tr, this message translates to:
  /// **'S.S.S.'**
  String get helpSupportFaqTitle;

  /// No description provided for @helpSupportFaqSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sık sorulan sorulara göz atın'**
  String get helpSupportFaqSubtitle;

  /// No description provided for @helpSupportFaqBadge.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Çözümler'**
  String get helpSupportFaqBadge;

  /// No description provided for @helpSupportGuideTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Rehberi'**
  String get helpSupportGuideTitle;

  /// No description provided for @helpSupportGuideSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı daha iyi öğrenin'**
  String get helpSupportGuideSubtitle;

  /// No description provided for @helpSupportGuideBadge.
  ///
  /// In tr, this message translates to:
  /// **'Rehbere Git'**
  String get helpSupportGuideBadge;

  /// No description provided for @helpSupportPopularTopicsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Popüler Konular'**
  String get helpSupportPopularTopicsTitle;

  /// No description provided for @helpSupportSeeAllButton.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get helpSupportSeeAllButton;

  /// No description provided for @helpSupportNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı.'**
  String get helpSupportNoResults;

  /// No description provided for @helpSupportHelpCenterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yardım Merkezi'**
  String get helpSupportHelpCenterTitle;

  /// No description provided for @helpSupportAccountOpsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap İşlemleri'**
  String get helpSupportAccountOpsTitle;

  /// No description provided for @helpSupportAccountOpsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap, giriş, şifre ve profil işlemleri'**
  String get helpSupportAccountOpsSubtitle;

  /// No description provided for @helpSupportContributionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Katkı ve Puanlar'**
  String get helpSupportContributionsTitle;

  /// No description provided for @helpSupportContributionsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Katkı yapma, puan kazanma ve ödüller'**
  String get helpSupportContributionsSubtitle;

  /// No description provided for @helpSupportAppUsageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Kullanımı'**
  String get helpSupportAppUsageTitle;

  /// No description provided for @helpSupportAppUsageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama özellikleri ve kullanımı'**
  String get helpSupportAppUsageSubtitle;

  /// No description provided for @helpSupportLegalPrivacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yasal & Gizlilik'**
  String get helpSupportLegalPrivacyTitle;

  /// No description provided for @helpSupportLegalPrivacySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik, güvenlik ve yasal konular'**
  String get helpSupportLegalPrivacySubtitle;

  /// No description provided for @helpSupportContactTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bizimle İletişime Geçin'**
  String get helpSupportContactTitle;

  /// No description provided for @helpSupportContactBody.
  ///
  /// In tr, this message translates to:
  /// **'Her türlü soru, öneri veya şikayetinizi bizimle paylaşabilirsiniz.'**
  String get helpSupportContactBody;

  /// No description provided for @helpSupportContactHours.
  ///
  /// In tr, this message translates to:
  /// **'Hafta içi 09:00 - 18:00'**
  String get helpSupportContactHours;

  /// No description provided for @helpSupportResolvedQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Sorununuz çözüldü mü?'**
  String get helpSupportResolvedQuestion;

  /// No description provided for @helpSupportThanksSnackbar.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler! 👍'**
  String get helpSupportThanksSnackbar;

  /// No description provided for @helpSupportYesResolvedButton.
  ///
  /// In tr, this message translates to:
  /// **'Evet, çözüldü'**
  String get helpSupportYesResolvedButton;

  /// No description provided for @helpSupportNoContinueButton.
  ///
  /// In tr, this message translates to:
  /// **'Hayır, devam ediyor'**
  String get helpSupportNoContinueButton;

  /// No description provided for @faqCategoryAccountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hesap İşlemleri'**
  String get faqCategoryAccountLabel;

  /// No description provided for @faqCategorySecurityLabel.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get faqCategorySecurityLabel;

  /// No description provided for @faqCategoryPaymentsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeler'**
  String get faqCategoryPaymentsLabel;

  /// No description provided for @faqCategoryCampaignsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kampanya ve Fırsatlar'**
  String get faqCategoryCampaignsLabel;

  /// No description provided for @faqCategoryAppUsageLabel.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Kullanımı'**
  String get faqCategoryAppUsageLabel;

  /// No description provided for @faqQ1Question.
  ///
  /// In tr, this message translates to:
  /// **'Hesabıma nasıl giriş yapıyım?'**
  String get faqQ1Question;

  /// No description provided for @faqQ1Answer.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama açıldığında \"Giriş Yap\" seçeneğine dokunun. E-posta adresinizi ve şifrenizi girerek hesabınıza erişebilirsiniz.'**
  String get faqQ1Answer;

  /// No description provided for @faqQ2Question.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum, ne yapmalıyım?'**
  String get faqQ2Question;

  /// No description provided for @faqQ2Answer.
  ///
  /// In tr, this message translates to:
  /// **'Giriş ekranındaki \"Şifremi Unuttum\" seçeneğine tıklayarak şifrenizi sıfırlayabilirsiniz. Kayıtlı e-posta adresinize bağlantı gönderilir.'**
  String get faqQ2Answer;

  /// No description provided for @faqQ3Question.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresimi nasıl değiştiririm?'**
  String get faqQ3Question;

  /// No description provided for @faqQ3Answer.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Bilgileri > E-posta alanından e-posta adresinizi değiştirebilirsiniz. Yeni adresinize onay e-postası gönderilecektir.'**
  String get faqQ3Answer;

  /// No description provided for @faqQ4Question.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı nasıl silebilirim?'**
  String get faqQ4Question;

  /// No description provided for @faqQ4Answer.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar > Hesap Güvenliği > Hesabı Sil seçeneğinden hesabınızı kalıcı olarak silebilirsiniz. Bu işlem geri alınamaz.'**
  String get faqQ4Answer;

  /// No description provided for @faqQ5Question.
  ///
  /// In tr, this message translates to:
  /// **'Profilime nasıl fotoğraf eklerim?'**
  String get faqQ5Question;

  /// No description provided for @faqQ5Answer.
  ///
  /// In tr, this message translates to:
  /// **'Profil sayfanızda avatarınıza dokunun ve galerinizden veya kameranızdan fotoğraf seçin.'**
  String get faqQ5Answer;

  /// No description provided for @faqQ6Question.
  ///
  /// In tr, this message translates to:
  /// **'İki adımlı doğrulamayı nasıl etkinleştiririm?'**
  String get faqQ6Question;

  /// No description provided for @faqQ6Answer.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Güvenliği sayfasında \"İki Adımlı Doğrulama\" seçeneğini açarak telefonunuza SMS kodu gönderilmesini sağlayabilirsiniz.'**
  String get faqQ6Answer;

  /// No description provided for @faqQ7Question.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımda şüpheli bir etkinlik var, ne yapmalıyım?'**
  String get faqQ7Question;

  /// No description provided for @faqQ7Answer.
  ///
  /// In tr, this message translates to:
  /// **'Hemen \"Şifremi Değiştir\" seçeneğini kullanın ve aktif oturumları sonlandırın. Ardından destek ekibimizle iletişime geçin.'**
  String get faqQ7Answer;

  /// No description provided for @faqQ8Question.
  ///
  /// In tr, this message translates to:
  /// **'Verilerim güvende mi?'**
  String get faqQ8Question;

  /// No description provided for @faqQ8Answer.
  ///
  /// In tr, this message translates to:
  /// **'Tüm verileriniz 256-bit SSL sertifikası ile şifrelenerek korunmaktadır. KVKK kapsamında kişisel verileriniz işlenmektedir.'**
  String get faqQ8Answer;

  /// No description provided for @faqQ9Question.
  ///
  /// In tr, this message translates to:
  /// **'Oturumu kapatmayı unutursam ne olur?'**
  String get faqQ9Question;

  /// No description provided for @faqQ9Answer.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Güvenliği sayfasından tüm aktif oturumlarınızı uzaktan sonlandırabilirsiniz.'**
  String get faqQ9Answer;

  /// No description provided for @faqQ10Question.
  ///
  /// In tr, this message translates to:
  /// **'Ödemelerimi görüntüleyebilir miyim?'**
  String get faqQ10Question;

  /// No description provided for @faqQ10Answer.
  ///
  /// In tr, this message translates to:
  /// **'Evet. Tüm ödeme geçmişiniz 256-bit SSL sertifikası ile korunmakta olup Ödemeler ekranından takip edebilirsiniz.'**
  String get faqQ10Answer;

  /// No description provided for @faqQ11Question.
  ///
  /// In tr, this message translates to:
  /// **'İade işlemi nasıl yapılır?'**
  String get faqQ11Question;

  /// No description provided for @faqQ11Answer.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş sayfanızdan ilgili siparişi seçerek iade talep edebilirsiniz. İşlem 3-5 iş günü içinde tamamlanır.'**
  String get faqQ11Answer;

  /// No description provided for @faqQ12Question.
  ///
  /// In tr, this message translates to:
  /// **'Hangi ödeme yöntemleri desteklenmektedir?'**
  String get faqQ12Question;

  /// No description provided for @faqQ12Answer.
  ///
  /// In tr, this message translates to:
  /// **'Kredi kartı, banka kartı ve havale/EFT ile ödeme yapabilirsiniz. Apple Pay ve Google Pay desteği yakında eklenecektir.'**
  String get faqQ12Answer;

  /// No description provided for @faqQ13Question.
  ///
  /// In tr, this message translates to:
  /// **'Kampanyalardan nasıl haberdar olabilirim?'**
  String get faqQ13Question;

  /// No description provided for @faqQ13Answer.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim tercihlerinizde \"Kampanya ve Fırsatlar\" bildirimlerini açarsanız yeni fırsatlarda anlık bildirim alırsınız.'**
  String get faqQ13Answer;

  /// No description provided for @faqQ14Question.
  ///
  /// In tr, this message translates to:
  /// **'Kupon kodumu nasıl kullanırım?'**
  String get faqQ14Question;

  /// No description provided for @faqQ14Answer.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme ekranında \"Kupon Kodu\" alanına kodunuzu girebilirsiniz. İndirim tutarı otomatik uygulanır.'**
  String get faqQ14Answer;

  /// No description provided for @faqQ15Question.
  ///
  /// In tr, this message translates to:
  /// **'QR menü nasıl taranır?'**
  String get faqQ15Question;

  /// No description provided for @faqQ15Answer.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranda sağ üstteki QR simgesine dokunun ve kamerayı masadaki QR koda tutun. Menü otomatik açılır.'**
  String get faqQ15Answer;

  /// No description provided for @faqQ16Question.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat değişikliği nasıl bildirilir?'**
  String get faqQ16Question;

  /// No description provided for @faqQ16Answer.
  ///
  /// In tr, this message translates to:
  /// **'Bir işletmeyi ziyaret ettikten sonra \"Fiyat Bildir\" butonuna tıklayarak güncel fiyatı girebilirsiniz. Katkınız için puan kazanırsınız.'**
  String get faqQ16Answer;

  /// No description provided for @faqQ17Question.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık mod var mı?'**
  String get faqQ17Question;

  /// No description provided for @faqQ17Answer.
  ///
  /// In tr, this message translates to:
  /// **'Evet. Ayarlar > Uygulama Tercihleri > Tema bölümünden karanlık modu etkinleştirebilirsiniz.'**
  String get faqQ17Answer;

  /// No description provided for @faqQ18Question.
  ///
  /// In tr, this message translates to:
  /// **'Konum iznini nasıl veririm?'**
  String get faqQ18Question;

  /// No description provided for @faqQ18Answer.
  ///
  /// In tr, this message translates to:
  /// **'Cihazınızın Ayarlar > Uygulamalar > Yeedoy > İzinler menüsünden konum iznini aktif edebilirsiniz.'**
  String get faqQ18Answer;

  /// No description provided for @faqPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sıkça Sorulan Sorular'**
  String get faqPageTitle;

  /// No description provided for @faqSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Soru veya konu ara...'**
  String get faqSearchHint;

  /// No description provided for @faqCategoriesSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get faqCategoriesSectionTitle;

  /// No description provided for @faqQuestionCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Soru'**
  String faqQuestionCount(int count);

  /// No description provided for @faqListSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sık Sorulan Sorular'**
  String get faqListSectionTitle;

  /// No description provided for @faqNoResultsInCategory.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoride sonuç bulunamadı.'**
  String get faqNoResultsInCategory;

  /// No description provided for @faqSupportBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aradığınız cevabı bulamadınız mı?'**
  String get faqSupportBannerTitle;

  /// No description provided for @faqSupportBannerBody.
  ///
  /// In tr, this message translates to:
  /// **'Destek ekibimiz size yardımcı olmaktan mutluluk duyar.'**
  String get faqSupportBannerBody;

  /// No description provided for @faqSupportBannerButton.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Destek'**
  String get faqSupportBannerButton;

  /// No description provided for @faqBottomHelpfulQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfa size yardımcı oldu mu?'**
  String get faqBottomHelpfulQuestion;

  /// No description provided for @faqThanksSnackbar.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler! 👍'**
  String get faqThanksSnackbar;

  /// No description provided for @faqYesHelpfulButton.
  ///
  /// In tr, this message translates to:
  /// **'Evet, yardımcı oldu'**
  String get faqYesHelpfulButton;

  /// No description provided for @faqNoHelpfulButton.
  ///
  /// In tr, this message translates to:
  /// **'Hayır, olmadı'**
  String get faqNoHelpfulButton;

  /// No description provided for @yemekGunluguPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yemek Günlüğüm'**
  String get yemekGunluguPageTitle;

  /// No description provided for @yemekGunluguReminderTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı Ayarla'**
  String get yemekGunluguReminderTooltip;

  /// No description provided for @yemekGunluguRetryButton.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get yemekGunluguRetryButton;

  /// No description provided for @yemekGunluguEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yemek günlüğün boş'**
  String get yemekGunluguEmptyTitle;

  /// No description provided for @yemekGunluguEmptyDescription.
  ///
  /// In tr, this message translates to:
  /// **'Henüz check-in kaydın yok. Bir işletmeye gittiğinde check-in yap!'**
  String get yemekGunluguEmptyDescription;

  /// No description provided for @yemekGunluguReminderSetSnackbar.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı {time} için ayarlandı'**
  String yemekGunluguReminderSetSnackbar(String time);

  /// No description provided for @yemekGunluguReminderOffSnackbar.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı kapatıldı'**
  String get yemekGunluguReminderOffSnackbar;

  /// No description provided for @yemekGunluguToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get yemekGunluguToday;

  /// No description provided for @yemekGunluguYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yemekGunluguYesterday;

  /// No description provided for @yemekGunluguMonthJanuary.
  ///
  /// In tr, this message translates to:
  /// **'Ocak'**
  String get yemekGunluguMonthJanuary;

  /// No description provided for @yemekGunluguMonthFebruary.
  ///
  /// In tr, this message translates to:
  /// **'Şubat'**
  String get yemekGunluguMonthFebruary;

  /// No description provided for @yemekGunluguMonthMarch.
  ///
  /// In tr, this message translates to:
  /// **'Mart'**
  String get yemekGunluguMonthMarch;

  /// No description provided for @yemekGunluguMonthApril.
  ///
  /// In tr, this message translates to:
  /// **'Nisan'**
  String get yemekGunluguMonthApril;

  /// No description provided for @yemekGunluguMonthMay.
  ///
  /// In tr, this message translates to:
  /// **'Mayıs'**
  String get yemekGunluguMonthMay;

  /// No description provided for @yemekGunluguMonthJune.
  ///
  /// In tr, this message translates to:
  /// **'Haziran'**
  String get yemekGunluguMonthJune;

  /// No description provided for @yemekGunluguMonthJuly.
  ///
  /// In tr, this message translates to:
  /// **'Temmuz'**
  String get yemekGunluguMonthJuly;

  /// No description provided for @yemekGunluguMonthAugust.
  ///
  /// In tr, this message translates to:
  /// **'Ağustos'**
  String get yemekGunluguMonthAugust;

  /// No description provided for @yemekGunluguMonthSeptember.
  ///
  /// In tr, this message translates to:
  /// **'Eylül'**
  String get yemekGunluguMonthSeptember;

  /// No description provided for @yemekGunluguMonthOctober.
  ///
  /// In tr, this message translates to:
  /// **'Ekim'**
  String get yemekGunluguMonthOctober;

  /// No description provided for @yemekGunluguMonthNovember.
  ///
  /// In tr, this message translates to:
  /// **'Kasım'**
  String get yemekGunluguMonthNovember;

  /// No description provided for @yemekGunluguMonthDecember.
  ///
  /// In tr, this message translates to:
  /// **'Aralık'**
  String get yemekGunluguMonthDecember;

  /// No description provided for @yemekGunluguEditLabel.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get yemekGunluguEditLabel;

  /// No description provided for @yemekGunluguAmountPaidLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ödenen tutar'**
  String get yemekGunluguAmountPaidLabel;

  /// No description provided for @yemekGunluguAmountHint.
  ///
  /// In tr, this message translates to:
  /// **'0.00'**
  String get yemekGunluguAmountHint;

  /// No description provided for @yemekGunluguNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Notunuz'**
  String get yemekGunluguNoteLabel;

  /// No description provided for @yemekGunluguNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Deneyiminizi yazın...'**
  String get yemekGunluguNoteHint;

  /// No description provided for @yemekGunluguRatingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Puanınız'**
  String get yemekGunluguRatingLabel;

  /// No description provided for @yemekGunluguSaveButton.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get yemekGunluguSaveButton;

  /// No description provided for @yemekGunluguReminderSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yemek Günlüğü Hatırlatıcısı'**
  String get yemekGunluguReminderSheetTitle;

  /// No description provided for @yemekGunluguReminderSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her gün belirlediğin saatte check-in hatırlatması gönderilir.'**
  String get yemekGunluguReminderSheetSubtitle;

  /// No description provided for @yemekGunluguDailyReminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Hatırlatıcı'**
  String get yemekGunluguDailyReminderTitle;

  /// No description provided for @yemekGunluguDailyReminderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her gün seçilen saatte bildirim gönder'**
  String get yemekGunluguDailyReminderSubtitle;

  /// No description provided for @yemekGunluguReminderTimeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma Saati'**
  String get yemekGunluguReminderTimeLabel;

  /// No description provided for @yemekGunluguHourLabel.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get yemekGunluguHourLabel;

  /// No description provided for @yemekGunluguMinuteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dakika'**
  String get yemekGunluguMinuteLabel;

  /// No description provided for @searchFilterAllOption.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get searchFilterAllOption;

  /// No description provided for @searchFilterCategoryRestaurant.
  ///
  /// In tr, this message translates to:
  /// **'Restoran'**
  String get searchFilterCategoryRestaurant;

  /// No description provided for @searchFilterCategoryCafe.
  ///
  /// In tr, this message translates to:
  /// **'Kafe'**
  String get searchFilterCategoryCafe;

  /// No description provided for @searchFilterCategoryFastFood.
  ///
  /// In tr, this message translates to:
  /// **'Fast Food'**
  String get searchFilterCategoryFastFood;

  /// No description provided for @searchFilterCategoryBakery.
  ///
  /// In tr, this message translates to:
  /// **'Pastane'**
  String get searchFilterCategoryBakery;

  /// No description provided for @searchFilterCategoryBreakfast.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get searchFilterCategoryBreakfast;

  /// No description provided for @searchFilterCategoryFishMeat.
  ///
  /// In tr, this message translates to:
  /// **'Balık/Et'**
  String get searchFilterCategoryFishMeat;

  /// No description provided for @searchFilterCategoryVenue.
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get searchFilterCategoryVenue;

  /// No description provided for @searchFilterCuisineTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türk Mutfağı'**
  String get searchFilterCuisineTurkish;

  /// No description provided for @searchFilterCuisineItalian.
  ///
  /// In tr, this message translates to:
  /// **'İtalyan'**
  String get searchFilterCuisineItalian;

  /// No description provided for @searchFilterCuisineFarEast.
  ///
  /// In tr, this message translates to:
  /// **'Uzakdoğu'**
  String get searchFilterCuisineFarEast;

  /// No description provided for @searchFilterCuisineHamburger.
  ///
  /// In tr, this message translates to:
  /// **'Hamburger'**
  String get searchFilterCuisineHamburger;

  /// No description provided for @searchFilterCuisineVegetarian.
  ///
  /// In tr, this message translates to:
  /// **'Vejetar'**
  String get searchFilterCuisineVegetarian;

  /// No description provided for @searchFilterCuisineChinese.
  ///
  /// In tr, this message translates to:
  /// **'Çin'**
  String get searchFilterCuisineChinese;

  /// No description provided for @searchFilterCuisineMexican.
  ///
  /// In tr, this message translates to:
  /// **'Meksika'**
  String get searchFilterCuisineMexican;

  /// No description provided for @searchFilterCuisineIndian.
  ///
  /// In tr, this message translates to:
  /// **'Hint'**
  String get searchFilterCuisineIndian;

  /// No description provided for @searchFilterCuisineJapanese.
  ///
  /// In tr, this message translates to:
  /// **'Japon'**
  String get searchFilterCuisineJapanese;

  /// No description provided for @searchFilterPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arama & Filtrele'**
  String get searchFilterPageTitle;

  /// No description provided for @searchFilterClearButton.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get searchFilterClearButton;

  /// No description provided for @searchFilterSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'İşletme, mutfak veya menü ara...'**
  String get searchFilterSearchHint;

  /// No description provided for @searchFilterLocationSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get searchFilterLocationSectionTitle;

  /// No description provided for @searchFilterChangeButton.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get searchFilterChangeButton;

  /// No description provided for @searchFilterLocationNotSelected.
  ///
  /// In tr, this message translates to:
  /// **'Konum seçilmedi'**
  String get searchFilterLocationNotSelected;

  /// No description provided for @searchFilterCategoriesSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get searchFilterCategoriesSectionTitle;

  /// No description provided for @searchFilterCuisineSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mutfak Türü'**
  String get searchFilterCuisineSectionTitle;

  /// No description provided for @searchFilterPriceRangeSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Aralığı'**
  String get searchFilterPriceRangeSectionTitle;

  /// No description provided for @searchFilterEnterRangeButton.
  ///
  /// In tr, this message translates to:
  /// **'Aralığı gir'**
  String get searchFilterEnterRangeButton;

  /// No description provided for @searchFilterRatingSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get searchFilterRatingSectionTitle;

  /// No description provided for @searchFilterOpenClosedSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Açık / Kapalı'**
  String get searchFilterOpenClosedSectionTitle;

  /// No description provided for @searchFilterOpenOnly.
  ///
  /// In tr, this message translates to:
  /// **'Açık Olanlar'**
  String get searchFilterOpenOnly;

  /// No description provided for @searchFilterOpenNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu An Açık'**
  String get searchFilterOpenNow;

  /// No description provided for @searchFilterClosedOnly.
  ///
  /// In tr, this message translates to:
  /// **'Kapalılar'**
  String get searchFilterClosedOnly;

  /// No description provided for @searchFilterOtherFiltersSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diğer Filtreler'**
  String get searchFilterOtherFiltersSectionTitle;

  /// No description provided for @searchFilterOffersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fırsatları Olanlar'**
  String get searchFilterOffersTitle;

  /// No description provided for @searchFilterOffersSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İndirim veya fırsat sunan işletmeler'**
  String get searchFilterOffersSubtitle;

  /// No description provided for @searchFilterPriceAlertTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Alarmı Kurduğum İşletmeler'**
  String get searchFilterPriceAlertTitle;

  /// No description provided for @searchFilterPriceAlertSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Alarm kurduğun işletmeleri göster'**
  String get searchFilterPriceAlertSubtitle;

  /// No description provided for @searchFilterFavoritesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerim'**
  String get searchFilterFavoritesTitle;

  /// No description provided for @searchFilterFavoritesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerine eklediğin işletmeler'**
  String get searchFilterFavoritesSubtitle;

  /// No description provided for @searchFilterShowResultsButton.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçları Göster ({count})'**
  String searchFilterShowResultsButton(int count);

  /// No description provided for @searchFilterPriceDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Aralığı Gir'**
  String get searchFilterPriceDialogTitle;

  /// No description provided for @searchFilterMinPriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Min ₺'**
  String get searchFilterMinPriceLabel;

  /// No description provided for @searchFilterMaxPriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Max ₺'**
  String get searchFilterMaxPriceLabel;

  /// No description provided for @searchFilterMaxPriceHint.
  ///
  /// In tr, this message translates to:
  /// **'1000+'**
  String get searchFilterMaxPriceHint;

  /// No description provided for @searchFilterCancelButton.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get searchFilterCancelButton;

  /// No description provided for @searchFilterApplyButton.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get searchFilterApplyButton;

  /// No description provided for @reservationNameTooShortError.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad en az 2 karakter olmalıdır.'**
  String get reservationNameTooShortError;

  /// No description provided for @reservationPhoneTooShortError.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası en az 10 karakter olmalıdır.'**
  String get reservationPhoneTooShortError;

  /// No description provided for @reservationDateRequiredError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir tarih seçin.'**
  String get reservationDateRequiredError;

  /// No description provided for @reservationPartySizeRangeError.
  ///
  /// In tr, this message translates to:
  /// **'Kişi sayısı {min} ile {max} arasında olmalıdır.'**
  String reservationPartySizeRangeError(int min, int max);

  /// No description provided for @reservationPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon Yap'**
  String get reservationPageTitle;

  /// No description provided for @reservationCloseTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get reservationCloseTooltip;

  /// No description provided for @reservationNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad *'**
  String get reservationNameLabel;

  /// No description provided for @reservationNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Adınız ve soyadınız'**
  String get reservationNameHint;

  /// No description provided for @reservationPhoneLabel.
  ///
  /// In tr, this message translates to:
  /// **'Telefon *'**
  String get reservationPhoneLabel;

  /// No description provided for @reservationPhoneHint.
  ///
  /// In tr, this message translates to:
  /// **'0555 000 00 00'**
  String get reservationPhoneHint;

  /// No description provided for @reservationEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get reservationEmailLabel;

  /// No description provided for @reservationEmailHint.
  ///
  /// In tr, this message translates to:
  /// **'ornek@email.com'**
  String get reservationEmailHint;

  /// No description provided for @reservationDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tarih *'**
  String get reservationDateLabel;

  /// No description provided for @reservationDatePickHint.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seçin'**
  String get reservationDatePickHint;

  /// No description provided for @reservationTimeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Saat *'**
  String get reservationTimeLabel;

  /// No description provided for @reservationTimePickHint.
  ///
  /// In tr, this message translates to:
  /// **'Saat seçin'**
  String get reservationTimePickHint;

  /// No description provided for @reservationPartySizeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kişi Sayısı *'**
  String get reservationPartySizeLabel;

  /// No description provided for @reservationPartySizeRangeHint.
  ///
  /// In tr, this message translates to:
  /// **'({min}–{max} kişi)'**
  String reservationPartySizeRangeHint(int min, int max);

  /// No description provided for @reservationSpecialRequestLabel.
  ///
  /// In tr, this message translates to:
  /// **'Özel İstek'**
  String get reservationSpecialRequestLabel;

  /// No description provided for @reservationSpecialRequestHint.
  ///
  /// In tr, this message translates to:
  /// **'Doğum günü, pencere kenarı, vb.'**
  String get reservationSpecialRequestHint;

  /// No description provided for @reservationSuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon Talebiniz Alındı!'**
  String get reservationSuccessTitle;

  /// No description provided for @reservationSuccessSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletme en kısa sürede sizinle iletişime geçecektir.'**
  String get reservationSuccessSubtitle;

  /// No description provided for @reservationNumberLabel.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon No'**
  String get reservationNumberLabel;

  /// No description provided for @reservationOkButton.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get reservationOkButton;

  /// No description provided for @contributePageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Katkı Yap'**
  String get contributePageTitle;

  /// No description provided for @contributePageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Topluluğa katkı sağlayarak menüleri ve fiyatları güncel tut.'**
  String get contributePageSubtitle;

  /// No description provided for @contributeHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Katkıların değerli!'**
  String get contributeHeroTitle;

  /// No description provided for @contributeHeroSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanan katkılarla puan ve rozet kazan.'**
  String get contributeHeroSubtitle;

  /// No description provided for @contributeQrScanTitle.
  ///
  /// In tr, this message translates to:
  /// **'QR Menü Tara'**
  String get contributeQrScanTitle;

  /// No description provided for @contributeQrScanSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Mekanın QR menüsünü hızlıca tara'**
  String get contributeQrScanSubtitle;

  /// No description provided for @contributePhotoUploadTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Yükle'**
  String get contributePhotoUploadTitle;

  /// No description provided for @contributePhotoUploadSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Menü, mekan veya yemek fotoğrafı ekle'**
  String get contributePhotoUploadSubtitle;

  /// No description provided for @contributePriceVerifyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Değişimi Doğrula'**
  String get contributePriceVerifyTitle;

  /// No description provided for @contributePriceVerifySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güncel fiyat bilgisini onayla'**
  String get contributePriceVerifySubtitle;

  /// No description provided for @contributeRecentSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son katkıların'**
  String get contributeRecentSectionTitle;

  /// No description provided for @contributeSeeAllButton.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü gör'**
  String get contributeSeeAllButton;

  /// No description provided for @contributeEmptyState.
  ///
  /// In tr, this message translates to:
  /// **'Henüz katkın yok.\nYukarıdan bir katkı türü seçerek başlayabilirsin!'**
  String get contributeEmptyState;

  /// No description provided for @contributeScoreLabel.
  ///
  /// In tr, this message translates to:
  /// **'Katkı puanın'**
  String get contributeScoreLabel;

  /// No description provided for @contributeThisWeekLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta'**
  String get contributeThisWeekLabel;

  /// No description provided for @contributeWeeklyCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'{count} katkı yaptın'**
  String contributeWeeklyCountLabel(int count);

  /// No description provided for @contributeQrScannedSnackbar.
  ///
  /// In tr, this message translates to:
  /// **'QR kod okundu, incelemeye gönderildi.'**
  String get contributeQrScannedSnackbar;

  /// No description provided for @contributeVisitBusinessSnackbar.
  ///
  /// In tr, this message translates to:
  /// **'Katkı yapmak için bir işletme sayfasını ziyaret edin.'**
  String get contributeVisitBusinessSnackbar;

  /// No description provided for @contributeTypePriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulaması'**
  String get contributeTypePriceLabel;

  /// No description provided for @contributeTypeMenuLabel.
  ///
  /// In tr, this message translates to:
  /// **'Menü katkısı'**
  String get contributeTypeMenuLabel;

  /// No description provided for @contributeTypeBusinessLabel.
  ///
  /// In tr, this message translates to:
  /// **'İşletme önerisi'**
  String get contributeTypeBusinessLabel;

  /// No description provided for @contributeStatusApproved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get contributeStatusApproved;

  /// No description provided for @contributeStatusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get contributeStatusRejected;

  /// No description provided for @contributeStatusUnderReview.
  ///
  /// In tr, this message translates to:
  /// **'İnceleniyor'**
  String get contributeStatusUnderReview;

  /// No description provided for @contributeStatusPending.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get contributeStatusPending;

  /// No description provided for @contributeMinutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} dakika önce'**
  String contributeMinutesAgo(int count);

  /// No description provided for @contributeHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} saat önce'**
  String contributeHoursAgo(int count);

  /// No description provided for @contributeOneDayAgo.
  ///
  /// In tr, this message translates to:
  /// **'1 gün önce'**
  String get contributeOneDayAgo;

  /// No description provided for @contributeDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün önce'**
  String contributeDaysAgo(int count);

  /// No description provided for @oyVerDefaultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Grup Oyu'**
  String get oyVerDefaultTitle;

  /// No description provided for @oyVerListNotFoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'Liste bulunamadı'**
  String get oyVerListNotFoundTitle;

  /// No description provided for @oyVerInvalidTokenBody.
  ///
  /// In tr, this message translates to:
  /// **'Token geçersiz olabilir.'**
  String get oyVerInvalidTokenBody;

  /// No description provided for @oyVerEmptyListMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu listede henüz işletme yok.'**
  String get oyVerEmptyListMessage;

  /// No description provided for @oyVerOptionsCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'{count} seçenek — beğenin veya beğenmeyin'**
  String oyVerOptionsCountLabel(int count);

  /// No description provided for @oyVerYesButton.
  ///
  /// In tr, this message translates to:
  /// **'Gidelim'**
  String get oyVerYesButton;

  /// No description provided for @oyVerNoButton.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get oyVerNoButton;

  /// No description provided for @priceAlertsPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygun fiyatları kaçırma, alarm kur!'**
  String get priceAlertsPageSubtitle;

  /// No description provided for @priceAlertsDeleteDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alarmı sil'**
  String get priceAlertsDeleteDialogTitle;

  /// No description provided for @priceAlertsDeleteDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu alarm silinecek. Emin misin?'**
  String get priceAlertsDeleteDialogBody;

  /// No description provided for @priceAlertsCancelButton.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get priceAlertsCancelButton;

  /// No description provided for @priceAlertsDeleteButton.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get priceAlertsDeleteButton;

  /// No description provided for @priceAlertsPromoBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat düşünce haberin olsun!'**
  String get priceAlertsPromoBannerTitle;

  /// No description provided for @priceAlertsPromoBannerBody.
  ///
  /// In tr, this message translates to:
  /// **'Alarmlarını ayarla, fırsatları ilk sen yakala.'**
  String get priceAlertsPromoBannerBody;

  /// No description provided for @priceAlertsSetAlarmButton.
  ///
  /// In tr, this message translates to:
  /// **'Alarm Kur'**
  String get priceAlertsSetAlarmButton;

  /// No description provided for @priceAlertsActiveTab.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Alarmlar'**
  String get priceAlertsActiveTab;

  /// No description provided for @priceAlertsTriggeredTab.
  ///
  /// In tr, this message translates to:
  /// **'Tetiklenenler'**
  String get priceAlertsTriggeredTab;

  /// No description provided for @priceAlertsPausedTab.
  ///
  /// In tr, this message translates to:
  /// **'Pasif Alarmlar'**
  String get priceAlertsPausedTab;

  /// No description provided for @priceAlertsNoActiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktif alarm yok'**
  String get priceAlertsNoActiveTitle;

  /// No description provided for @priceAlertsNoPausedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Pasif alarm yok'**
  String get priceAlertsNoPausedTitle;

  /// No description provided for @priceAlertsNoActiveDescription.
  ///
  /// In tr, this message translates to:
  /// **'Alarm kur ve fiyat düşünce bildirim al.'**
  String get priceAlertsNoActiveDescription;

  /// No description provided for @priceAlertsNoPausedDescription.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatılmış alarm bulunmuyor.'**
  String get priceAlertsNoPausedDescription;

  /// No description provided for @priceAlertsTargetPriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Fiyat'**
  String get priceAlertsTargetPriceLabel;

  /// No description provided for @priceAlertsPauseButton.
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get priceAlertsPauseButton;

  /// No description provided for @priceAlertsActivateButton.
  ///
  /// In tr, this message translates to:
  /// **'Aktifleştir'**
  String get priceAlertsActivateButton;

  /// No description provided for @priceAlertsNoTriggeredTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tetiklenen alarm yok'**
  String get priceAlertsNoTriggeredTitle;

  /// No description provided for @priceAlertsNoTriggeredDescription.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat hedefine ulaşınca burada görünecek.'**
  String get priceAlertsNoTriggeredDescription;

  /// No description provided for @priceAlertsMatchedPriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşen Fiyat'**
  String get priceAlertsMatchedPriceLabel;

  /// No description provided for @priceAlertsPreviousPriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Önceki Fiyat'**
  String get priceAlertsPreviousPriceLabel;

  /// No description provided for @priceAlertsPercentDropLabel.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} düştü'**
  String priceAlertsPercentDropLabel(int percent);

  /// No description provided for @priceAlertsTipBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatlar değişiyor, fırsatlar kaçmasın!'**
  String get priceAlertsTipBannerTitle;

  /// No description provided for @priceAlertsTipBannerBody.
  ///
  /// In tr, this message translates to:
  /// **'Alarmlarını düzenli kontrol etmeyi unutma.'**
  String get priceAlertsTipBannerBody;

  /// No description provided for @myReviewsRetryButton.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get myReviewsRetryButton;

  /// No description provided for @myReviewsPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlarım'**
  String get myReviewsPageTitle;

  /// No description provided for @myReviewsPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Deneyimlerini paylaştığın mekanlar'**
  String get myReviewsPageSubtitle;

  /// No description provided for @myReviewsTabAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get myReviewsTabAll;

  /// No description provided for @myReviewsTabPublished.
  ///
  /// In tr, this message translates to:
  /// **'Yayınlanan'**
  String get myReviewsTabPublished;

  /// No description provided for @myReviewsTabPending.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen'**
  String get myReviewsTabPending;

  /// No description provided for @myReviewsHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yorumların değerli!'**
  String get myReviewsHeroTitle;

  /// No description provided for @myReviewsHeroSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Deneyimlerin diğer kullanıcılara yol gösteriyor. Teşekkür ederiz.'**
  String get myReviewsHeroSubtitle;

  /// No description provided for @myReviewsGuidelinesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yorumların bizim için önemli'**
  String get myReviewsGuidelinesTitle;

  /// No description provided for @myReviewsGuidelinesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk kurallarımıza uygun yapılan yorumlar yayınlanır. Detaylı bilgi için tıkla.'**
  String get myReviewsGuidelinesSubtitle;

  /// No description provided for @myReviewsEmptyPublished.
  ///
  /// In tr, this message translates to:
  /// **'Yayınlanmış yorumun yok.'**
  String get myReviewsEmptyPublished;

  /// No description provided for @myReviewsEmptyPending.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekleyen yorumun yok.'**
  String get myReviewsEmptyPending;

  /// No description provided for @myReviewsEmptyAll.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yapmadın.'**
  String get myReviewsEmptyAll;

  /// No description provided for @myReviewsLoginPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlarını görmek için giriş yap.'**
  String get myReviewsLoginPrompt;

  /// No description provided for @myReviewsLoginButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get myReviewsLoginButton;

  /// No description provided for @myReviewsTimeJustNow.
  ///
  /// In tr, this message translates to:
  /// **'Az önce'**
  String get myReviewsTimeJustNow;

  /// No description provided for @myReviewsTimeHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat önce'**
  String myReviewsTimeHoursAgo(int hours);

  /// No description provided for @myReviewsTimeDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce'**
  String myReviewsTimeDaysAgo(int days);

  /// No description provided for @myReviewsTimeWeeksAgo.
  ///
  /// In tr, this message translates to:
  /// **'{weeks} hafta önce'**
  String myReviewsTimeWeeksAgo(int weeks);

  /// No description provided for @myReviewsTimeMonthsAgo.
  ///
  /// In tr, this message translates to:
  /// **'{months} ay önce'**
  String myReviewsTimeMonthsAgo(int months);

  /// No description provided for @myReviewsTimeYearsAgo.
  ///
  /// In tr, this message translates to:
  /// **'{years} yıl önce'**
  String myReviewsTimeYearsAgo(int years);

  /// No description provided for @myReviewsStatusPublished.
  ///
  /// In tr, this message translates to:
  /// **'Yayınlandı'**
  String get myReviewsStatusPublished;

  /// No description provided for @myReviewsStatusPending.
  ///
  /// In tr, this message translates to:
  /// **'Onay Bekliyor'**
  String get myReviewsStatusPending;

  /// No description provided for @myReviewsStatusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get myReviewsStatusRejected;

  /// No description provided for @myReviewsMenuEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get myReviewsMenuEdit;

  /// No description provided for @myReviewsMenuDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get myReviewsMenuDelete;

  /// No description provided for @mySuggestionsTabSent.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilen Öneriler'**
  String get mySuggestionsTabSent;

  /// No description provided for @mySuggestionsTabAnswered.
  ///
  /// In tr, this message translates to:
  /// **'Cevaplananlar'**
  String get mySuggestionsTabAnswered;

  /// No description provided for @mySuggestionsTabRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedilenler'**
  String get mySuggestionsTabRejected;

  /// No description provided for @mySuggestionsPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Önerimlerim'**
  String get mySuggestionsPageTitle;

  /// No description provided for @mySuggestionsPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletmelere gönderdiğin fiyat önerilerini buradan takip edebilirsin.'**
  String get mySuggestionsPageSubtitle;

  /// No description provided for @mySuggestionsInfoBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatını sen belirle, fırsatı yakala!'**
  String get mySuggestionsInfoBannerTitle;

  /// No description provided for @mySuggestionsInfoBannerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletmelerin sana özel teklif vermesini bekle.'**
  String get mySuggestionsInfoBannerSubtitle;

  /// No description provided for @mySuggestionsTipCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'İpucu'**
  String get mySuggestionsTipCardTitle;

  /// No description provided for @mySuggestionsTipCardBody.
  ///
  /// In tr, this message translates to:
  /// **'Önerini makul aralıkta tutarsan, onaylanma şansın artar!'**
  String get mySuggestionsTipCardBody;

  /// No description provided for @mySuggestionsViewDetailsButton.
  ///
  /// In tr, this message translates to:
  /// **'Detayları Gör'**
  String get mySuggestionsViewDetailsButton;

  /// No description provided for @mySuggestionsStatusApproved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get mySuggestionsStatusApproved;

  /// No description provided for @mySuggestionsStatusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get mySuggestionsStatusRejected;

  /// No description provided for @mySuggestionsStatusPending.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get mySuggestionsStatusPending;

  /// No description provided for @mySuggestionsEmptySentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gönderilen öneri yok'**
  String get mySuggestionsEmptySentTitle;

  /// No description provided for @mySuggestionsEmptySentBody.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir fiyat önerisi göndermedin.'**
  String get mySuggestionsEmptySentBody;

  /// No description provided for @mySuggestionsEmptyAnsweredTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cevaplanan öneri yok'**
  String get mySuggestionsEmptyAnsweredTitle;

  /// No description provided for @mySuggestionsEmptyAnsweredBody.
  ///
  /// In tr, this message translates to:
  /// **'Önerilerin henüz cevaplanmadı.'**
  String get mySuggestionsEmptyAnsweredBody;

  /// No description provided for @mySuggestionsEmptyRejectedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Reddedilen öneri yok'**
  String get mySuggestionsEmptyRejectedTitle;

  /// No description provided for @mySuggestionsEmptyRejectedBody.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir önerin reddedilmedi.'**
  String get mySuggestionsEmptyRejectedBody;

  /// No description provided for @mySuggestionsRefreshButton.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get mySuggestionsRefreshButton;

  /// No description provided for @mySuggestionsNoLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum yok'**
  String get mySuggestionsNoLocation;

  /// No description provided for @mySuggestionsMonthJanuary.
  ///
  /// In tr, this message translates to:
  /// **'Ocak'**
  String get mySuggestionsMonthJanuary;

  /// No description provided for @mySuggestionsMonthFebruary.
  ///
  /// In tr, this message translates to:
  /// **'Şubat'**
  String get mySuggestionsMonthFebruary;

  /// No description provided for @mySuggestionsMonthMarch.
  ///
  /// In tr, this message translates to:
  /// **'Mart'**
  String get mySuggestionsMonthMarch;

  /// No description provided for @mySuggestionsMonthApril.
  ///
  /// In tr, this message translates to:
  /// **'Nisan'**
  String get mySuggestionsMonthApril;

  /// No description provided for @mySuggestionsMonthMay.
  ///
  /// In tr, this message translates to:
  /// **'Mayıs'**
  String get mySuggestionsMonthMay;

  /// No description provided for @mySuggestionsMonthJune.
  ///
  /// In tr, this message translates to:
  /// **'Haziran'**
  String get mySuggestionsMonthJune;

  /// No description provided for @mySuggestionsMonthJuly.
  ///
  /// In tr, this message translates to:
  /// **'Temmuz'**
  String get mySuggestionsMonthJuly;

  /// No description provided for @mySuggestionsMonthAugust.
  ///
  /// In tr, this message translates to:
  /// **'Ağustos'**
  String get mySuggestionsMonthAugust;

  /// No description provided for @mySuggestionsMonthSeptember.
  ///
  /// In tr, this message translates to:
  /// **'Eylül'**
  String get mySuggestionsMonthSeptember;

  /// No description provided for @mySuggestionsMonthOctober.
  ///
  /// In tr, this message translates to:
  /// **'Ekim'**
  String get mySuggestionsMonthOctober;

  /// No description provided for @mySuggestionsMonthNovember.
  ///
  /// In tr, this message translates to:
  /// **'Kasım'**
  String get mySuggestionsMonthNovember;

  /// No description provided for @mySuggestionsMonthDecember.
  ///
  /// In tr, this message translates to:
  /// **'Aralık'**
  String get mySuggestionsMonthDecember;

  /// No description provided for @businessDetailMealCardsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli Yemek Kartları'**
  String get businessDetailMealCardsTitle;

  /// No description provided for @businessDetailMealCardsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu işletmede kabul edilen kartlar aşağıda listelenir.'**
  String get businessDetailMealCardsSubtitle;

  /// No description provided for @businessDetailSeeAllButton.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü gör'**
  String get businessDetailSeeAllButton;

  /// No description provided for @businessDetailCommunityPhotosTitle.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk Fotoğrafları'**
  String get businessDetailCommunityPhotosTitle;

  /// No description provided for @businessDetailPhotoViewerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf {current} / {total}'**
  String businessDetailPhotoViewerTitle(int current, int total);

  /// No description provided for @businessDetailFrequentlyMentionedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sıkça Bahsedilen'**
  String get businessDetailFrequentlyMentionedTitle;

  /// No description provided for @businessBadgeCertificateShareText.
  ///
  /// In tr, this message translates to:
  /// **'{businessName} — Yeedoy Başarım Sertifikası 🏆'**
  String businessBadgeCertificateShareText(String businessName);

  /// No description provided for @businessBadgeCertificateShareFailed.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım başarısız oldu.'**
  String get businessBadgeCertificateShareFailed;

  /// No description provided for @businessBadgeCertificateSharing.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılıyor...'**
  String get businessBadgeCertificateSharing;

  /// No description provided for @businessBadgeCertificateShareButton.
  ///
  /// In tr, this message translates to:
  /// **'Sertifikayı Paylaş'**
  String get businessBadgeCertificateShareButton;

  /// No description provided for @businessBadgeCertificateSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Başarım Sertifikası'**
  String get businessBadgeCertificateSubtitle;

  /// No description provided for @dietProfileAllergenMilk.
  ///
  /// In tr, this message translates to:
  /// **'Süt ve süt ürünleri'**
  String get dietProfileAllergenMilk;

  /// No description provided for @dietProfileAllergenNuts.
  ///
  /// In tr, this message translates to:
  /// **'Fındık'**
  String get dietProfileAllergenNuts;

  /// No description provided for @dietProfileAllergenEgg.
  ///
  /// In tr, this message translates to:
  /// **'Yumurta'**
  String get dietProfileAllergenEgg;

  /// No description provided for @dietProfileAllergenSeafood.
  ///
  /// In tr, this message translates to:
  /// **'Deniz ürünleri'**
  String get dietProfileAllergenSeafood;

  /// No description provided for @dietProfileAllergenGluten.
  ///
  /// In tr, this message translates to:
  /// **'Glüten'**
  String get dietProfileAllergenGluten;

  /// No description provided for @dietProfileAllergenSoy.
  ///
  /// In tr, this message translates to:
  /// **'Soya'**
  String get dietProfileAllergenSoy;

  /// No description provided for @dietProfileAllergenSesame.
  ///
  /// In tr, this message translates to:
  /// **'Susam'**
  String get dietProfileAllergenSesame;

  /// No description provided for @dietProfileAllergenWheat.
  ///
  /// In tr, this message translates to:
  /// **'Buğday'**
  String get dietProfileAllergenWheat;

  /// No description provided for @dietProfileAllergenHalal.
  ///
  /// In tr, this message translates to:
  /// **'Helal'**
  String get dietProfileAllergenHalal;

  /// No description provided for @dietProfileSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilirken bir hata oluştu.'**
  String get dietProfileSaveError;

  /// No description provided for @dietProfileLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Profil yüklenemedi. Lütfen tekrar deneyin.'**
  String get dietProfileLoadError;

  /// No description provided for @dietProfileDietSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diyet tercihin'**
  String get dietProfileDietSectionTitle;

  /// No description provided for @dietProfileDietSectionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana en uygun beslenme şeklini seç veya birden fazlasını işaretle.'**
  String get dietProfileDietSectionSubtitle;

  /// No description provided for @dietProfileGoalSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin'**
  String get dietProfileGoalSectionTitle;

  /// No description provided for @dietProfileGoalSectionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana daha doğru öneriler sunabilmemiz için hedefini belirt.'**
  String get dietProfileGoalSectionSubtitle;

  /// No description provided for @dietProfilePageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Profili'**
  String get dietProfilePageTitle;

  /// No description provided for @dietProfileHelpSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diyet Profili Nedir?'**
  String get dietProfileHelpSheetTitle;

  /// No description provided for @dietProfileHelpSheetBody.
  ///
  /// In tr, this message translates to:
  /// **'Diyet profilin, yemek önerilerini ve menü filtrelerini kişiselleştirmek için kullanılır. Tercihlerini kaydederek sana en uygun işletmeleri ve yemekleri önerebiliriz.'**
  String get dietProfileHelpSheetBody;

  /// No description provided for @dietProfileHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sana özel lezzetler'**
  String get dietProfileHeroTitle;

  /// No description provided for @dietProfileHeroSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Diyet tercihlerine göre sana uygun mekanları ve yemekleri önerelim.'**
  String get dietProfileHeroSubtitle;

  /// No description provided for @dietProfileHeroFeaturePersonalized.
  ///
  /// In tr, this message translates to:
  /// **'Kişiselleştirilmiş\nöneriler'**
  String get dietProfileHeroFeaturePersonalized;

  /// No description provided for @dietProfileHeroFeatureHealthier.
  ///
  /// In tr, this message translates to:
  /// **'Daha sağlıklı\nseçimler'**
  String get dietProfileHeroFeatureHealthier;

  /// No description provided for @dietProfileHeroFeatureSaveTime.
  ///
  /// In tr, this message translates to:
  /// **'Zamanını\ntasarruf et'**
  String get dietProfileHeroFeatureSaveTime;

  /// No description provided for @dietProfileDietBalancedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dengeli Beslenme'**
  String get dietProfileDietBalancedLabel;

  /// No description provided for @dietProfileDietBalancedDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tüm besin gruplarını dengeli tüketiyorum.'**
  String get dietProfileDietBalancedDesc;

  /// No description provided for @dietProfileDietVegetarianLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vejetaryen'**
  String get dietProfileDietVegetarianLabel;

  /// No description provided for @dietProfileDietVegetarianDesc.
  ///
  /// In tr, this message translates to:
  /// **'Et ve et ürünleri tüketmiyorum.'**
  String get dietProfileDietVegetarianDesc;

  /// No description provided for @dietProfileDietVeganLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vegan'**
  String get dietProfileDietVeganLabel;

  /// No description provided for @dietProfileDietVeganDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir hayvansal ürün tüketmiyorum.'**
  String get dietProfileDietVeganDesc;

  /// No description provided for @dietProfileDietGlutenFreeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Glutensiz'**
  String get dietProfileDietGlutenFreeLabel;

  /// No description provided for @dietProfileDietGlutenFreeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Glüten içeren besinleri tüketmiyorum.'**
  String get dietProfileDietGlutenFreeDesc;

  /// No description provided for @dietProfileDietKetogenicLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ketojenik'**
  String get dietProfileDietKetogenicLabel;

  /// No description provided for @dietProfileDietKetogenicDesc.
  ///
  /// In tr, this message translates to:
  /// **'Düşük karbonhidrat, yüksek yağ.'**
  String get dietProfileDietKetogenicDesc;

  /// No description provided for @dietProfileDietMediterraneanLabel.
  ///
  /// In tr, this message translates to:
  /// **'Akdeniz Diyeti'**
  String get dietProfileDietMediterraneanLabel;

  /// No description provided for @dietProfileDietMediterraneanDesc.
  ///
  /// In tr, this message translates to:
  /// **'Zeytinyağı, sebze ve balık odaklı besleniyorum.'**
  String get dietProfileDietMediterraneanDesc;

  /// No description provided for @dietProfileOtherDietRow.
  ///
  /// In tr, this message translates to:
  /// **'Diğer diyet tercihlerim var'**
  String get dietProfileOtherDietRow;

  /// No description provided for @dietProfileGoalLoseWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo vermek'**
  String get dietProfileGoalLoseWeight;

  /// No description provided for @dietProfileGoalGainWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo almak'**
  String get dietProfileGoalGainWeight;

  /// No description provided for @dietProfileGoalMaintain.
  ///
  /// In tr, this message translates to:
  /// **'Kilo korumak'**
  String get dietProfileGoalMaintain;

  /// No description provided for @dietProfileGoalHealthyEating.
  ///
  /// In tr, this message translates to:
  /// **'Daha sağlıklı beslenmek'**
  String get dietProfileGoalHealthyEating;

  /// No description provided for @dietProfileAllergenSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alerjiler ve hassasiyetler'**
  String get dietProfileAllergenSectionTitle;

  /// No description provided for @dietProfileAddButton.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get dietProfileAddButton;

  /// No description provided for @dietProfileAllergenSectionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Alerjinin veya hassasiyetin olan besinleri seç.'**
  String get dietProfileAllergenSectionSubtitle;

  /// No description provided for @dietProfileAllergenEmptyPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Alerji veya hassasiyet ekle'**
  String get dietProfileAllergenEmptyPrompt;

  /// No description provided for @dietProfileSavedBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profilin kaydedildi'**
  String get dietProfileSavedBannerTitle;

  /// No description provided for @dietProfileSavedBannerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tercihlerine göre sana özel öneriler sunacağız.'**
  String get dietProfileSavedBannerSubtitle;

  /// No description provided for @dietProfileEditButton.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get dietProfileEditButton;

  /// No description provided for @dietProfileSaveButton.
  ///
  /// In tr, this message translates to:
  /// **'Profili Kaydet'**
  String get dietProfileSaveButton;

  /// No description provided for @dietProfileAllergenPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alerji veya hassasiyet seç'**
  String get dietProfileAllergenPickerTitle;

  /// No description provided for @dietProfileAllergenPickerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla seçebilirsin.'**
  String get dietProfileAllergenPickerSubtitle;

  /// No description provided for @dietProfileApplyButton.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get dietProfileApplyButton;

  /// No description provided for @locationPickerRequiredSnackbar.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen il ve ilçe seçin.'**
  String get locationPickerRequiredSnackbar;

  /// No description provided for @locationPickerCityLabel.
  ///
  /// In tr, this message translates to:
  /// **'İl Seçin'**
  String get locationPickerCityLabel;

  /// No description provided for @locationPickerDistrictLabel.
  ///
  /// In tr, this message translates to:
  /// **'İlçe Seçin'**
  String get locationPickerDistrictLabel;

  /// No description provided for @locationPickerNeighborhoodSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mahalle Seçin'**
  String get locationPickerNeighborhoodSheetTitle;

  /// No description provided for @locationPickerPlaceholderSelect.
  ///
  /// In tr, this message translates to:
  /// **'Seçiniz'**
  String get locationPickerPlaceholderSelect;

  /// No description provided for @locationPickerCityHint.
  ///
  /// In tr, this message translates to:
  /// **'Bulunduğunuz şehirdeki işletmeleri ve fiyatları göreceksiniz.'**
  String get locationPickerCityHint;

  /// No description provided for @locationPickerDistrictHint.
  ///
  /// In tr, this message translates to:
  /// **'Daha doğru sonuçlar için ilçenizi seçin.'**
  String get locationPickerDistrictHint;

  /// No description provided for @locationPickerNeighborhoodLabel.
  ///
  /// In tr, this message translates to:
  /// **'Mahalle'**
  String get locationPickerNeighborhoodLabel;

  /// No description provided for @locationPickerOptionalSuffix.
  ///
  /// In tr, this message translates to:
  /// **'  (isteğe bağlı)'**
  String get locationPickerOptionalSuffix;

  /// No description provided for @locationPickerOptionalPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Seçiniz (isteğe bağlı)'**
  String get locationPickerOptionalPlaceholder;

  /// No description provided for @locationPickerNeighborhoodHint.
  ///
  /// In tr, this message translates to:
  /// **'Mahalle seçerek çok daha yerel sonuçlar alabilirsiniz.'**
  String get locationPickerNeighborhoodHint;

  /// No description provided for @locationPickerPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum Seç'**
  String get locationPickerPageTitle;

  /// No description provided for @locationPickerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Size özel öneriler ve fiyat alarmları için konumunuzu seçin.'**
  String get locationPickerSubtitle;

  /// No description provided for @locationPickerInfoCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neden konum seçmeliyim?'**
  String get locationPickerInfoCardTitle;

  /// No description provided for @locationPickerInfoCardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bulunduğunuz konuma göre işletmeleri, fiyatları ve fırsatları en doğru şekilde gösteriyoruz.'**
  String get locationPickerInfoCardSubtitle;

  /// No description provided for @locationPickerSelectedCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen Konumunuz'**
  String get locationPickerSelectedCardTitle;

  /// No description provided for @locationPickerNoLocationSelected.
  ///
  /// In tr, this message translates to:
  /// **'Henüz konum seçilmedi'**
  String get locationPickerNoLocationSelected;

  /// No description provided for @locationPickerNeighborhoodSuffix.
  ///
  /// In tr, this message translates to:
  /// **'{neighborhood} Mahallesi'**
  String locationPickerNeighborhoodSuffix(String neighborhood);

  /// No description provided for @locationPickerUseGpsButton.
  ///
  /// In tr, this message translates to:
  /// **'Konumumu Kullan'**
  String get locationPickerUseGpsButton;

  /// No description provided for @locationPickerSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum Ayarları'**
  String get locationPickerSettingsTitle;

  /// No description provided for @locationPickerBgPermissionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda konum izni'**
  String get locationPickerBgPermissionTitle;

  /// No description provided for @locationPickerBgPermissionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alarmları ve fırsat bildirimleri için konum erişimi sağlanır.'**
  String get locationPickerBgPermissionSubtitle;

  /// No description provided for @locationPickerSaveButton.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get locationPickerSaveButton;

  /// No description provided for @locationPickerSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Ara...'**
  String get locationPickerSearchHint;

  /// No description provided for @businessLocationUpdateSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Konum başarıyla güncellendi.'**
  String get businessLocationUpdateSuccess;

  /// No description provided for @businessLocationSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Konum kaydedilemedi. Tekrar deneyin.'**
  String get businessLocationSaveError;

  /// No description provided for @businessLocationTapHint.
  ///
  /// In tr, this message translates to:
  /// **'Haritaya dokunarak konum seçin'**
  String get businessLocationTapHint;

  /// No description provided for @businessLocationPanelTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Konumu'**
  String get businessLocationPanelTitle;

  /// No description provided for @businessLocationPanelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Haritaya dokunarak yeni konumu seçin, ardından kaydedin.'**
  String get businessLocationPanelSubtitle;

  /// No description provided for @businessLocationNoLocationSelected.
  ///
  /// In tr, this message translates to:
  /// **'Henüz konum seçilmedi'**
  String get businessLocationNoLocationSelected;

  /// No description provided for @businessLocationSaveButton.
  ///
  /// In tr, this message translates to:
  /// **'Bu Konumu Kaydet'**
  String get businessLocationSaveButton;

  /// No description provided for @perksAppBarTitle.
  ///
  /// In tr, this message translates to:
  /// **'{businessName} – Ayrıcalıklar'**
  String perksAppBarTitle(String businessName);

  /// No description provided for @perksEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktif ayrıcalık yok'**
  String get perksEmptyTitle;

  /// No description provided for @perksEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu işletme henüz aktif bir kampanya sunmuyor.'**
  String get perksEmptySubtitle;

  /// No description provided for @perksRetryButton.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get perksRetryButton;

  /// No description provided for @perksNewBadge.
  ///
  /// In tr, this message translates to:
  /// **'YENİ'**
  String get perksNewBadge;

  /// No description provided for @perksExpiringBadge.
  ///
  /// In tr, this message translates to:
  /// **'Son {days} gün'**
  String perksExpiringBadge(int days);

  /// No description provided for @perksRequiresCheckin.
  ///
  /// In tr, this message translates to:
  /// **'Check-in gerektirir'**
  String get perksRequiresCheckin;

  /// No description provided for @perksStartsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç: {date}'**
  String perksStartsLabel(String date);

  /// No description provided for @perksEndsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş: {date}'**
  String perksEndsLabel(String date);

  /// No description provided for @sadakatKartlarimAppBarTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sadakat Kartlarım'**
  String get sadakatKartlarimAppBarTitle;

  /// No description provided for @sadakatKartlarimRetryButton.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get sadakatKartlarimRetryButton;

  /// No description provided for @sadakatKartlarimEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sadakat kartın yok'**
  String get sadakatKartlarimEmptyTitle;

  /// No description provided for @sadakatKartlarimEmptyDescription.
  ///
  /// In tr, this message translates to:
  /// **'Katıldığın işletmelerin sadakat programları burada görünecek.'**
  String get sadakatKartlarimEmptyDescription;

  /// No description provided for @sadakatKartlarimQrHint.
  ///
  /// In tr, this message translates to:
  /// **'Damga/puan kazanmak için işletmede bu kodu gösterin.'**
  String get sadakatKartlarimQrHint;

  /// No description provided for @sadakatKartlarimLoginToSeeCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodunuzu görmek için giriş yapın.'**
  String get sadakatKartlarimLoginToSeeCode;

  /// No description provided for @sadakatKartlarimCodePrivateNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bu kod size özeldir, paylaşmayın.'**
  String get sadakatKartlarimCodePrivateNotice;

  /// No description provided for @legalAcceptancePageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yasal Kabul'**
  String get legalAcceptancePageTitle;

  /// No description provided for @legalAcceptanceRetryButton.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get legalAcceptanceRetryButton;

  /// No description provided for @legalAcceptanceHeading.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için güncel sözleşmeleri onaylayın.'**
  String get legalAcceptanceHeading;

  /// No description provided for @legalAcceptanceIntro.
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy, kullanım şartları ve gizlilik politikası sürümlerini kullanıcı bazında kaydeder. Yeni sürüm yayınlandığında uygulamaya devam etmeden önce tekrar onay istenir.'**
  String get legalAcceptanceIntro;

  /// No description provided for @legalAcceptancePendingVersionsChip.
  ///
  /// In tr, this message translates to:
  /// **'{count} zorunlu sürüm'**
  String legalAcceptancePendingVersionsChip(int count);

  /// No description provided for @legalAcceptanceSourceChip.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: yeedoy.com/legal'**
  String get legalAcceptanceSourceChip;

  /// No description provided for @legalAcceptanceConsentHelperText.
  ///
  /// In tr, this message translates to:
  /// **'Bu onay verilmeden uygulama oturumu açılmış olsa bile içerik yüzeylerine geçilmez.'**
  String get legalAcceptanceConsentHelperText;

  /// No description provided for @legalAcceptanceOptionalPrefsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı tercihler'**
  String get legalAcceptanceOptionalPrefsTitle;

  /// No description provided for @legalAcceptanceMarketingOptInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kampanya ve bildirim izinleri'**
  String get legalAcceptanceMarketingOptInTitle;

  /// No description provided for @legalAcceptanceAnalyticsOptInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ürün analitiği iyileştirme izni'**
  String get legalAcceptanceAnalyticsOptInTitle;

  /// No description provided for @legalAcceptanceOptionalPrefsNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu tercihler zorunlu sözleşme kabulünden ayrı tutulur ve daha sonra profil ayarlarından güncellenebilir.'**
  String get legalAcceptanceOptionalPrefsNote;

  /// No description provided for @legalAcceptanceSavingButton.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get legalAcceptanceSavingButton;

  /// No description provided for @legalAcceptanceAcceptButton.
  ///
  /// In tr, this message translates to:
  /// **'Kabul Et ve Devam Et'**
  String get legalAcceptanceAcceptButton;

  /// No description provided for @legalAcceptanceRequiredSnackbar.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için gerekli sözleşmeleri kabul etmelisiniz.'**
  String get legalAcceptanceRequiredSnackbar;

  /// No description provided for @legalAcceptanceMarketingSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Pazarlama e-posta tercihiniz kaydedilemedi. Bildirim ayarlarından tekrar değiştirebilirsiniz.'**
  String get legalAcceptanceMarketingSaveFailed;

  /// No description provided for @legalAcceptanceVersionDateLine.
  ///
  /// In tr, this message translates to:
  /// **'{versionLabel} • {date}'**
  String legalAcceptanceVersionDateLine(String versionLabel, String date);

  /// No description provided for @legalAcceptanceMonthJanuary.
  ///
  /// In tr, this message translates to:
  /// **'Ocak'**
  String get legalAcceptanceMonthJanuary;

  /// No description provided for @legalAcceptanceMonthFebruary.
  ///
  /// In tr, this message translates to:
  /// **'Şubat'**
  String get legalAcceptanceMonthFebruary;

  /// No description provided for @legalAcceptanceMonthMarch.
  ///
  /// In tr, this message translates to:
  /// **'Mart'**
  String get legalAcceptanceMonthMarch;

  /// No description provided for @legalAcceptanceMonthApril.
  ///
  /// In tr, this message translates to:
  /// **'Nisan'**
  String get legalAcceptanceMonthApril;

  /// No description provided for @legalAcceptanceMonthMay.
  ///
  /// In tr, this message translates to:
  /// **'Mayıs'**
  String get legalAcceptanceMonthMay;

  /// No description provided for @legalAcceptanceMonthJune.
  ///
  /// In tr, this message translates to:
  /// **'Haziran'**
  String get legalAcceptanceMonthJune;

  /// No description provided for @legalAcceptanceMonthJuly.
  ///
  /// In tr, this message translates to:
  /// **'Temmuz'**
  String get legalAcceptanceMonthJuly;

  /// No description provided for @legalAcceptanceMonthAugust.
  ///
  /// In tr, this message translates to:
  /// **'Ağustos'**
  String get legalAcceptanceMonthAugust;

  /// No description provided for @legalAcceptanceMonthSeptember.
  ///
  /// In tr, this message translates to:
  /// **'Eylül'**
  String get legalAcceptanceMonthSeptember;

  /// No description provided for @legalAcceptanceMonthOctober.
  ///
  /// In tr, this message translates to:
  /// **'Ekim'**
  String get legalAcceptanceMonthOctober;

  /// No description provided for @legalAcceptanceMonthNovember.
  ///
  /// In tr, this message translates to:
  /// **'Kasım'**
  String get legalAcceptanceMonthNovember;

  /// No description provided for @legalAcceptanceMonthDecember.
  ///
  /// In tr, this message translates to:
  /// **'Aralık'**
  String get legalAcceptanceMonthDecember;

  /// No description provided for @collabListGroupVoteButton.
  ///
  /// In tr, this message translates to:
  /// **'Grup Oyuna Geç'**
  String get collabListGroupVoteButton;
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
