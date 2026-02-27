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

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'Canlı menüler, doğrulanmış fiyatlar'**
  String get appTagline;

  /// No description provided for @appTaglineLine1.
  ///
  /// In tr, this message translates to:
  /// **'Canlı menüler'**
  String get appTaglineLine1;

  /// No description provided for @appTaglineLine2.
  ///
  /// In tr, this message translates to:
  /// **'Dogrulanmis fiyatlar'**
  String get appTaglineLine2;

  /// No description provided for @emptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz eklenmemis'**
  String get emptyTitle;

  /// No description provided for @emptyRegionDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy\'da bu bölgede henüz veri yok. İstersen ilk katkıyı sen ekle.'**
  String get emptyRegionDescription;

  /// No description provided for @webDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy - Canlı menüler, doğrulanmış fiyatlar ve akıllı keşif.'**
  String get webDescription;

  /// No description provided for @discover.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get discover;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @map.
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get map;

  /// No description provided for @list.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get list;

  /// No description provided for @favorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get favorites;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @privacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get privacy;

  /// No description provided for @socialLinks.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Bağlantılar'**
  String get socialLinks;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @contribute.
  ///
  /// In tr, this message translates to:
  /// **'Katkı Yap'**
  String get contribute;

  /// No description provided for @uploadPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Yükle'**
  String get uploadPhoto;

  /// No description provided for @scanQr.
  ///
  /// In tr, this message translates to:
  /// **'QR Tara'**
  String get scanQr;

  /// No description provided for @verifyPrice.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatı Doğrula'**
  String get verifyPrice;

  /// No description provided for @openInBrowser.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda Aç'**
  String get openInBrowser;

  /// No description provided for @linkPreview.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı Önizleme'**
  String get linkPreview;

  /// No description provided for @profileSettings.
  ///
  /// In tr, this message translates to:
  /// **'Profil Ayarları'**
  String get profileSettings;

  /// No description provided for @saving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get saving;

  /// No description provided for @loginRequired.
  ///
  /// In tr, this message translates to:
  /// **'Önce giris yapmalisin.'**
  String get loginRequired;

  /// No description provided for @profileSaved.
  ///
  /// In tr, this message translates to:
  /// **'Profil ayarları kaydedildi.'**
  String get profileSaved;

  /// No description provided for @saveError.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme hatasi: {error}'**
  String saveError(String error);

  /// No description provided for @namePrivacy.
  ///
  /// In tr, this message translates to:
  /// **'İsim Gizliliği'**
  String get namePrivacy;

  /// No description provided for @firstName.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get lastName;

  /// No description provided for @showFullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad Görünsün'**
  String get showFullName;

  /// No description provided for @hideLastName.
  ///
  /// In tr, this message translates to:
  /// **'Sadece Soyadı Gizle'**
  String get hideLastName;

  /// No description provided for @hideBothNames.
  ///
  /// In tr, this message translates to:
  /// **'Ad ve Soyadı Gizle'**
  String get hideBothNames;

  /// No description provided for @preview.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get preview;

  /// No description provided for @socialMedia.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Medya'**
  String get socialMedia;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In tr, this message translates to:
  /// **'Sistem (Varsayılan)'**
  String get systemDefault;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get english;

  /// No description provided for @account.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get account;

  /// No description provided for @invalidLink.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir bağlantı gir.'**
  String get invalidLink;

  /// No description provided for @socialPreview.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Önizleme'**
  String get socialPreview;

  /// No description provided for @pasteLinkHelper.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı yapıştır (https://...)'**
  String get pasteLinkHelper;

  /// No description provided for @privacySocialSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İsim gizliliği ve sosyal medya bağlantıları'**
  String get privacySocialSubtitle;

  /// No description provided for @updateBusinessTitle.
  ///
  /// In tr, this message translates to:
  /// **'{businessName} güncelle'**
  String updateBusinessTitle(String businessName);

  /// No description provided for @contributeSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Topluluğun menü fiyatlarını doğrulamasına yardımcı ol.'**
  String get contributeSheetSubtitle;

  /// No description provided for @scanMenuQr.
  ///
  /// In tr, this message translates to:
  /// **'Menü QR tara'**
  String get scanMenuQr;

  /// No description provided for @scanMenuQrSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'QR ile anında doğrulama'**
  String get scanMenuQrSubtitle;

  /// No description provided for @uploadPhotoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Menünün fotoğrafını çek'**
  String get uploadPhotoSubtitle;

  /// No description provided for @confirmPriceChange.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat değişimini doğrula'**
  String get confirmPriceChange;

  /// No description provided for @confirmPriceChangeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güncel olmayan bir fiyatı bildir'**
  String get confirmPriceChangeSubtitle;

  /// No description provided for @qrAction.
  ///
  /// In tr, this message translates to:
  /// **'QR Aksiyonu'**
  String get qrAction;

  /// No description provided for @embed.
  ///
  /// In tr, this message translates to:
  /// **'Gömülü'**
  String get embed;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @invalidLinkMessage.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz bağlantı'**
  String get invalidLinkMessage;

  /// No description provided for @browserOpened.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda açıldı'**
  String get browserOpened;

  /// No description provided for @embedFailed.
  ///
  /// In tr, this message translates to:
  /// **'İçerik görüntülenemedi, tarayıcıya yönlendirdik.'**
  String get embedFailed;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @updatedDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce güncellendi'**
  String updatedDaysAgo(int days);

  /// No description provided for @verifiedDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce doğrulandı'**
  String verifiedDaysAgo(int days);

  /// No description provided for @distanceKm.
  ///
  /// In tr, this message translates to:
  /// **'{km} km'**
  String distanceKm(num km);

  /// No description provided for @avgSpendPerPerson.
  ///
  /// In tr, this message translates to:
  /// **'Kişi başı {amount}'**
  String avgSpendPerPerson(String amount);

  /// No description provided for @reviewsCount.
  ///
  /// In tr, this message translates to:
  /// **'Yorum ({count})'**
  String reviewsCount(int count);

  /// No description provided for @openNow.
  ///
  /// In tr, this message translates to:
  /// **'Şuan açık'**
  String get openNow;

  /// No description provided for @closedNow.
  ///
  /// In tr, this message translates to:
  /// **'Şuan kapalı'**
  String get closedNow;

  /// No description provided for @livePrices.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Fiyatlar'**
  String get livePrices;

  /// No description provided for @trustScore.
  ///
  /// In tr, this message translates to:
  /// **'Güven Skoru'**
  String get trustScore;

  /// No description provided for @lastUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Son Güncelleme'**
  String get lastUpdated;

  /// No description provided for @lastAudit.
  ///
  /// In tr, this message translates to:
  /// **'Son Denetim'**
  String get lastAudit;

  /// No description provided for @avgCost.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama Tutar'**
  String get avgCost;

  /// No description provided for @avgSpend.
  ///
  /// In tr, this message translates to:
  /// **'ORT. HARCAMA'**
  String get avgSpend;

  /// No description provided for @verified.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get verified;

  /// No description provided for @priceVerified.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Doğrulandı'**
  String get priceVerified;

  /// No description provided for @communityVerified.
  ///
  /// In tr, this message translates to:
  /// **'Toplulukça Doğrulandı'**
  String get communityVerified;

  /// No description provided for @confirmedByUsersToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {users} kullanıcı tarafından doğrulandı'**
  String confirmedByUsersToday(int users);

  /// No description provided for @priceHistory.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Geçmişi'**
  String get priceHistory;

  /// No description provided for @contributeMenuPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Menü Fotoğrafı Katkısı Yap'**
  String get contributeMenuPhoto;

  /// No description provided for @verify.
  ///
  /// In tr, this message translates to:
  /// **'DOĞRULA'**
  String get verify;

  /// No description provided for @signatureSteaks.
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkan Steakler'**
  String get signatureSteaks;

  /// No description provided for @signatureSection.
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkan {section}'**
  String signatureSection(String section);

  /// No description provided for @spottedPriceChange.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat değişikliği mi fark ettin?'**
  String get spottedPriceChange;

  /// No description provided for @spottedPriceChangeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu menüyü güncelleyerek katkı sağla.'**
  String get spottedPriceChangeSubtitle;

  /// No description provided for @updateDateUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme tarihi yok'**
  String get updateDateUnavailable;

  /// No description provided for @currentLocation.
  ///
  /// In tr, this message translates to:
  /// **'MEVCUT KONUM'**
  String get currentLocation;

  /// No description provided for @changeLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumu Değiştir'**
  String get changeLocation;

  /// No description provided for @filters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get filters;

  /// No description provided for @searchKebabsHint.
  ///
  /// In tr, this message translates to:
  /// **'Kebap, burger ara...'**
  String get searchKebabsHint;

  /// No description provided for @budget.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe'**
  String get budget;

  /// No description provided for @freshMenuUpdates.
  ///
  /// In tr, this message translates to:
  /// **'Taze Menü Güncellemeleri'**
  String get freshMenuUpdates;

  /// No description provided for @seeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get seeAll;

  /// No description provided for @freshLinks.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Bağlantılar'**
  String get freshLinks;

  /// No description provided for @discoveryNearbyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakınımda'**
  String get discoveryNearbyTitle;

  /// No description provided for @discoveryNearbySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Konumuna göre en iyi sonuçlar'**
  String get discoveryNearbySubtitle;

  /// No description provided for @discoveryLocationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şehir/ilçeye göre keşfet'**
  String get discoveryLocationSubtitle;

  /// No description provided for @nearbyVerifiedSpots.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki Doğrulanmış Mekanlar'**
  String get nearbyVerifiedSpots;

  /// No description provided for @noNearbyVerifiedSpots.
  ///
  /// In tr, this message translates to:
  /// **'Yakında doğrulanmış mekan bulunamadı'**
  String get noNearbyVerifiedSpots;

  /// No description provided for @changeFiltersTryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Konumu veya filtreleri değiştirip tekrar dene.'**
  String get changeFiltersTryAgain;

  /// No description provided for @noFreshData.
  ///
  /// In tr, this message translates to:
  /// **'Henüz taze veri yok'**
  String get noFreshData;

  /// No description provided for @freshDataWillAppear.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki menü güncellemeleri burada görünecek.'**
  String get freshDataWillAppear;

  /// No description provided for @businessLabel.
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get businessLabel;

  /// No description provided for @report.
  ///
  /// In tr, this message translates to:
  /// **'Bildir'**
  String get report;

  /// No description provided for @favoriteAdded.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerde'**
  String get favoriteAdded;

  /// No description provided for @addToFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriye ekle'**
  String get addToFavorites;

  /// No description provided for @writeReview.
  ///
  /// In tr, this message translates to:
  /// **'Yorum yap'**
  String get writeReview;

  /// No description provided for @other.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get other;

  /// No description provided for @itemsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} ürün'**
  String itemsCount(int count);

  /// No description provided for @weakConnectionQueueNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı zayıf. Doğrulama sıraya alındı, çevrimiçi olunca otomatik gönderilecek.'**
  String get weakConnectionQueueNotice;

  /// No description provided for @pendingVerificationsSent.
  ///
  /// In tr, this message translates to:
  /// **'{count} bekleyen doğrulama gönderildi.'**
  String pendingVerificationsSent(int count);

  /// No description provided for @loadMenuItemsFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce menü ürünlerini yükle.'**
  String get loadMenuItemsFirst;

  /// No description provided for @menuNotAddedYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz eklenmedi'**
  String get menuNotAddedYet;

  /// No description provided for @menuNotAddedYetDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu işletme için henüz menü eklenmemiş.'**
  String get menuNotAddedYetDescription;

  /// No description provided for @weakConnection.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı zayıf'**
  String get weakConnection;

  /// No description provided for @contentLoadFailedCheckInternet.
  ///
  /// In tr, this message translates to:
  /// **'İçerik şu anda yüklenemedi. Varsa önbellek verisi gösterilecek. İnterneti kontrol edip tekrar dene.'**
  String get contentLoadFailedCheckInternet;

  /// No description provided for @trustDataUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Güven verisi yok'**
  String get trustDataUnavailable;

  /// No description provided for @freshnessAndTrust.
  ///
  /// In tr, this message translates to:
  /// **'Güncellik ve güven'**
  String get freshnessAndTrust;

  /// No description provided for @menuUpdatedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Menü Güncellendi'**
  String get menuUpdatedLabel;

  /// No description provided for @lastPriceVerification.
  ///
  /// In tr, this message translates to:
  /// **'Son Fiyat Doğrulaması'**
  String get lastPriceVerification;

  /// No description provided for @trustScoreLabel.
  ///
  /// In tr, this message translates to:
  /// **'Güven Skoru'**
  String get trustScoreLabel;

  /// No description provided for @last3MonthsPriceChange.
  ///
  /// In tr, this message translates to:
  /// **'Son 3 Ay Fiyat Değişimi'**
  String get last3MonthsPriceChange;

  /// No description provided for @hoursInfoUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma saatleri bilgisi yok'**
  String get hoursInfoUnavailable;

  /// No description provided for @hoursInfoMissing.
  ///
  /// In tr, this message translates to:
  /// **'Saat bilgisi yok'**
  String get hoursInfoMissing;

  /// No description provided for @addHoursHelp.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılara yardımcı olmak için çalışma saatlerini ekle.'**
  String get addHoursHelp;

  /// No description provided for @reportHoursInfo.
  ///
  /// In tr, this message translates to:
  /// **'Saat bilgisi bildir'**
  String get reportHoursInfo;

  /// No description provided for @menus.
  ///
  /// In tr, this message translates to:
  /// **'Menüler'**
  String get menus;

  /// No description provided for @menusLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Menüler yüklenemedi'**
  String get menusLoadFailed;

  /// No description provided for @noMenu.
  ///
  /// In tr, this message translates to:
  /// **'Menü yok'**
  String get noMenu;

  /// No description provided for @addFirstMenuHelp.
  ///
  /// In tr, this message translates to:
  /// **'İlk menüyü ekleyerek kullanıcılara yardımcı ol.'**
  String get addFirstMenuHelp;

  /// No description provided for @crowdInfoUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Yoğunluk bilgisi yok'**
  String get crowdInfoUnavailable;

  /// No description provided for @liveCrowdLabel.
  ///
  /// In tr, this message translates to:
  /// **'Anlık yoğunluk: {state}'**
  String liveCrowdLabel(String state);

  /// No description provided for @reviewsLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar yüklenemedi'**
  String get reviewsLoadFailed;

  /// No description provided for @noReviews.
  ///
  /// In tr, this message translates to:
  /// **'Yorum yok'**
  String get noReviews;

  /// No description provided for @leaveFirstReviewHelp.
  ///
  /// In tr, this message translates to:
  /// **'İlk yorumu sen yaz.'**
  String get leaveFirstReviewHelp;

  /// No description provided for @writeFirstReview.
  ///
  /// In tr, this message translates to:
  /// **'İlk yorumu yaz'**
  String get writeFirstReview;

  /// No description provided for @recentReviews.
  ///
  /// In tr, this message translates to:
  /// **'Son yorumlar'**
  String get recentReviews;

  /// No description provided for @reviewFallbackTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get reviewFallbackTitle;

  /// No description provided for @activeCampaigns.
  ///
  /// In tr, this message translates to:
  /// **'Aktif kampanyalar'**
  String get activeCampaigns;

  /// No description provided for @menuDataUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Menü verisi yok'**
  String get menuDataUnavailable;

  /// No description provided for @noMenuProductsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz menü ürünü yok'**
  String get noMenuProductsYet;

  /// No description provided for @menu.
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get menu;

  /// No description provided for @featuredFromCuisine.
  ///
  /// In tr, this message translates to:
  /// **'{cuisine} mutfağından öne çıkanlar'**
  String featuredFromCuisine(String category, Object cuisine);

  /// No description provided for @weeklyPriceChange.
  ///
  /// In tr, this message translates to:
  /// **'+₺50 bu hafta'**
  String get weeklyPriceChange;

  /// No description provided for @chartPlaceholderSoon.
  ///
  /// In tr, this message translates to:
  /// **'Grafik alanı (yakında)'**
  String get chartPlaceholderSoon;

  /// No description provided for @featuredCuisineSuffix.
  ///
  /// In tr, this message translates to:
  /// **'mutfağından öne çıkan lezzetler'**
  String get featuredCuisineSuffix;

  /// No description provided for @connectionProblemTryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı sorunu var, tekrar dene.'**
  String get connectionProblemTryAgain;

  /// No description provided for @noActiveCampaign.
  ///
  /// In tr, this message translates to:
  /// **'Aktif kampanya yok'**
  String get noActiveCampaign;

  /// No description provided for @activeCampaignCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'aktif kampanya'**
  String get activeCampaignCountLabel;

  /// No description provided for @noAmenityInfo.
  ///
  /// In tr, this message translates to:
  /// **'İmkan bilgisi yok'**
  String get noAmenityInfo;

  /// No description provided for @amenityCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'{count} imkan'**
  String amenityCountLabel(Object count);

  /// No description provided for @noLocationVerificationData.
  ///
  /// In tr, this message translates to:
  /// **'Konum doğrulama verisi yok'**
  String get noLocationVerificationData;

  /// No description provided for @lastLocationVerification.
  ///
  /// In tr, this message translates to:
  /// **'Son konum doğrulaması'**
  String get lastLocationVerification;

  /// No description provided for @noNewProductRecord.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ürün kaydı yok'**
  String get noNewProductRecord;

  /// No description provided for @newProduct.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ürün'**
  String get newProduct;

  /// No description provided for @reportInfoErrorPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim bilgisi hatası:'**
  String get reportInfoErrorPrefix;

  /// No description provided for @noLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum yok'**
  String get noLocation;

  /// No description provided for @noHoursInfo.
  ///
  /// In tr, this message translates to:
  /// **'Saat bilgisi yok'**
  String get noHoursInfo;

  /// No description provided for @reviewsCountSuffix.
  ///
  /// In tr, this message translates to:
  /// **'yorum'**
  String get reviewsCountSuffix;

  /// No description provided for @noTime.
  ///
  /// In tr, this message translates to:
  /// **'Saat yok'**
  String get noTime;

  /// No description provided for @tabSteaks.
  ///
  /// In tr, this message translates to:
  /// **'Etler'**
  String get tabSteaks;

  /// No description provided for @tabBurgers.
  ///
  /// In tr, this message translates to:
  /// **'Burgerler'**
  String get tabBurgers;

  /// No description provided for @tabSides.
  ///
  /// In tr, this message translates to:
  /// **'Yan Ürünler'**
  String get tabSides;

  /// No description provided for @tabBeverages.
  ///
  /// In tr, this message translates to:
  /// **'İçecekler'**
  String get tabBeverages;

  /// No description provided for @locationNotAvailable.
  ///
  /// In tr, this message translates to:
  /// **'Konum kullanılamıyor'**
  String get locationNotAvailable;

  /// No description provided for @sortRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen'**
  String get sortRecommended;

  /// No description provided for @sortDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get sortDistance;

  /// No description provided for @sortRating.
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get sortRating;

  /// No description provided for @sortPriceLow.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get sortPriceLow;

  /// No description provided for @sortNewlyVerified.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Doğrulanan'**
  String get sortNewlyVerified;

  /// No description provided for @rankingFormulaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama Formülü'**
  String get rankingFormulaTitle;

  /// No description provided for @rankingFormulaIntro.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama puanı şu bileşenlerden oluşur:'**
  String get rankingFormulaIntro;

  /// No description provided for @rankingWeightDistance.
  ///
  /// In tr, this message translates to:
  /// **'%30 Mesafe'**
  String get rankingWeightDistance;

  /// No description provided for @rankingWeightAccuracy.
  ///
  /// In tr, this message translates to:
  /// **'Doğruluk ağırlığı'**
  String get rankingWeightAccuracy;

  /// No description provided for @rankingWeightEngagement.
  ///
  /// In tr, this message translates to:
  /// **'Etkileşim ağırlığı'**
  String get rankingWeightEngagement;

  /// No description provided for @rankingWeightQuality.
  ///
  /// In tr, this message translates to:
  /// **'%20 Kalite (kalite skoru)'**
  String get rankingWeightQuality;

  /// No description provided for @rankingFormulaNote.
  ///
  /// In tr, this message translates to:
  /// **'Not: Puanlar düzenli olarak güncellenir.'**
  String get rankingFormulaNote;

  /// No description provided for @minRatingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Minimum puan: {value}'**
  String minRatingLabel(String value);

  /// No description provided for @priceLevel.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat seviyesi'**
  String get priceLevel;

  /// No description provided for @prioritizeOpenNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu an açık olanları öne çıkar'**
  String get prioritizeOpenNow;

  /// No description provided for @prioritizeNewlyVerified.
  ///
  /// In tr, this message translates to:
  /// **'Yeni doğrulananları öne çıkar'**
  String get prioritizeNewlyVerified;

  /// No description provided for @reset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// No description provided for @priceTierAny.
  ///
  /// In tr, this message translates to:
  /// **'Her seviye'**
  String get priceTierAny;

  /// No description provided for @priceTierBudget.
  ///
  /// In tr, this message translates to:
  /// **'Ekonomik'**
  String get priceTierBudget;

  /// No description provided for @priceTierMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get priceTierMedium;

  /// No description provided for @priceTierPremium.
  ///
  /// In tr, this message translates to:
  /// **'Üst Seviye'**
  String get priceTierPremium;

  /// No description provided for @tabAllItems.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Ürünler'**
  String get tabAllItems;

  /// No description provided for @tabStarters.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıçlar'**
  String get tabStarters;

  /// No description provided for @usersLabel.
  ///
  /// In tr, this message translates to:
  /// **'kullanıcı'**
  String get usersLabel;

  /// No description provided for @unknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknown;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @dayUnit.
  ///
  /// In tr, this message translates to:
  /// **'gün'**
  String get dayUnit;

  /// No description provided for @tekrarDene.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get tekrarDene;

  /// No description provided for @vazgec.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get vazgec;

  /// No description provided for @reddet.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get reddet;

  /// No description provided for @title.
  ///
  /// In tr, this message translates to:
  /// **'title'**
  String get title;

  /// No description provided for @isleniyor.
  ///
  /// In tr, this message translates to:
  /// **'İşleniyor...'**
  String get isleniyor;

  /// No description provided for @onayla.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get onayla;

  /// No description provided for @approved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get approved;

  /// No description provided for @tumu.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get tumu;

  /// No description provided for @kayitBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı.'**
  String get kayitBulunamadi;

  /// No description provided for @temizle.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get temizle;

  /// No description provided for @uygula.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get uygula;

  /// No description provided for @pending.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get pending;

  /// No description provided for @reddedildi.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get reddedildi;

  /// No description provided for @satirSec.
  ///
  /// In tr, this message translates to:
  /// **'Satır seç'**
  String get satirSec;

  /// No description provided for @gonder.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get gonder;

  /// No description provided for @rejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get rejected;

  /// No description provided for @detay.
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get detay;

  /// No description provided for @duzenle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get duzenle;

  /// No description provided for @eminMisin.
  ///
  /// In tr, this message translates to:
  /// **'Emin misin?'**
  String get eminMisin;

  /// No description provided for @guncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Güncellendi.'**
  String get guncellendi;

  /// No description provided for @reddedildi_2.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi.'**
  String get reddedildi_2;

  /// No description provided for @sla.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dönüş Süresi'**
  String get sla;

  /// No description provided for @csvDisaAktar.
  ///
  /// In tr, this message translates to:
  /// **'CSV Dışa Aktar'**
  String get csvDisaAktar;

  /// No description provided for @onaylandi.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get onaylandi;

  /// No description provided for @yenile.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get yenile;

  /// No description provided for @atanan.
  ///
  /// In tr, this message translates to:
  /// **'Atanan'**
  String get atanan;

  /// No description provided for @beklemede.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get beklemede;

  /// No description provided for @durum.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get durum;

  /// No description provided for @tabRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Önerilenler'**
  String get tabRecommended;

  /// No description provided for @tabCampaigns.
  ///
  /// In tr, this message translates to:
  /// **'Kampanyalar'**
  String get tabCampaigns;

  /// No description provided for @tabFoods.
  ///
  /// In tr, this message translates to:
  /// **'Yemekler'**
  String get tabFoods;

  /// No description provided for @whyTop.
  ///
  /// In tr, this message translates to:
  /// **'Neden üstte?'**
  String get whyTop;

  /// No description provided for @quickSuggestionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Öneri'**
  String get quickSuggestionTitle;

  /// No description provided for @quickSuggestionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dakikalar içinde karar ver'**
  String get quickSuggestionSubtitle;

  /// No description provided for @quickSuggestionPreset.
  ///
  /// In tr, this message translates to:
  /// **'2 kişi / ₺600'**
  String get quickSuggestionPreset;

  /// No description provided for @whatToEatTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne yesek?'**
  String get whatToEatTitle;

  /// No description provided for @whatToEatSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı öneriler'**
  String get whatToEatSubtitle;

  /// No description provided for @nearbyShort.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get nearbyShort;

  /// No description provided for @affordableShort.
  ///
  /// In tr, this message translates to:
  /// **'Uygun fiyat'**
  String get affordableShort;

  /// No description provided for @quickDecisionShort.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Karar'**
  String get quickDecisionShort;

  /// No description provided for @start.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get start;

  /// No description provided for @friendGroupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaş Grubu'**
  String get friendGroupTitle;

  /// No description provided for @friendGroupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birlikte karar verin'**
  String get friendGroupSubtitle;

  /// No description provided for @openGroup.
  ///
  /// In tr, this message translates to:
  /// **'Grubu Aç'**
  String get openGroup;

  /// No description provided for @myGroups.
  ///
  /// In tr, this message translates to:
  /// **'Gruplarım'**
  String get myGroups;

  /// No description provided for @onTheRoadTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yoldayım'**
  String get onTheRoadTitle;

  /// No description provided for @onTheRoadSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Rotandaki duraklar'**
  String get onTheRoadSubtitle;

  /// No description provided for @heroesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kahramanlar'**
  String get heroesTitle;

  /// No description provided for @heroesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Öne çıkan keşifler'**
  String get heroesSubtitle;

  /// No description provided for @view.
  ///
  /// In tr, this message translates to:
  /// **'Görüntüle'**
  String get view;

  /// No description provided for @bestBusinessesThisWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu Haftanın En İyi İşletmeleri'**
  String get bestBusinessesThisWeek;

  /// No description provided for @bestBusinessesThisMonth.
  ///
  /// In tr, this message translates to:
  /// **'Bu Ayın En İyi İşletmeleri'**
  String get bestBusinessesThisMonth;

  /// No description provided for @onTheRoad20km.
  ///
  /// In tr, this message translates to:
  /// **'Yolda • 20 km'**
  String get onTheRoad20km;

  /// No description provided for @nearbyKm.
  ///
  /// In tr, this message translates to:
  /// **'Yakında • {km} km'**
  String nearbyKm(int km);

  /// No description provided for @liveResultsUpdating.
  ///
  /// In tr, this message translates to:
  /// **'Canlı sonuçlar güncelleniyor'**
  String get liveResultsUpdating;

  /// No description provided for @businessApprovedData.
  ///
  /// In tr, this message translates to:
  /// **'İşletme onaylı verisi'**
  String get businessApprovedData;

  /// No description provided for @communityData.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk verisi'**
  String get communityData;

  /// No description provided for @removeFromFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get removeFromFavorites;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni ver'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki yerleri göstermek için konum izni gerekli.'**
  String get locationPermissionDescription;

  /// No description provided for @allow.
  ///
  /// In tr, this message translates to:
  /// **'İzin Ver'**
  String get allow;

  /// No description provided for @selectLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum Seç'**
  String get selectLocation;

  /// No description provided for @manualLocationHint.
  ///
  /// In tr, this message translates to:
  /// **'Konumu manuel seçebilirsin.'**
  String get manualLocationHint;

  /// No description provided for @noResultsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sonuç yok'**
  String get noResultsYet;

  /// No description provided for @lowDataInArea.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölgede veri az'**
  String get lowDataInArea;

  /// No description provided for @tryDifferentSearchOrFilter.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir arama ya da filtre dene.'**
  String get tryDifferentSearchOrFilter;

  /// No description provided for @beFirstContributorInArea.
  ///
  /// In tr, this message translates to:
  /// **'Bölgede ilk katkıyı sen yap.'**
  String get beFirstContributorInArea;

  /// No description provided for @topVerifiedMenus.
  ///
  /// In tr, this message translates to:
  /// **'En Çok Doğrulanan Menüler'**
  String get topVerifiedMenus;

  /// No description provided for @mostTrustedMenusInCity.
  ///
  /// In tr, this message translates to:
  /// **'Şehirde En Güvenilen Menüler'**
  String get mostTrustedMenusInCity;

  /// No description provided for @seeList.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Gör'**
  String get seeList;

  /// No description provided for @localContributionCall.
  ///
  /// In tr, this message translates to:
  /// **'Yerel katkı çağrısı'**
  String get localContributionCall;

  /// No description provided for @addFirstMenu.
  ///
  /// In tr, this message translates to:
  /// **'İlk Menüyü Ekle'**
  String get addFirstMenu;

  /// No description provided for @suggestBusiness.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Öner'**
  String get suggestBusiness;

  /// No description provided for @noSurpriseSuggestionNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu an sürpriz öneri yok'**
  String get noSurpriseSuggestionNow;

  /// No description provided for @priceVerifiedInLast48h.
  ///
  /// In tr, this message translates to:
  /// **'Bu fiyat son 48 saatte doğrulandı'**
  String get priceVerifiedInLast48h;

  /// No description provided for @menuMayBeOutdated.
  ///
  /// In tr, this message translates to:
  /// **'Menü güncel olmayabilir'**
  String get menuMayBeOutdated;

  /// No description provided for @verifiedByBusiness.
  ///
  /// In tr, this message translates to:
  /// **'İşletme tarafından doğrulandı'**
  String get verifiedByBusiness;

  /// No description provided for @updatedByCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk tarafından güncellendi'**
  String get updatedByCommunity;

  /// No description provided for @topRankedInDistrict.
  ///
  /// In tr, this message translates to:
  /// **'İlçede üst sıralarda'**
  String get topRankedInDistrict;

  /// No description provided for @surpriseDiscoveryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sürpriz Keşif'**
  String get surpriseDiscoveryTitle;

  /// No description provided for @surpriseDiscoverySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Alışkanlığının dışına çık'**
  String get surpriseDiscoverySubtitle;

  /// No description provided for @randomButGood.
  ///
  /// In tr, this message translates to:
  /// **'Rastgele ama iyi'**
  String get randomButGood;

  /// No description provided for @outsideYourUsual.
  ///
  /// In tr, this message translates to:
  /// **'Rutin dışı'**
  String get outsideYourUsual;

  /// No description provided for @pricePerformanceSurprise.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat/performans sürprizi'**
  String get pricePerformanceSurprise;

  /// No description provided for @nearbyCampaignsAndAnnouncements.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki kampanyalar ve duyurular'**
  String get nearbyCampaignsAndAnnouncements;

  /// No description provided for @noNearbyCampaign.
  ///
  /// In tr, this message translates to:
  /// **'Yakında kampanya yok'**
  String get noNearbyCampaign;

  /// No description provided for @noActiveAnnouncementInArea.
  ///
  /// In tr, this message translates to:
  /// **'Bölgede aktif duyuru yok'**
  String get noActiveAnnouncementInArea;

  /// No description provided for @remainingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kalan'**
  String get remainingLabel;

  /// No description provided for @campaign.
  ///
  /// In tr, this message translates to:
  /// **'Kampanya'**
  String get campaign;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @noLocationDataForMap.
  ///
  /// In tr, this message translates to:
  /// **'Harita için konum verisi yok'**
  String get noLocationDataForMap;

  /// No description provided for @mapDataMissingUseList.
  ///
  /// In tr, this message translates to:
  /// **'Harita verisi eksik, liste görünümünü kullan.'**
  String get mapDataMissingUseList;

  /// No description provided for @openMapView.
  ///
  /// In tr, this message translates to:
  /// **'Harita Görünümünü Aç'**
  String get openMapView;

  /// No description provided for @mapHintTapPins.
  ///
  /// In tr, this message translates to:
  /// **'İğnelere dokunarak detayları gör.'**
  String get mapHintTapPins;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni gerekli.'**
  String get locationPermissionRequired;

  /// No description provided for @noFoodFoundForCriteria.
  ///
  /// In tr, this message translates to:
  /// **'Bu kriterlere uygun yemek bulunamadı'**
  String get noFoodFoundForCriteria;

  /// No description provided for @whatToEatDescription.
  ///
  /// In tr, this message translates to:
  /// **'Tercihlerine göre öneriler'**
  String get whatToEatDescription;

  /// No description provided for @stepPeopleCount.
  ///
  /// In tr, this message translates to:
  /// **'Kişi sayısı'**
  String get stepPeopleCount;

  /// No description provided for @quickDecisionThreeOptions.
  ///
  /// In tr, this message translates to:
  /// **'3 seçenekle hızlı karar'**
  String get quickDecisionThreeOptions;

  /// No description provided for @stepBudgetTotal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam bütçe'**
  String get stepBudgetTotal;

  /// No description provided for @budgetTl.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe (₺)'**
  String get budgetTl;

  /// No description provided for @stepDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get stepDistance;

  /// No description provided for @locationNotSelected.
  ///
  /// In tr, this message translates to:
  /// **'Konum seçilmedi'**
  String get locationNotSelected;

  /// No description provided for @seeSuggestions.
  ///
  /// In tr, this message translates to:
  /// **'Önerileri Gör'**
  String get seeSuggestions;

  /// No description provided for @getSingleSuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Tek öneri al'**
  String get getSingleSuggestion;

  /// No description provided for @go.
  ///
  /// In tr, this message translates to:
  /// **'Git'**
  String get go;

  /// No description provided for @restart.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Başlat'**
  String get restart;

  /// No description provided for @quickShortcuts.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Kısayollar'**
  String get quickShortcuts;

  /// No description provided for @quickShortcutsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'En sık kullanılanlar'**
  String get quickShortcutsSubtitle;

  /// No description provided for @savedItems.
  ///
  /// In tr, this message translates to:
  /// **'Kaydettiklerim'**
  String get savedItems;

  /// No description provided for @myFriendGroup.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaş Grubum'**
  String get myFriendGroup;

  /// No description provided for @tasteExperts.
  ///
  /// In tr, this message translates to:
  /// **'Lezzet Uzmanları'**
  String get tasteExperts;

  /// No description provided for @businessTools.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Araçları'**
  String get businessTools;

  /// No description provided for @businessToolsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yönetim ve içgörüler'**
  String get businessToolsSubtitle;

  /// No description provided for @sponsoredLabelChip.
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu etiket'**
  String get sponsoredLabelChip;

  /// No description provided for @sponsored.
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu'**
  String get sponsored;

  /// No description provided for @ready.
  ///
  /// In tr, this message translates to:
  /// **'Hazır'**
  String get ready;

  /// No description provided for @plan.
  ///
  /// In tr, this message translates to:
  /// **'plan'**
  String get plan;

  /// No description provided for @sponsoredDisclosure.
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu içerik'**
  String get sponsoredDisclosure;

  /// No description provided for @sponsoredTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Bu içerik sponsorlu olabilir.'**
  String get sponsoredTooltip;

  /// No description provided for @localInsightsReady.
  ///
  /// In tr, this message translates to:
  /// **'Yerel içgörüler hazır'**
  String localInsightsReady(String area);

  /// No description provided for @show.
  ///
  /// In tr, this message translates to:
  /// **'Göster'**
  String get show;

  /// No description provided for @restaurant.
  ///
  /// In tr, this message translates to:
  /// **'Restoran'**
  String get restaurant;

  /// No description provided for @cafe.
  ///
  /// In tr, this message translates to:
  /// **'Kafe'**
  String get cafe;

  /// No description provided for @venue.
  ///
  /// In tr, this message translates to:
  /// **'Mekan'**
  String get venue;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @businessPackage.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Paketi'**
  String get businessPackage;

  /// No description provided for @redirectToReservation.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyona yönlendir'**
  String get redirectToReservation;

  /// No description provided for @priceAlerts.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Uyarıları'**
  String get priceAlerts;

  /// No description provided for @corporateIntegration.
  ///
  /// In tr, this message translates to:
  /// **'Kurumsal Entegrasyon'**
  String get corporateIntegration;

  /// No description provided for @detailedReports.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Raporlar'**
  String get detailedReports;

  /// No description provided for @qrTools.
  ///
  /// In tr, this message translates to:
  /// **'QR Araçları'**
  String get qrTools;

  /// No description provided for @unlockNewFeatures.
  ///
  /// In tr, this message translates to:
  /// **'Yeni özelliklerin kilidini aç'**
  String get unlockNewFeatures;

  /// No description provided for @branchManagement.
  ///
  /// In tr, this message translates to:
  /// **'Şube Yönetimi'**
  String get branchManagement;

  /// No description provided for @menuWithQr.
  ///
  /// In tr, this message translates to:
  /// **'QR ile Menü'**
  String get menuWithQr;

  /// No description provided for @newFeatures.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Özellikler'**
  String get newFeatures;

  /// No description provided for @nearOpenSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakında Açık Olanlar'**
  String nearOpenSectionTitle(String area);

  /// No description provided for @mostViewedThisWeekTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu Haftanın En Çok Görüntülenenleri'**
  String mostViewedThisWeekTitle(String area);

  /// No description provided for @noViewDataInArea.
  ///
  /// In tr, this message translates to:
  /// **'Bölgede görüntüleme verisi yok'**
  String get noViewDataInArea;

  /// No description provided for @viewsMetric.
  ///
  /// In tr, this message translates to:
  /// **'görüntüleme'**
  String viewsMetric(int count);

  /// No description provided for @highestPriceChangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'En Yüksek Fiyat Değişimi'**
  String highestPriceChangeTitle(String area);

  /// No description provided for @noPriceMovementInArea.
  ///
  /// In tr, this message translates to:
  /// **'Bölgede fiyat hareketi yok'**
  String get noPriceMovementInArea;

  /// No description provided for @priceChangeMetric.
  ///
  /// In tr, this message translates to:
  /// **'fiyat değişimi'**
  String priceChangeMetric(int count);

  /// No description provided for @nightOpenFavoritesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gece Açık Favoriler'**
  String nightOpenFavoritesTitle(String area);

  /// No description provided for @noNightOpenFavoritesInArea.
  ///
  /// In tr, this message translates to:
  /// **'Bölgede gece açık favori yok'**
  String get noNightOpenFavoritesInArea;

  /// No description provided for @followersMetric.
  ///
  /// In tr, this message translates to:
  /// **'takipçi'**
  String followersMetric(int count);

  /// No description provided for @popularCategoriesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Popüler Kategoriler'**
  String popularCategoriesTitle(String area);

  /// No description provided for @regionalPriceIndexTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bölgesel Fiyat Endeksi'**
  String regionalPriceIndexTitle(String area);

  /// No description provided for @detailedAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı Analiz'**
  String get detailedAnalysis;

  /// No description provided for @loadWhenScrolledDown.
  ///
  /// In tr, this message translates to:
  /// **'Aşağı kaydırınca yüklenir'**
  String get loadWhenScrolledDown;

  /// No description provided for @anomalyMonitoringTitle.
  ///
  /// In tr, this message translates to:
  /// **'{area} anomali izlemesi'**
  String anomalyMonitoringTitle(String area);

  /// No description provided for @general.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get general;

  /// No description provided for @priceIndexLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat endeksi yüklenemedi'**
  String get priceIndexLoadFailed;

  /// No description provided for @noPriceIndexDataInArea.
  ///
  /// In tr, this message translates to:
  /// **'Bölgede fiyat endeksi verisi yok'**
  String get noPriceIndexDataInArea;

  /// No description provided for @medianPriceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Medyan fiyat {price}'**
  String medianPriceLabel(String price);

  /// No description provided for @anomalyListLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Anomali listesi yüklenemedi'**
  String get anomalyListLoadFailed;

  /// No description provided for @noPriceAnomalyLast30Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 günde fiyat anomalisi yok'**
  String get noPriceAnomalyLast30Days;

  /// No description provided for @sectionLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm yüklenemedi'**
  String get sectionLoadFailed;

  /// No description provided for @rankedAt.
  ///
  /// In tr, this message translates to:
  /// **'Sıra: {rank}'**
  String rankedAt(String prefix, int rank);

  /// No description provided for @yourScore.
  ///
  /// In tr, this message translates to:
  /// **'Puanın: {score}'**
  String yourScore(Object score);

  /// No description provided for @createGroup.
  ///
  /// In tr, this message translates to:
  /// **'Grup kur'**
  String get createGroup;

  /// No description provided for @newPlaces.
  ///
  /// In tr, this message translates to:
  /// **'Yeni yerler'**
  String get newPlaces;

  /// No description provided for @campaignEnded.
  ///
  /// In tr, this message translates to:
  /// **'bitti'**
  String get campaignEnded;

  /// No description provided for @timeDays.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
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
  /// **'{count} gün önce'**
  String timeDaysAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} saat önce'**
  String timeHoursAgo(int count);

  /// No description provided for @timeMinutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} dakika önce'**
  String timeMinutesAgo(int count);

  /// No description provided for @statusVerifiedShort.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get statusVerifiedShort;

  /// No description provided for @statusMixedShort.
  ///
  /// In tr, this message translates to:
  /// **'Karışık'**
  String get statusMixedShort;

  /// No description provided for @statusOutdatedShort.
  ///
  /// In tr, this message translates to:
  /// **'Güncel Değil'**
  String get statusOutdatedShort;

  /// No description provided for @statusUnknownShort.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get statusUnknownShort;

  /// No description provided for @threeMonthsShort.
  ///
  /// In tr, this message translates to:
  /// **'(3 Ay)'**
  String get threeMonthsShort;

  /// No description provided for @versionAndSource.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm ve kaynak'**
  String versionAndSource(int version, String source);

  /// No description provided for @sourceOwner.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: işletme'**
  String get sourceOwner;

  /// No description provided for @sourceCommunity.
  ///
  /// In tr, this message translates to:
  /// **'topluluk'**
  String get sourceCommunity;

  /// No description provided for @sourceAi.
  ///
  /// In tr, this message translates to:
  /// **'otomatik'**
  String get sourceAi;

  /// No description provided for @shareBusinessMessage.
  ///
  /// In tr, this message translates to:
  /// **'İşletmeyi paylaş'**
  String shareBusinessMessage(
    String name,
    String location,
    String web,
    String deep,
  );

  /// No description provided for @noLinkFound.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı bulunamadı'**
  String get noLinkFound;

  /// No description provided for @newEmbedLinksWillAppear.
  ///
  /// In tr, this message translates to:
  /// **'Yeni gömülü bağlantılar burada görünecek.'**
  String get newEmbedLinksWillAppear;

  /// No description provided for @link.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı'**
  String get link;

  /// No description provided for @untitledLink.
  ///
  /// In tr, this message translates to:
  /// **'Başlıksız bağlantı'**
  String get untitledLink;

  /// No description provided for @menuShareNotFoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'Menü bulunamadı • {appName}'**
  String menuShareNotFoundTitle(String appName);

  /// No description provided for @menuShareNotFoundDescription.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan menü içeriği bulunamadı.'**
  String get menuShareNotFoundDescription;

  /// No description provided for @menuContentNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Menü içeriği bulunamadı'**
  String get menuContentNotFound;

  /// No description provided for @openAppForBetterExperience.
  ///
  /// In tr, this message translates to:
  /// **'Daha iyi deneyim için uygulamayı aç.'**
  String get openAppForBetterExperience;

  /// No description provided for @openApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Aç'**
  String get openApp;

  /// No description provided for @nearbyPeopleViewed.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki kişiler görüntüledi'**
  String nearbyPeopleViewed(int count);

  /// No description provided for @verifiedPrices.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış fiyatlar'**
  String get verifiedPrices;

  /// No description provided for @selectRatingFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce puan seç'**
  String get selectRatingFirst;

  /// No description provided for @thankYou.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler'**
  String get thankYou;

  /// No description provided for @noProductsFound.
  ///
  /// In tr, this message translates to:
  /// **'Ürün bulunamadı'**
  String get noProductsFound;

  /// No description provided for @preparedWithApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama ile hazırlandı'**
  String preparedWithApp(String appName);

  /// No description provided for @tableLabel.
  ///
  /// In tr, this message translates to:
  /// **'Masa {tableNo}'**
  String tableLabel(String tableNo);

  /// No description provided for @tableServiceQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Masa servisi var mı?'**
  String tableServiceQuestion(String tableNo);

  /// No description provided for @shortNoteOptional.
  ///
  /// In tr, this message translates to:
  /// **'Kısa not (opsiyonel)'**
  String get shortNoteOptional;

  /// No description provided for @submit.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get submit;

  /// No description provided for @submitted.
  ///
  /// In tr, this message translates to:
  /// **'Gönderildi'**
  String get submitted;

  /// No description provided for @submitting.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor'**
  String get submitting;

  /// No description provided for @mySuggestionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Önerilerim'**
  String get mySuggestionsTitle;

  /// No description provided for @mySuggestionsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gönderdiğin fiyat önerileri'**
  String get mySuggestionsSubtitle;

  /// No description provided for @viewBusiness.
  ///
  /// In tr, this message translates to:
  /// **'İşletmeyi Gör'**
  String get viewBusiness;

  /// No description provided for @statusApproved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get statusRejected;

  /// No description provided for @statusPending.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get statusPending;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @notNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get notNow;

  /// No description provided for @onboardingLiveMenusTitle.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Menüler'**
  String get onboardingLiveMenusTitle;

  /// No description provided for @onboardingLiveMenusDescription.
  ///
  /// In tr, this message translates to:
  /// **'Güncel menülere anında eriş.'**
  String get onboardingLiveMenusDescription;

  /// No description provided for @onboardingContributeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Katkıda Bulun'**
  String get onboardingContributeTitle;

  /// No description provided for @onboardingContributeDescription.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk için fiyatları doğrula ve güncelle.'**
  String get onboardingContributeDescription;

  /// No description provided for @getStarted.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get getStarted;

  /// No description provided for @continueAction.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueAction;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @enableLocationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konumu Aç'**
  String get enableLocationTitle;

  /// No description provided for @enableLocationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki yerleri göstermek için konumunu aç.'**
  String get enableLocationSubtitle;

  /// No description provided for @locationPermissionGranted.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verildi'**
  String get locationPermissionGranted;

  /// No description provided for @locationOptionalInfo.
  ///
  /// In tr, this message translates to:
  /// **'İstersen daha sonra da açabilirsin.'**
  String get locationOptionalInfo;

  /// No description provided for @allowLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konuma izin ver'**
  String get allowLocation;

  /// No description provided for @chooseLocationManually.
  ///
  /// In tr, this message translates to:
  /// **'Konumu Elle Seç'**
  String get chooseLocationManually;

  /// No description provided for @menuReading.
  ///
  /// In tr, this message translates to:
  /// **'Menü okunuyor'**
  String get menuReading;

  /// No description provided for @noPriceDetectionFound.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat tespiti bulunamadı'**
  String get noPriceDetectionFound;

  /// No description provided for @receiptOcrNotSupportedWeb.
  ///
  /// In tr, this message translates to:
  /// **'Web sürümünde fiş OCR desteklenmiyor'**
  String get receiptOcrNotSupportedWeb;

  /// No description provided for @receiptReading.
  ///
  /// In tr, this message translates to:
  /// **'Fiş okunuyor'**
  String get receiptReading;

  /// No description provided for @noPriceFoundOnReceipt.
  ///
  /// In tr, this message translates to:
  /// **'Fişte fiyat bulunamadı'**
  String get noPriceFoundOnReceipt;

  /// No description provided for @receiptUploading.
  ///
  /// In tr, this message translates to:
  /// **'Fiş yükleniyor'**
  String get receiptUploading;

  /// No description provided for @receiptUploadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Fiş yükleme başarısız'**
  String get receiptUploadFailed;

  /// No description provided for @camera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get gallery;

  /// No description provided for @matchReceipt.
  ///
  /// In tr, this message translates to:
  /// **'Fişi Eşleştir'**
  String get matchReceipt;

  /// No description provided for @matchPrices.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatları Eşleştir'**
  String get matchPrices;

  /// No description provided for @autoMatchedRowsCheck.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik eşleşen satırları kontrol et.'**
  String autoMatchedRowsCheck(int count);

  /// No description provided for @unlabeled.
  ///
  /// In tr, this message translates to:
  /// **'Etiketsiz'**
  String get unlabeled;

  /// No description provided for @priceTry.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat (₺)'**
  String get priceTry;

  /// No description provided for @selectMenuItem.
  ///
  /// In tr, this message translates to:
  /// **'Menü ürünü seç'**
  String get selectMenuItem;

  /// No description provided for @sendReceipt.
  ///
  /// In tr, this message translates to:
  /// **'Fişi Gönder'**
  String get sendReceipt;

  /// No description provided for @sendReceiptSuggestions.
  ///
  /// In tr, this message translates to:
  /// **'Fiş Önerilerini Gönder'**
  String get sendReceiptSuggestions;

  /// No description provided for @selectAtLeastOneItem.
  ///
  /// In tr, this message translates to:
  /// **'En az bir ürün seç'**
  String get selectAtLeastOneItem;

  /// No description provided for @invalidPriceExists.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz fiyat var'**
  String get invalidPriceExists;

  /// No description provided for @sendingReceipt.
  ///
  /// In tr, this message translates to:
  /// **'Fiş gönderiliyor'**
  String get sendingReceipt;

  /// No description provided for @receiptSent.
  ///
  /// In tr, this message translates to:
  /// **'Fiş gönderildi'**
  String get receiptSent;

  /// No description provided for @sendingReceiptSuggestions.
  ///
  /// In tr, this message translates to:
  /// **'Fiş önerileri gönderiliyor'**
  String get sendingReceiptSuggestions;

  /// No description provided for @priceSuggestionsSent.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerileri gönderildi'**
  String get priceSuggestionsSent;

  /// No description provided for @searchFoodHint.
  ///
  /// In tr, this message translates to:
  /// **'Yemek ara...'**
  String get searchFoodHint;

  /// No description provided for @profileActive.
  ///
  /// In tr, this message translates to:
  /// **'Profil aktif'**
  String get profileActive;

  /// No description provided for @profileLoading.
  ///
  /// In tr, this message translates to:
  /// **'Profil yükleniyor'**
  String get profileLoading;

  /// No description provided for @dietProfileNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme profili bulunamadı'**
  String get dietProfileNotFound;

  /// No description provided for @noResultsFound.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get noResultsFound;

  /// No description provided for @allowLocationForNearby.
  ///
  /// In tr, this message translates to:
  /// **'Yakın sonuçlar için konum izni ver'**
  String get allowLocationForNearby;

  /// No description provided for @setPriceAlert.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat uyarısı kur'**
  String get setPriceAlert;

  /// No description provided for @vegan.
  ///
  /// In tr, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// No description provided for @vegetarian.
  ///
  /// In tr, this message translates to:
  /// **'Vejetaryen'**
  String get vegetarian;

  /// No description provided for @lactoseFree.
  ///
  /// In tr, this message translates to:
  /// **'Laktozsuz'**
  String get lactoseFree;

  /// No description provided for @maxCalories.
  ///
  /// In tr, this message translates to:
  /// **'Maksimum kalori'**
  String get maxCalories;

  /// No description provided for @onlyVerifiedPrice.
  ///
  /// In tr, this message translates to:
  /// **'Sadece teyitli fiyat'**
  String get onlyVerifiedPrice;

  /// No description provided for @votes.
  ///
  /// In tr, this message translates to:
  /// **'{count} oy'**
  String votes(int count);

  /// No description provided for @glutenFree.
  ///
  /// In tr, this message translates to:
  /// **'Glutensiz'**
  String get glutenFree;

  /// No description provided for @menuItem.
  ///
  /// In tr, this message translates to:
  /// **'Menü ürünü'**
  String get menuItem;

  /// No description provided for @cataloged.
  ///
  /// In tr, this message translates to:
  /// **'Kataloglu'**
  String get cataloged;

  /// No description provided for @priceAlert.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Alarmı'**
  String get priceAlert;

  /// No description provided for @priceAlertSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Belirlediğin fiyatın altına düşünce haber verelim.'**
  String get priceAlertSubtitle;

  /// No description provided for @addToBill.
  ///
  /// In tr, this message translates to:
  /// **'Hesaba Ekle'**
  String get addToBill;

  /// No description provided for @voteSaved.
  ///
  /// In tr, this message translates to:
  /// **'Oyun kaydedildi'**
  String get voteSaved;

  /// No description provided for @photoAdded.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf eklendi'**
  String get photoAdded;

  /// No description provided for @photoQualityWarning.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf {warnings} görünüyor. Daha net ve aydınlık bir fotoğraf yükleyebilirsin.'**
  String photoQualityWarning(String warnings);

  /// No description provided for @suggestEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenleme öner'**
  String get suggestEdit;

  /// No description provided for @verifyPriceWithReceipt.
  ///
  /// In tr, this message translates to:
  /// **'Fiş ile fiyat doğrula'**
  String get verifyPriceWithReceipt;

  /// No description provided for @cart.
  ///
  /// In tr, this message translates to:
  /// **'Sepet'**
  String get cart;

  /// No description provided for @cartEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Sepet boş'**
  String get cartEmpty;

  /// No description provided for @addItemToCalculate.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplamak için ürün ekle'**
  String get addItemToCalculate;

  /// No description provided for @tipPercentage.
  ///
  /// In tr, this message translates to:
  /// **'Bahşiş Yüzdesi'**
  String get tipPercentage;

  /// No description provided for @serviceIncluded.
  ///
  /// In tr, this message translates to:
  /// **'Servis dahil'**
  String get serviceIncluded;

  /// No description provided for @coverIncluded.
  ///
  /// In tr, this message translates to:
  /// **'Kuver dahil'**
  String get coverIncluded;

  /// No description provided for @subtotal.
  ///
  /// In tr, this message translates to:
  /// **'Ara toplam'**
  String get subtotal;

  /// No description provided for @cover.
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
  /// **'Bahşiş ({percent}%)'**
  String tipWithPercent(int percent);

  /// No description provided for @serviceCoverMayVary.
  ///
  /// In tr, this message translates to:
  /// **'Servis/kuver işletmeye göre değişebilir.'**
  String get serviceCoverMayVary;

  /// No description provided for @estimatedTotal.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini Toplam'**
  String get estimatedTotal;

  /// No description provided for @vatExcluded.
  ///
  /// In tr, this message translates to:
  /// **'KDV hariç'**
  String get vatExcluded;

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Bir sorun oluştu'**
  String get errorOccurred;

  /// No description provided for @menuItemNotFoundDescription.
  ///
  /// In tr, this message translates to:
  /// **'Aradığın ürün henüz eklenmemiş olabilir. İstersen ilk sen ekle.'**
  String get menuItemNotFoundDescription;

  /// No description provided for @trustScoreInfoNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu güven puanı kullanıcı oylaması değil, katkı kalitesinden oluşur.'**
  String get trustScoreInfoNote;

  /// No description provided for @plusPoints.
  ///
  /// In tr, this message translates to:
  /// **'+{points} puan'**
  String plusPoints(int points);

  /// No description provided for @verifyContributionRaisedScore.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulaman katkın puanını yükseltti.'**
  String get verifyContributionRaisedScore;

  /// No description provided for @priceVerification.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulama'**
  String get priceVerification;

  /// No description provided for @priceVerificationSteps.
  ///
  /// In tr, this message translates to:
  /// **'1) Gördüğün fiyatı yaz  2) Gerekirse not/foto ekle  3) Gönder'**
  String get priceVerificationSteps;

  /// No description provided for @newPriceTry.
  ///
  /// In tr, this message translates to:
  /// **'Yeni fiyat (₺)'**
  String get newPriceTry;

  /// No description provided for @note.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get note;

  /// No description provided for @addEvidencePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Kanıt fotoğrafı ekle'**
  String get addEvidencePhoto;

  /// No description provided for @evidenceAdded.
  ///
  /// In tr, this message translates to:
  /// **'Kanıt eklendi'**
  String get evidenceAdded;

  /// No description provided for @menuItemName.
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı'**
  String get menuItemName;

  /// No description provided for @menuItemNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı boş olamaz'**
  String get menuItemNameRequired;

  /// No description provided for @enterValidPrice.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir fiyat gir'**
  String get enterValidPrice;

  /// No description provided for @sendSuggestion.
  ///
  /// In tr, this message translates to:
  /// **'Öneri Gönder'**
  String get sendSuggestion;

  /// No description provided for @noChanges.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklik yok'**
  String get noChanges;

  /// No description provided for @priceCannotBeEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat boş olamaz'**
  String get priceCannotBeEmpty;

  /// No description provided for @suggestionSentPendingApproval.
  ///
  /// In tr, this message translates to:
  /// **'Önerin gönderildi, onay bekliyor.'**
  String get suggestionSentPendingApproval;

  /// No description provided for @noSuggestionFound.
  ///
  /// In tr, this message translates to:
  /// **'Öneri bulunamadı'**
  String get noSuggestionFound;

  /// No description provided for @suggestedFoods.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen Yemekler'**
  String get suggestedFoods;

  /// No description provided for @priceHistoryLast3.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geçmişi (son 3)'**
  String get priceHistoryLast3;

  /// No description provided for @price.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get price;

  /// No description provided for @last30DaysVotes.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün oyları'**
  String last30DaysVotes(int ok, int bad);

  /// No description provided for @lastVerificationDate.
  ///
  /// In tr, this message translates to:
  /// **'Son doğrulama: {date}'**
  String lastVerificationDate(String date);

  /// No description provided for @uniqueVerifiersIn48h.
  ///
  /// In tr, this message translates to:
  /// **'48 saatte doğrulayan farklı kullanıcı: {count}'**
  String uniqueVerifiersIn48h(int count);

  /// No description provided for @strongConsensusPriceSafe.
  ///
  /// In tr, this message translates to:
  /// **'Güçlü uzlaşı var, fiyat güvenli görünüyor.'**
  String get strongConsensusPriceSafe;

  /// No description provided for @priceConfidenceScore.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat güven puanı: %{score}'**
  String priceConfidenceScore(int score);

  /// No description provided for @seenCorrect.
  ///
  /// In tr, this message translates to:
  /// **'Gördüm • Doğru'**
  String get seenCorrect;

  /// No description provided for @seenIncorrect.
  ///
  /// In tr, this message translates to:
  /// **'Gördüm • Yanlış'**
  String get seenIncorrect;

  /// No description provided for @suggestNewPrice.
  ///
  /// In tr, this message translates to:
  /// **'Yeni fiyat öner'**
  String get suggestNewPrice;

  /// No description provided for @howCalculated.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl hesaplandı?'**
  String get howCalculated;

  /// No description provided for @verificationRate.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama oranı'**
  String get verificationRate;

  /// No description provided for @recentPositiveVotes.
  ///
  /// In tr, this message translates to:
  /// **'Son olumlu oylar'**
  String get recentPositiveVotes;

  /// No description provided for @priceStability.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat istikrarı'**
  String get priceStability;

  /// No description provided for @priceChangeLast30Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 günde fiyat değişimi: {count}'**
  String priceChangeLast30Days(int count);

  /// No description provided for @scoreForInfoOnly.
  ///
  /// In tr, this message translates to:
  /// **'Bu skor yalnızca bilgilendirme amaçlıdır.'**
  String get scoreForInfoOnly;

  /// No description provided for @pricePerformance.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat/Performans'**
  String get pricePerformance;

  /// No description provided for @valueScoreFormulaHint.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama oranı, son olumlu oylar ve fiyat istikrarına göre hesaplanır.'**
  String get valueScoreFormulaHint;

  /// No description provided for @menuPhotos.
  ///
  /// In tr, this message translates to:
  /// **'Menü Fotoğrafları'**
  String get menuPhotos;

  /// No description provided for @updateMenuEarnPoints.
  ///
  /// In tr, this message translates to:
  /// **'Menü güncelle, puan kazan'**
  String updateMenuEarnPoints(int points);

  /// No description provided for @menuPhotosHint.
  ///
  /// In tr, this message translates to:
  /// **'Menü fotoğrafları ürünü göstermeli. Otomatik kırpılır; karanlık/flu olanlar uyarılır.'**
  String get menuPhotosHint;

  /// No description provided for @noPhotosYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz fotoğraf yok.'**
  String get noPhotosYet;

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// No description provided for @timeMonthsAgo.
  ///
  /// In tr, this message translates to:
  /// **'{count} ay önce'**
  String timeMonthsAgo(int count);

  /// No description provided for @priceInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geçersiz'**
  String get priceInvalid;

  /// No description provided for @noteNoLinkPhone.
  ///
  /// In tr, this message translates to:
  /// **'Not alanına bağlantı veya telefon eklenemez.'**
  String get noteNoLinkPhone;

  /// No description provided for @noteContainsProfanity.
  ///
  /// In tr, this message translates to:
  /// **'Notta uygunsuz ifade var.'**
  String get noteContainsProfanity;

  /// No description provided for @noteTooManyEmoji.
  ///
  /// In tr, this message translates to:
  /// **'Notta çok fazla emoji var'**
  String get noteTooManyEmoji;

  /// No description provided for @rateLimited24h.
  ///
  /// In tr, this message translates to:
  /// **'24 saatlik sınır aşıldı'**
  String get rateLimited24h;

  /// No description provided for @dailyPriceSuggestionLimitReached.
  ///
  /// In tr, this message translates to:
  /// **'Günlük fiyat öneri limitine ulaşıldı'**
  String get dailyPriceSuggestionLimitReached;

  /// No description provided for @invalidEvidenceLink.
  ///
  /// In tr, this message translates to:
  /// **'Kanıt bağlantısı geçersiz.'**
  String get invalidEvidenceLink;

  /// No description provided for @invalidCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz para birimi'**
  String get invalidCurrency;

  /// No description provided for @ownerSections.
  ///
  /// In tr, this message translates to:
  /// **'Bölümler'**
  String get ownerSections;

  /// No description provided for @ownerAddSection.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Ekle'**
  String get ownerAddSection;

  /// No description provided for @ownerSectionNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bölüm yok.'**
  String get ownerSectionNotFound;

  /// No description provided for @ownerEditSection.
  ///
  /// In tr, this message translates to:
  /// **'Bölümü Düzenle'**
  String get ownerEditSection;

  /// No description provided for @ownerDeleteSection.
  ///
  /// In tr, this message translates to:
  /// **'Bölümü Sil'**
  String get ownerDeleteSection;

  /// No description provided for @ownerSectionWillBeDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm silinecek.'**
  String get ownerSectionWillBeDeleted;

  /// No description provided for @ownerArchiveItemsInSection.
  ///
  /// In tr, this message translates to:
  /// **'Bölümdeki ürünleri arşivle'**
  String get ownerArchiveItemsInSection;

  /// No description provided for @ownerSectionAdded.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm eklendi.'**
  String get ownerSectionAdded;

  /// No description provided for @ownerSectionUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm güncellendi.'**
  String get ownerSectionUpdated;

  /// No description provided for @ownerSectionDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Bölüm silindi.'**
  String get ownerSectionDeleted;

  /// No description provided for @ownerEditMenu.
  ///
  /// In tr, this message translates to:
  /// **'Menüyü Düzenle'**
  String get ownerEditMenu;

  /// No description provided for @ownerMenuTypeOptional.
  ///
  /// In tr, this message translates to:
  /// **'Menü türü (opsiyonel)'**
  String get ownerMenuTypeOptional;

  /// No description provided for @ownerMenuUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Menü güncellendi.'**
  String get ownerMenuUpdated;

  /// No description provided for @ownerArchiveMenuConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu menüyü arşivlemek istiyor musun?'**
  String get ownerArchiveMenuConfirm;

  /// No description provided for @ownerPublishMenuConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu menüyü yayına almak istiyor musun?'**
  String get ownerPublishMenuConfirm;

  /// No description provided for @ownerSharePanel.
  ///
  /// In tr, this message translates to:
  /// **'Menü Paylaşım Paneli'**
  String get ownerSharePanel;

  /// No description provided for @ownerMenuLink.
  ///
  /// In tr, this message translates to:
  /// **'Menü bağlantısı'**
  String get ownerMenuLink;

  /// No description provided for @ownerQrPng.
  ///
  /// In tr, this message translates to:
  /// **'QR PNG'**
  String get ownerQrPng;

  /// No description provided for @ownerQrPdf.
  ///
  /// In tr, this message translates to:
  /// **'QR PDF'**
  String get ownerQrPdf;

  /// No description provided for @ownerA6Pdf.
  ///
  /// In tr, this message translates to:
  /// **'A6 PDF'**
  String get ownerA6Pdf;

  /// No description provided for @ownerFieldGainCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sahada görünürlük kartı'**
  String get ownerFieldGainCardTitle;

  /// No description provided for @ownerFieldGainCardLine1.
  ///
  /// In tr, this message translates to:
  /// **'QR kartı yazdırıp müşterilere menüyü doğrulat.'**
  String get ownerFieldGainCardLine1;

  /// No description provided for @ownerFieldGainCardLine2.
  ///
  /// In tr, this message translates to:
  /// **'Menü ne kadar güncelse o kadar çok öne çıkarsın.'**
  String get ownerFieldGainCardLine2;

  /// No description provided for @ownerCopyMiniDashboard.
  ///
  /// In tr, this message translates to:
  /// **'Mini panel bağlantısını kopyala'**
  String get ownerCopyMiniDashboard;

  /// No description provided for @ownerMoatTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletme güven özeti'**
  String get ownerMoatTitle;

  /// No description provided for @ownerMoatSummary.
  ///
  /// In tr, this message translates to:
  /// **'Güven: {trust} | Menü güncelliği: {freshness} | Fiyat doğruluğu: {accuracy}'**
  String ownerMoatSummary(int trust, int freshness, int accuracy);

  /// No description provided for @ownerMoatSignal.
  ///
  /// In tr, this message translates to:
  /// **'Sinyal: {validators} doğrulayıcı, kanıt oranı %{evidencePct}, bugün menü görüntüleme: {viewsToday}'**
  String ownerMoatSignal(int validators, int evidencePct, int viewsToday);

  /// No description provided for @ownerCopyMoatText.
  ///
  /// In tr, this message translates to:
  /// **'Özet metni kopyala'**
  String get ownerCopyMoatText;

  /// No description provided for @ownerWhatsappText.
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp metni'**
  String get ownerWhatsappText;

  /// No description provided for @ownerCopyWhatsapp.
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp için kopyala'**
  String get ownerCopyWhatsapp;

  /// No description provided for @ownerXText.
  ///
  /// In tr, this message translates to:
  /// **'X (Twitter) metni'**
  String get ownerXText;

  /// No description provided for @ownerCopyX.
  ///
  /// In tr, this message translates to:
  /// **'X için kopyala'**
  String get ownerCopyX;

  /// No description provided for @ownerInstagramBio.
  ///
  /// In tr, this message translates to:
  /// **'Instagram biyografi metni'**
  String get ownerInstagramBio;

  /// No description provided for @ownerCopyInstagram.
  ///
  /// In tr, this message translates to:
  /// **'Instagram için kopyala'**
  String get ownerCopyInstagram;

  /// No description provided for @ownerCopied.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı'**
  String get ownerCopied;

  /// No description provided for @ownerNearbyViewed.
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi yakında bu menüye baktı'**
  String ownerNearbyViewed(int count);

  /// No description provided for @ownerViewed.
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi baktı'**
  String ownerViewed(int count);

  /// No description provided for @ownerCurrentMenuVerifiedPrices.
  ///
  /// In tr, this message translates to:
  /// **'Güncel menü ve doğrulanmış fiyatlar'**
  String get ownerCurrentMenuVerifiedPrices;

  /// No description provided for @ownerCurrentMenuVerifiedPricesColon.
  ///
  /// In tr, this message translates to:
  /// **'Güncel menü ve doğrulanmış fiyatlar:'**
  String get ownerCurrentMenuVerifiedPricesColon;

  /// No description provided for @ownerStatusPublished.
  ///
  /// In tr, this message translates to:
  /// **'Yayında'**
  String get ownerStatusPublished;

  /// No description provided for @ownerStatusArchived.
  ///
  /// In tr, this message translates to:
  /// **'Arşivde'**
  String get ownerStatusArchived;

  /// No description provided for @ownerStatusDraft.
  ///
  /// In tr, this message translates to:
  /// **'Taslak'**
  String get ownerStatusDraft;

  /// No description provided for @ownerMenuStatus.
  ///
  /// In tr, this message translates to:
  /// **'Durum: {status}'**
  String ownerMenuStatus(String status);

  /// No description provided for @ownerProducts.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler'**
  String get ownerProducts;

  /// No description provided for @ownerApplying.
  ///
  /// In tr, this message translates to:
  /// **'Uygulanıyor...'**
  String get ownerApplying;

  /// No description provided for @ownerBulkPrice.
  ///
  /// In tr, this message translates to:
  /// **'Toplu Fiyat'**
  String get ownerBulkPrice;

  /// No description provided for @ownerCsvImport.
  ///
  /// In tr, this message translates to:
  /// **'CSV İçe Aktar'**
  String get ownerCsvImport;

  /// No description provided for @ownerAddItem.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Ekle'**
  String get ownerAddItem;

  /// No description provided for @ownerProductNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ürün yok.'**
  String get ownerProductNotFound;

  /// No description provided for @ownerLoadMore.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla yükle'**
  String get ownerLoadMore;

  /// No description provided for @ownerEditItem.
  ///
  /// In tr, this message translates to:
  /// **'Ürünü Düzenle'**
  String get ownerEditItem;

  /// No description provided for @ownerItemAdded.
  ///
  /// In tr, this message translates to:
  /// **'Ürün eklendi.'**
  String get ownerItemAdded;

  /// No description provided for @ownerItemUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Ürün güncellendi.'**
  String get ownerItemUpdated;

  /// No description provided for @ownerArchiveItemConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu ürünü arşivlemek istiyor musun?'**
  String get ownerArchiveItemConfirm;

  /// No description provided for @ownerItemArchived.
  ///
  /// In tr, this message translates to:
  /// **'Ürün arşivlendi.'**
  String get ownerItemArchived;

  /// No description provided for @ownerBulkPriceUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Toplu fiyat güncelle'**
  String get ownerBulkPriceUpdate;

  /// No description provided for @ownerMethod.
  ///
  /// In tr, this message translates to:
  /// **'Yöntem'**
  String get ownerMethod;

  /// No description provided for @ownerPercent.
  ///
  /// In tr, this message translates to:
  /// **'Yüzde'**
  String get ownerPercent;

  /// No description provided for @ownerFixedAmountTl.
  ///
  /// In tr, this message translates to:
  /// **'Sabit tutar (TL)'**
  String get ownerFixedAmountTl;

  /// No description provided for @ownerOperation.
  ///
  /// In tr, this message translates to:
  /// **'İşlem'**
  String get ownerOperation;

  /// No description provided for @ownerIncrease.
  ///
  /// In tr, this message translates to:
  /// **'Artır'**
  String get ownerIncrease;

  /// No description provided for @ownerDecrease.
  ///
  /// In tr, this message translates to:
  /// **'Azalt'**
  String get ownerDecrease;

  /// No description provided for @ownerValuePercent.
  ///
  /// In tr, this message translates to:
  /// **'Değer (%)'**
  String get ownerValuePercent;

  /// No description provided for @ownerValueTl.
  ///
  /// In tr, this message translates to:
  /// **'Değer (TL)'**
  String get ownerValueTl;

  /// No description provided for @ownerEnterValidValue.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen geçerli bir değer gir.'**
  String get ownerEnterValidValue;

  /// No description provided for @ownerUpdatedItemPrices.
  ///
  /// In tr, this message translates to:
  /// **'{count} ürünün fiyatı güncellendi.'**
  String ownerUpdatedItemPrices(int count);

  /// No description provided for @ownerCsvFormatHint.
  ///
  /// In tr, this message translates to:
  /// **'Format: ad,fiyat,açıklama,para_birimi'**
  String get ownerCsvFormatHint;

  /// No description provided for @ownerSelecting.
  ///
  /// In tr, this message translates to:
  /// **'Seçiliyor...'**
  String get ownerSelecting;

  /// No description provided for @ownerSelectFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya Seç'**
  String get ownerSelectFile;

  /// No description provided for @ownerCsvExample.
  ///
  /// In tr, this message translates to:
  /// **'Döner,220,100 gr et,TRY'**
  String get ownerCsvExample;

  /// No description provided for @ownerImportContent.
  ///
  /// In tr, this message translates to:
  /// **'İçe Aktar'**
  String get ownerImportContent;

  /// No description provided for @ownerNoValidRows.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli satır bulunamadı.'**
  String get ownerNoValidRows;

  /// No description provided for @ownerImportedItems.
  ///
  /// In tr, this message translates to:
  /// **'{success} ürün içe aktarıldı.'**
  String ownerImportedItems(int success);

  /// No description provided for @ownerImportedItemsWithSkipped.
  ///
  /// In tr, this message translates to:
  /// **'{success} ürün eklendi, {failed} satır atlandı.'**
  String ownerImportedItemsWithSkipped(int success, int failed);

  /// No description provided for @ownerAreYouSure.
  ///
  /// In tr, this message translates to:
  /// **'Emin misin?'**
  String get ownerAreYouSure;

  /// No description provided for @ownerConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get ownerConfirm;

  /// No description provided for @ownerArchiveAction.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get ownerArchiveAction;

  /// No description provided for @ownerPublishAction.
  ///
  /// In tr, this message translates to:
  /// **'Yayına Al'**
  String get ownerPublishAction;

  /// No description provided for @ownerDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get ownerDelete;

  /// No description provided for @ownerItemName.
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı'**
  String get ownerItemName;

  /// No description provided for @ownerDescriptionOptional.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama (opsiyonel)'**
  String get ownerDescriptionOptional;

  /// No description provided for @ownerPriceTl.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat (TL)'**
  String get ownerPriceTl;

  /// No description provided for @ownerCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get ownerCurrency;

  /// No description provided for @ownerCatalogSearch.
  ///
  /// In tr, this message translates to:
  /// **'Katalog ara'**
  String get ownerCatalogSearch;

  /// No description provided for @ownerCatalogSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Köfte, Burger...'**
  String get ownerCatalogSearchHint;

  /// No description provided for @ownerSelectedCatalogId.
  ///
  /// In tr, this message translates to:
  /// **'Seçili katalog ID: {id}'**
  String ownerSelectedCatalogId(int id);

  /// No description provided for @ownerItemNameMin2.
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı en az 2 karakter olmalı.'**
  String get ownerItemNameMin2;

  /// No description provided for @ownerInvalidPrice.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geçersiz.'**
  String get ownerInvalidPrice;

  /// No description provided for @ownerVariants.
  ///
  /// In tr, this message translates to:
  /// **'Varyantlar'**
  String get ownerVariants;

  /// No description provided for @ownerAddVariant.
  ///
  /// In tr, this message translates to:
  /// **'Varyant Ekle'**
  String get ownerAddVariant;

  /// No description provided for @ownerNoVariantsHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu ürün için henüz varyant yok. Örnek: 80gr / 120gr'**
  String get ownerNoVariantsHint;

  /// No description provided for @ownerDefaultVariant.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get ownerDefaultVariant;

  /// No description provided for @ownerSetDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan yap'**
  String get ownerSetDefault;

  /// No description provided for @ownerLabelExample.
  ///
  /// In tr, this message translates to:
  /// **'Etiket (örn: 120gr)'**
  String get ownerLabelExample;

  /// No description provided for @ownerDefaultVariantSwitch.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan varyant'**
  String get ownerDefaultVariantSwitch;

  /// No description provided for @ownerPhotos.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraflar'**
  String get ownerPhotos;

  /// No description provided for @ownerUploading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get ownerUploading;

  /// No description provided for @ownerAddPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Ekle'**
  String get ownerAddPhoto;

  /// No description provided for @ownerNoPhotoYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz fotoğraf yok.'**
  String get ownerNoPhotoYet;

  /// No description provided for @ownerViewAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü gör'**
  String get ownerViewAll;

  /// No description provided for @ownerPhotoUploaded.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yüklendi.'**
  String get ownerPhotoUploaded;

  /// No description provided for @ownerDeletePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafı sil'**
  String get ownerDeletePhoto;

  /// No description provided for @ownerDeletePhotoConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu fotoğraf silinecek.'**
  String get ownerDeletePhotoConfirm;

  /// No description provided for @ownerPhotoDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf silindi.'**
  String get ownerPhotoDeleted;

  /// No description provided for @adminAppealsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İtiraz Kuyruğu'**
  String get adminAppealsTitle;

  /// No description provided for @adminAppealsEmptySla.
  ///
  /// In tr, this message translates to:
  /// **'İtiraz yok. Hedef süre: rapor 24 saat, sahiplik talebi 48 saat.'**
  String get adminAppealsEmptySla;

  /// No description provided for @adminAppealSourceAndUser.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: {sourceId} · Kullanıcı: {userId}'**
  String adminAppealSourceAndUser(String sourceId, String userId);

  /// No description provided for @adminAppealDecisionTitle.
  ///
  /// In tr, this message translates to:
  /// **'İtiraz Kararı · {id}'**
  String adminAppealDecisionTitle(String id);

  /// No description provided for @adminAppealApproveAction.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get adminAppealApproveAction;

  /// No description provided for @adminAppealRejectAction.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get adminAppealRejectAction;

  /// No description provided for @adminAppealDecisionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Karar'**
  String get adminAppealDecisionLabel;

  /// No description provided for @adminAppealTemplateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hazır şablon'**
  String get adminAppealTemplateLabel;

  /// No description provided for @adminAppealDecisionTextLabel.
  ///
  /// In tr, this message translates to:
  /// **'Karar metni'**
  String get adminAppealDecisionTextLabel;

  /// No description provided for @adminAppealDecisionTextHint.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcıya gösterilecek kısa açıklama'**
  String get adminAppealDecisionTextHint;

  /// No description provided for @ownerNewBusinessTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme ekle'**
  String get ownerNewBusinessTitle;

  /// No description provided for @ownerNewBusinessIntro.
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletmeni eklemek için bilgileri doldur.'**
  String get ownerNewBusinessIntro;

  /// No description provided for @ownerBusinessNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'İşletme adı'**
  String get ownerBusinessNameLabel;

  /// No description provided for @ownerCategoryLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get ownerCategoryLabel;

  /// No description provided for @ownerAddressLabel.
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get ownerAddressLabel;

  /// No description provided for @ownerPhoneOptionalLabel.
  ///
  /// In tr, this message translates to:
  /// **'Telefon (opsiyonel)'**
  String get ownerPhoneOptionalLabel;

  /// No description provided for @ownerWebsiteOptionalLabel.
  ///
  /// In tr, this message translates to:
  /// **'Web sitesi (opsiyonel)'**
  String get ownerWebsiteOptionalLabel;

  /// No description provided for @ownerSubmitApplication.
  ///
  /// In tr, this message translates to:
  /// **'Başvuruyu gönder'**
  String get ownerSubmitApplication;

  /// No description provided for @ownerSubmitting.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor...'**
  String get ownerSubmitting;

  /// No description provided for @ownerRequiredFieldsWarning.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen zorunlu alanları doldur.'**
  String get ownerRequiredFieldsWarning;

  /// No description provided for @ownerApplicationReceived.
  ///
  /// In tr, this message translates to:
  /// **'Başvuru alındı.'**
  String get ownerApplicationReceived;

  /// No description provided for @ownerBusinessesTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletmelerim'**
  String get ownerBusinessesTitle;

  /// No description provided for @ownerChainPage.
  ///
  /// In tr, this message translates to:
  /// **'Zincir sayfası'**
  String get ownerChainPage;

  /// No description provided for @ownerMyApplications.
  ///
  /// In tr, this message translates to:
  /// **'Başvurularım'**
  String get ownerMyApplications;

  /// No description provided for @ownerLinksUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Linkler güncellendi.'**
  String get ownerLinksUpdated;

  /// No description provided for @ownerReservationOrderLinksTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon ve sipariş linkleri'**
  String get ownerReservationOrderLinksTitle;

  /// No description provided for @ownerReservationUrlLabel.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon URL'**
  String get ownerReservationUrlLabel;

  /// No description provided for @ownerYemeksepetiUrlLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yemeksepeti URL'**
  String get ownerYemeksepetiUrlLabel;

  /// No description provided for @ownerTrendyolGoUrlLabel.
  ///
  /// In tr, this message translates to:
  /// **'Trendyol Go URL'**
  String get ownerTrendyolGoUrlLabel;

  /// No description provided for @ownerGetirUrlLabel.
  ///
  /// In tr, this message translates to:
  /// **'Getir URL'**
  String get ownerGetirUrlLabel;

  /// No description provided for @ownerChainLabel.
  ///
  /// In tr, this message translates to:
  /// **'Marka/Zincir'**
  String get ownerChainLabel;

  /// No description provided for @ownerAllBranches.
  ///
  /// In tr, this message translates to:
  /// **'Tüm şubeler'**
  String get ownerAllBranches;

  /// No description provided for @ownerBranchLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şube'**
  String get ownerBranchLabel;

  /// No description provided for @ownerChainPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Zincir: {chain}'**
  String ownerChainPrefix(String chain);

  /// No description provided for @ownerPriceVerificationAction.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulama'**
  String get ownerPriceVerificationAction;

  /// No description provided for @ownerRequestsAction.
  ///
  /// In tr, this message translates to:
  /// **'Talepler'**
  String get ownerRequestsAction;

  /// No description provided for @ownerRequestsOwnerOnly.
  ///
  /// In tr, this message translates to:
  /// **'Talepler (yalnızca işletme sahibi)'**
  String get ownerRequestsOwnerOnly;

  /// No description provided for @ownerReservationOrderLinksAction.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon ve sipariş linkleri'**
  String get ownerReservationOrderLinksAction;

  /// No description provided for @ownerStatsNotFound.
  ///
  /// In tr, this message translates to:
  /// **'İstatistik bulunamadı.'**
  String get ownerStatsNotFound;

  /// No description provided for @ownerPerformanceLast30Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün performans'**
  String get ownerPerformanceLast30Days;

  /// No description provided for @ownerMetricMenuViews.
  ///
  /// In tr, this message translates to:
  /// **'Menü görüntülenme'**
  String get ownerMetricMenuViews;

  /// No description provided for @ownerMetricQrScans.
  ///
  /// In tr, this message translates to:
  /// **'QR tarama'**
  String get ownerMetricQrScans;

  /// No description provided for @ownerMetricSearchImpressions.
  ///
  /// In tr, this message translates to:
  /// **'Arama gösterimi'**
  String get ownerMetricSearchImpressions;

  /// No description provided for @ownerMetricConversion.
  ///
  /// In tr, this message translates to:
  /// **'Dönüşüm'**
  String get ownerMetricConversion;

  /// No description provided for @ownerMetricOutboundClicks.
  ///
  /// In tr, this message translates to:
  /// **'Dış bağlantı tıklamaları'**
  String get ownerMetricOutboundClicks;

  /// No description provided for @ownerMetricPriceDropoff.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat nedeniyle vazgeçme (tahmini)'**
  String get ownerMetricPriceDropoff;

  /// No description provided for @ownerMetricPriceVsCompetitors.
  ///
  /// In tr, this message translates to:
  /// **'Rakibe göre fiyat'**
  String get ownerMetricPriceVsCompetitors;

  /// No description provided for @ownerOutboundClicksValue.
  ///
  /// In tr, this message translates to:
  /// **'{outbound} (Rez: {reservation}, Sipariş: {order})'**
  String ownerOutboundClicksValue(int outbound, int reservation, int order);

  /// No description provided for @ownerPricePositionHigher.
  ///
  /// In tr, this message translates to:
  /// **'Daha pahalı{pct}'**
  String ownerPricePositionHigher(String pct);

  /// No description provided for @ownerPricePositionLower.
  ///
  /// In tr, this message translates to:
  /// **'Daha uygun{pct}'**
  String ownerPricePositionLower(String pct);

  /// No description provided for @ownerPricePositionSimilar.
  ///
  /// In tr, this message translates to:
  /// **'Pazarla uyumlu'**
  String get ownerPricePositionSimilar;

  /// No description provided for @ownerPricePositionNoData.
  ///
  /// In tr, this message translates to:
  /// **'Yeterli veri yok'**
  String get ownerPricePositionNoData;

  /// No description provided for @ownerNoBusinessesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz işletme yok'**
  String get ownerNoBusinessesTitle;

  /// No description provided for @ownerNoBusinessesDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme başvurusu oluşturabilirsin.'**
  String get ownerNoBusinessesDescription;

  /// No description provided for @ownerRoleOwner.
  ///
  /// In tr, this message translates to:
  /// **'İşletme sahibi'**
  String get ownerRoleOwner;

  /// No description provided for @ownerRoleManager.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get ownerRoleManager;

  /// No description provided for @ownerMenuAction.
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get ownerMenuAction;

  /// No description provided for @city.
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get city;

  /// No description provided for @district.
  ///
  /// In tr, this message translates to:
  /// **'İlçe'**
  String get district;

  /// No description provided for @ownerActiveRange.
  ///
  /// In tr, this message translates to:
  /// **'Aktif: {from} - {to}'**
  String ownerActiveRange(String from, String to);

  /// No description provided for @vatIncluded.
  ///
  /// In tr, this message translates to:
  /// **'KDV dahil'**
  String get vatIncluded;

  /// No description provided for @webHomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Canlı menü, fiyat şeffaflığı ve topluluk doğrulama platformu.'**
  String get webHomeSubtitle;

  /// No description provided for @webHomeNextLinkLabel.
  ///
  /// In tr, this message translates to:
  /// **'QR Menü Web (Next.js)'**
  String get webHomeNextLinkLabel;

  /// No description provided for @webHomeBusinessAreaTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Alanı'**
  String get webHomeBusinessAreaTitle;

  /// No description provided for @webHomeBusinessAreaSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Panele erişmek için işletme veya admin hesabınla giriş yap.'**
  String get webHomeBusinessAreaSubtitle;

  /// No description provided for @webHomeBusinessLogin.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Girişi'**
  String get webHomeBusinessLogin;

  /// No description provided for @webHomeBusinessRegister.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Kaydı'**
  String get webHomeBusinessRegister;

  /// No description provided for @businessAuthEmailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get businessAuthEmailLabel;

  /// No description provided for @businessAuthPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get businessAuthPasswordLabel;

  /// No description provided for @businessAuthPasswordRepeatLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (tekrar)'**
  String get businessAuthPasswordRepeatLabel;

  /// No description provided for @businessLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Girişi'**
  String get businessLoginTitle;

  /// No description provided for @businessLoginIntro.
  ///
  /// In tr, this message translates to:
  /// **'İşletme sahibi veya admin paneline erişmek için giriş yap.'**
  String get businessLoginIntro;

  /// No description provided for @businessLoginNoPermissionError.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesapta işletme veya admin yetkisi bulunamadı. İşletme kaydı ile devam edebilirsin.'**
  String get businessLoginNoPermissionError;

  /// No description provided for @businessLoginSubmitting.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılıyor...'**
  String get businessLoginSubmitting;

  /// No description provided for @businessLoginGoRegister.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Kaydına Git'**
  String get businessLoginGoRegister;

  /// No description provided for @businessRegisterTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Kaydı'**
  String get businessRegisterTitle;

  /// No description provided for @businessRegisterIntro.
  ///
  /// In tr, this message translates to:
  /// **'İşletme paneline erişmek için kayıt oluştur.'**
  String get businessRegisterIntro;

  /// No description provided for @businessRegisterPasswordMinError.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı.'**
  String get businessRegisterPasswordMinError;

  /// No description provided for @businessRegisterPasswordMismatchError.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler aynı değil.'**
  String get businessRegisterPasswordMismatchError;

  /// No description provided for @businessRegisterSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuldu. Doğrulama adımını tamamladıktan sonra işletme girişi yapabilirsin.'**
  String get businessRegisterSuccess;

  /// No description provided for @businessRegisterSubmitting.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuluyor...'**
  String get businessRegisterSubmitting;

  /// No description provided for @businessRegisterBackToLogin.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Girişine Dön'**
  String get businessRegisterBackToLogin;
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
