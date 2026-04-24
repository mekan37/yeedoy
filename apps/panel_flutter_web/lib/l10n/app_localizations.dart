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

  /// Auto metadata for map
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get map;

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

  /// Auto metadata for logout
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// Auto metadata for uploadPhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Yükle'**
  String get uploadPhoto;

  /// Auto metadata for saving
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get saving;

  /// Auto metadata for preview
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get preview;

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

  /// L10n key: embedUnsupported
  ///
  /// In tr, this message translates to:
  /// **'Bu bağlantı gömülü olarak desteklenmiyor. Bağlantıyı kopyalayabilir veya tarayıcıda açabilirsin.'**
  String get embedUnsupported;

  /// L10n key: embedCopyLinkAction
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kopyala'**
  String get embedCopyLinkAction;

  /// L10n key: embedOpenBrowserAction
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda aç'**
  String get embedOpenBrowserAction;

  /// Auto metadata for back
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

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

  /// Auto metadata for verified
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get verified;

  /// Auto metadata for businessLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get businessLabel;

  /// Auto metadata for menu
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get menu;

  /// Auto metadata for apply
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// Auto metadata for unknown
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknown;

  /// Auto metadata for title
  ///
  /// In tr, this message translates to:
  /// **'title'**
  String get title;

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

  /// Auto metadata for pending
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get pending;

  /// Auto metadata for rejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get rejected;

  /// Auto metadata for duzenle
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get duzenle;

  /// Auto metadata for sla
  ///
  /// In tr, this message translates to:
  /// **'Geri Dönüş Süresi'**
  String get sla;

  /// Auto metadata for yenile
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get yenile;

  /// Auto metadata for start
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get start;

  /// Auto metadata for campaign
  ///
  /// In tr, this message translates to:
  /// **'Kampanya'**
  String get campaign;

  /// Auto metadata for go
  ///
  /// In tr, this message translates to:
  /// **'Git'**
  String get go;

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

  /// Auto metadata for retry
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

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

  /// Auto metadata for cover
  ///
  /// In tr, this message translates to:
  /// **'Kuver'**
  String get cover;

  /// Auto metadata for note
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get note;

  /// Auto metadata for menuItemName
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı'**
  String get menuItemName;

  /// Auto metadata for price
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get price;

  /// Auto metadata for priceStability
  ///
  /// In tr, this message translates to:
  /// **'Fiyat istikrarı'**
  String get priceStability;

  /// L10n key: ownerSections
  ///
  /// In tr, this message translates to:
  /// **'Bölümler'**
  String get ownerSections;

  /// L10n key: ownerAddSection
  ///
  /// In tr, this message translates to:
  /// **'Bölüm Ekle'**
  String get ownerAddSection;

  /// L10n key: ownerSectionNotFound
  ///
  /// In tr, this message translates to:
  /// **'Henüz bölüm yok.'**
  String get ownerSectionNotFound;

  /// L10n key: ownerEditSection
  ///
  /// In tr, this message translates to:
  /// **'Bölümü Düzenle'**
  String get ownerEditSection;

  /// L10n key: ownerDeleteSection
  ///
  /// In tr, this message translates to:
  /// **'Bölümü Sil'**
  String get ownerDeleteSection;

  /// L10n key: ownerSectionWillBeDeleted
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm silinecek.'**
  String get ownerSectionWillBeDeleted;

  /// L10n key: ownerArchiveItemsInSection
  ///
  /// In tr, this message translates to:
  /// **'Bölümdeki ürünleri arşivle'**
  String get ownerArchiveItemsInSection;

  /// L10n key: ownerSectionAdded
  ///
  /// In tr, this message translates to:
  /// **'Bölüm eklendi.'**
  String get ownerSectionAdded;

  /// L10n key: ownerSectionUpdated
  ///
  /// In tr, this message translates to:
  /// **'Bölüm güncellendi.'**
  String get ownerSectionUpdated;

  /// L10n key: ownerSectionDeleted
  ///
  /// In tr, this message translates to:
  /// **'Bölüm silindi.'**
  String get ownerSectionDeleted;

  /// L10n key: ownerEditMenu
  ///
  /// In tr, this message translates to:
  /// **'Menüyü Düzenle'**
  String get ownerEditMenu;

  /// L10n key: ownerMenuTypeOptional
  ///
  /// In tr, this message translates to:
  /// **'Menü türü (opsiyonel)'**
  String get ownerMenuTypeOptional;

  /// L10n key: ownerMenuUpdated
  ///
  /// In tr, this message translates to:
  /// **'Menü güncellendi.'**
  String get ownerMenuUpdated;

  /// L10n key: ownerArchiveMenuConfirm
  ///
  /// In tr, this message translates to:
  /// **'Bu menüyü arşivlemek istiyor musun?'**
  String get ownerArchiveMenuConfirm;

  /// L10n key: ownerPublishMenuConfirm
  ///
  /// In tr, this message translates to:
  /// **'Bu menüyü yayına almak istiyor musun?'**
  String get ownerPublishMenuConfirm;

  /// L10n key: ownerSharePanel
  ///
  /// In tr, this message translates to:
  /// **'Menü Paylaşım Paneli'**
  String get ownerSharePanel;

  /// L10n key: ownerMenuLink
  ///
  /// In tr, this message translates to:
  /// **'Menü bağlantısı'**
  String get ownerMenuLink;

  /// L10n key: ownerQrPng
  ///
  /// In tr, this message translates to:
  /// **'QR PNG'**
  String get ownerQrPng;

  /// L10n key: ownerQrPdf
  ///
  /// In tr, this message translates to:
  /// **'QR PDF'**
  String get ownerQrPdf;

  /// L10n key: ownerA6Pdf
  ///
  /// In tr, this message translates to:
  /// **'A6 PDF'**
  String get ownerA6Pdf;

  /// L10n key: ownerFieldGainCardTitle
  ///
  /// In tr, this message translates to:
  /// **'Sahada görünürlük kartı'**
  String get ownerFieldGainCardTitle;

  /// L10n key: ownerFieldGainCardLine1
  ///
  /// In tr, this message translates to:
  /// **'QR kartı yazdırıp müşterilere menüyü doğrulat.'**
  String get ownerFieldGainCardLine1;

  /// L10n key: ownerFieldGainCardLine2
  ///
  /// In tr, this message translates to:
  /// **'Menü ne kadar güncelse o kadar çok öne çıkarsın.'**
  String get ownerFieldGainCardLine2;

  /// L10n key: ownerCopyMiniDashboard
  ///
  /// In tr, this message translates to:
  /// **'Mini panel bağlantısını kopyala'**
  String get ownerCopyMiniDashboard;

  /// L10n key: ownerMoatTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme güven özeti'**
  String get ownerMoatTitle;

  /// L10n key: ownerMoatSummary
  ///
  /// In tr, this message translates to:
  /// **'Güven: {trust} | Menü güncelliği: {freshness} | Fiyat doğruluğu: {accuracy}'**
  String ownerMoatSummary(int trust, int freshness, int accuracy);

  /// L10n key: ownerMoatSignal
  ///
  /// In tr, this message translates to:
  /// **'Sinyal: {validators} doğrulayıcı, kanıt oranı %{evidencePct}, bugün menü görüntüleme: {viewsToday}'**
  String ownerMoatSignal(int validators, int evidencePct, int viewsToday);

  /// L10n key: ownerCopyMoatText
  ///
  /// In tr, this message translates to:
  /// **'Özet metni kopyala'**
  String get ownerCopyMoatText;

  /// L10n key: ownerWhatsappText
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp metni'**
  String get ownerWhatsappText;

  /// L10n key: ownerCopyWhatsapp
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp için kopyala'**
  String get ownerCopyWhatsapp;

  /// L10n key: ownerXText
  ///
  /// In tr, this message translates to:
  /// **'X (Twitter) metni'**
  String get ownerXText;

  /// L10n key: ownerCopyX
  ///
  /// In tr, this message translates to:
  /// **'X için kopyala'**
  String get ownerCopyX;

  /// L10n key: ownerInstagramBio
  ///
  /// In tr, this message translates to:
  /// **'Instagram biyografi metni'**
  String get ownerInstagramBio;

  /// L10n key: ownerCopyInstagram
  ///
  /// In tr, this message translates to:
  /// **'Instagram için kopyala'**
  String get ownerCopyInstagram;

  /// L10n key: ownerCopied
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı'**
  String get ownerCopied;

  /// L10n key: ownerNearbyViewed
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi yakında bu menüye baktı'**
  String ownerNearbyViewed(int count);

  /// L10n key: ownerViewed
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi baktı'**
  String ownerViewed(int count);

  /// L10n key: ownerCurrentMenuVerifiedPrices
  ///
  /// In tr, this message translates to:
  /// **'Güncel menü ve doğrulanmış fiyatlar'**
  String get ownerCurrentMenuVerifiedPrices;

  /// L10n key: ownerCurrentMenuVerifiedPricesColon
  ///
  /// In tr, this message translates to:
  /// **'Güncel menü ve doğrulanmış fiyatlar:'**
  String get ownerCurrentMenuVerifiedPricesColon;

  /// L10n key: ownerStatusPublished
  ///
  /// In tr, this message translates to:
  /// **'Yayında'**
  String get ownerStatusPublished;

  /// L10n key: ownerStatusArchived
  ///
  /// In tr, this message translates to:
  /// **'Arşivde'**
  String get ownerStatusArchived;

  /// L10n key: ownerStatusDraft
  ///
  /// In tr, this message translates to:
  /// **'Taslak'**
  String get ownerStatusDraft;

  /// L10n key: ownerMenuStatus
  ///
  /// In tr, this message translates to:
  /// **'Durum: {status}'**
  String ownerMenuStatus(String status);

  /// L10n key: ownerProducts
  ///
  /// In tr, this message translates to:
  /// **'Ürünler'**
  String get ownerProducts;

  /// L10n key: ownerApplying
  ///
  /// In tr, this message translates to:
  /// **'Uygulanıyor...'**
  String get ownerApplying;

  /// L10n key: ownerBulkPrice
  ///
  /// In tr, this message translates to:
  /// **'Toplu Fiyat'**
  String get ownerBulkPrice;

  /// L10n key: ownerCsvImport
  ///
  /// In tr, this message translates to:
  /// **'CSV İçe Aktar'**
  String get ownerCsvImport;

  /// L10n key: ownerAddItem
  ///
  /// In tr, this message translates to:
  /// **'Ürün Ekle'**
  String get ownerAddItem;

  /// L10n key: ownerProductNotFound
  ///
  /// In tr, this message translates to:
  /// **'Henüz ürün yok.'**
  String get ownerProductNotFound;

  /// L10n key: ownerLoadMore
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla yükle'**
  String get ownerLoadMore;

  /// L10n key: ownerEditItem
  ///
  /// In tr, this message translates to:
  /// **'Ürünü Düzenle'**
  String get ownerEditItem;

  /// L10n key: ownerItemAdded
  ///
  /// In tr, this message translates to:
  /// **'Ürün eklendi.'**
  String get ownerItemAdded;

  /// L10n key: ownerItemUpdated
  ///
  /// In tr, this message translates to:
  /// **'Ürün güncellendi.'**
  String get ownerItemUpdated;

  /// L10n key: ownerArchiveItemConfirm
  ///
  /// In tr, this message translates to:
  /// **'Bu ürünü arşivlemek istiyor musun?'**
  String get ownerArchiveItemConfirm;

  /// L10n key: ownerItemArchived
  ///
  /// In tr, this message translates to:
  /// **'Ürün arşivlendi.'**
  String get ownerItemArchived;

  /// L10n key: ownerBulkPriceUpdate
  ///
  /// In tr, this message translates to:
  /// **'Toplu fiyat güncelle'**
  String get ownerBulkPriceUpdate;

  /// L10n key: ownerMethod
  ///
  /// In tr, this message translates to:
  /// **'Yöntem'**
  String get ownerMethod;

  /// L10n key: ownerPercent
  ///
  /// In tr, this message translates to:
  /// **'Yüzde'**
  String get ownerPercent;

  /// L10n key: ownerFixedAmountTl
  ///
  /// In tr, this message translates to:
  /// **'Sabit tutar (TL)'**
  String get ownerFixedAmountTl;

  /// L10n key: ownerOperation
  ///
  /// In tr, this message translates to:
  /// **'İşlem'**
  String get ownerOperation;

  /// L10n key: ownerIncrease
  ///
  /// In tr, this message translates to:
  /// **'Artır'**
  String get ownerIncrease;

  /// L10n key: ownerDecrease
  ///
  /// In tr, this message translates to:
  /// **'Azalt'**
  String get ownerDecrease;

  /// L10n key: ownerValuePercent
  ///
  /// In tr, this message translates to:
  /// **'Değer (%)'**
  String get ownerValuePercent;

  /// L10n key: ownerValueTl
  ///
  /// In tr, this message translates to:
  /// **'Değer (TL)'**
  String get ownerValueTl;

  /// L10n key: ownerEnterValidValue
  ///
  /// In tr, this message translates to:
  /// **'Lütfen geçerli bir değer gir.'**
  String get ownerEnterValidValue;

  /// L10n key: ownerUpdatedItemPrices
  ///
  /// In tr, this message translates to:
  /// **'{count} ürünün fiyatı güncellendi.'**
  String ownerUpdatedItemPrices(int count);

  /// L10n key: ownerCsvFormatHint
  ///
  /// In tr, this message translates to:
  /// **'Format: ad,fiyat,açıklama,para_birimi'**
  String get ownerCsvFormatHint;

  /// L10n key: ownerSelecting
  ///
  /// In tr, this message translates to:
  /// **'Seçiliyor...'**
  String get ownerSelecting;

  /// L10n key: ownerSelectFile
  ///
  /// In tr, this message translates to:
  /// **'Dosya Seç'**
  String get ownerSelectFile;

  /// L10n key: ownerCsvExample
  ///
  /// In tr, this message translates to:
  /// **'Döner,220,100 gr et,TRY'**
  String get ownerCsvExample;

  /// L10n key: ownerImportContent
  ///
  /// In tr, this message translates to:
  /// **'İçe Aktar'**
  String get ownerImportContent;

  /// L10n key: ownerNoValidRows
  ///
  /// In tr, this message translates to:
  /// **'Geçerli satır bulunamadı.'**
  String get ownerNoValidRows;

  /// L10n key: ownerImportedItems
  ///
  /// In tr, this message translates to:
  /// **'{success} ürün içe aktarıldı.'**
  String ownerImportedItems(int success);

  /// L10n key: ownerImportedItemsWithSkipped
  ///
  /// In tr, this message translates to:
  /// **'{success} ürün eklendi, {failed} satır atlandı.'**
  String ownerImportedItemsWithSkipped(int success, int failed);

  /// L10n key: ownerAreYouSure
  ///
  /// In tr, this message translates to:
  /// **'Emin misin?'**
  String get ownerAreYouSure;

  /// L10n key: ownerConfirm
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get ownerConfirm;

  /// L10n key: ownerArchiveAction
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get ownerArchiveAction;

  /// L10n key: ownerPublishAction
  ///
  /// In tr, this message translates to:
  /// **'Yayına Al'**
  String get ownerPublishAction;

  /// L10n key: ownerDelete
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get ownerDelete;

  /// L10n key: ownerItemName
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı'**
  String get ownerItemName;

  /// L10n key: ownerDescriptionOptional
  ///
  /// In tr, this message translates to:
  /// **'Açıklama (opsiyonel)'**
  String get ownerDescriptionOptional;

  /// L10n key: ownerPriceTl
  ///
  /// In tr, this message translates to:
  /// **'Fiyat (TL)'**
  String get ownerPriceTl;

  /// L10n key: ownerCurrency
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get ownerCurrency;

  /// L10n key: ownerCatalogSearch
  ///
  /// In tr, this message translates to:
  /// **'Katalog ara'**
  String get ownerCatalogSearch;

  /// L10n key: ownerCatalogSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Örn: Köfte, Burger...'**
  String get ownerCatalogSearchHint;

  /// L10n key: ownerSelectedCatalogId
  ///
  /// In tr, this message translates to:
  /// **'Seçili katalog ID: {id}'**
  String ownerSelectedCatalogId(int id);

  /// L10n key: ownerItemNameMin2
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı en az 2 karakter olmalı.'**
  String get ownerItemNameMin2;

  /// L10n key: ownerInvalidPrice
  ///
  /// In tr, this message translates to:
  /// **'Fiyat geçersiz.'**
  String get ownerInvalidPrice;

  /// L10n key: ownerVariants
  ///
  /// In tr, this message translates to:
  /// **'Varyantlar'**
  String get ownerVariants;

  /// L10n key: ownerAddVariant
  ///
  /// In tr, this message translates to:
  /// **'Varyant Ekle'**
  String get ownerAddVariant;

  /// L10n key: ownerNoVariantsHint
  ///
  /// In tr, this message translates to:
  /// **'Bu ürün için henüz varyant yok. Örnek: 80gr / 120gr'**
  String get ownerNoVariantsHint;

  /// L10n key: ownerDefaultVariant
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get ownerDefaultVariant;

  /// L10n key: ownerSetDefault
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan yap'**
  String get ownerSetDefault;

  /// L10n key: ownerLabelExample
  ///
  /// In tr, this message translates to:
  /// **'Etiket (örn: 120gr)'**
  String get ownerLabelExample;

  /// L10n key: ownerDefaultVariantSwitch
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan varyant'**
  String get ownerDefaultVariantSwitch;

  /// L10n key: ownerPhotos
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraflar'**
  String get ownerPhotos;

  /// L10n key: ownerUploading
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get ownerUploading;

  /// L10n key: ownerAddPhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Ekle'**
  String get ownerAddPhoto;

  /// L10n key: ownerNoPhotoYet
  ///
  /// In tr, this message translates to:
  /// **'Henüz fotoğraf yok.'**
  String get ownerNoPhotoYet;

  /// L10n key: ownerViewAll
  ///
  /// In tr, this message translates to:
  /// **'Tümünü gör'**
  String get ownerViewAll;

  /// L10n key: ownerPhotoUploaded
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf yüklendi.'**
  String get ownerPhotoUploaded;

  /// L10n key: ownerDeletePhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafı sil'**
  String get ownerDeletePhoto;

  /// L10n key: ownerDeletePhotoConfirm
  ///
  /// In tr, this message translates to:
  /// **'Bu fotoğraf silinecek.'**
  String get ownerDeletePhotoConfirm;

  /// L10n key: ownerPhotoDeleted
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf silindi.'**
  String get ownerPhotoDeleted;

  /// L10n key: adminAppealsTitle
  ///
  /// In tr, this message translates to:
  /// **'İtiraz Kuyruğu'**
  String get adminAppealsTitle;

  /// L10n key: adminAppealsEmptySla
  ///
  /// In tr, this message translates to:
  /// **'İtiraz yok. Hedef süre: rapor 24 saat, sahiplik talebi 48 saat.'**
  String get adminAppealsEmptySla;

  /// L10n key: adminAppealSourceAndUser
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: {sourceId} · Kullanıcı: {userId}'**
  String adminAppealSourceAndUser(String sourceId, String userId);

  /// L10n key: adminAppealDecisionTitle
  ///
  /// In tr, this message translates to:
  /// **'İtiraz Kararı · {id}'**
  String adminAppealDecisionTitle(String id);

  /// L10n key: adminAppealApproveAction
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get adminAppealApproveAction;

  /// L10n key: adminAppealRejectAction
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get adminAppealRejectAction;

  /// L10n key: adminAppealDecisionLabel
  ///
  /// In tr, this message translates to:
  /// **'Karar'**
  String get adminAppealDecisionLabel;

  /// L10n key: adminAppealTemplateLabel
  ///
  /// In tr, this message translates to:
  /// **'Hazır şablon'**
  String get adminAppealTemplateLabel;

  /// L10n key: adminAppealDecisionTextLabel
  ///
  /// In tr, this message translates to:
  /// **'Karar metni'**
  String get adminAppealDecisionTextLabel;

  /// L10n key: adminAppealDecisionTextHint
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcıya gösterilecek kısa açıklama'**
  String get adminAppealDecisionTextHint;

  /// L10n key: ownerNewBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme ekle'**
  String get ownerNewBusinessTitle;

  /// L10n key: ownerNewBusinessIntro
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletmeni eklemek için bilgileri doldur.'**
  String get ownerNewBusinessIntro;

  /// L10n key: ownerBusinessNameLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme adı'**
  String get ownerBusinessNameLabel;

  /// L10n key: ownerCategoryLabel
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get ownerCategoryLabel;

  /// L10n key: ownerAddressLabel
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get ownerAddressLabel;

  /// L10n key: ownerPhoneOptionalLabel
  ///
  /// In tr, this message translates to:
  /// **'Telefon (opsiyonel)'**
  String get ownerPhoneOptionalLabel;

  /// L10n key: ownerWebsiteOptionalLabel
  ///
  /// In tr, this message translates to:
  /// **'Web sitesi (opsiyonel)'**
  String get ownerWebsiteOptionalLabel;

  /// L10n key: ownerSubmitApplication
  ///
  /// In tr, this message translates to:
  /// **'Başvuruyu gönder'**
  String get ownerSubmitApplication;

  /// L10n key: ownerSubmitting
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor...'**
  String get ownerSubmitting;

  /// L10n key: ownerRequiredFieldsWarning
  ///
  /// In tr, this message translates to:
  /// **'Lütfen zorunlu alanları doldur.'**
  String get ownerRequiredFieldsWarning;

  /// L10n key: ownerApplicationReceived
  ///
  /// In tr, this message translates to:
  /// **'Başvuru alındı.'**
  String get ownerApplicationReceived;

  /// L10n key: ownerBusinessesTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletmelerim'**
  String get ownerBusinessesTitle;

  /// L10n key: ownerChainPage
  ///
  /// In tr, this message translates to:
  /// **'Zincir sayfası'**
  String get ownerChainPage;

  /// L10n key: ownerMyApplications
  ///
  /// In tr, this message translates to:
  /// **'Başvurularım'**
  String get ownerMyApplications;

  /// L10n key: ownerLinksUpdated
  ///
  /// In tr, this message translates to:
  /// **'Linkler güncellendi.'**
  String get ownerLinksUpdated;

  /// L10n key: ownerReservationOrderLinksTitle
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon ve sipariş linkleri'**
  String get ownerReservationOrderLinksTitle;

  /// L10n key: ownerReservationUrlLabel
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon URL'**
  String get ownerReservationUrlLabel;

  /// L10n key: ownerYemeksepetiUrlLabel
  ///
  /// In tr, this message translates to:
  /// **'Yemeksepeti URL'**
  String get ownerYemeksepetiUrlLabel;

  /// L10n key: ownerTrendyolGoUrlLabel
  ///
  /// In tr, this message translates to:
  /// **'Trendyol Go URL'**
  String get ownerTrendyolGoUrlLabel;

  /// L10n key: ownerGetirUrlLabel
  ///
  /// In tr, this message translates to:
  /// **'Getir URL'**
  String get ownerGetirUrlLabel;

  /// L10n key: ownerChainLabel
  ///
  /// In tr, this message translates to:
  /// **'Marka/Zincir'**
  String get ownerChainLabel;

  /// L10n key: ownerAllBranches
  ///
  /// In tr, this message translates to:
  /// **'Tüm şubeler'**
  String get ownerAllBranches;

  /// L10n key: ownerBranchLabel
  ///
  /// In tr, this message translates to:
  /// **'Şube'**
  String get ownerBranchLabel;

  /// L10n key: ownerChainPrefix
  ///
  /// In tr, this message translates to:
  /// **'Zincir: {chain}'**
  String ownerChainPrefix(String chain);

  /// L10n key: ownerPriceVerificationAction
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulama'**
  String get ownerPriceVerificationAction;

  /// L10n key: ownerRequestsAction
  ///
  /// In tr, this message translates to:
  /// **'Talepler'**
  String get ownerRequestsAction;

  /// L10n key: ownerRequestsOwnerOnly
  ///
  /// In tr, this message translates to:
  /// **'Talepler (yalnızca işletme sahibi)'**
  String get ownerRequestsOwnerOnly;

  /// L10n key: ownerReservationOrderLinksAction
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon ve sipariş linkleri'**
  String get ownerReservationOrderLinksAction;

  /// L10n key: ownerStatsNotFound
  ///
  /// In tr, this message translates to:
  /// **'İstatistik bulunamadı.'**
  String get ownerStatsNotFound;

  /// L10n key: ownerPerformanceLast30Days
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün performans'**
  String get ownerPerformanceLast30Days;

  /// L10n key: ownerMetricMenuViews
  ///
  /// In tr, this message translates to:
  /// **'Menü görüntülenme'**
  String get ownerMetricMenuViews;

  /// L10n key: ownerMetricQrScans
  ///
  /// In tr, this message translates to:
  /// **'QR tarama'**
  String get ownerMetricQrScans;

  /// L10n key: ownerMetricSearchImpressions
  ///
  /// In tr, this message translates to:
  /// **'Arama gösterimi'**
  String get ownerMetricSearchImpressions;

  /// L10n key: ownerMetricConversion
  ///
  /// In tr, this message translates to:
  /// **'Dönüşüm'**
  String get ownerMetricConversion;

  /// L10n key: ownerMetricOutboundClicks
  ///
  /// In tr, this message translates to:
  /// **'Dış bağlantı tıklamaları'**
  String get ownerMetricOutboundClicks;

  /// L10n key: ownerMetricPriceDropoff
  ///
  /// In tr, this message translates to:
  /// **'Fiyat nedeniyle vazgeçme (tahmini)'**
  String get ownerMetricPriceDropoff;

  /// L10n key: ownerMetricPriceVsCompetitors
  ///
  /// In tr, this message translates to:
  /// **'Rakibe göre fiyat'**
  String get ownerMetricPriceVsCompetitors;

  /// L10n key: ownerOutboundClicksValue
  ///
  /// In tr, this message translates to:
  /// **'{outbound} (Rez: {reservation}, Sipariş: {order})'**
  String ownerOutboundClicksValue(int outbound, int reservation, int order);

  /// L10n key: ownerPricePositionHigher
  ///
  /// In tr, this message translates to:
  /// **'Daha pahalı{pct}'**
  String ownerPricePositionHigher(String pct);

  /// L10n key: ownerPricePositionLower
  ///
  /// In tr, this message translates to:
  /// **'Daha uygun{pct}'**
  String ownerPricePositionLower(String pct);

  /// L10n key: ownerPricePositionSimilar
  ///
  /// In tr, this message translates to:
  /// **'Pazarla uyumlu'**
  String get ownerPricePositionSimilar;

  /// L10n key: ownerPricePositionNoData
  ///
  /// In tr, this message translates to:
  /// **'Yeterli veri yok'**
  String get ownerPricePositionNoData;

  /// L10n key: ownerNoBusinessesTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz işletme yok'**
  String get ownerNoBusinessesTitle;

  /// L10n key: ownerNoBusinessesDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme başvurusu oluşturabilirsin.'**
  String get ownerNoBusinessesDescription;

  /// L10n key: ownerRoleOwner
  ///
  /// In tr, this message translates to:
  /// **'İşletme sahibi'**
  String get ownerRoleOwner;

  /// L10n key: ownerRoleManager
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get ownerRoleManager;

  /// L10n key: ownerMenuAction
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get ownerMenuAction;

  /// L10n key: city
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get city;

  /// L10n key: district
  ///
  /// In tr, this message translates to:
  /// **'İlçe'**
  String get district;

  /// L10n key: ownerActiveRange
  ///
  /// In tr, this message translates to:
  /// **'Aktif: {from} - {to}'**
  String ownerActiveRange(String from, String to);

  /// L10n key: webHomeSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Canlı menü, fiyat şeffaflığı ve topluluk doğrulama platformu.'**
  String get webHomeSubtitle;

  /// L10n key: webHomeNextLinkLabel
  ///
  /// In tr, this message translates to:
  /// **'QR Menü Web (Next.js)'**
  String get webHomeNextLinkLabel;

  /// L10n key: webHomeBusinessAreaTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme Alanı'**
  String get webHomeBusinessAreaTitle;

  /// L10n key: webHomeBusinessAreaSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Panele erişmek için işletme veya admin hesabınla giriş yap.'**
  String get webHomeBusinessAreaSubtitle;

  /// L10n key: webHomeBusinessLogin
  ///
  /// In tr, this message translates to:
  /// **'İşletme Girişi'**
  String get webHomeBusinessLogin;

  /// L10n key: webHomeBusinessRegister
  ///
  /// In tr, this message translates to:
  /// **'İşletme Kaydı'**
  String get webHomeBusinessRegister;

  /// L10n key: businessAuthEmailLabel
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get businessAuthEmailLabel;

  /// L10n key: businessAuthPasswordLabel
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get businessAuthPasswordLabel;

  /// L10n key: businessAuthPasswordRepeatLabel
  ///
  /// In tr, this message translates to:
  /// **'Şifre (tekrar)'**
  String get businessAuthPasswordRepeatLabel;

  /// L10n key: businessLoginTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme Girişi'**
  String get businessLoginTitle;

  /// L10n key: businessLoginIntro
  ///
  /// In tr, this message translates to:
  /// **'İşletme sahibi veya admin paneline erişmek için giriş yap.'**
  String get businessLoginIntro;

  /// L10n key: businessLoginNoPermissionError
  ///
  /// In tr, this message translates to:
  /// **'Bu hesapta işletme veya admin yetkisi bulunamadı. İşletme kaydı ile devam edebilirsin.'**
  String get businessLoginNoPermissionError;

  /// L10n key: businessLoginSubmitting
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılıyor...'**
  String get businessLoginSubmitting;

  /// L10n key: businessLoginGoRegister
  ///
  /// In tr, this message translates to:
  /// **'İşletme Kaydına Git'**
  String get businessLoginGoRegister;

  /// L10n key: businessRegisterTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme Kaydı'**
  String get businessRegisterTitle;

  /// L10n key: businessRegisterIntro
  ///
  /// In tr, this message translates to:
  /// **'İşletme paneline erişmek için kayıt oluştur.'**
  String get businessRegisterIntro;

  /// L10n key: businessRegisterPasswordMinError
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı.'**
  String get businessRegisterPasswordMinError;

  /// L10n key: businessRegisterPasswordMismatchError
  ///
  /// In tr, this message translates to:
  /// **'Şifreler aynı değil.'**
  String get businessRegisterPasswordMismatchError;

  /// L10n key: businessRegisterSuccess
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuldu. Doğrulama adımını tamamladıktan sonra işletme girişi yapabilirsin.'**
  String get businessRegisterSuccess;

  /// L10n key: businessRegisterSubmitting
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuluyor...'**
  String get businessRegisterSubmitting;

  /// L10n key: businessRegisterBackToLogin
  ///
  /// In tr, this message translates to:
  /// **'İşletme Girişine Dön'**
  String get businessRegisterBackToLogin;

  /// L10n key: close
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// L10n key: adminSponsorshipCreateTitle
  ///
  /// In tr, this message translates to:
  /// **'Sponsorluk oluştur'**
  String get adminSponsorshipCreateTitle;

  /// L10n key: adminSponsorshipSurfaceLabel
  ///
  /// In tr, this message translates to:
  /// **'Gösterim alanı'**
  String get adminSponsorshipSurfaceLabel;

  /// L10n key: adminSponsorshipSurfaceDiscovery
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get adminSponsorshipSurfaceDiscovery;

  /// L10n key: adminSponsorshipSurfaceBusinessPage
  ///
  /// In tr, this message translates to:
  /// **'İşletme sayfası'**
  String get adminSponsorshipSurfaceBusinessPage;

  /// L10n key: adminSponsorshipPackageLabel
  ///
  /// In tr, this message translates to:
  /// **'Paket'**
  String get adminSponsorshipPackageLabel;

  /// L10n key: adminSponsorshipPackageOption
  ///
  /// In tr, this message translates to:
  /// **'{name} • {days} gün'**
  String adminSponsorshipPackageOption(String name, int days);

  /// L10n key: adminSponsorshipStartDateLabel
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç (YYYY-MM-DD)'**
  String get adminSponsorshipStartDateLabel;

  /// L10n key: adminSponsorshipEndDateLabel
  ///
  /// In tr, this message translates to:
  /// **'Bitiş (YYYY-MM-DD)'**
  String get adminSponsorshipEndDateLabel;

  /// L10n key: adminSponsorshipDailyCapLabel
  ///
  /// In tr, this message translates to:
  /// **'Günlük limit'**
  String get adminSponsorshipDailyCapLabel;

  /// L10n key: adminSponsorshipTotalCapLabel
  ///
  /// In tr, this message translates to:
  /// **'Toplam limit'**
  String get adminSponsorshipTotalCapLabel;

  /// L10n key: adminSponsorshipPriorityOptionalLabel
  ///
  /// In tr, this message translates to:
  /// **'Öncelik (opsiyonel)'**
  String get adminSponsorshipPriorityOptionalLabel;

  /// L10n key: adminSponsorshipTargetingTitle
  ///
  /// In tr, this message translates to:
  /// **'Hedefleme'**
  String get adminSponsorshipTargetingTitle;

  /// L10n key: adminSponsorshipSearchBusinessHint
  ///
  /// In tr, this message translates to:
  /// **'İşletme ara (isim veya adres)'**
  String get adminSponsorshipSearchBusinessHint;

  /// L10n key: adminSponsorshipSearchAction
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get adminSponsorshipSearchAction;

  /// L10n key: adminSponsorshipSearchingAction
  ///
  /// In tr, this message translates to:
  /// **'Aranıyor...'**
  String get adminSponsorshipSearchingAction;

  /// L10n key: adminSponsorshipRemoveBusinessAction
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get adminSponsorshipRemoveBusinessAction;

  /// L10n key: adminSponsorshipAddTargetingValueAction
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get adminSponsorshipAddTargetingValueAction;

  /// L10n key: adminSponsorshipCreateAction
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get adminSponsorshipCreateAction;

  /// L10n key: adminSponsorshipSavingAction
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get adminSponsorshipSavingAction;

  /// L10n key: adminSponsorshipSelectBusinessError
  ///
  /// In tr, this message translates to:
  /// **'İşletme seçin.'**
  String get adminSponsorshipSelectBusinessError;

  /// L10n key: adminSponsorshipSelectPackageError
  ///
  /// In tr, this message translates to:
  /// **'Paket seçin.'**
  String get adminSponsorshipSelectPackageError;

  /// L10n key: adminSponsorshipCreated
  ///
  /// In tr, this message translates to:
  /// **'Sponsorluk oluşturuldu.'**
  String get adminSponsorshipCreated;

  /// L10n key: adminNewItemsBannerLabel
  ///
  /// In tr, this message translates to:
  /// **'{label} (+{count})'**
  String adminNewItemsBannerLabel(String label, int count);

  /// L10n key: adminRiskQueueTitle
  ///
  /// In tr, this message translates to:
  /// **'Riskli kullanıcılar'**
  String get adminRiskQueueTitle;

  /// L10n key: adminRiskQueueScoreThreshold
  ///
  /// In tr, this message translates to:
  /// **'Skor >= {score}'**
  String adminRiskQueueScoreThreshold(int score);

  /// L10n key: adminRiskQueueFilterLabel
  ///
  /// In tr, this message translates to:
  /// **'Filtre'**
  String get adminRiskQueueFilterLabel;

  /// L10n key: adminRiskQueueEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Riskli kullanıcı yok'**
  String get adminRiskQueueEmptyTitle;

  /// L10n key: adminRiskQueueEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu filtre için şu anda işlem gerektiren kullanıcı yok.'**
  String get adminRiskQueueEmptyDescription;

  /// L10n key: adminRiskQueueReasonDialogTitle
  ///
  /// In tr, this message translates to:
  /// **'Aksiyon nedeni'**
  String get adminRiskQueueReasonDialogTitle;

  /// L10n key: adminRiskQueueActionWithName
  ///
  /// In tr, this message translates to:
  /// **'Aksiyon: {action}'**
  String adminRiskQueueActionWithName(String action);

  /// L10n key: adminRiskQueueReasonLabel
  ///
  /// In tr, this message translates to:
  /// **'Gerekçe (zorunlu)'**
  String get adminRiskQueueReasonLabel;

  /// L10n key: adminRiskQueueReasonHint
  ///
  /// In tr, this message translates to:
  /// **'Kısa bir açıklama girin'**
  String get adminRiskQueueReasonHint;

  /// L10n key: adminRiskQueueCopyUserId
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı kimliğini kopyala'**
  String get adminRiskQueueCopyUserId;

  /// L10n key: adminRiskQueueSignalCount
  ///
  /// In tr, this message translates to:
  /// **'Sinyal: {count}'**
  String adminRiskQueueSignalCount(int count);

  /// L10n key: adminRiskQueueNewAccountHits
  ///
  /// In tr, this message translates to:
  /// **'Yeni hesap: {count}'**
  String adminRiskQueueNewAccountHits(int count);

  /// L10n key: adminRiskQueueDeviceChangeHits
  ///
  /// In tr, this message translates to:
  /// **'Cihaz değişimi: {count}'**
  String adminRiskQueueDeviceChangeHits(int count);

  /// L10n key: adminRiskQueueSameIpHits
  ///
  /// In tr, this message translates to:
  /// **'IP yoğunluğu: {count}'**
  String adminRiskQueueSameIpHits(int count);

  /// L10n key: adminRiskQueueDuplicateTextHits
  ///
  /// In tr, this message translates to:
  /// **'Kopya metin: {count}'**
  String adminRiskQueueDuplicateTextHits(int count);

  /// L10n key: adminRiskQueueSoftLimitAction
  ///
  /// In tr, this message translates to:
  /// **'Yumuşak limit {minutes} dk'**
  String adminRiskQueueSoftLimitAction(int minutes);

  /// L10n key: adminRiskQueueAutoPendingAction
  ///
  /// In tr, this message translates to:
  /// **'Otomatik bekleme {hours} sa'**
  String adminRiskQueueAutoPendingAction(int hours);

  /// L10n key: adminRiskQueueShadowBanAction
  ///
  /// In tr, this message translates to:
  /// **'Gölge yasak {hours} sa'**
  String adminRiskQueueShadowBanAction(int hours);

  /// L10n key: adminRiskQueueClearAction
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get adminRiskQueueClearAction;

  /// L10n key: adminRiskQueueScoreLabel
  ///
  /// In tr, this message translates to:
  /// **'Skor {score}'**
  String adminRiskQueueScoreLabel(int score);

  /// L10n key: adminAuditTitle
  ///
  /// In tr, this message translates to:
  /// **'Denetim kaydı'**
  String get adminAuditTitle;

  /// L10n key: adminAuditOwnerTitle
  ///
  /// In tr, this message translates to:
  /// **'İşlem geçmişi'**
  String get adminAuditOwnerTitle;

  /// L10n key: adminAuditRecordCount
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt'**
  String adminAuditRecordCount(int count);

  /// L10n key: adminAuditEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı'**
  String get adminAuditEmptyTitle;

  /// L10n key: adminAuditEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri genişletip tekrar deneyin.'**
  String get adminAuditEmptyDescription;

  /// L10n key: adminAuditClearFilters
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri temizle'**
  String get adminAuditClearFilters;

  /// L10n key: adminAuditCreatedAtColumn
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma'**
  String get adminAuditCreatedAtColumn;

  /// L10n key: adminAuditActionColumn
  ///
  /// In tr, this message translates to:
  /// **'Aksiyon'**
  String get adminAuditActionColumn;

  /// L10n key: adminAuditTargetTypeColumn
  ///
  /// In tr, this message translates to:
  /// **'Hedef tür'**
  String get adminAuditTargetTypeColumn;

  /// L10n key: adminAuditTargetIdColumn
  ///
  /// In tr, this message translates to:
  /// **'Hedef ID'**
  String get adminAuditTargetIdColumn;

  /// L10n key: adminAuditActorColumn
  ///
  /// In tr, this message translates to:
  /// **'Aktör'**
  String get adminAuditActorColumn;

  /// L10n key: adminAuditDetailsAction
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get adminAuditDetailsAction;

  /// L10n key: adminAuditCopyTargetId
  ///
  /// In tr, this message translates to:
  /// **'Hedef kimliğini kopyala'**
  String get adminAuditCopyTargetId;

  /// L10n key: adminAuditCopied
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı.'**
  String get adminAuditCopied;

  /// L10n key: adminAuditDetailsTitle
  ///
  /// In tr, this message translates to:
  /// **'Denetim detayı'**
  String get adminAuditDetailsTitle;

  /// L10n key: adminAuditActorIdLabel
  ///
  /// In tr, this message translates to:
  /// **'Aktör ID'**
  String get adminAuditActorIdLabel;

  /// L10n key: adminAuditActorRoleLabel
  ///
  /// In tr, this message translates to:
  /// **'Aktör rolü'**
  String get adminAuditActorRoleLabel;

  /// L10n key: adminAuditBeforeAfterTitle
  ///
  /// In tr, this message translates to:
  /// **'Önce / Sonra'**
  String get adminAuditBeforeAfterTitle;

  /// L10n key: adminAuditDiffFieldLabel
  ///
  /// In tr, this message translates to:
  /// **'Alan'**
  String get adminAuditDiffFieldLabel;

  /// L10n key: adminAuditDiffBeforeLabel
  ///
  /// In tr, this message translates to:
  /// **'Önce'**
  String get adminAuditDiffBeforeLabel;

  /// L10n key: adminAuditDiffAfterLabel
  ///
  /// In tr, this message translates to:
  /// **'Sonra'**
  String get adminAuditDiffAfterLabel;

  /// L10n key: adminAuditDiffNoChanges
  ///
  /// In tr, this message translates to:
  /// **'Alan bazlı fark bulunamadı. Gerekirse aşağıdaki ham JSON kaydını inceleyebilirsin.'**
  String get adminAuditDiffNoChanges;

  /// L10n key: adminAuditDiffRootField
  ///
  /// In tr, this message translates to:
  /// **'Kayıt'**
  String get adminAuditDiffRootField;

  /// L10n key: adminAuditRawBeforeTitle
  ///
  /// In tr, this message translates to:
  /// **'Ham önce verisi'**
  String get adminAuditRawBeforeTitle;

  /// L10n key: adminAuditRawAfterTitle
  ///
  /// In tr, this message translates to:
  /// **'Ham sonra verisi'**
  String get adminAuditRawAfterTitle;

  /// L10n key: adminAuditMetaTitle
  ///
  /// In tr, this message translates to:
  /// **'Meta'**
  String get adminAuditMetaTitle;

  /// L10n key: adminAuditActionFilterAll
  ///
  /// In tr, this message translates to:
  /// **'Aksiyon (tümü)'**
  String get adminAuditActionFilterAll;

  /// L10n key: adminAuditTargetTypeFilterAll
  ///
  /// In tr, this message translates to:
  /// **'Tablo (tümü)'**
  String get adminAuditTargetTypeFilterAll;

  /// L10n key: adminAuditRelativeNow
  ///
  /// In tr, this message translates to:
  /// **'Şimdi'**
  String get adminAuditRelativeNow;

  /// L10n key: adminAuditRelativeMinutes
  ///
  /// In tr, this message translates to:
  /// **'{count} dk'**
  String adminAuditRelativeMinutes(int count);

  /// L10n key: adminAuditRelativeHours
  ///
  /// In tr, this message translates to:
  /// **'{count} sa'**
  String adminAuditRelativeHours(int count);

  /// L10n key: adminAuditRelativeDays
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String adminAuditRelativeDays(int count);

  /// L10n key: adminAuditRelativeWeeks
  ///
  /// In tr, this message translates to:
  /// **'{count} hf'**
  String adminAuditRelativeWeeks(int count);

  /// L10n key: adminAuditRelativeMonths
  ///
  /// In tr, this message translates to:
  /// **'{count} ay'**
  String adminAuditRelativeMonths(int count);

  /// L10n key: adminB2bExportsTitle
  ///
  /// In tr, this message translates to:
  /// **'B2B veri ihracı'**
  String get adminB2bExportsTitle;

  /// L10n key: adminB2bExportsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'B2B içgörüleri için fiyat endeksi ve bölgesel trend raporlarını CSV olarak indirebilirsiniz.'**
  String get adminB2bExportsSubtitle;

  /// L10n key: adminB2bExportsPriceIndexChip
  ///
  /// In tr, this message translates to:
  /// **'Fiyat endeksi'**
  String get adminB2bExportsPriceIndexChip;

  /// L10n key: adminB2bExportsRegionalTrendChip
  ///
  /// In tr, this message translates to:
  /// **'Bölgesel trend'**
  String get adminB2bExportsRegionalTrendChip;

  /// L10n key: adminB2bExportsMenuInflationChip
  ///
  /// In tr, this message translates to:
  /// **'Menü enflasyonu'**
  String get adminB2bExportsMenuInflationChip;

  /// L10n key: adminB2bExportsPeriodLabel
  ///
  /// In tr, this message translates to:
  /// **'Dönem:'**
  String get adminB2bExportsPeriodLabel;

  /// L10n key: adminB2bExportsDayOption
  ///
  /// In tr, this message translates to:
  /// **'{days} gün'**
  String adminB2bExportsDayOption(int days);

  /// L10n key: adminB2bExportsAnonymousTrendsTitle
  ///
  /// In tr, this message translates to:
  /// **'Anonim trend verisi'**
  String get adminB2bExportsAnonymousTrendsTitle;

  /// L10n key: adminB2bExportsAnonymousTrendsDescription
  ///
  /// In tr, this message translates to:
  /// **'Gün, şehir, ilçe ve etkinlik bazında anonimleştirilmiş trend kaydı.'**
  String get adminB2bExportsAnonymousTrendsDescription;

  /// L10n key: adminB2bExportsRegionalPriceIndexTitle
  ///
  /// In tr, this message translates to:
  /// **'Bölgesel fiyat endeksi'**
  String get adminB2bExportsRegionalPriceIndexTitle;

  /// L10n key: adminB2bExportsRegionalPriceIndexDescription
  ///
  /// In tr, this message translates to:
  /// **'Şehir ve ilçe bazında ortalama, medyan fiyat ve önceki döneme göre değişim.'**
  String get adminB2bExportsRegionalPriceIndexDescription;

  /// L10n key: adminB2bExportsMenuInflationTitle
  ///
  /// In tr, this message translates to:
  /// **'Menü enflasyonu raporu'**
  String get adminB2bExportsMenuInflationTitle;

  /// L10n key: adminB2bExportsMenuInflationDescription
  ///
  /// In tr, this message translates to:
  /// **'Ürün bazında dönem içindeki ilk ve son fiyat ile enflasyon yüzdesi.'**
  String get adminB2bExportsMenuInflationDescription;

  /// L10n key: adminB2bExportsPriceAnomaliesTitle
  ///
  /// In tr, this message translates to:
  /// **'Fiyat anomali raporu'**
  String get adminB2bExportsPriceAnomaliesTitle;

  /// L10n key: adminB2bExportsPriceAnomaliesDescription
  ///
  /// In tr, this message translates to:
  /// **'Kısa sürede aşırı fiyat artışı yaşayan ürünleri listeler.'**
  String get adminB2bExportsPriceAnomaliesDescription;

  /// L10n key: adminB2bExportsPreparingAction
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor...'**
  String get adminB2bExportsPreparingAction;

  /// L10n key: adminB2bExportsDownloadCsvAction
  ///
  /// In tr, this message translates to:
  /// **'CSV indir'**
  String get adminB2bExportsDownloadCsvAction;

  /// L10n key: adminB2bExportsGovernanceTitle
  ///
  /// In tr, this message translates to:
  /// **'Veri urunu siniri'**
  String get adminB2bExportsGovernanceTitle;

  /// L10n key: adminB2bExportsGovernanceDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu ekran tum exportlari ayni ticari seviyede gormez; her dataset hangi urun hattina ait oldugu ve ne kadar anonimlestirildigi ile siniflandirilir.'**
  String get adminB2bExportsGovernanceDescription;

  /// L10n key: adminB2bExportsGovernanceAnonymousRule
  ///
  /// In tr, this message translates to:
  /// **'Anonymous aggregate: ham kullanici kimligi, cihaz kimligi veya tek isletmeye geri donen izler disari cikmaz.'**
  String get adminB2bExportsGovernanceAnonymousRule;

  /// L10n key: adminB2bExportsGovernanceRestrictedRule
  ///
  /// In tr, this message translates to:
  /// **'Restricted aggregate: isletme veya urun seviyesinde sinyal vardir; owner premium raporlama icin adaydir, dis satista ek gozden gecirme gerekir.'**
  String get adminB2bExportsGovernanceRestrictedRule;

  /// L10n key: adminB2bExportsGovernanceContractRule
  ///
  /// In tr, this message translates to:
  /// **'Contract only: anomali ve hassas veri setleri varsayilan olarak yalnizca ic operasyon veya sozmeli analiz akisi icin kullanilir.'**
  String get adminB2bExportsGovernanceContractRule;

  /// L10n key: adminB2bExportsLaneLabel
  ///
  /// In tr, this message translates to:
  /// **'Urun hatti'**
  String get adminB2bExportsLaneLabel;

  /// L10n key: adminB2bExportsPrivacyLabel
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik sinifi'**
  String get adminB2bExportsPrivacyLabel;

  /// L10n key: adminB2bExportsFreshnessLabel
  ///
  /// In tr, this message translates to:
  /// **'Tazelik'**
  String get adminB2bExportsFreshnessLabel;

  /// L10n key: adminB2bExportsLaneInternalOps
  ///
  /// In tr, this message translates to:
  /// **'Ic operasyon'**
  String get adminB2bExportsLaneInternalOps;

  /// L10n key: adminB2bExportsLanePremiumCandidate
  ///
  /// In tr, this message translates to:
  /// **'Premium raporlama adayi'**
  String get adminB2bExportsLanePremiumCandidate;

  /// L10n key: adminB2bExportsLaneExternalCandidate
  ///
  /// In tr, this message translates to:
  /// **'Dis veri urunu adayi'**
  String get adminB2bExportsLaneExternalCandidate;

  /// L10n key: adminB2bExportsPrivacyAnonymousAggregate
  ///
  /// In tr, this message translates to:
  /// **'Anonymous aggregate'**
  String get adminB2bExportsPrivacyAnonymousAggregate;

  /// L10n key: adminB2bExportsPrivacyRestrictedAggregate
  ///
  /// In tr, this message translates to:
  /// **'Restricted aggregate'**
  String get adminB2bExportsPrivacyRestrictedAggregate;

  /// L10n key: adminB2bExportsPrivacyContractOnly
  ///
  /// In tr, this message translates to:
  /// **'Contract only'**
  String get adminB2bExportsPrivacyContractOnly;

  /// L10n key: adminB2bExportsFreshnessDailySeries
  ///
  /// In tr, this message translates to:
  /// **'Gunluk seri'**
  String get adminB2bExportsFreshnessDailySeries;

  /// L10n key: adminB2bExportsFreshnessRollingWindow
  ///
  /// In tr, this message translates to:
  /// **'Rolling window'**
  String get adminB2bExportsFreshnessRollingWindow;

  /// L10n key: adminB2bExportsStatusInternalReady
  ///
  /// In tr, this message translates to:
  /// **'Ic kullanim hazir'**
  String get adminB2bExportsStatusInternalReady;

  /// L10n key: adminB2bExportsStatusPremiumCandidate
  ///
  /// In tr, this message translates to:
  /// **'Premium paket adayi'**
  String get adminB2bExportsStatusPremiumCandidate;

  /// L10n key: adminB2bExportsStatusExternalCandidate
  ///
  /// In tr, this message translates to:
  /// **'Dis satis adayi'**
  String get adminB2bExportsStatusExternalCandidate;

  /// L10n key: adminBusinessSubmissionsStatusLabel
  ///
  /// In tr, this message translates to:
  /// **'Durum:'**
  String get adminBusinessSubmissionsStatusLabel;

  /// L10n key: adminBusinessSubmissionsNewStatus
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get adminBusinessSubmissionsNewStatus;

  /// L10n key: adminBusinessSubmissionsEmpty
  ///
  /// In tr, this message translates to:
  /// **'Başvuru bulunamadı.'**
  String get adminBusinessSubmissionsEmpty;

  /// L10n key: adminBusinessSubmissionsApproveConfirm
  ///
  /// In tr, this message translates to:
  /// **'Başvuruyu onaylamak istiyor musun?'**
  String get adminBusinessSubmissionsApproveConfirm;

  /// L10n key: adminBusinessSubmissionsOptionalNoteLabel
  ///
  /// In tr, this message translates to:
  /// **'Not (opsiyonel)'**
  String get adminBusinessSubmissionsOptionalNoteLabel;

  /// L10n key: adminBusinessesTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletmeler'**
  String get adminBusinessesTitle;

  /// L10n key: adminBusinessesSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Ara (isim, adres)'**
  String get adminBusinessesSearchHint;

  /// L10n key: adminBusinessesLogoColumn
  ///
  /// In tr, this message translates to:
  /// **'Logo'**
  String get adminBusinessesLogoColumn;

  /// L10n key: adminBusinessesNameColumn
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get adminBusinessesNameColumn;

  /// L10n key: adminBusinessesRiskColumn
  ///
  /// In tr, this message translates to:
  /// **'Risk'**
  String get adminBusinessesRiskColumn;

  /// L10n key: adminBusinessesCreatedAtColumn
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma'**
  String get adminBusinessesCreatedAtColumn;

  /// L10n key: adminBusinessesAssignedColumn
  ///
  /// In tr, this message translates to:
  /// **'Atanan'**
  String get adminBusinessesAssignedColumn;

  /// L10n key: adminBusinessesMergeAction
  ///
  /// In tr, this message translates to:
  /// **'Birleştir'**
  String get adminBusinessesMergeAction;

  /// L10n key: adminBusinessesQrMenuAction
  ///
  /// In tr, this message translates to:
  /// **'Dijital Menü ve QR'**
  String get adminBusinessesQrMenuAction;

  /// L10n key: adminBusinessesPublicMenuAction
  ///
  /// In tr, this message translates to:
  /// **'Public menü linki'**
  String get adminBusinessesPublicMenuAction;

  /// L10n key: adminBusinessesEmpty
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı.'**
  String get adminBusinessesEmpty;

  /// L10n key: adminBusinessesUpdated
  ///
  /// In tr, this message translates to:
  /// **'Güncellendi.'**
  String get adminBusinessesUpdated;

  /// L10n key: adminBusinessesEditTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletmeyi düzenle'**
  String get adminBusinessesEditTitle;

  /// L10n key: adminBusinessesPublicMenuLinkLabel
  ///
  /// In tr, this message translates to:
  /// **'Public menü bağlantısı'**
  String get adminBusinessesPublicMenuLinkLabel;

  /// L10n key: adminBusinessesQrGenerationLinkLabel
  ///
  /// In tr, this message translates to:
  /// **'QR üretim bağlantısı'**
  String get adminBusinessesQrGenerationLinkLabel;

  /// L10n key: adminBusinessesCopyMenuLinkAction
  ///
  /// In tr, this message translates to:
  /// **'Menü linkini kopyala'**
  String get adminBusinessesCopyMenuLinkAction;

  /// L10n key: adminBusinessesInfoTab
  ///
  /// In tr, this message translates to:
  /// **'Bilgi'**
  String get adminBusinessesInfoTab;

  /// L10n key: adminBusinessesMediaTab
  ///
  /// In tr, this message translates to:
  /// **'Medya'**
  String get adminBusinessesMediaTab;

  /// L10n key: adminBusinessesLatitudeLabel
  ///
  /// In tr, this message translates to:
  /// **'Enlem'**
  String get adminBusinessesLatitudeLabel;

  /// L10n key: adminBusinessesLongitudeLabel
  ///
  /// In tr, this message translates to:
  /// **'Boylam'**
  String get adminBusinessesLongitudeLabel;

  /// L10n key: adminBusinessesUploadMediaAction
  ///
  /// In tr, this message translates to:
  /// **'Yükle'**
  String get adminBusinessesUploadMediaAction;

  /// L10n key: adminBusinessesClearAction
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get adminBusinessesClearAction;

  /// L10n key: adminBusinessesLogoUrlLabel
  ///
  /// In tr, this message translates to:
  /// **'Logo URL'**
  String get adminBusinessesLogoUrlLabel;

  /// L10n key: adminBusinessesCoverLabel
  ///
  /// In tr, this message translates to:
  /// **'Kapak'**
  String get adminBusinessesCoverLabel;

  /// L10n key: adminBusinessesCoverUrlLabel
  ///
  /// In tr, this message translates to:
  /// **'Kapak URL'**
  String get adminBusinessesCoverUrlLabel;

  /// L10n key: adminBusinessesPublicMenuCopied
  ///
  /// In tr, this message translates to:
  /// **'Public menü linki kopyalandı.'**
  String get adminBusinessesPublicMenuCopied;

  /// L10n key: adminBusinessesStatusNeedsReview
  ///
  /// In tr, this message translates to:
  /// **'İnceleme gerekli'**
  String get adminBusinessesStatusNeedsReview;

  /// L10n key: adminBusinessesEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme bulunamadı'**
  String get adminBusinessesEmptyTitle;

  /// L10n key: adminBusinessesEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri temizleyip farklı bir arama deneyin.'**
  String get adminBusinessesEmptyDescription;

  /// L10n key: adminBusinessesErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletmeler yüklenemedi'**
  String get adminBusinessesErrorTitle;

  /// L10n key: adminBusinessesVerificationUpdatedCount
  ///
  /// In tr, this message translates to:
  /// **'Seçili {count} işletmenin doğrulama durumu güncellendi.'**
  String adminBusinessesVerificationUpdatedCount(int count);

  /// L10n key: adminBusinessesAssignedCount
  ///
  /// In tr, this message translates to:
  /// **'Seçili {count} işletmenin atama durumu güncellendi.'**
  String adminBusinessesAssignedCount(int count);

  /// L10n key: adminBusinessesBulkStatusLabel
  ///
  /// In tr, this message translates to:
  /// **'Toplu durum'**
  String get adminBusinessesBulkStatusLabel;

  /// L10n key: adminBusinessesBulkStatusVerified
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı olarak işaretle'**
  String get adminBusinessesBulkStatusVerified;

  /// L10n key: adminBusinessesBulkStatusNeedsReview
  ///
  /// In tr, this message translates to:
  /// **'İnceleme gerekli olarak işaretle'**
  String get adminBusinessesBulkStatusNeedsReview;

  /// L10n key: adminBusinessesBulkStatusUnassigned
  ///
  /// In tr, this message translates to:
  /// **'Atamayı kaldır'**
  String get adminBusinessesBulkStatusUnassigned;

  /// L10n key: adminBusinessesNoMergeCandidates
  ///
  /// In tr, this message translates to:
  /// **'Birleştirme adayı bulunamadı.'**
  String get adminBusinessesNoMergeCandidates;

  /// L10n key: adminBusinessesMergeSuggestedNote
  ///
  /// In tr, this message translates to:
  /// **'Aynı işletme kaydı olabilir. Birleştirme kontrolü önerildi.'**
  String get adminBusinessesMergeSuggestedNote;

  /// L10n key: adminBusinessesMergeCandidateTitle
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" için birleştirme adayı seçin'**
  String adminBusinessesMergeCandidateTitle(String name);

  /// L10n key: adminBusinessesMergeApplyNowTitle
  ///
  /// In tr, this message translates to:
  /// **'Anında birleştir (zorla birleştir)'**
  String get adminBusinessesMergeApplyNowTitle;

  /// L10n key: adminBusinessesMergeApplyNowDescription
  ///
  /// In tr, this message translates to:
  /// **'Kapalıysa yalnızca merge talebi denetim kaydına yazılır.'**
  String get adminBusinessesMergeApplyNowDescription;

  /// L10n key: adminBusinessesMergePreviewAction
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get adminBusinessesMergePreviewAction;

  /// L10n key: adminBusinessesMergePreviewSummary
  ///
  /// In tr, this message translates to:
  /// **'Önizleme: menüler {menus}, ürünler {items}, yorumlar {reviews}, medya {media}'**
  String adminBusinessesMergePreviewSummary(
    int menus,
    int items,
    int reviews,
    int media,
  );

  /// L10n key: adminBusinessesMergeApplyNowAction
  ///
  /// In tr, this message translates to:
  /// **'Birleştir ve uygula'**
  String get adminBusinessesMergeApplyNowAction;

  /// L10n key: adminBusinessesMergeCreateProposalAction
  ///
  /// In tr, this message translates to:
  /// **'Birleştirme talebi oluştur'**
  String get adminBusinessesMergeCreateProposalAction;

  /// L10n key: adminBusinessesMergeCompleted
  ///
  /// In tr, this message translates to:
  /// **'Birleştirme tamamlandı.'**
  String get adminBusinessesMergeCompleted;

  /// L10n key: adminBusinessesMergeProposalLogged
  ///
  /// In tr, this message translates to:
  /// **'Birleştirme talebi denetim kaydına eklendi.'**
  String get adminBusinessesMergeProposalLogged;

  /// L10n key: adminBusinessesRiskSuspicious
  ///
  /// In tr, this message translates to:
  /// **'Şüpheli'**
  String get adminBusinessesRiskSuspicious;

  /// L10n key: adminBusinessesRiskMedium
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get adminBusinessesRiskMedium;

  /// L10n key: adminBusinessesRiskLow
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get adminBusinessesRiskLow;

  /// L10n key: adminBusinessesRiskMissing
  ///
  /// In tr, this message translates to:
  /// **'yok'**
  String get adminBusinessesRiskMissing;

  /// L10n key: adminBusinessesRiskAvailable
  ///
  /// In tr, this message translates to:
  /// **'var'**
  String get adminBusinessesRiskAvailable;

  /// L10n key: adminBusinessesRiskTooltip
  ///
  /// In tr, this message translates to:
  /// **'Adres: {address} • Telefon: {phone} • Foto: {photoCount} • Etkileşim: {engagementCount}'**
  String adminBusinessesRiskTooltip(
    String address,
    String phone,
    int photoCount,
    int engagementCount,
  );

  /// L10n key: adminClaimsTitle
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talepleri'**
  String get adminClaimsTitle;

  /// L10n key: adminClaimsExportingAction
  ///
  /// In tr, this message translates to:
  /// **'İndiriliyor...'**
  String get adminClaimsExportingAction;

  /// L10n key: adminClaimsExportCsvAction
  ///
  /// In tr, this message translates to:
  /// **'CSV dışa aktar'**
  String get adminClaimsExportCsvAction;

  /// L10n key: adminClaimsSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Ara (ID, isim, telefon)'**
  String get adminClaimsSearchHint;

  /// L10n key: adminClaimsAssignedUnassigned
  ///
  /// In tr, this message translates to:
  /// **'Boşta'**
  String get adminClaimsAssignedUnassigned;

  /// L10n key: adminClaimsAssignedMine
  ///
  /// In tr, this message translates to:
  /// **'Benim'**
  String get adminClaimsAssignedMine;

  /// L10n key: adminClaimsAssignedAnotherAdmin
  ///
  /// In tr, this message translates to:
  /// **'Başka admin'**
  String get adminClaimsAssignedAnotherAdmin;

  /// L10n key: adminClaimsNewRecordsAvailable
  ///
  /// In tr, this message translates to:
  /// **'Yeni kayıtlar var'**
  String get adminClaimsNewRecordsAvailable;

  /// L10n key: adminClaimsBulkUpdated
  ///
  /// In tr, this message translates to:
  /// **'Güncellendi.'**
  String get adminClaimsBulkUpdated;

  /// L10n key: adminClaimsSelectSamePhoneAction
  ///
  /// In tr, this message translates to:
  /// **'Aynı telefonu seç'**
  String get adminClaimsSelectSamePhoneAction;

  /// L10n key: adminClaimsAssignSelectedToMeAction
  ///
  /// In tr, this message translates to:
  /// **'Seçilileri bana ata'**
  String get adminClaimsAssignSelectedToMeAction;

  /// L10n key: adminClaimsFullNameColumn
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get adminClaimsFullNameColumn;

  /// L10n key: adminClaimsPriorityColumn
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get adminClaimsPriorityColumn;

  /// L10n key: adminClaimsStatusColumn
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get adminClaimsStatusColumn;

  /// L10n key: adminClaimsAssignedColumn
  ///
  /// In tr, this message translates to:
  /// **'Atanan'**
  String get adminClaimsAssignedColumn;

  /// L10n key: adminClaimsCreatedAtColumn
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma'**
  String get adminClaimsCreatedAtColumn;

  /// L10n key: adminClaimsAgeColumn
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get adminClaimsAgeColumn;

  /// L10n key: adminClaimsDetailsAction
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get adminClaimsDetailsAction;

  /// L10n key: adminClaimsAutoModeratedTooltip
  ///
  /// In tr, this message translates to:
  /// **'Otomatik moderasyon uygulandı'**
  String get adminClaimsAutoModeratedTooltip;

  /// L10n key: adminClaimsEmpty
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı.'**
  String get adminClaimsEmpty;

  /// L10n key: adminClaimsSlaBreached
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt SLA aştı: {age}'**
  String adminClaimsSlaBreached(String age);

  /// L10n key: adminClaimsDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Kayıt detayı'**
  String get adminClaimsDetailTitle;

  /// L10n key: adminClaimsPhoneLabel
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get adminClaimsPhoneLabel;

  /// L10n key: adminClaimsEvidenceLabel
  ///
  /// In tr, this message translates to:
  /// **'Kanıt'**
  String get adminClaimsEvidenceLabel;

  /// L10n key: adminClaimsAdminNoteOptionalLabel
  ///
  /// In tr, this message translates to:
  /// **'Admin notu (opsiyonel)'**
  String get adminClaimsAdminNoteOptionalLabel;

  /// L10n key: adminClaimsAutoRulesTitle
  ///
  /// In tr, this message translates to:
  /// **'Otomatik kurallar'**
  String get adminClaimsAutoRulesTitle;

  /// L10n key: adminClaimsAutoRuleApplied
  ///
  /// In tr, this message translates to:
  /// **'Otomatik kural uygulandı.'**
  String get adminClaimsAutoRuleApplied;

  /// L10n key: adminClaimsNoAutoRuleFound
  ///
  /// In tr, this message translates to:
  /// **'Uygun otomatik kural bulunamadı.'**
  String get adminClaimsNoAutoRuleFound;

  /// L10n key: adminClaimsApplyingAction
  ///
  /// In tr, this message translates to:
  /// **'Uygulanıyor...'**
  String get adminClaimsApplyingAction;

  /// L10n key: adminClaimsApplyRulesAction
  ///
  /// In tr, this message translates to:
  /// **'Kuralları uygula'**
  String get adminClaimsApplyRulesAction;

  /// L10n key: adminClaimsDone
  ///
  /// In tr, this message translates to:
  /// **'İşlem bitti.'**
  String get adminClaimsDone;

  /// L10n key: adminClaimsProcessingAction
  ///
  /// In tr, this message translates to:
  /// **'İşleniyor...'**
  String get adminClaimsProcessingAction;

  /// L10n key: adminClaimsAssignToMeAction
  ///
  /// In tr, this message translates to:
  /// **'Bana ata'**
  String get adminClaimsAssignToMeAction;

  /// L10n key: adminClaimsUnassignAction
  ///
  /// In tr, this message translates to:
  /// **'Atamayı kaldır'**
  String get adminClaimsUnassignAction;

  /// L10n key: adminClaimsAssignmentRemoved
  ///
  /// In tr, this message translates to:
  /// **'Atama kaldırıldı.'**
  String get adminClaimsAssignmentRemoved;

  /// L10n key: adminClaimsApproved
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı.'**
  String get adminClaimsApproved;

  /// L10n key: adminClaimsRejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi.'**
  String get adminClaimsRejected;

  /// L10n key: adminClaimsSelectRowFirst
  ///
  /// In tr, this message translates to:
  /// **'Satır seç'**
  String get adminClaimsSelectRowFirst;

  /// L10n key: adminClaimsNoPhone
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıtta telefon yok.'**
  String get adminClaimsNoPhone;

  /// L10n key: adminClaimsAssignedToYou
  ///
  /// In tr, this message translates to:
  /// **'{count} talep sana atandı.'**
  String adminClaimsAssignedToYou(int count);

  /// L10n key: adminClaimsSelectedCount
  ///
  /// In tr, this message translates to:
  /// **'Seçili: {count}'**
  String adminClaimsSelectedCount(int count);

  /// L10n key: adminClaimsClearSelectionAction
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get adminClaimsClearSelectionAction;

  /// L10n key: adminClaimsAgeValue
  ///
  /// In tr, this message translates to:
  /// **'{days} gün'**
  String adminClaimsAgeValue(String days);

  /// L10n key: adminClaimsDecisionTemplateApproved
  ///
  /// In tr, this message translates to:
  /// **'Belge ve bilgiler doğrulandı, talep onaylandı.'**
  String get adminClaimsDecisionTemplateApproved;

  /// L10n key: adminClaimsDecisionTemplateRejected
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kriterleri sağlanamadı, talep reddedildi.'**
  String get adminClaimsDecisionTemplateRejected;

  /// L10n key: adminClaimsDecisionTemplateNeedsDocuments
  ///
  /// In tr, this message translates to:
  /// **'Ek belge gerekiyor, inceleme devam ediyor.'**
  String get adminClaimsDecisionTemplateNeedsDocuments;

  /// L10n key: adminDashboardOverviewTitle
  ///
  /// In tr, this message translates to:
  /// **'Genel Bakış'**
  String get adminDashboardOverviewTitle;

  /// L10n key: adminDashboardOverviewSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Operasyon ve büyüme metrikleri'**
  String get adminDashboardOverviewSubtitle;

  /// L10n key: adminDashboardOpenReports
  ///
  /// In tr, this message translates to:
  /// **'Açık raporlar'**
  String get adminDashboardOpenReports;

  /// L10n key: adminDashboardPendingClaims
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen sahiplik'**
  String get adminDashboardPendingClaims;

  /// L10n key: adminDashboardPendingSuggestions
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen öneriler'**
  String get adminDashboardPendingSuggestions;

  /// L10n key: adminDashboardReportAssignMinutes
  ///
  /// In tr, this message translates to:
  /// **'Rapor atama (dk)'**
  String get adminDashboardReportAssignMinutes;

  /// L10n key: adminDashboardReportCloseMinutes
  ///
  /// In tr, this message translates to:
  /// **'Rapor kapanışı (dk)'**
  String get adminDashboardReportCloseMinutes;

  /// L10n key: adminDashboardClaimAssignMinutes
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik atama (dk)'**
  String get adminDashboardClaimAssignMinutes;

  /// L10n key: adminDashboardClaimDecisionMinutes
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik karar (dk)'**
  String get adminDashboardClaimDecisionMinutes;

  /// L10n key: adminDashboardGrowth30Days
  ///
  /// In tr, this message translates to:
  /// **'Büyüme (30 gün)'**
  String get adminDashboardGrowth30Days;

  /// L10n key: adminDashboardMenuLinkOpened
  ///
  /// In tr, this message translates to:
  /// **'Menü link açıldı'**
  String get adminDashboardMenuLinkOpened;

  /// L10n key: adminDashboardQrScanned
  ///
  /// In tr, this message translates to:
  /// **'QR okutuldu'**
  String get adminDashboardQrScanned;

  /// L10n key: adminDashboardMenuShared
  ///
  /// In tr, this message translates to:
  /// **'Menü paylaşıldı'**
  String get adminDashboardMenuShared;

  /// L10n key: adminDashboardAppInstall
  ///
  /// In tr, this message translates to:
  /// **'Uygulama kurulum'**
  String get adminDashboardAppInstall;

  /// L10n key: adminDashboardKpi30Days
  ///
  /// In tr, this message translates to:
  /// **'KPI (30 gün)'**
  String get adminDashboardKpi30Days;

  /// L10n key: adminDashboardDau
  ///
  /// In tr, this message translates to:
  /// **'DAU'**
  String get adminDashboardDau;

  /// L10n key: adminDashboardWau
  ///
  /// In tr, this message translates to:
  /// **'WAU'**
  String get adminDashboardWau;

  /// L10n key: adminDashboardDiscoveryCtr
  ///
  /// In tr, this message translates to:
  /// **'Keşfet → İşletme CTR'**
  String get adminDashboardDiscoveryCtr;

  /// L10n key: adminDashboardBusinessToMenuRate
  ///
  /// In tr, this message translates to:
  /// **'İşletme → Menü oranı'**
  String get adminDashboardBusinessToMenuRate;

  /// L10n key: adminDashboardPriceVerificationConversion
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulama dönüşümü'**
  String get adminDashboardPriceVerificationConversion;

  /// L10n key: adminDashboardReportResolutionMinutes
  ///
  /// In tr, this message translates to:
  /// **'Rapor çözüm süresi (dk)'**
  String get adminDashboardReportResolutionMinutes;

  /// L10n key: adminDashboardQualityGateTitle
  ///
  /// In tr, this message translates to:
  /// **'V3 Kalite ve Güven Kapısı (P0)'**
  String get adminDashboardQualityGateTitle;

  /// L10n key: adminDashboardQualityGateSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Yanlış bilgiyi düşür, güveni yükselt. Büyüme için kaliteyi gevşetme.'**
  String get adminDashboardQualityGateSubtitle;

  /// L10n key: adminDashboardLiveGate
  ///
  /// In tr, this message translates to:
  /// **'Canlı kapı: {passed}/{total}'**
  String adminDashboardLiveGate(int passed, int total);

  /// L10n key: adminDashboardGateAccuracyScores
  ///
  /// In tr, this message translates to:
  /// **'Doğruluk skorları'**
  String get adminDashboardGateAccuracyScores;

  /// L10n key: adminDashboardGatePriceVerification
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğrulama'**
  String get adminDashboardGatePriceVerification;

  /// L10n key: adminDashboardGateMenuHistory
  ///
  /// In tr, this message translates to:
  /// **'Menü versiyon/geçmiş'**
  String get adminDashboardGateMenuHistory;

  /// L10n key: adminDashboardGateFalseInfoReporting
  ///
  /// In tr, this message translates to:
  /// **'Yanlış bilgi bildirimi'**
  String get adminDashboardGateFalseInfoReporting;

  /// L10n key: adminDashboardGateBusinessLifecycle
  ///
  /// In tr, this message translates to:
  /// **'İşletme yaşam döngüsü'**
  String get adminDashboardGateBusinessLifecycle;

  /// L10n key: adminDashboardGateReviewQuality
  ///
  /// In tr, this message translates to:
  /// **'Yorum kalite sistemi'**
  String get adminDashboardGateReviewQuality;

  /// L10n key: adminDashboardGateOpenNowCheck
  ///
  /// In tr, this message translates to:
  /// **'Şimdi açık kontrolü'**
  String get adminDashboardGateOpenNowCheck;

  /// L10n key: adminDashboardGateBusinessPanelCore
  ///
  /// In tr, this message translates to:
  /// **'İşletme panel temel'**
  String get adminDashboardGateBusinessPanelCore;

  /// L10n key: adminDashboardGateAdminQueue
  ///
  /// In tr, this message translates to:
  /// **'Admin kuyruk'**
  String get adminDashboardGateAdminQueue;

  /// L10n key: adminDashboardGateInbox
  ///
  /// In tr, this message translates to:
  /// **'Uygulama içi gelen kutusu'**
  String get adminDashboardGateInbox;

  /// L10n key: adminDashboardGuardrailSummary
  ///
  /// In tr, this message translates to:
  /// **'Korkuluk: sponsor etiketi={requireLabel}, min sponsor güveni={minTrust}, işletme yorum silme={ownerDelete}, kalite bypass={bypass}.'**
  String adminDashboardGuardrailSummary(
    String requireLabel,
    String minTrust,
    String ownerDelete,
    String bypass,
  );

  /// L10n key: adminDevToolsTitle
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici araçları'**
  String get adminDevToolsTitle;

  /// L10n key: adminDevToolsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Özellik, test kullanıcı ve test şehir ayarları.'**
  String get adminDevToolsSubtitle;

  /// L10n key: adminDevToolsAchievementRequired
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ID ve Başarı ID zorunlu.'**
  String get adminDevToolsAchievementRequired;

  /// L10n key: adminDevToolsResetFailed
  ///
  /// In tr, this message translates to:
  /// **'Reset başarısız: {error}'**
  String adminDevToolsResetFailed(String error);

  /// L10n key: adminDevToolsAchievementResetLogged
  ///
  /// In tr, this message translates to:
  /// **'Başarı resetlendi ve denetim kayda yazıldı.'**
  String get adminDevToolsAchievementResetLogged;

  /// L10n key: adminDevToolsNoRecordButLogged
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunmadı ama denetim kayda yazıldı.'**
  String get adminDevToolsNoRecordButLogged;

  /// L10n key: adminDevToolsError
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String adminDevToolsError(String error);

  /// L10n key: adminDevToolsAchievementModerationTitle
  ///
  /// In tr, this message translates to:
  /// **'Başarı moderasyonu'**
  String get adminDevToolsAchievementModerationTitle;

  /// L10n key: adminDevToolsAchievementModerationDescription
  ///
  /// In tr, this message translates to:
  /// **'Gerekirse başarı kaydını sil ve profile XP/seviyeyi yeniden hesapla.'**
  String get adminDevToolsAchievementModerationDescription;

  /// L10n key: adminDevToolsUserIdUuidLabel
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı ID (UUID)'**
  String get adminDevToolsUserIdUuidLabel;

  /// L10n key: adminDevToolsWriterUserIdHint
  ///
  /// In tr, this message translates to:
  /// **'yazar kullanıcı ID'**
  String get adminDevToolsWriterUserIdHint;

  /// L10n key: adminDevToolsAchievementIdLabel
  ///
  /// In tr, this message translates to:
  /// **'Başarı ID'**
  String get adminDevToolsAchievementIdLabel;

  /// L10n key: adminDevToolsAchievementIdHint
  ///
  /// In tr, this message translates to:
  /// **'örnek: trusted_contributor'**
  String get adminDevToolsAchievementIdHint;

  /// L10n key: adminDevToolsReasonOptionalLabel
  ///
  /// In tr, this message translates to:
  /// **'Neden (opsiyonel)'**
  String get adminDevToolsReasonOptionalLabel;

  /// L10n key: adminDevToolsResettingAction
  ///
  /// In tr, this message translates to:
  /// **'Resetleniyor...'**
  String get adminDevToolsResettingAction;

  /// L10n key: adminDevToolsAchievementResetAction
  ///
  /// In tr, this message translates to:
  /// **'Başarı resetle'**
  String get adminDevToolsAchievementResetAction;

  /// L10n key: adminDevToolsGuardrailThresholdsTitle
  ///
  /// In tr, this message translates to:
  /// **'Korkuluk eşikleri'**
  String get adminDevToolsGuardrailThresholdsTitle;

  /// L10n key: adminDevToolsGuardrailThresholdsDescription
  ///
  /// In tr, this message translates to:
  /// **'Canlı kalite eşiklerini admin panelinden ayarla.'**
  String get adminDevToolsGuardrailThresholdsDescription;

  /// L10n key: adminDevToolsRequireSponsoredLabel
  ///
  /// In tr, this message translates to:
  /// **'Sponsor etiketi zorunlu'**
  String get adminDevToolsRequireSponsoredLabel;

  /// L10n key: adminDevToolsOwnerCanDeleteReviews
  ///
  /// In tr, this message translates to:
  /// **'İşletme yorum silebilir'**
  String get adminDevToolsOwnerCanDeleteReviews;

  /// L10n key: adminDevToolsLowQualityGrowthBypass
  ///
  /// In tr, this message translates to:
  /// **'Düşük kalite büyüme bypass'**
  String get adminDevToolsLowQualityGrowthBypass;

  /// L10n key: adminDevToolsMinSponsorTrustLabel
  ///
  /// In tr, this message translates to:
  /// **'Min sponsor güveni (0-1)'**
  String get adminDevToolsMinSponsorTrustLabel;

  /// L10n key: adminDevToolsMinSponsorRatingLabel
  ///
  /// In tr, this message translates to:
  /// **'Min sponsor puanı (0-5)'**
  String get adminDevToolsMinSponsorRatingLabel;

  /// L10n key: adminDevToolsEnterValidThresholds
  ///
  /// In tr, this message translates to:
  /// **'Geçerli eşik değerleri gir.'**
  String get adminDevToolsEnterValidThresholds;

  /// L10n key: adminDevToolsSaveThresholdsAction
  ///
  /// In tr, this message translates to:
  /// **'Eşikleri kaydet'**
  String get adminDevToolsSaveThresholdsAction;

  /// L10n key: adminDevToolsDefaultAction
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get adminDevToolsDefaultAction;

  /// L10n key: adminDevToolsFeatureFlagsTitle
  ///
  /// In tr, this message translates to:
  /// **'Özellik bayrakları'**
  String get adminDevToolsFeatureFlagsTitle;

  /// L10n key: adminDevToolsTestUserTitle
  ///
  /// In tr, this message translates to:
  /// **'Test kullanıcı'**
  String get adminDevToolsTestUserTitle;

  /// L10n key: adminDevToolsActiveUser
  ///
  /// In tr, this message translates to:
  /// **'Aktif kullanıcı: {userId}'**
  String adminDevToolsActiveUser(String userId);

  /// L10n key: adminDevToolsTestUserUidLabel
  ///
  /// In tr, this message translates to:
  /// **'Test kullanıcı UID'**
  String get adminDevToolsTestUserUidLabel;

  /// L10n key: adminDevToolsClearAction
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get adminDevToolsClearAction;

  /// L10n key: adminDevToolsTestCityTitle
  ///
  /// In tr, this message translates to:
  /// **'Test şehir'**
  String get adminDevToolsTestCityTitle;

  /// L10n key: adminDevToolsTestCityDescription
  ///
  /// In tr, this message translates to:
  /// **'Konum geçersiz bırakıldığında otomatik konum akışı devre dışı kalır.'**
  String get adminDevToolsTestCityDescription;

  /// L10n key: adminDevToolsActiveLocation
  ///
  /// In tr, this message translates to:
  /// **'Aktif: {city} / {district}'**
  String adminDevToolsActiveLocation(String city, String district);

  /// L10n key: adminGroupRequestsRequestsTitle
  ///
  /// In tr, this message translates to:
  /// **'Talepler'**
  String get adminGroupRequestsRequestsTitle;

  /// L10n key: adminGroupRequestsOffersTitle
  ///
  /// In tr, this message translates to:
  /// **'Teklifler'**
  String get adminGroupRequestsOffersTitle;

  /// L10n key: adminGroupRequestsNoRecords
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok'**
  String get adminGroupRequestsNoRecords;

  /// L10n key: adminGroupRequestsRequestSummary
  ///
  /// In tr, this message translates to:
  /// **'{city} • {partySize} kişi'**
  String adminGroupRequestsRequestSummary(String city, int partySize);

  /// L10n key: adminGrowthTitle
  ///
  /// In tr, this message translates to:
  /// **'Büyüme'**
  String get adminGrowthTitle;

  /// L10n key: adminGrowthLastDays
  ///
  /// In tr, this message translates to:
  /// **'Son {days} gün'**
  String adminGrowthLastDays(int days);

  /// L10n key: adminGrowthBusinessIdOptional
  ///
  /// In tr, this message translates to:
  /// **'İşletme ID (opsiyonel)'**
  String get adminGrowthBusinessIdOptional;

  /// L10n key: adminGrowthNoData
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı.'**
  String get adminGrowthNoData;

  /// L10n key: adminGrowthTodayBusinessTraffic
  ///
  /// In tr, this message translates to:
  /// **'Bugün işletme trafiği'**
  String get adminGrowthTodayBusinessTraffic;

  /// L10n key: adminGrowthMenuLinkOpened
  ///
  /// In tr, this message translates to:
  /// **'Menü link açıldı'**
  String get adminGrowthMenuLinkOpened;

  /// L10n key: adminGrowthQrScanned
  ///
  /// In tr, this message translates to:
  /// **'QR okutuldu'**
  String get adminGrowthQrScanned;

  /// L10n key: adminGrowthMenuShared
  ///
  /// In tr, this message translates to:
  /// **'Menü paylaşıldı'**
  String get adminGrowthMenuShared;

  /// L10n key: adminGrowthAppInstall
  ///
  /// In tr, this message translates to:
  /// **'Uygulama kurulum'**
  String get adminGrowthAppInstall;

  /// L10n key: adminGrowthDailyTrafficTotal
  ///
  /// In tr, this message translates to:
  /// **'Günlük trafik (toplam)'**
  String get adminGrowthDailyTrafficTotal;

  /// L10n key: adminGrowthDayColumn
  ///
  /// In tr, this message translates to:
  /// **'Gün'**
  String get adminGrowthDayColumn;

  /// L10n key: adminGrowthFunnelTitle
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı hunisi'**
  String get adminGrowthFunnelTitle;

  /// L10n key: adminGrowthFunnelSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Keşif → Etkileşim → Dönüşüm (seçili dönem toplamı)'**
  String get adminGrowthFunnelSubtitle;

  /// L10n key: adminGrowthFunnelDiscovery
  ///
  /// In tr, this message translates to:
  /// **'Keşif'**
  String get adminGrowthFunnelDiscovery;

  /// L10n key: adminGrowthFunnelEngagement
  ///
  /// In tr, this message translates to:
  /// **'Etkileşim'**
  String get adminGrowthFunnelEngagement;

  /// L10n key: adminGrowthFunnelConversion
  ///
  /// In tr, this message translates to:
  /// **'Dönüşüm'**
  String get adminGrowthFunnelConversion;

  /// L10n key: adminIncidentCenterTitle
  ///
  /// In tr, this message translates to:
  /// **'Kriz müdahale merkezi'**
  String get adminIncidentCenterTitle;

  /// L10n key: adminIncidentCenterSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Sahte işletme, yanlış fiyat ve medya krizleri için hızlı panel.'**
  String get adminIncidentCenterSubtitle;

  /// L10n key: adminIncidentCenterNoLogs
  ///
  /// In tr, this message translates to:
  /// **'Henüz kayıtlı kriz logu yok.'**
  String get adminIncidentCenterNoLogs;

  /// L10n key: adminIncidentCenterTransparentLogTitle
  ///
  /// In tr, this message translates to:
  /// **'Şeffaf log'**
  String get adminIncidentCenterTransparentLogTitle;

  /// L10n key: adminIncidentCenterHowFixed
  ///
  /// In tr, this message translates to:
  /// **'Nasıl düzelttik: {action}'**
  String adminIncidentCenterHowFixed(String action);

  /// L10n key: adminIncidentCenterFillAllFields
  ///
  /// In tr, this message translates to:
  /// **'Tüm alanları doldur.'**
  String get adminIncidentCenterFillAllFields;

  /// L10n key: adminIncidentCenterQuickPanelTitle
  ///
  /// In tr, this message translates to:
  /// **'Hızlı müdahale paneli'**
  String get adminIncidentCenterQuickPanelTitle;

  /// L10n key: adminIncidentCenterReportsQueueAction
  ///
  /// In tr, this message translates to:
  /// **'Rapor kuyruğu'**
  String get adminIncidentCenterReportsQueueAction;

  /// L10n key: adminIncidentCenterReviewBusinessAction
  ///
  /// In tr, this message translates to:
  /// **'İşletme incele'**
  String get adminIncidentCenterReviewBusinessAction;

  /// L10n key: adminIncidentCenterAuditLogAction
  ///
  /// In tr, this message translates to:
  /// **'Denetim log'**
  String get adminIncidentCenterAuditLogAction;

  /// L10n key: adminIncidentCenterHowWeFixedAction
  ///
  /// In tr, this message translates to:
  /// **'Nasıl düzelttik ekranı'**
  String get adminIncidentCenterHowWeFixedAction;

  /// L10n key: adminIncidentCenterReadyResponsesTitle
  ///
  /// In tr, this message translates to:
  /// **'Hazır cevaplar'**
  String get adminIncidentCenterReadyResponsesTitle;

  /// L10n key: adminIncidentCenterReadyResponseWrongPrice
  ///
  /// In tr, this message translates to:
  /// **'Yanlış fiyat: Hata kaydı açıldı, ilgili menü geçici olarak geri plana alındı, doğrulama sonrası tekrar aktif.'**
  String get adminIncidentCenterReadyResponseWrongPrice;

  /// L10n key: adminIncidentCenterReadyResponseFakeBusiness
  ///
  /// In tr, this message translates to:
  /// **'Sahte işletme: Kayıt incelemeye alındı, görünürlük düşürüldü, yinelenen ve sahte sinyalleri için otomatik kısıt uygulandı.'**
  String get adminIncidentCenterReadyResponseFakeBusiness;

  /// L10n key: adminIncidentCenterReadyResponseMedia
  ///
  /// In tr, this message translates to:
  /// **'Medya senaryosu: Açık zaman çizelgesi yayınlandı, yapılan düzeltmeler ve SLA adımları şeffaf şekilde paylaşıldı.'**
  String get adminIncidentCenterReadyResponseMedia;

  /// L10n key: adminIncidentCenterLogEntryTitle
  ///
  /// In tr, this message translates to:
  /// **'Şeffaf log girdisi'**
  String get adminIncidentCenterLogEntryTitle;

  /// L10n key: adminIncidentCenterIncidentKeyLabel
  ///
  /// In tr, this message translates to:
  /// **'Olay anahtarı'**
  String get adminIncidentCenterIncidentKeyLabel;

  /// L10n key: adminIncidentCenterTitleLabel
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get adminIncidentCenterTitleLabel;

  /// L10n key: adminIncidentCenterWhatHappenedLabel
  ///
  /// In tr, this message translates to:
  /// **'Ne oldu?'**
  String get adminIncidentCenterWhatHappenedLabel;

  /// L10n key: adminIncidentCenterHowDidWeFixLabel
  ///
  /// In tr, this message translates to:
  /// **'Nasıl düzelttik?'**
  String get adminIncidentCenterHowDidWeFixLabel;

  /// L10n key: adminIncidentCenterStatusOpen
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get adminIncidentCenterStatusOpen;

  /// L10n key: adminIncidentCenterStatusMitigated
  ///
  /// In tr, this message translates to:
  /// **'İyileştirildi'**
  String get adminIncidentCenterStatusMitigated;

  /// L10n key: adminIncidentCenterStatusResolved
  ///
  /// In tr, this message translates to:
  /// **'Çözüldü'**
  String get adminIncidentCenterStatusResolved;

  /// L10n key: adminIncidentCenterVisibilityPublic
  ///
  /// In tr, this message translates to:
  /// **'Herkese açık'**
  String get adminIncidentCenterVisibilityPublic;

  /// L10n key: adminIncidentCenterVisibilityInternal
  ///
  /// In tr, this message translates to:
  /// **'İç kullanım'**
  String get adminIncidentCenterVisibilityInternal;

  /// L10n key: adminIncidentCenterAddLogAction
  ///
  /// In tr, this message translates to:
  /// **'Log ekle'**
  String get adminIncidentCenterAddLogAction;

  /// L10n key: adminCommonUpdated
  ///
  /// In tr, this message translates to:
  /// **'Güncellendi.'**
  String get adminCommonUpdated;

  /// L10n key: adminCommonDownloading
  ///
  /// In tr, this message translates to:
  /// **'İndiriliyor...'**
  String get adminCommonDownloading;

  /// L10n key: adminCommonExportCsv
  ///
  /// In tr, this message translates to:
  /// **'CSV Dışa Aktar'**
  String get adminCommonExportCsv;

  /// L10n key: adminCommonUnassigned
  ///
  /// In tr, this message translates to:
  /// **'Boşta'**
  String get adminCommonUnassigned;

  /// L10n key: adminCommonMine
  ///
  /// In tr, this message translates to:
  /// **'Benim'**
  String get adminCommonMine;

  /// L10n key: adminCommonOtherAdmin
  ///
  /// In tr, this message translates to:
  /// **'Başka admin'**
  String get adminCommonOtherAdmin;

  /// L10n key: adminCommonNewRecordsAvailable
  ///
  /// In tr, this message translates to:
  /// **'Yeni kayıtlar var'**
  String get adminCommonNewRecordsAvailable;

  /// L10n key: adminCommonAge
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get adminCommonAge;

  /// L10n key: adminCommonPriority
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get adminCommonPriority;

  /// L10n key: adminCommonAssigned
  ///
  /// In tr, this message translates to:
  /// **'Atanan'**
  String get adminCommonAssigned;

  /// L10n key: adminCommonDetails
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get adminCommonDetails;

  /// L10n key: adminCommonNoRecordsFound
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı.'**
  String get adminCommonNoRecordsFound;

  /// L10n key: adminCommonProcessing
  ///
  /// In tr, this message translates to:
  /// **'İşleniyor...'**
  String get adminCommonProcessing;

  /// L10n key: adminCommonConfirmTitle
  ///
  /// In tr, this message translates to:
  /// **'Emin misiniz?'**
  String get adminCommonConfirmTitle;

  /// L10n key: adminCommonSelectRow
  ///
  /// In tr, this message translates to:
  /// **'Satır seçin.'**
  String get adminCommonSelectRow;

  /// L10n key: adminCommonClear
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get adminCommonClear;

  /// L10n key: adminLocationsTitle
  ///
  /// In tr, this message translates to:
  /// **'Araçlar > Konumlar'**
  String get adminLocationsTitle;

  /// L10n key: adminLocationsTableBusinesses
  ///
  /// In tr, this message translates to:
  /// **'İşletmeler'**
  String get adminLocationsTableBusinesses;

  /// L10n key: adminLocationsTableBusinessSuggestions
  ///
  /// In tr, this message translates to:
  /// **'İşletme önerileri'**
  String get adminLocationsTableBusinessSuggestions;

  /// L10n key: adminLocationsTableLabel
  ///
  /// In tr, this message translates to:
  /// **'Tablo'**
  String get adminLocationsTableLabel;

  /// L10n key: adminLocationsFieldLabel
  ///
  /// In tr, this message translates to:
  /// **'Alan'**
  String get adminLocationsFieldLabel;

  /// L10n key: adminLocationsCaseInsensitive
  ///
  /// In tr, this message translates to:
  /// **'Büyük/küçük harf duyarsız'**
  String get adminLocationsCaseInsensitive;

  /// L10n key: adminLocationsFromLabel
  ///
  /// In tr, this message translates to:
  /// **'Eski değer'**
  String get adminLocationsFromLabel;

  /// L10n key: adminLocationsToLabel
  ///
  /// In tr, this message translates to:
  /// **'Yeni değer'**
  String get adminLocationsToLabel;

  /// L10n key: adminLocationsAffectedCount
  ///
  /// In tr, this message translates to:
  /// **'Etkilenecek kayıt: {count}'**
  String adminLocationsAffectedCount(int count);

  /// L10n key: adminLocationsChecking
  ///
  /// In tr, this message translates to:
  /// **'Kontrol ediliyor...'**
  String get adminLocationsChecking;

  /// L10n key: adminLocationsValuesRequired
  ///
  /// In tr, this message translates to:
  /// **'Eski değer ve yeni değer gerekli.'**
  String get adminLocationsValuesRequired;

  /// L10n key: adminLocationsConfirmTitle
  ///
  /// In tr, this message translates to:
  /// **'Değişikliği onayla'**
  String get adminLocationsConfirmTitle;

  /// L10n key: adminLocationsConfirmMessage
  ///
  /// In tr, this message translates to:
  /// **'\"{from}\" değeri \"{to}\" olarak güncellenecek. Onaylıyor musunuz?'**
  String adminLocationsConfirmMessage(String from, String to);

  /// L10n key: adminLocationsApplying
  ///
  /// In tr, this message translates to:
  /// **'Uygulanıyor...'**
  String get adminLocationsApplying;

  /// L10n key: adminObservabilityTitle
  ///
  /// In tr, this message translates to:
  /// **'Observability'**
  String get adminObservabilityTitle;

  /// L10n key: adminObservabilitySubtitle
  ///
  /// In tr, this message translates to:
  /// **'Request trace, performans hedefleri ve yerel tercih görünürlüğü.'**
  String get adminObservabilitySubtitle;

  /// L10n key: adminObservabilityRequestTraceTitle
  ///
  /// In tr, this message translates to:
  /// **'Request Trace'**
  String get adminObservabilityRequestTraceTitle;

  /// Admin observability edge maintenance section title
  ///
  /// In tr, this message translates to:
  /// **'Edge operasyonları'**
  String get adminObservabilityEdgeOpsTitle;

  /// Admin observability edge maintenance summary
  ///
  /// In tr, this message translates to:
  /// **'Panelden çıkmadan admin yetkili Supabase edge bakım işlerini çalıştır.'**
  String get adminObservabilityEdgeOpsSummary;

  /// Admin observability push dispatch card title
  ///
  /// In tr, this message translates to:
  /// **'Push dispatch kuyruğu'**
  String get adminObservabilityPushDispatchTitle;

  /// Admin observability push dispatch description
  ///
  /// In tr, this message translates to:
  /// **'Kuyruktaki bildirim işlerini dequeue edip push worker üzerinden gönderir.'**
  String get adminObservabilityPushDispatchDescription;

  /// Admin observability push dispatch action
  ///
  /// In tr, this message translates to:
  /// **'Push dispatch çalıştır'**
  String get adminObservabilityPushDispatchAction;

  /// Admin observability temp purge title
  ///
  /// In tr, this message translates to:
  /// **'Geçici yükleme temizliği'**
  String get adminObservabilityTempPurgeTitle;

  /// Admin observability temp purge description
  ///
  /// In tr, this message translates to:
  /// **'Silinmeyi bekleyen geçici upload storage queue kayıtlarını işler.'**
  String get adminObservabilityTempPurgeDescription;

  /// Admin observability temp purge action
  ///
  /// In tr, this message translates to:
  /// **'Temizliği çalıştır'**
  String get adminObservabilityTempPurgeAction;

  /// Admin observability running button label
  ///
  /// In tr, this message translates to:
  /// **'Çalışıyor...'**
  String get adminObservabilityRunning;

  /// Admin observability last run result
  ///
  /// In tr, this message translates to:
  /// **'{label}: {summary}'**
  String adminObservabilityLastRunResult(String label, String summary);

  /// L10n key: adminObservabilityRequestIdValue
  ///
  /// In tr, this message translates to:
  /// **'request_id: {requestId}'**
  String adminObservabilityRequestIdValue(String requestId);

  /// L10n key: adminObservabilityHeadersValue
  ///
  /// In tr, this message translates to:
  /// **'headers: {headers}'**
  String adminObservabilityHeadersValue(String headers);

  /// L10n key: adminObservabilityPayloadValue
  ///
  /// In tr, this message translates to:
  /// **'payload: {payload}'**
  String adminObservabilityPayloadValue(String payload);

  /// L10n key: adminObservabilityGenerateRequestId
  ///
  /// In tr, this message translates to:
  /// **'Yeni request_id üret'**
  String get adminObservabilityGenerateRequestId;

  /// L10n key: adminObservabilityPerfTitle
  ///
  /// In tr, this message translates to:
  /// **'Performans SLO ve alarm simülasyonu'**
  String get adminObservabilityPerfTitle;

  /// L10n key: adminObservabilityPerfSummary
  ///
  /// In tr, this message translates to:
  /// **'SLO: cold<=2000ms, warm<=800ms, home_tti<=1200ms, jank<=1%'**
  String get adminObservabilityPerfSummary;

  /// L10n key: adminObservabilityCrashFreeLabel
  ///
  /// In tr, this message translates to:
  /// **'Crash-free'**
  String get adminObservabilityCrashFreeLabel;

  /// L10n key: adminObservabilityHomeTtiLabel
  ///
  /// In tr, this message translates to:
  /// **'Home TTI p95'**
  String get adminObservabilityHomeTtiLabel;

  /// L10n key: adminObservabilityEdgeSpikeLabel
  ///
  /// In tr, this message translates to:
  /// **'Edge 429 spike'**
  String get adminObservabilityEdgeSpikeLabel;

  /// L10n key: adminObservabilityCrashFreeInput
  ///
  /// In tr, this message translates to:
  /// **'Crash-free oranı (0-1)'**
  String get adminObservabilityCrashFreeInput;

  /// L10n key: adminObservabilityHomeTtiInput
  ///
  /// In tr, this message translates to:
  /// **'Home TTI p95 (ms)'**
  String get adminObservabilityHomeTtiInput;

  /// L10n key: adminObservabilityEdgeCurrentInput
  ///
  /// In tr, this message translates to:
  /// **'Edge 429 mevcut pencere'**
  String get adminObservabilityEdgeCurrentInput;

  /// L10n key: adminObservabilityEdgeBaselineInput
  ///
  /// In tr, this message translates to:
  /// **'Edge 429 baz pencere'**
  String get adminObservabilityEdgeBaselineInput;

  /// L10n key: adminObservabilityConstantsSummary
  ///
  /// In tr, this message translates to:
  /// **'Sabitler: startup(cold={cold}, warm={warm}) home_tti={homeTti}, search_hit={searchHit}, search_miss={searchMiss}'**
  String adminObservabilityConstantsSummary(
    int cold,
    int warm,
    int homeTti,
    int searchHit,
    int searchMiss,
  );

  /// L10n key: adminObservabilityPrefsReadError
  ///
  /// In tr, this message translates to:
  /// **'Prefs okunamadı: {error}'**
  String adminObservabilityPrefsReadError(String error);

  /// L10n key: adminObservabilityPrefsEmpty
  ///
  /// In tr, this message translates to:
  /// **'Prefs verisi yok.'**
  String get adminObservabilityPrefsEmpty;

  /// L10n key: adminObservabilityPrefsExplorerTitle
  ///
  /// In tr, this message translates to:
  /// **'Prefs Explorer'**
  String get adminObservabilityPrefsExplorerTitle;

  /// L10n key: adminObservabilityStatusChip
  ///
  /// In tr, this message translates to:
  /// **'{label}: {status}'**
  String adminObservabilityStatusChip(String label, String status);

  /// L10n key: adminObservabilityStatusOk
  ///
  /// In tr, this message translates to:
  /// **'OK'**
  String get adminObservabilityStatusOk;

  /// L10n key: adminObservabilityStatusAlarm
  ///
  /// In tr, this message translates to:
  /// **'ALARM'**
  String get adminObservabilityStatusAlarm;

  /// L10n key: adminPriceSuggestionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerileri'**
  String get adminPriceSuggestionsTitle;

  /// L10n key: adminPriceSuggestionsItemLabel
  ///
  /// In tr, this message translates to:
  /// **'Öğe'**
  String get adminPriceSuggestionsItemLabel;

  /// L10n key: adminPriceSuggestionsCurrentPrice
  ///
  /// In tr, this message translates to:
  /// **'Mevcut'**
  String get adminPriceSuggestionsCurrentPrice;

  /// L10n key: adminPriceSuggestionsSuggestedPrice
  ///
  /// In tr, this message translates to:
  /// **'Önerilen'**
  String get adminPriceSuggestionsSuggestedPrice;

  /// L10n key: adminPriceSuggestionsSlaExceeded
  ///
  /// In tr, this message translates to:
  /// **'SLA aşıldı: {age}'**
  String adminPriceSuggestionsSlaExceeded(String age);

  /// L10n key: adminPriceSuggestionsDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi detayı'**
  String get adminPriceSuggestionsDetailTitle;

  /// L10n key: adminPriceSuggestionsLocationValue
  ///
  /// In tr, this message translates to:
  /// **'Konum: {city} / {district}'**
  String adminPriceSuggestionsLocationValue(String city, String district);

  /// L10n key: adminPriceSuggestionsCurrencyLabel
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get adminPriceSuggestionsCurrencyLabel;

  /// L10n key: adminPriceSuggestionsCreatedBy
  ///
  /// In tr, this message translates to:
  /// **'Oluşturan'**
  String get adminPriceSuggestionsCreatedBy;

  /// L10n key: adminPriceSuggestionsMetaTitle
  ///
  /// In tr, this message translates to:
  /// **'Meta'**
  String get adminPriceSuggestionsMetaTitle;

  /// L10n key: adminPriceSuggestionsRejectNoteLabel
  ///
  /// In tr, this message translates to:
  /// **'Reddetme notu (en az 3 karakter)'**
  String get adminPriceSuggestionsRejectNoteLabel;

  /// L10n key: adminPriceSuggestionsApproveConfirm
  ///
  /// In tr, this message translates to:
  /// **'Öneri onaylansın mı?'**
  String get adminPriceSuggestionsApproveConfirm;

  /// L10n key: adminPriceSuggestionsRejectConfirm
  ///
  /// In tr, this message translates to:
  /// **'Öneri reddedilsin mi?'**
  String get adminPriceSuggestionsRejectConfirm;

  /// L10n key: adminPriceSuggestionsGoToBusiness
  ///
  /// In tr, this message translates to:
  /// **'İşletme sayfasına git'**
  String get adminPriceSuggestionsGoToBusiness;

  /// L10n key: adminPriceSuggestionsGoToItem
  ///
  /// In tr, this message translates to:
  /// **'Öğe sayfasına git'**
  String get adminPriceSuggestionsGoToItem;

  /// L10n key: adminReceiptSubmissionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Fiş doğrulamaları'**
  String get adminReceiptSubmissionsTitle;

  /// L10n key: adminReceiptSubmissionsMatchSummary
  ///
  /// In tr, this message translates to:
  /// **'Eşleşme: {count} • {date}'**
  String adminReceiptSubmissionsMatchSummary(int count, String date);

  /// L10n key: adminReceiptSubmissionsSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Receipt/OCR akışlarını tek listede değil, saha triage workbench\'i olarak yönet.'**
  String get adminReceiptSubmissionsSubtitle;

  /// L10n key: adminReceiptSubmissionsSearchHint
  ///
  /// In tr, this message translates to:
  /// **'İşletme, şehir, ilçe veya zincir ara'**
  String get adminReceiptSubmissionsSearchHint;

  /// L10n key: adminReceiptSubmissionsStatusAll
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get adminReceiptSubmissionsStatusAll;

  /// L10n key: adminReceiptSubmissionsStatusPending
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get adminReceiptSubmissionsStatusPending;

  /// L10n key: adminReceiptSubmissionsStatusReviewed
  ///
  /// In tr, this message translates to:
  /// **'İncelendi'**
  String get adminReceiptSubmissionsStatusReviewed;

  /// L10n key: adminReceiptSubmissionsStatusNeedsFollowup
  ///
  /// In tr, this message translates to:
  /// **'Takip gerekli'**
  String get adminReceiptSubmissionsStatusNeedsFollowup;

  /// L10n key: adminReceiptSubmissionsOnlyUnmatched
  ///
  /// In tr, this message translates to:
  /// **'Sadece eşleşmesiz'**
  String get adminReceiptSubmissionsOnlyUnmatched;

  /// L10n key: adminReceiptSubmissionsSummaryTotal
  ///
  /// In tr, this message translates to:
  /// **'Toplam kayıt'**
  String get adminReceiptSubmissionsSummaryTotal;

  /// L10n key: adminReceiptSubmissionsSummaryPending
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen'**
  String get adminReceiptSubmissionsSummaryPending;

  /// L10n key: adminReceiptSubmissionsSummaryNeedsFollowup
  ///
  /// In tr, this message translates to:
  /// **'Takip gereken'**
  String get adminReceiptSubmissionsSummaryNeedsFollowup;

  /// L10n key: adminReceiptSubmissionsSummaryZeroMatch
  ///
  /// In tr, this message translates to:
  /// **'Sıfır eşleşme'**
  String get adminReceiptSubmissionsSummaryZeroMatch;

  /// L10n key: adminReceiptSubmissionsSummaryRecent24h
  ///
  /// In tr, this message translates to:
  /// **'Son 24 saat'**
  String get adminReceiptSubmissionsSummaryRecent24h;

  /// L10n key: adminReceiptSubmissionsSummaryBusinesses
  ///
  /// In tr, this message translates to:
  /// **'İşletme sayısı'**
  String get adminReceiptSubmissionsSummaryBusinesses;

  /// L10n key: adminReceiptSubmissionsBatchTitle
  ///
  /// In tr, this message translates to:
  /// **'Toplu inceleme fırsatları'**
  String get adminReceiptSubmissionsBatchTitle;

  /// L10n key: adminReceiptSubmissionsBatchDescription
  ///
  /// In tr, this message translates to:
  /// **'Aynı işletme veya zincirde biriken fişler operatöre toplu menü güncelleme adayını gösterir.'**
  String get adminReceiptSubmissionsBatchDescription;

  /// L10n key: adminReceiptSubmissionsBatchEmpty
  ///
  /// In tr, this message translates to:
  /// **'Şu an öne çıkan toplu inceleme kümesi yok.'**
  String get adminReceiptSubmissionsBatchEmpty;

  /// L10n key: adminReceiptSubmissionsBatchValue
  ///
  /// In tr, this message translates to:
  /// **'{pending} bekleyen • {zeroMatch} sıfır eşleşme • son {date}'**
  String adminReceiptSubmissionsBatchValue(
    int pending,
    int zeroMatch,
    String date,
  );

  /// L10n key: adminReceiptSubmissionsEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Fiş kuyruğu boş'**
  String get adminReceiptSubmissionsEmptyTitle;

  /// L10n key: adminReceiptSubmissionsEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu filtrelerle işlem bekleyen receipt kaydı bulunamadı.'**
  String get adminReceiptSubmissionsEmptyDescription;

  /// L10n key: adminReceiptSubmissionsDetailEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Kayıt seçin'**
  String get adminReceiptSubmissionsDetailEmptyTitle;

  /// L10n key: adminReceiptSubmissionsDetailEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Soldaki listeden bir fiş seçildiğinde OCR eşleşmeleri ve review alanı burada görünür.'**
  String get adminReceiptSubmissionsDetailEmptyDescription;

  /// L10n key: adminReceiptSubmissionsReviewAction
  ///
  /// In tr, this message translates to:
  /// **'Review aç'**
  String get adminReceiptSubmissionsReviewAction;

  /// L10n key: adminReceiptSubmissionsOpenBusinessAction
  ///
  /// In tr, this message translates to:
  /// **'Public işletmeyi aç'**
  String get adminReceiptSubmissionsOpenBusinessAction;

  /// L10n key: adminReceiptSubmissionsOpenBusinessAdminAction
  ///
  /// In tr, this message translates to:
  /// **'Admin işletme kaydını aç'**
  String get adminReceiptSubmissionsOpenBusinessAdminAction;

  /// L10n key: adminReceiptSubmissionsDetailMatches
  ///
  /// In tr, this message translates to:
  /// **'OCR eşleşmesi'**
  String get adminReceiptSubmissionsDetailMatches;

  /// L10n key: adminReceiptSubmissionsDetailSubmittedAt
  ///
  /// In tr, this message translates to:
  /// **'Gönderim'**
  String get adminReceiptSubmissionsDetailSubmittedAt;

  /// L10n key: adminReceiptSubmissionsDetailUser
  ///
  /// In tr, this message translates to:
  /// **'Gönderen'**
  String get adminReceiptSubmissionsDetailUser;

  /// L10n key: adminReceiptSubmissionsMatchTableTitle
  ///
  /// In tr, this message translates to:
  /// **'OCR eşleşme tablosu'**
  String get adminReceiptSubmissionsMatchTableTitle;

  /// L10n key: adminReceiptSubmissionsMatchTableDescription
  ///
  /// In tr, this message translates to:
  /// **'Tespit edilen fiyat ile sistemdeki mevcut fiyat farkı birlikte görülür.'**
  String get adminReceiptSubmissionsMatchTableDescription;

  /// L10n key: adminReceiptSubmissionsNoMatches
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt için menü item eşleşmesi bulunamadı. Takip veya saha incelemesi gerekebilir.'**
  String get adminReceiptSubmissionsNoMatches;

  /// L10n key: adminReceiptSubmissionsMatchItemColumn
  ///
  /// In tr, this message translates to:
  /// **'Ürün'**
  String get adminReceiptSubmissionsMatchItemColumn;

  /// L10n key: adminReceiptSubmissionsMatchDetectedColumn
  ///
  /// In tr, this message translates to:
  /// **'Tespit edilen'**
  String get adminReceiptSubmissionsMatchDetectedColumn;

  /// L10n key: adminReceiptSubmissionsMatchCurrentColumn
  ///
  /// In tr, this message translates to:
  /// **'Sistemdeki fiyat'**
  String get adminReceiptSubmissionsMatchCurrentColumn;

  /// L10n key: adminReceiptSubmissionsMatchDeltaColumn
  ///
  /// In tr, this message translates to:
  /// **'Fark'**
  String get adminReceiptSubmissionsMatchDeltaColumn;

  /// L10n key: adminReceiptSubmissionsReviewSheetTitle
  ///
  /// In tr, this message translates to:
  /// **'Receipt review'**
  String get adminReceiptSubmissionsReviewSheetTitle;

  /// L10n key: adminReceiptSubmissionsReviewStatusLabel
  ///
  /// In tr, this message translates to:
  /// **'Review durumu'**
  String get adminReceiptSubmissionsReviewStatusLabel;

  /// L10n key: adminReceiptSubmissionsReviewNoteLabel
  ///
  /// In tr, this message translates to:
  /// **'Operatör notu'**
  String get adminReceiptSubmissionsReviewNoteLabel;

  /// L10n key: adminReceiptSubmissionsSaveReview
  ///
  /// In tr, this message translates to:
  /// **'Review kaydet'**
  String get adminReceiptSubmissionsSaveReview;

  /// L10n key: adminReceiptSubmissionsSaved
  ///
  /// In tr, this message translates to:
  /// **'Receipt review kaydedildi.'**
  String get adminReceiptSubmissionsSaved;

  /// L10n key: adminReportsOtherReason
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get adminReportsOtherReason;

  /// L10n key: adminReportsTitle
  ///
  /// In tr, this message translates to:
  /// **'Raporlar'**
  String get adminReportsTitle;

  /// L10n key: adminReportsSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Ara (ID, sebep, detay)'**
  String get adminReportsSearchHint;

  /// L10n key: adminReportsStatusOpen
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get adminReportsStatusOpen;

  /// L10n key: adminReportsStatusInvestigating
  ///
  /// In tr, this message translates to:
  /// **'İnceleniyor'**
  String get adminReportsStatusInvestigating;

  /// L10n key: adminReportsStatusClosed
  ///
  /// In tr, this message translates to:
  /// **'Kapandı'**
  String get adminReportsStatusClosed;

  /// L10n key: adminReportsSelectSameReporter
  ///
  /// In tr, this message translates to:
  /// **'Aynı hesabı seç'**
  String get adminReportsSelectSameReporter;

  /// L10n key: adminReportsAssignSelectedToMe
  ///
  /// In tr, this message translates to:
  /// **'Seçili kayıtları bana ata'**
  String get adminReportsAssignSelectedToMe;

  /// L10n key: adminReportsCloseSpamWave
  ///
  /// In tr, this message translates to:
  /// **'Spam dalgasını kapat'**
  String get adminReportsCloseSpamWave;

  /// L10n key: adminReportsReasonColumn
  ///
  /// In tr, this message translates to:
  /// **'Sebep'**
  String get adminReportsReasonColumn;

  /// L10n key: adminReportsStatusColumn
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get adminReportsStatusColumn;

  /// L10n key: adminReportsCreatedAtColumn
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma'**
  String get adminReportsCreatedAtColumn;

  /// L10n key: adminReportsPhotoColumn
  ///
  /// In tr, this message translates to:
  /// **'Foto'**
  String get adminReportsPhotoColumn;

  /// L10n key: adminReportsAutoModerationApplied
  ///
  /// In tr, this message translates to:
  /// **'Otomatik moderasyon uygulandı'**
  String get adminReportsAutoModerationApplied;

  /// L10n key: adminReportsMenuPhotoTooltip
  ///
  /// In tr, this message translates to:
  /// **'Menü fotoğrafı'**
  String get adminReportsMenuPhotoTooltip;

  /// L10n key: adminReportsBusinessPhotoTooltip
  ///
  /// In tr, this message translates to:
  /// **'Mekan fotoğrafı'**
  String get adminReportsBusinessPhotoTooltip;

  /// L10n key: adminReportsSlaExceeded
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt SLA aştı: {age}'**
  String adminReportsSlaExceeded(String age);

  /// L10n key: adminReportsDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Rapor detayı'**
  String get adminReportsDetailTitle;

  /// L10n key: adminReportsReviewLabel
  ///
  /// In tr, this message translates to:
  /// **'İnceleme'**
  String get adminReportsReviewLabel;

  /// L10n key: adminReportsMenuPhotoLabel
  ///
  /// In tr, this message translates to:
  /// **'Menü fotoğrafı'**
  String get adminReportsMenuPhotoLabel;

  /// L10n key: adminReportsBusinessPhotoLabel
  ///
  /// In tr, this message translates to:
  /// **'Mekan fotoğrafı'**
  String get adminReportsBusinessPhotoLabel;

  /// L10n key: adminReportsTargetValue
  ///
  /// In tr, this message translates to:
  /// **'Hedef: {targetType} / {targetId}'**
  String adminReportsTargetValue(String targetType, String targetId);

  /// L10n key: adminReportsOpenPhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafı aç'**
  String get adminReportsOpenPhoto;

  /// L10n key: adminReportsReasonLabel
  ///
  /// In tr, this message translates to:
  /// **'Sebep'**
  String get adminReportsReasonLabel;

  /// L10n key: adminReportsAdminNoteOptional
  ///
  /// In tr, this message translates to:
  /// **'Admin notu (opsiyonel)'**
  String get adminReportsAdminNoteOptional;

  /// L10n key: adminReportsAutomaticRulesTitle
  ///
  /// In tr, this message translates to:
  /// **'Otomatik kurallar'**
  String get adminReportsAutomaticRulesTitle;

  /// L10n key: adminReportsAutomaticRuleApplied
  ///
  /// In tr, this message translates to:
  /// **'Otomatik kural uygulandı.'**
  String get adminReportsAutomaticRuleApplied;

  /// L10n key: adminReportsAutomaticRuleNotFound
  ///
  /// In tr, this message translates to:
  /// **'Uygun otomatik kural bulunamadı.'**
  String get adminReportsAutomaticRuleNotFound;

  /// L10n key: adminReportsApplyingRules
  ///
  /// In tr, this message translates to:
  /// **'Uygulanıyor...'**
  String get adminReportsApplyingRules;

  /// L10n key: adminReportsApplyRules
  ///
  /// In tr, this message translates to:
  /// **'Kuralları uygula'**
  String get adminReportsApplyRules;

  /// L10n key: adminReportsClaimed
  ///
  /// In tr, this message translates to:
  /// **'Üzerine alındı.'**
  String get adminReportsClaimed;

  /// L10n key: adminReportsAssignToMe
  ///
  /// In tr, this message translates to:
  /// **'Bana ata'**
  String get adminReportsAssignToMe;

  /// L10n key: adminReportsAssignmentRemoved
  ///
  /// In tr, this message translates to:
  /// **'Atama kaldırıldı.'**
  String get adminReportsAssignmentRemoved;

  /// L10n key: adminReportsUnassign
  ///
  /// In tr, this message translates to:
  /// **'Atamayı kaldır'**
  String get adminReportsUnassign;

  /// L10n key: adminReportsMissingReporterInfo
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıtta reporter bilgisi yok.'**
  String get adminReportsMissingReporterInfo;

  /// L10n key: adminReportsBulkSpamNote
  ///
  /// In tr, this message translates to:
  /// **'Toplu: spam dalgası nedeniyle kapatıldı'**
  String get adminReportsBulkSpamNote;

  /// L10n key: adminReportsSelectedClosed
  ///
  /// In tr, this message translates to:
  /// **'Seçili raporlar kapatıldı.'**
  String get adminReportsSelectedClosed;

  /// L10n key: adminReportsAssignedCount
  ///
  /// In tr, this message translates to:
  /// **'{count} rapor sana atandı.'**
  String adminReportsAssignedCount(int count);

  /// L10n key: adminReportsModerationScanComplete
  ///
  /// In tr, this message translates to:
  /// **'Tarama tamamlandı. Benzer foto grup: {photoGroups}, menü kopya grup: {menuGroups}'**
  String adminReportsModerationScanComplete(int photoGroups, int menuGroups);

  /// L10n key: adminReportsReasonDistribution
  ///
  /// In tr, this message translates to:
  /// **'Sebep dağılımı ({total})'**
  String adminReportsReasonDistribution(int total);

  /// L10n key: adminReportsModerationSummary
  ///
  /// In tr, this message translates to:
  /// **'Moderasyon: benzer foto grup {duplicatePhotoGroups}, kopya menü grup {copiedMenuGroups}'**
  String adminReportsModerationSummary(
    int duplicatePhotoGroups,
    int copiedMenuGroups,
  );

  /// L10n key: adminReportsScanning
  ///
  /// In tr, this message translates to:
  /// **'Taranıyor...'**
  String get adminReportsScanning;

  /// L10n key: adminReportsScan
  ///
  /// In tr, this message translates to:
  /// **'Tara'**
  String get adminReportsScan;

  /// L10n key: adminReportsSelectedCount
  ///
  /// In tr, this message translates to:
  /// **'Seçili: {count}'**
  String adminReportsSelectedCount(int count);

  /// L10n key: adminReportsHoursValue
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat'**
  String adminReportsHoursValue(String hours);

  /// L10n key: adminReportsDecisionTemplateViolationConfirmed
  ///
  /// In tr, this message translates to:
  /// **'İhlal teyit edildi, gerekli işlem uygulandı.'**
  String get adminReportsDecisionTemplateViolationConfirmed;

  /// L10n key: adminReportsDecisionTemplateInsufficientEvidence
  ///
  /// In tr, this message translates to:
  /// **'Kanıt yetersiz, rapor kapatıldı.'**
  String get adminReportsDecisionTemplateInsufficientEvidence;

  /// L10n key: adminReportsDecisionTemplateNeedsMoreInfo
  ///
  /// In tr, this message translates to:
  /// **'Ek bilgi gerekiyor, kayıt inceleniyor.'**
  String get adminReportsDecisionTemplateNeedsMoreInfo;

  /// L10n key: adminReportsPhotoNotFound
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf bulunamadı.'**
  String get adminReportsPhotoNotFound;

  /// L10n key: adminReportsVisibilityLoading
  ///
  /// In tr, this message translates to:
  /// **'{label} · görünürlük yükleniyor...'**
  String adminReportsVisibilityLoading(String label);

  /// L10n key: adminReportsVisibilityUnknown
  ///
  /// In tr, this message translates to:
  /// **'{label} · görünürlük bilinmiyor'**
  String adminReportsVisibilityUnknown(String label);

  /// L10n key: adminReportsVisibilityHidden
  ///
  /// In tr, this message translates to:
  /// **'{label} · gölge (gizli)'**
  String adminReportsVisibilityHidden(String label);

  /// L10n key: adminReportsVisibilityNormal
  ///
  /// In tr, this message translates to:
  /// **'{label} · normal (açık)'**
  String adminReportsVisibilityNormal(String label);

  /// L10n key: adminCommonSaved
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi.'**
  String get adminCommonSaved;

  /// L10n key: adminShellAdminTitle
  ///
  /// In tr, this message translates to:
  /// **'Admin'**
  String get adminShellAdminTitle;

  /// L10n key: adminShellWebOnlyMessage
  ///
  /// In tr, this message translates to:
  /// **'Bu ekran sadece web üzerinde kullanılabilir.'**
  String get adminShellWebOnlyMessage;

  /// L10n key: adminShellAccessCheckFailed
  ///
  /// In tr, this message translates to:
  /// **'Admin erişimi doğrulanamadı.'**
  String get adminShellAccessCheckFailed;

  /// L10n key: adminShellAccessDenied
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfaya erişim iznin yok.'**
  String get adminShellAccessDenied;

  /// L10n key: adminShellProjectInfo
  ///
  /// In tr, this message translates to:
  /// **'Proje: {projectRef} • UID: {userId}'**
  String adminShellProjectInfo(String projectRef, String userId);

  /// L10n key: adminShellDashboardLabel
  ///
  /// In tr, this message translates to:
  /// **'Genel bakış'**
  String get adminShellDashboardLabel;

  /// L10n key: adminShellDashboardDescription
  ///
  /// In tr, this message translates to:
  /// **'Admin panel genel görünümü ve hızlı aksiyonlar.'**
  String get adminShellDashboardDescription;

  /// L10n key: adminShellQueueLabel
  ///
  /// In tr, this message translates to:
  /// **'Birleşik kuyruk'**
  String get adminShellQueueLabel;

  /// L10n key: adminShellQueueDescription
  ///
  /// In tr, this message translates to:
  /// **'Rapor, claim, fiyat ve medya moderasyonunu tek kuyrukta yönet.'**
  String get adminShellQueueDescription;

  /// L10n key: adminShellReportsLabel
  ///
  /// In tr, this message translates to:
  /// **'Raporlar'**
  String get adminShellReportsLabel;

  /// L10n key: adminShellReportsDescription
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bildirimlerini incele, durum ve atama yönet.'**
  String get adminShellReportsDescription;

  /// L10n key: adminShellAppealsLabel
  ///
  /// In tr, this message translates to:
  /// **'İtirazlar'**
  String get adminShellAppealsLabel;

  /// L10n key: adminShellAppealsDescription
  ///
  /// In tr, this message translates to:
  /// **'Moderasyon kararlarına gelen itirazları değerlendir.'**
  String get adminShellAppealsDescription;

  /// L10n key: adminShellGrowthLabel
  ///
  /// In tr, this message translates to:
  /// **'Büyüme'**
  String get adminShellGrowthLabel;

  /// L10n key: adminShellGrowthDescription
  ///
  /// In tr, this message translates to:
  /// **'Menü linki ve QR trafiğini günlük bazda takip et.'**
  String get adminShellGrowthDescription;

  /// L10n key: adminShellClaimsLabel
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talepleri'**
  String get adminShellClaimsLabel;

  /// L10n key: adminShellClaimsDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme sahipliği taleplerini onayla ya da reddet.'**
  String get adminShellClaimsDescription;

  /// L10n key: adminShellSuspendedClaimsLabel
  ///
  /// In tr, this message translates to:
  /// **'Askıdaki talepler'**
  String get adminShellSuspendedClaimsLabel;

  /// L10n key: adminShellSuspendedClaimsDescription
  ///
  /// In tr, this message translates to:
  /// **'Askıdaki yemek taleplerini doğrula ve sonuçlandır.'**
  String get adminShellSuspendedClaimsDescription;

  /// L10n key: adminShellPriceSuggestionsLabel
  ///
  /// In tr, this message translates to:
  /// **'Fiyat onayları'**
  String get adminShellPriceSuggestionsLabel;

  /// L10n key: adminShellPriceSuggestionsDescription
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerilerini değerlendir, onayla veya reddet.'**
  String get adminShellPriceSuggestionsDescription;

  /// L10n key: adminShellReceiptSubmissionsLabel
  ///
  /// In tr, this message translates to:
  /// **'Fiş doğrulama'**
  String get adminShellReceiptSubmissionsLabel;

  /// L10n key: adminShellReceiptSubmissionsDescription
  ///
  /// In tr, this message translates to:
  /// **'Fiş doğrulama gönderimlerini listele ve kontrol et.'**
  String get adminShellReceiptSubmissionsDescription;

  /// L10n key: adminShellSuggestionsLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme önerileri'**
  String get adminShellSuggestionsLabel;

  /// L10n key: adminShellSuggestionsDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme önerilerini kontrol edip işleme al.'**
  String get adminShellSuggestionsDescription;

  /// L10n key: adminShellBusinessesLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletmeler'**
  String get adminShellBusinessesLabel;

  /// L10n key: adminShellBusinessesDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme kayıtlarını düzenle, doğrula ve güncelle.'**
  String get adminShellBusinessesDescription;

  /// L10n key: adminShellBusinessSubmissionsLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme başvuruları'**
  String get adminShellBusinessSubmissionsLabel;

  /// L10n key: adminShellBusinessSubmissionsDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme başvurularını onayla veya reddet.'**
  String get adminShellBusinessSubmissionsDescription;

  /// L10n key: adminShellSponsorshipsLabel
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu gösterimler'**
  String get adminShellSponsorshipsLabel;

  /// L10n key: adminShellSponsorshipsDescription
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu işletme gösterimlerini yönet ve durum değiştir.'**
  String get adminShellSponsorshipsDescription;

  /// L10n key: adminShellSponsorshipPackagesLabel
  ///
  /// In tr, this message translates to:
  /// **'Paketler'**
  String get adminShellSponsorshipPackagesLabel;

  /// L10n key: adminShellSponsorshipPackagesDescription
  ///
  /// In tr, this message translates to:
  /// **'Sponsor paketlerini oluştur ve fiyatlandırmayı yönet.'**
  String get adminShellSponsorshipPackagesDescription;

  /// L10n key: adminShellSponsorshipLeadsLabel
  ///
  /// In tr, this message translates to:
  /// **'Lead\'ler'**
  String get adminShellSponsorshipLeadsLabel;

  /// L10n key: adminShellSponsorshipLeadsDescription
  ///
  /// In tr, this message translates to:
  /// **'Sponsor satış taleplerini takip et ve kapat.'**
  String get adminShellSponsorshipLeadsDescription;

  /// L10n key: adminShellVerifiedLabel
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama'**
  String get adminShellVerifiedLabel;

  /// L10n key: adminShellVerifiedDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme doğrulama ve premium statüsünü yönet.'**
  String get adminShellVerifiedDescription;

  /// L10n key: adminShellLocationsLabel
  ///
  /// In tr, this message translates to:
  /// **'Araçlar > Konumlar'**
  String get adminShellLocationsLabel;

  /// L10n key: adminShellLocationsDescription
  ///
  /// In tr, this message translates to:
  /// **'Konum verilerini toplu düzelt ve güncelle.'**
  String get adminShellLocationsDescription;

  /// L10n key: adminShellAuditLabel
  ///
  /// In tr, this message translates to:
  /// **'Denetim kayıtları'**
  String get adminShellAuditLabel;

  /// L10n key: adminShellAuditDescription
  ///
  /// In tr, this message translates to:
  /// **'Sistem içi işlem kayıtlarını incele.'**
  String get adminShellAuditDescription;

  /// L10n key: adminShellTableFeedbackLabel
  ///
  /// In tr, this message translates to:
  /// **'Masa geri bildirim'**
  String get adminShellTableFeedbackLabel;

  /// L10n key: adminShellTableFeedbackDescription
  ///
  /// In tr, this message translates to:
  /// **'Masa QR geri bildirimlerini görüntüle ve filtrele.'**
  String get adminShellTableFeedbackDescription;

  /// L10n key: adminShellGroupRequestsLabel
  ///
  /// In tr, this message translates to:
  /// **'Grup talepleri'**
  String get adminShellGroupRequestsLabel;

  /// L10n key: adminShellGroupRequestsDescription
  ///
  /// In tr, this message translates to:
  /// **'Grup yemeği taleplerini ve teklifleri gözlemle.'**
  String get adminShellGroupRequestsDescription;

  /// L10n key: adminShellDevToolsLabel
  ///
  /// In tr, this message translates to:
  /// **'Dev tools'**
  String get adminShellDevToolsLabel;

  /// L10n key: adminShellDevToolsDescription
  ///
  /// In tr, this message translates to:
  /// **'Feature flag ve test override ayarları.'**
  String get adminShellDevToolsDescription;

  /// L10n key: adminShellObservabilityLabel
  ///
  /// In tr, this message translates to:
  /// **'Observability'**
  String get adminShellObservabilityLabel;

  /// L10n key: adminShellObservabilityDescription
  ///
  /// In tr, this message translates to:
  /// **'Request trace, perf SLO ve prefs görünümü.'**
  String get adminShellObservabilityDescription;

  /// L10n key: adminShellB2bExportsLabel
  ///
  /// In tr, this message translates to:
  /// **'B2B veri ihracı'**
  String get adminShellB2bExportsLabel;

  /// L10n key: adminShellB2bExportsDescription
  ///
  /// In tr, this message translates to:
  /// **'Anonim trend, bölgesel fiyat endeksi ve menü enflasyonu çıktıları.'**
  String get adminShellB2bExportsDescription;

  /// L10n key: adminShellIncidentCenterLabel
  ///
  /// In tr, this message translates to:
  /// **'Kriz müdahale'**
  String get adminShellIncidentCenterLabel;

  /// L10n key: adminShellIncidentCenterDescription
  ///
  /// In tr, this message translates to:
  /// **'Şeffaf log, hazır cevaplar ve hızlı müdahale aksiyonları.'**
  String get adminShellIncidentCenterDescription;

  /// L10n key: adminShellTempUploadsLabel
  ///
  /// In tr, this message translates to:
  /// **'Geçici yükleme inceleme'**
  String get adminShellTempUploadsLabel;

  /// L10n key: adminShellTempUploadsDescription
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen geçici menü yüklemelerini incele.'**
  String get adminShellTempUploadsDescription;

  /// L10n key: adminSponsorshipLeadsTitle
  ///
  /// In tr, this message translates to:
  /// **'Sponsor talepleri'**
  String get adminSponsorshipLeadsTitle;

  /// L10n key: adminSponsorshipLeadsContactColumn
  ///
  /// In tr, this message translates to:
  /// **'İletişim'**
  String get adminSponsorshipLeadsContactColumn;

  /// L10n key: adminSponsorshipLeadsOwnerColumn
  ///
  /// In tr, this message translates to:
  /// **'İşletme sahibi'**
  String get adminSponsorshipLeadsOwnerColumn;

  /// L10n key: adminSponsorshipLeadsCreatedAtColumn
  ///
  /// In tr, this message translates to:
  /// **'Oluşturma'**
  String get adminSponsorshipLeadsCreatedAtColumn;

  /// L10n key: adminSponsorshipLeadsDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Lead detayı'**
  String get adminSponsorshipLeadsDetailTitle;

  /// L10n key: adminSponsorshipLeadsPhoneLabel
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get adminSponsorshipLeadsPhoneLabel;

  /// L10n key: adminSponsorshipLeadsMessageLabel
  ///
  /// In tr, this message translates to:
  /// **'Mesaj'**
  String get adminSponsorshipLeadsMessageLabel;

  /// L10n key: adminSponsorshipLeadsTargetingLabel
  ///
  /// In tr, this message translates to:
  /// **'Hedefleme'**
  String get adminSponsorshipLeadsTargetingLabel;

  /// L10n key: adminSponsorshipLeadsCreateSponsorship
  ///
  /// In tr, this message translates to:
  /// **'Sponsorluk oluştur'**
  String get adminSponsorshipLeadsCreateSponsorship;

  /// L10n key: adminSponsorshipLeadStatusNew
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get adminSponsorshipLeadStatusNew;

  /// L10n key: adminSponsorshipLeadStatusContacted
  ///
  /// In tr, this message translates to:
  /// **'İletişime geçildi'**
  String get adminSponsorshipLeadStatusContacted;

  /// L10n key: adminSponsorshipLeadStatusClosed
  ///
  /// In tr, this message translates to:
  /// **'Kapandı'**
  String get adminSponsorshipLeadStatusClosed;

  /// L10n key: adminSponsorshipPackagesTitle
  ///
  /// In tr, this message translates to:
  /// **'Sponsor paketleri'**
  String get adminSponsorshipPackagesTitle;

  /// L10n key: adminSponsorshipPackagesNewPackage
  ///
  /// In tr, this message translates to:
  /// **'Yeni paket'**
  String get adminSponsorshipPackagesNewPackage;

  /// L10n key: adminSponsorshipPackagesEditPackage
  ///
  /// In tr, this message translates to:
  /// **'Paket düzenle'**
  String get adminSponsorshipPackagesEditPackage;

  /// L10n key: adminSponsorshipPackagesNameColumn
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get adminSponsorshipPackagesNameColumn;

  /// L10n key: adminSponsorshipPackagesDurationColumn
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get adminSponsorshipPackagesDurationColumn;

  /// L10n key: adminSponsorshipPackagesPriceColumn
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get adminSponsorshipPackagesPriceColumn;

  /// L10n key: adminSponsorshipPackagesActiveColumn
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get adminSponsorshipPackagesActiveColumn;

  /// L10n key: adminSponsorshipPackagesCreatedAtColumn
  ///
  /// In tr, this message translates to:
  /// **'Oluşturma'**
  String get adminSponsorshipPackagesCreatedAtColumn;

  /// L10n key: adminSponsorshipPackagesDurationValue
  ///
  /// In tr, this message translates to:
  /// **'{days} gün'**
  String adminSponsorshipPackagesDurationValue(int days);

  /// L10n key: adminSponsorshipPackagesDurationInput
  ///
  /// In tr, this message translates to:
  /// **'Süre (gün)'**
  String get adminSponsorshipPackagesDurationInput;

  /// L10n key: adminSponsorshipPackagesPriceInput
  ///
  /// In tr, this message translates to:
  /// **'Fiyat gösterimi'**
  String get adminSponsorshipPackagesPriceInput;

  /// L10n key: adminSponsorshipPackagesPriceAmountInput
  ///
  /// In tr, this message translates to:
  /// **'Fiyat (kuruş)'**
  String get adminSponsorshipPackagesPriceAmountInput;

  /// L10n key: adminSponsorshipPackagesCurrencyInput
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get adminSponsorshipPackagesCurrencyInput;

  /// L10n key: adminSponsorshipPackagesInventoryInput
  ///
  /// In tr, this message translates to:
  /// **'Envanter limiti'**
  String get adminSponsorshipPackagesInventoryInput;

  /// L10n key: adminSponsorshipPackagesSurfaceDiscovery
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get adminSponsorshipPackagesSurfaceDiscovery;

  /// L10n key: adminSponsorshipPackagesSurfaceBusinessPage
  ///
  /// In tr, this message translates to:
  /// **'İşletme sayfası'**
  String get adminSponsorshipPackagesSurfaceBusinessPage;

  /// L10n key: adminSponsorshipPackagesSurfaceStories
  ///
  /// In tr, this message translates to:
  /// **'Hikayeler'**
  String get adminSponsorshipPackagesSurfaceStories;

  /// L10n key: adminSponsorshipPackagesSurfaceVerified
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get adminSponsorshipPackagesSurfaceVerified;

  /// L10n key: adminSponsorshipPackagesSurfacePremium
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get adminSponsorshipPackagesSurfacePremium;

  /// L10n key: adminSponsorshipPackagesInventoryColumn
  ///
  /// In tr, this message translates to:
  /// **'Envanter'**
  String get adminSponsorshipPackagesInventoryColumn;

  /// L10n key: adminSponsorshipsTitle
  ///
  /// In tr, this message translates to:
  /// **'Sponsorluklar'**
  String get adminSponsorshipsTitle;

  /// L10n key: adminSponsorshipsNewAction
  ///
  /// In tr, this message translates to:
  /// **'Yeni sponsorluk'**
  String get adminSponsorshipsNewAction;

  /// L10n key: adminSponsorshipsOverviewTitle
  ///
  /// In tr, this message translates to:
  /// **'Portföy özeti'**
  String get adminSponsorshipsOverviewTitle;

  /// L10n key: adminSponsorshipsOverviewDescription
  ///
  /// In tr, this message translates to:
  /// **'Aktif sponsorluk, açık lead, erişim ve tahmini gelir tek ekranda izlenir.'**
  String get adminSponsorshipsOverviewDescription;

  /// L10n key: adminSponsorshipsInventoryTitle
  ///
  /// In tr, this message translates to:
  /// **'Yüzey envanteri'**
  String get adminSponsorshipsInventoryTitle;

  /// L10n key: adminSponsorshipsInventoryDescription
  ///
  /// In tr, this message translates to:
  /// **'Her gösterim yüzeyinde canlı doluluk, boş slot ve son 30 gün performansı görünür.'**
  String get adminSponsorshipsInventoryDescription;

  /// L10n key: adminSponsorshipsSurfaceColumn
  ///
  /// In tr, this message translates to:
  /// **'Yüzey'**
  String get adminSponsorshipsSurfaceColumn;

  /// L10n key: adminSponsorshipsStatusColumn
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get adminSponsorshipsStatusColumn;

  /// L10n key: adminSponsorshipsDateRangeColumn
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get adminSponsorshipsDateRangeColumn;

  /// L10n key: adminSponsorshipsPackageColumn
  ///
  /// In tr, this message translates to:
  /// **'Paket'**
  String get adminSponsorshipsPackageColumn;

  /// L10n key: adminSponsorshipsQuotaColumn
  ///
  /// In tr, this message translates to:
  /// **'Kota'**
  String get adminSponsorshipsQuotaColumn;

  /// L10n key: adminSponsorshipsCreatedAtColumn
  ///
  /// In tr, this message translates to:
  /// **'Oluşturma'**
  String get adminSponsorshipsCreatedAtColumn;

  /// L10n key: adminSponsorshipsMetricActive
  ///
  /// In tr, this message translates to:
  /// **'Aktif sponsorluk'**
  String get adminSponsorshipsMetricActive;

  /// L10n key: adminSponsorshipsMetricPending
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen sponsorluk'**
  String get adminSponsorshipsMetricPending;

  /// L10n key: adminSponsorshipsMetricOpenLeads
  ///
  /// In tr, this message translates to:
  /// **'Açık lead'**
  String get adminSponsorshipsMetricOpenLeads;

  /// L10n key: adminSponsorshipsMetricImpressions30d
  ///
  /// In tr, this message translates to:
  /// **'30 gün gösterim'**
  String get adminSponsorshipsMetricImpressions30d;

  /// L10n key: adminSponsorshipsMetricUniqueUsers30d
  ///
  /// In tr, this message translates to:
  /// **'30 gün tekil kullanıcı'**
  String get adminSponsorshipsMetricUniqueUsers30d;

  /// L10n key: adminSponsorshipsMetricEstimatedRevenue
  ///
  /// In tr, this message translates to:
  /// **'Tahmini aktif gelir'**
  String get adminSponsorshipsMetricEstimatedRevenue;

  /// L10n key: adminSponsorshipsInventoryPackagesColumn
  ///
  /// In tr, this message translates to:
  /// **'Paketler'**
  String get adminSponsorshipsInventoryPackagesColumn;

  /// L10n key: adminSponsorshipsInventoryUnitsColumn
  ///
  /// In tr, this message translates to:
  /// **'Canlı / boş'**
  String get adminSponsorshipsInventoryUnitsColumn;

  /// L10n key: adminSponsorshipsInventoryDemandColumn
  ///
  /// In tr, this message translates to:
  /// **'Talep'**
  String get adminSponsorshipsInventoryDemandColumn;

  /// L10n key: adminSponsorshipsInventoryPerformanceColumn
  ///
  /// In tr, this message translates to:
  /// **'Performans'**
  String get adminSponsorshipsInventoryPerformanceColumn;

  /// L10n key: adminSponsorshipsInventoryPackagesValue
  ///
  /// In tr, this message translates to:
  /// **'{active} aktif / {total} toplam • limit {inventory}'**
  String adminSponsorshipsInventoryPackagesValue(
    Object active,
    Object total,
    Object inventory,
  );

  /// L10n key: adminSponsorshipsInventoryUnitsValue
  ///
  /// In tr, this message translates to:
  /// **'{live} canlı • {open} boş'**
  String adminSponsorshipsInventoryUnitsValue(Object live, Object open);

  /// L10n key: adminSponsorshipsInventoryDemandValue
  ///
  /// In tr, this message translates to:
  /// **'{pending} bekleyen • {leads} lead'**
  String adminSponsorshipsInventoryDemandValue(Object pending, Object leads);

  /// L10n key: adminSponsorshipsInventoryPerformanceValue
  ///
  /// In tr, this message translates to:
  /// **'{impressions} gösterim • {users} kullanıcı'**
  String adminSponsorshipsInventoryPerformanceValue(
    Object impressions,
    Object users,
  );

  /// L10n key: adminSponsorshipsActivateAction
  ///
  /// In tr, this message translates to:
  /// **'Aktif et'**
  String get adminSponsorshipsActivateAction;

  /// L10n key: adminSponsorshipsPauseAction
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get adminSponsorshipsPauseAction;

  /// L10n key: adminSponsorshipsEndAction
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get adminSponsorshipsEndAction;

  /// L10n key: adminSponsorshipsStatusActive
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get adminSponsorshipsStatusActive;

  /// L10n key: adminSponsorshipsStatusPaused
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı'**
  String get adminSponsorshipsStatusPaused;

  /// L10n key: adminSponsorshipsStatusEnded
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get adminSponsorshipsStatusEnded;

  /// L10n key: adminSponsorshipsQuotaValue
  ///
  /// In tr, this message translates to:
  /// **'D:{daily} / T:{total}'**
  String adminSponsorshipsQuotaValue(String daily, String total);

  /// L10n key: adminSponsorshipsInfinity
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız'**
  String get adminSponsorshipsInfinity;

  /// L10n key: adminSponsorshipsDateRangeValue
  ///
  /// In tr, this message translates to:
  /// **'{start} -> {end}'**
  String adminSponsorshipsDateRangeValue(String start, String end);

  /// L10n key: adminSuggestionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Öneriler'**
  String get adminSuggestionsTitle;

  /// L10n key: adminSuggestionsSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Ara (isim, şehir, ilçe)'**
  String get adminSuggestionsSearchHint;

  /// L10n key: adminSuggestionsNameColumn
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get adminSuggestionsNameColumn;

  /// L10n key: adminSuggestionsStatusColumn
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get adminSuggestionsStatusColumn;

  /// L10n key: adminSuggestionsCreatedAtColumn
  ///
  /// In tr, this message translates to:
  /// **'Oluşturma'**
  String get adminSuggestionsCreatedAtColumn;

  /// L10n key: adminSuggestionsSlaExceeded
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt SLA aştı: {age}'**
  String adminSuggestionsSlaExceeded(String age);

  /// L10n key: adminSuggestionsDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Öneri detayı'**
  String get adminSuggestionsDetailTitle;

  /// L10n key: adminSuggestionsCategoryLabel
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get adminSuggestionsCategoryLabel;

  /// L10n key: adminSuggestionsLocationLabel
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get adminSuggestionsLocationLabel;

  /// L10n key: adminSuggestionsAdminNoteOptional
  ///
  /// In tr, this message translates to:
  /// **'Admin notu (opsiyonel)'**
  String get adminSuggestionsAdminNoteOptional;

  /// L10n key: adminSuggestionsAssignedToMe
  ///
  /// In tr, this message translates to:
  /// **'Öneri bana atandı.'**
  String get adminSuggestionsAssignedToMe;

  /// L10n key: adminSuggestionsPossibleDuplicatesTitle
  ///
  /// In tr, this message translates to:
  /// **'Muhtemel kopyalar'**
  String get adminSuggestionsPossibleDuplicatesTitle;

  /// L10n key: adminSuggestionsNoSimilarBusiness
  ///
  /// In tr, this message translates to:
  /// **'Benzer işletme bulunamadı.'**
  String get adminSuggestionsNoSimilarBusiness;

  /// L10n key: adminSuggestionsCreatedNewBusiness
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme oluşturuldu.'**
  String get adminSuggestionsCreatedNewBusiness;

  /// L10n key: adminSuggestionsCreateNewBusiness
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme oluştur'**
  String get adminSuggestionsCreateNewBusiness;

  /// L10n key: adminSuggestionsLinkExistingConfirmTitle
  ///
  /// In tr, this message translates to:
  /// **'Mevcut işletmeyle eşleştirilsin mi?'**
  String get adminSuggestionsLinkExistingConfirmTitle;

  /// L10n key: adminSuggestionsLinkedToExisting
  ///
  /// In tr, this message translates to:
  /// **'Mevcut işletmeyle eşleştirildi.'**
  String get adminSuggestionsLinkedToExisting;

  /// L10n key: adminSuggestionsRejectSelected
  ///
  /// In tr, this message translates to:
  /// **'Seçilileri reddet'**
  String get adminSuggestionsRejectSelected;

  /// L10n key: adminSuggestionsLinkToThisBusiness
  ///
  /// In tr, this message translates to:
  /// **'Bu işletmeyle eşleştir'**
  String get adminSuggestionsLinkToThisBusiness;

  /// L10n key: adminSuggestionsNoLocation
  ///
  /// In tr, this message translates to:
  /// **'Konum yok'**
  String get adminSuggestionsNoLocation;

  /// L10n key: adminSuggestionsDaysValue
  ///
  /// In tr, this message translates to:
  /// **'{days} gün'**
  String adminSuggestionsDaysValue(String days);

  /// L10n key: adminSuspendedClaimsTitle
  ///
  /// In tr, this message translates to:
  /// **'Askıdaki talepler'**
  String get adminSuspendedClaimsTitle;

  /// L10n key: adminSuspendedClaimsAmountColumn
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get adminSuspendedClaimsAmountColumn;

  /// L10n key: adminSuspendedClaimsClaimantColumn
  ///
  /// In tr, this message translates to:
  /// **'Davacı'**
  String get adminSuspendedClaimsClaimantColumn;

  /// L10n key: adminSuspendedClaimsSlaExceeded
  ///
  /// In tr, this message translates to:
  /// **'SLA aşıldı: {age}'**
  String adminSuspendedClaimsSlaExceeded(String age);

  /// L10n key: adminSuspendedClaimsDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Talep detayı'**
  String get adminSuspendedClaimsDetailTitle;

  /// L10n key: adminSuspendedClaimsMealLabel
  ///
  /// In tr, this message translates to:
  /// **'Meal'**
  String get adminSuspendedClaimsMealLabel;

  /// L10n key: adminSuspendedClaimsRejectNoteOptional
  ///
  /// In tr, this message translates to:
  /// **'Reddetme notu (opsiyonel)'**
  String get adminSuspendedClaimsRejectNoteOptional;

  /// L10n key: adminSuspendedClaimsApproveConfirm
  ///
  /// In tr, this message translates to:
  /// **'Talep onaylansın mı?'**
  String get adminSuspendedClaimsApproveConfirm;

  /// L10n key: adminSuspendedClaimsRejectConfirm
  ///
  /// In tr, this message translates to:
  /// **'Talep reddedilsin mi?'**
  String get adminSuspendedClaimsRejectConfirm;

  /// L10n key: adminTableFeedbackTitle
  ///
  /// In tr, this message translates to:
  /// **'Masa geri bildirimleri'**
  String get adminTableFeedbackTitle;

  /// L10n key: adminTableFeedbackTableAndRating
  ///
  /// In tr, this message translates to:
  /// **'Masa {tableNo} • Puan {rating}'**
  String adminTableFeedbackTableAndRating(String tableNo, String rating);

  /// L10n key: adminTempUploadsTitle
  ///
  /// In tr, this message translates to:
  /// **'Geçici yükleme inceleme'**
  String get adminTempUploadsTitle;

  /// L10n key: adminTempUploadsPromoted
  ///
  /// In tr, this message translates to:
  /// **'Menüye aktarıldı.'**
  String get adminTempUploadsPromoted;

  /// L10n key: adminTempUploadsRejectReasonHint
  ///
  /// In tr, this message translates to:
  /// **'Red nedeni (opsiyonel)'**
  String get adminTempUploadsRejectReasonHint;

  /// L10n key: adminTempUploadsRejected
  ///
  /// In tr, this message translates to:
  /// **'Kayıt reddedildi.'**
  String get adminTempUploadsRejected;

  /// L10n key: adminTempUploadsEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen geçici yükleme yok'**
  String get adminTempUploadsEmptyTitle;

  /// L10n key: adminTempUploadsEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeni gönderimler geldiğinde burada listelenir.'**
  String get adminTempUploadsEmptyDescription;

  /// L10n key: adminTempUploadsBusinessId
  ///
  /// In tr, this message translates to:
  /// **'business_id: {businessId}'**
  String adminTempUploadsBusinessId(String businessId);

  /// L10n key: adminTempUploadsPromoteAction
  ///
  /// In tr, this message translates to:
  /// **'Menüye aktar'**
  String get adminTempUploadsPromoteAction;

  /// L10n key: adminVerifiedTitle
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama / Premium'**
  String get adminVerifiedTitle;

  /// L10n key: adminVerifiedSearchHint
  ///
  /// In tr, this message translates to:
  /// **'İşletme ara (isim/adres)'**
  String get adminVerifiedSearchHint;

  /// L10n key: adminVerifiedSearching
  ///
  /// In tr, this message translates to:
  /// **'Aranıyor...'**
  String get adminVerifiedSearching;

  /// L10n key: adminVerifiedSearchAction
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get adminVerifiedSearchAction;

  /// L10n key: adminVerifiedVerificationColumn
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama'**
  String get adminVerifiedVerificationColumn;

  /// L10n key: adminVerifiedYes
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get adminVerifiedYes;

  /// L10n key: adminVerifiedNo
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get adminVerifiedNo;

  /// L10n key: adminVerifiedSettingsTitle
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama ayarları'**
  String get adminVerifiedSettingsTitle;

  /// L10n key: adminVerifiedTierVerified
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get adminVerifiedTierVerified;

  /// L10n key: adminVerifiedTierPremium
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get adminVerifiedTierPremium;

  /// L10n key: adminVerifiedTierLabel
  ///
  /// In tr, this message translates to:
  /// **'Tier'**
  String get adminVerifiedTierLabel;

  /// L10n key: adminVerifiedEndsAtLabel
  ///
  /// In tr, this message translates to:
  /// **'Bitiş (YYYY-MM-DD)'**
  String get adminVerifiedEndsAtLabel;

  /// L10n key: loginSubmitting
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılıyor...'**
  String get loginSubmitting;

  /// L10n key: loginRegisterSubmitting
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuluyor...'**
  String get loginRegisterSubmitting;

  /// L10n key: loginRegisterSuccess
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuldu. E-posta/telefon doğrulamasını tamamla.'**
  String get loginRegisterSuccess;

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

  /// L10n key: legalTitle
  ///
  /// In tr, this message translates to:
  /// **'Yasal ve Güven'**
  String get legalTitle;

  /// L10n key: legalPrivacySectionTitle
  ///
  /// In tr, this message translates to:
  /// **'KVKK / GDPR'**
  String get legalPrivacySectionTitle;

  /// L10n key: legalPrivacyIntro
  ///
  /// In tr, this message translates to:
  /// **'{appName} kişisel verileri yalnızca hizmeti sunmak için işler. Açık rıza gerektiren işlemler için onay alınır, talep halinde veriler silinir veya taşınabilir şekilde paylaşılır.'**
  String legalPrivacyIntro(String appName);

  /// L10n key: legalPrivacyCategoriesAndRights
  ///
  /// In tr, this message translates to:
  /// **'Veri kategorileri: profil, konum, cihaz bilgisi, kullanım analitiği. Haklar: erişim, düzeltme, silme, itiraz, taşınabilirlik.'**
  String get legalPrivacyCategoriesAndRights;

  /// L10n key: legalPrivacyPolicyAction
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get legalPrivacyPolicyAction;

  /// L10n key: legalKvkkAction
  ///
  /// In tr, this message translates to:
  /// **'KVKK Metni'**
  String get legalKvkkAction;

  /// L10n key: legalGdprAction
  ///
  /// In tr, this message translates to:
  /// **'GDPR Metni'**
  String get legalGdprAction;

  /// L10n key: legalPrivacyApplicationHint
  ///
  /// In tr, this message translates to:
  /// **'Başvuru: e-posta ile talep oluştur.'**
  String get legalPrivacyApplicationHint;

  /// Auto metadata for legalCopyrightSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Foto Telif Bildirimi'**
  String get legalCopyrightSectionTitle;

  /// L10n key: legalCopyrightIntro
  ///
  /// In tr, this message translates to:
  /// **'Menü ve mekan fotoğrafları telif hakkına tabi olabilir. İhlal gördüğünde Bildir > Telif ile iletebilirsin.'**
  String get legalCopyrightIntro;

  /// L10n key: legalCopyrightBody
  ///
  /// In tr, this message translates to:
  /// **'Telif bildirimi için içerik bağlantısı, kanıt ve kısa açıklama yeterlidir. Doğrulanan ihlaller içerikten kaldırılır.'**
  String get legalCopyrightBody;

  /// L10n key: legalCopyrightPolicyAction
  ///
  /// In tr, this message translates to:
  /// **'Telif Politikası'**
  String get legalCopyrightPolicyAction;

  /// Auto metadata for legalOwnershipAppealSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme Sahipliği İtirazı'**
  String get legalOwnershipAppealSectionTitle;

  /// L10n key: legalOwnershipAppealIntro
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talebi reddedildiyse itiraz edebilirsin. Belgelerin tekrar incelenir.'**
  String get legalOwnershipAppealIntro;

  /// L10n key: legalOwnershipAppealRequirementsTitle
  ///
  /// In tr, this message translates to:
  /// **'İtiraz için gerekli bilgiler:'**
  String get legalOwnershipAppealRequirementsTitle;

  /// L10n key: legalOwnershipAppealRequirementsBody
  ///
  /// In tr, this message translates to:
  /// **'• İşyeri ünvanı ve vergi/ruhsat bilgisi\n• Yetkilendirme belgesi\n• İletişim telefonu'**
  String get legalOwnershipAppealRequirementsBody;

  /// L10n key: legalOwnershipAppealMailAction
  ///
  /// In tr, this message translates to:
  /// **'İtiraz e-postası gönder'**
  String get legalOwnershipAppealMailAction;

  /// L10n key: legalOwnershipAppealMailSubject
  ///
  /// In tr, this message translates to:
  /// **'{appName} - Sahiplik İtirazı'**
  String legalOwnershipAppealMailSubject(String appName);

  /// Auto metadata for legalProductPrinciplesSectionTitle
  ///
  /// In tr, this message translates to:
  /// **'Ürün İlkeleri'**
  String get legalProductPrinciplesSectionTitle;

  /// L10n key: legalProductPrinciplesDontsTitle
  ///
  /// In tr, this message translates to:
  /// **'Yapılmaması gerekenler:'**
  String get legalProductPrinciplesDontsTitle;

  /// L10n key: legalProductPrinciplesDontsBody
  ///
  /// In tr, this message translates to:
  /// **'• Herkese her şeyi açmak\n• Sponsorlu içeriği gizlemek\n• Owner hesaba yorum silme yetkisi vermek\n• Büyüme için kalite eşiğini gevşetmek'**
  String get legalProductPrinciplesDontsBody;

  /// L10n key: legalProductPrinciplesPolicy
  ///
  /// In tr, this message translates to:
  /// **'Policy: sponsor etiketi zorunlu={requireSponsoredLabel}, min sponsor trust={minSponsoredTrust}, owner yorum silme={ownerCanDeleteReviews}.'**
  String legalProductPrinciplesPolicy(
    String requireSponsoredLabel,
    String minSponsoredTrust,
    String ownerCanDeleteReviews,
  );

  /// L10n key: legalFooterNote
  ///
  /// In tr, this message translates to:
  /// **'Güncel politika metinleri ve detaylar web sitesinde yayımlanır.'**
  String get legalFooterNote;

  /// L10n key: ownerBusinessSubmissionsEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz başvuru yok'**
  String get ownerBusinessSubmissionsEmptyTitle;

  /// L10n key: ownerBusinessSubmissionsEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeni işletme başvuruları burada listelenecek.'**
  String get ownerBusinessSubmissionsEmptyDescription;

  /// L10n key: ownerPublicMenuLinkAction
  ///
  /// In tr, this message translates to:
  /// **'Public menü linki'**
  String get ownerPublicMenuLinkAction;

  /// L10n key: ownerCatalogLabel
  ///
  /// In tr, this message translates to:
  /// **'Katalog'**
  String get ownerCatalogLabel;

  /// L10n key: ownerSortOrder
  ///
  /// In tr, this message translates to:
  /// **'Sıra: {order}'**
  String ownerSortOrder(int order);

  /// L10n key: ownerUploadRequiresOwnership
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için işletme sahibi olmalısın.'**
  String get ownerUploadRequiresOwnership;

  /// L10n key: ownerUploadRateLimited
  ///
  /// In tr, this message translates to:
  /// **'Çok sık denedin, lütfen biraz sonra tekrar dene.'**
  String get ownerUploadRateLimited;

  /// L10n key: ownerUploadFailed
  ///
  /// In tr, this message translates to:
  /// **'Yükleme başarısız.'**
  String get ownerUploadFailed;

  /// L10n key: ownerDashboardNoPermission
  ///
  /// In tr, this message translates to:
  /// **'Bu işletme için yetkin yok.'**
  String get ownerDashboardNoPermission;

  /// L10n key: ownerDashboardOverview
  ///
  /// In tr, this message translates to:
  /// **'Operasyon özeti'**
  String get ownerDashboardOverview;

  /// L10n key: ownerDashboardOperationsDescription
  ///
  /// In tr, this message translates to:
  /// **'Menü kalitesi, güven sinyalleri ve günlük owner işleri bu ekranda toplanır.'**
  String get ownerDashboardOperationsDescription;

  /// L10n key: ownerDashboardOperationsActionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Operasyon aksiyonları'**
  String get ownerDashboardOperationsActionsTitle;

  /// L10n key: ownerDashboardOperationsActionsDescription
  ///
  /// In tr, this message translates to:
  /// **'Seçili işletme için müdahale gerektiren akışlara kısa yol.'**
  String get ownerDashboardOperationsActionsDescription;

  /// L10n key: ownerDashboardSelectBusinessForActions
  ///
  /// In tr, this message translates to:
  /// **'Önce bir işletme seç. Ardından menü, ekip ve askıda taleplere bu merkezden geç.'**
  String get ownerDashboardSelectBusinessForActions;

  /// L10n key: ownerDashboardKpiLoading
  ///
  /// In tr, this message translates to:
  /// **'KPI yükleniyor...'**
  String get ownerDashboardKpiLoading;

  /// L10n key: ownerDashboardSelectBusinessForKpi
  ///
  /// In tr, this message translates to:
  /// **'KPI için önce bir işletme seç.'**
  String get ownerDashboardSelectBusinessForKpi;

  /// L10n key: ownerDashboardKpiNotFound
  ///
  /// In tr, this message translates to:
  /// **'KPI bulunamadı.'**
  String get ownerDashboardKpiNotFound;

  /// L10n key: ownerDashboardKpiLast30Days
  ///
  /// In tr, this message translates to:
  /// **'KPI (30 gün)'**
  String get ownerDashboardKpiLast30Days;

  /// L10n key: ownerDashboardViews
  ///
  /// In tr, this message translates to:
  /// **'Görüntülenme'**
  String get ownerDashboardViews;

  /// L10n key: ownerDashboardClicks
  ///
  /// In tr, this message translates to:
  /// **'Tıklama'**
  String get ownerDashboardClicks;

  /// L10n key: ownerDashboardDirections
  ///
  /// In tr, this message translates to:
  /// **'Yol tarifi'**
  String get ownerDashboardDirections;

  /// L10n key: ownerDashboardSearchImpressions
  ///
  /// In tr, this message translates to:
  /// **'Arama gösterimi'**
  String get ownerDashboardSearchImpressions;

  /// L10n key: ownerDashboardQualityScoreLoading
  ///
  /// In tr, this message translates to:
  /// **'Kalite skoru yükleniyor...'**
  String get ownerDashboardQualityScoreLoading;

  /// L10n key: ownerDashboardSelectBusinessForScore
  ///
  /// In tr, this message translates to:
  /// **'Skoru görmek için önce bir işletme seç.'**
  String get ownerDashboardSelectBusinessForScore;

  /// L10n key: ownerDashboardScoreNotFound
  ///
  /// In tr, this message translates to:
  /// **'Skor bulunamadı.'**
  String get ownerDashboardScoreNotFound;

  /// L10n key: ownerDashboardMenuQualityScore
  ///
  /// In tr, this message translates to:
  /// **'Menü kalite skoru: {score}'**
  String ownerDashboardMenuQualityScore(int score);

  /// L10n key: ownerDashboardScoreGood
  ///
  /// In tr, this message translates to:
  /// **'Skor iyi seviyede.'**
  String get ownerDashboardScoreGood;

  /// L10n key: ownerDashboardScoreTarget
  ///
  /// In tr, this message translates to:
  /// **'Hedef 80+: aşağıdaki görevleri tamamla.'**
  String get ownerDashboardScoreTarget;

  /// L10n key: ownerDashboardNoExtraTasks
  ///
  /// In tr, this message translates to:
  /// **'Şu an için ek görev yok.'**
  String get ownerDashboardNoExtraTasks;

  /// L10n key: ownerDashboardProTitle
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy Pro'**
  String get ownerDashboardProTitle;

  /// L10n key: ownerDashboardProDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy Pro: kampanya ve görünürlük araçları.'**
  String get ownerDashboardProDescription;

  /// L10n key: ownerDashboardProFeatureSponsoredLabel
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu etiket ve şeffaf görünüm'**
  String get ownerDashboardProFeatureSponsoredLabel;

  /// L10n key: ownerDashboardProFeatureAdvancedAnalytics
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş analiz ve dönüşüm metrikleri'**
  String get ownerDashboardProFeatureAdvancedAnalytics;

  /// L10n key: ownerDashboardProFeatureCampaignAreas
  ///
  /// In tr, this message translates to:
  /// **'Kampanya ve duyuru alanları'**
  String get ownerDashboardProFeatureCampaignAreas;

  /// L10n key: ownerDashboardProFeatureFeaturedPlacement
  ///
  /// In tr, this message translates to:
  /// **'Öne çıkan alan ve ölçümlü yerleşim'**
  String get ownerDashboardProFeatureFeaturedPlacement;

  /// L10n key: ownerDashboardProFeatureMultiBranch
  ///
  /// In tr, this message translates to:
  /// **'Çok şubeyi tek panelden yönetme'**
  String get ownerDashboardProFeatureMultiBranch;

  /// L10n key: ownerDashboardProDisclaimer
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu alanlar organik kalite sırasını bozmaz.'**
  String get ownerDashboardProDisclaimer;

  /// L10n key: ownerDashboardSurfaceDiscovery
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get ownerDashboardSurfaceDiscovery;

  /// L10n key: ownerDashboardSurfaceBusinessPage
  ///
  /// In tr, this message translates to:
  /// **'İşletme sayfası'**
  String get ownerDashboardSurfaceBusinessPage;

  /// L10n key: ownerDashboardSurfaceStories
  ///
  /// In tr, this message translates to:
  /// **'Hikayeler'**
  String get ownerDashboardSurfaceStories;

  /// L10n key: ownerDashboardSurfaceVerified
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get ownerDashboardSurfaceVerified;

  /// L10n key: ownerDashboardSurfacePremium
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get ownerDashboardSurfacePremium;

  /// L10n key: ownerDashboardPreferredSurface
  ///
  /// In tr, this message translates to:
  /// **'Tercih edilen alan'**
  String get ownerDashboardPreferredSurface;

  /// L10n key: ownerDashboardTargetCities
  ///
  /// In tr, this message translates to:
  /// **'Hedef şehirler (virgülle)'**
  String get ownerDashboardTargetCities;

  /// L10n key: ownerDashboardTargetDistricts
  ///
  /// In tr, this message translates to:
  /// **'Hedef ilçeler (virgülle)'**
  String get ownerDashboardTargetDistricts;

  /// L10n key: ownerDashboardTargetCategories
  ///
  /// In tr, this message translates to:
  /// **'Hedef kategoriler (virgülle)'**
  String get ownerDashboardTargetCategories;

  /// L10n key: ownerDashboardMonthlyBudgetOptional
  ///
  /// In tr, this message translates to:
  /// **'Aylık bütçe (opsiyonel)'**
  String get ownerDashboardMonthlyBudgetOptional;

  /// L10n key: ownerDashboardMonthlyImpressionsOptional
  ///
  /// In tr, this message translates to:
  /// **'Aylık gösterim hedefi (opsiyonel)'**
  String get ownerDashboardMonthlyImpressionsOptional;

  /// L10n key: ownerDashboardPhoneOptional
  ///
  /// In tr, this message translates to:
  /// **'Telefon (opsiyonel)'**
  String get ownerDashboardPhoneOptional;

  /// L10n key: ownerDashboardNoteHint
  ///
  /// In tr, this message translates to:
  /// **'Hedef bölge veya kampanya notu...'**
  String get ownerDashboardNoteHint;

  /// L10n key: ownerDashboardSubmitting
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor...'**
  String get ownerDashboardSubmitting;

  /// L10n key: ownerDashboardSubmitProLead
  ///
  /// In tr, this message translates to:
  /// **'Pro talebi gönder'**
  String get ownerDashboardSubmitProLead;

  /// L10n key: ownerDashboardSelectBusinessFirst
  ///
  /// In tr, this message translates to:
  /// **'Önce bir işletme seçmelisin.'**
  String get ownerDashboardSelectBusinessFirst;

  /// L10n key: ownerDashboardRequestReceived
  ///
  /// In tr, this message translates to:
  /// **'Talebini aldık.'**
  String get ownerDashboardRequestReceived;

  /// L10n key: ownerDashboardMoatLoading
  ///
  /// In tr, this message translates to:
  /// **'Savunma özeti yükleniyor...'**
  String get ownerDashboardMoatLoading;

  /// L10n key: ownerDashboardSelectBusinessForMoat
  ///
  /// In tr, this message translates to:
  /// **'Skorları görmek için önce bir işletme seç.'**
  String get ownerDashboardSelectBusinessForMoat;

  /// L10n key: ownerDashboardMoatNotFound
  ///
  /// In tr, this message translates to:
  /// **'Skor verisi bulunamadı.'**
  String get ownerDashboardMoatNotFound;

  /// L10n key: ownerDashboardSignals
  ///
  /// In tr, this message translates to:
  /// **'Sinyaller: {validators} doğrulayıcı'**
  String ownerDashboardSignals(int validators);

  /// L10n key: ownerDashboardLastVerification
  ///
  /// In tr, this message translates to:
  /// **'son doğrulama {date}'**
  String ownerDashboardLastVerification(String date);

  /// L10n key: ownerDashboardLongTermDefense
  ///
  /// In tr, this message translates to:
  /// **'Uzun vadeli savunma duvarı'**
  String get ownerDashboardLongTermDefense;

  /// L10n key: ownerDashboardLongTermDefenseDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu skorlar arama sıralaması, öne çıkarma ve sponsor filtrelerinde kullanılır.'**
  String get ownerDashboardLongTermDefenseDescription;

  /// L10n key: ownerDashboardBusinessTrust
  ///
  /// In tr, this message translates to:
  /// **'İşletme güveni'**
  String get ownerDashboardBusinessTrust;

  /// L10n key: ownerDashboardMenuFreshness
  ///
  /// In tr, this message translates to:
  /// **'Menü güncelliği'**
  String get ownerDashboardMenuFreshness;

  /// L10n key: ownerDashboardPriceAccuracy
  ///
  /// In tr, this message translates to:
  /// **'Fiyat doğruluğu'**
  String get ownerDashboardPriceAccuracy;

  /// L10n key: ownerDashboardContributionTrust
  ///
  /// In tr, this message translates to:
  /// **'Katkı güveni'**
  String get ownerDashboardContributionTrust;

  /// L10n key: ownerDashboardEvidenceSummary
  ///
  /// In tr, this message translates to:
  /// **'Kanıt oranı: %{evidencePct} - Geçmiş katkı kalitesi: %{qualityPct}'**
  String ownerDashboardEvidenceSummary(int evidencePct, int qualityPct);

  /// L10n key: ownerDashboardLocalMicroData
  ///
  /// In tr, this message translates to:
  /// **'Yerel mikro veri: bugün menü bakma {viewsToday}'**
  String ownerDashboardLocalMicroData(int viewsToday);

  /// L10n key: ownerDashboardLocalMicroDataWithRank
  ///
  /// In tr, this message translates to:
  /// **'Yerel mikro veri: bugün menü bakma {viewsToday} - ilçe sırası #{rank}'**
  String ownerDashboardLocalMicroDataWithRank(int viewsToday, int rank);

  /// L10n key: ownerMenuManagementTitle
  ///
  /// In tr, this message translates to:
  /// **'Menü yönetimi'**
  String get ownerMenuManagementTitle;

  /// L10n key: ownerApprovedBusinessNotFound
  ///
  /// In tr, this message translates to:
  /// **'Onaylı işletme bulunamadı.'**
  String get ownerApprovedBusinessNotFound;

  /// L10n key: ownerMenuNotFound
  ///
  /// In tr, this message translates to:
  /// **'Henüz menü yok.'**
  String get ownerMenuNotFound;

  /// L10n key: ownerCreateMenuAction
  ///
  /// In tr, this message translates to:
  /// **'Yeni menü oluştur'**
  String get ownerCreateMenuAction;

  /// L10n key: ownerCreateMenuTitle
  ///
  /// In tr, this message translates to:
  /// **'Yeni menü'**
  String get ownerCreateMenuTitle;

  /// L10n key: ownerCreateAction
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get ownerCreateAction;

  /// L10n key: ownerMenuCreated
  ///
  /// In tr, this message translates to:
  /// **'Menü oluşturuldu.'**
  String get ownerMenuCreated;

  /// L10n key: ownerMenuArchived
  ///
  /// In tr, this message translates to:
  /// **'Menü arşivlendi.'**
  String get ownerMenuArchived;

  /// L10n key: ownerMenuPublished
  ///
  /// In tr, this message translates to:
  /// **'Menü yayına alındı.'**
  String get ownerMenuPublished;

  /// L10n key: ownerDigitalMenuStudioTitle
  ///
  /// In tr, this message translates to:
  /// **'Dijital Menü & QR Studio'**
  String get ownerDigitalMenuStudioTitle;

  /// L10n key: ownerDigitalMenuStudioSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Panelden başlat, tema, dil, bağlantı ve QR çıktısını tek yerden yönet.'**
  String get ownerDigitalMenuStudioSubtitle;

  /// L10n key: ownerAmenitiesTitle
  ///
  /// In tr, this message translates to:
  /// **'Özellikler'**
  String get ownerAmenitiesTitle;

  /// L10n key: ownerAmenitiesUpdated
  ///
  /// In tr, this message translates to:
  /// **'Özellikler güncellendi.'**
  String get ownerAmenitiesUpdated;

  /// L10n key: ownerProfileCompletionTitle
  ///
  /// In tr, this message translates to:
  /// **'Profil tamamlama'**
  String get ownerProfileCompletionTitle;

  /// L10n key: ownerProfileCompletionPercent
  ///
  /// In tr, this message translates to:
  /// **'%{pct} tamamlandı'**
  String ownerProfileCompletionPercent(int pct);

  /// L10n key: ownerSponsoredRequestsSoon
  ///
  /// In tr, this message translates to:
  /// **'Sponsor talepleri yakında açılacak.'**
  String get ownerSponsoredRequestsSoon;

  /// L10n key: ownerSponsoredVisibilityAction
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu görünürlük al'**
  String get ownerSponsoredVisibilityAction;

  /// L10n key: ownerMenuErrorNotOwner
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için yetkin yok.'**
  String get ownerMenuErrorNotOwner;

  /// L10n key: ownerMenuErrorNotFound
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı.'**
  String get ownerMenuErrorNotFound;

  /// L10n key: ownerMenuErrorHasItems
  ///
  /// In tr, this message translates to:
  /// **'Bölümde ürünler var.'**
  String get ownerMenuErrorHasItems;

  /// L10n key: ownerMenuErrorGeneric
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu.'**
  String get ownerMenuErrorGeneric;

  /// L10n key: ownerMoatPitchText
  ///
  /// In tr, this message translates to:
  /// **'{businessName} | Güven skoru {trust}/100 | Menü güncelliği {freshness}/100 | Fiyat doğruluğu {accuracy}/100 | {validators} doğrulayıcı | Kanıt oranı %{evidencePct} | Bugün menü bakma {viewsToday}\n{link}'**
  String ownerMoatPitchText(
    String businessName,
    int trust,
    int freshness,
    int accuracy,
    int validators,
    int evidencePct,
    int viewsToday,
    String link,
  );

  /// L10n key: ownerApproveAction
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get ownerApproveAction;

  /// L10n key: ownerRejectAction
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get ownerRejectAction;

  /// L10n key: ownerOnboardingTitle
  ///
  /// In tr, this message translates to:
  /// **'Kurulum'**
  String get ownerOnboardingTitle;

  /// L10n key: ownerOnboardingContinue
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get ownerOnboardingContinue;

  /// L10n key: ownerOnboardingFinish
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get ownerOnboardingFinish;

  /// L10n key: ownerOnboardingStepProfile
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get ownerOnboardingStepProfile;

  /// L10n key: ownerOnboardingStepAmenities
  ///
  /// In tr, this message translates to:
  /// **'Özellikler'**
  String get ownerOnboardingStepAmenities;

  /// L10n key: ownerOnboardingStepMenu
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get ownerOnboardingStepMenu;

  /// L10n key: ownerOnboardingStepPreview
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get ownerOnboardingStepPreview;

  /// L10n key: ownerOnboardingStepShare
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get ownerOnboardingStepShare;

  /// L10n key: ownerOnboardingUrlHint
  ///
  /// In tr, this message translates to:
  /// **'https://...'**
  String get ownerOnboardingUrlHint;

  /// L10n key: ownerOnboardingPasteAction
  ///
  /// In tr, this message translates to:
  /// **'Yapıştır'**
  String get ownerOnboardingPasteAction;

  /// L10n key: ownerOnboardingProfileIntro
  ///
  /// In tr, this message translates to:
  /// **'Logo ve kapak ekleyin, çalışma saatlerini belirleyin.'**
  String get ownerOnboardingProfileIntro;

  /// L10n key: ownerOnboardingLogoUrl
  ///
  /// In tr, this message translates to:
  /// **'Logo URL'**
  String get ownerOnboardingLogoUrl;

  /// L10n key: ownerOnboardingCoverUrl
  ///
  /// In tr, this message translates to:
  /// **'Kapak URL'**
  String get ownerOnboardingCoverUrl;

  /// L10n key: ownerOnboardingSelectOpenTime
  ///
  /// In tr, this message translates to:
  /// **'Açılış saatini seç'**
  String get ownerOnboardingSelectOpenTime;

  /// L10n key: ownerOnboardingOpenTime
  ///
  /// In tr, this message translates to:
  /// **'Açılış: {time}'**
  String ownerOnboardingOpenTime(String time);

  /// L10n key: ownerOnboardingSelectCloseTime
  ///
  /// In tr, this message translates to:
  /// **'Kapanış saatini seç'**
  String get ownerOnboardingSelectCloseTime;

  /// L10n key: ownerOnboardingCloseTime
  ///
  /// In tr, this message translates to:
  /// **'Kapanış: {time}'**
  String ownerOnboardingCloseTime(String time);

  /// L10n key: ownerOnboardingHoursHint
  ///
  /// In tr, this message translates to:
  /// **'Saatler tüm günlere uygulanır.'**
  String get ownerOnboardingHoursHint;

  /// L10n key: ownerOnboardingBusinessLinks
  ///
  /// In tr, this message translates to:
  /// **'İşletme linkleri (Instagram / YouTube / Facebook)'**
  String get ownerOnboardingBusinessLinks;

  /// L10n key: ownerOnboardingInstagramPreview
  ///
  /// In tr, this message translates to:
  /// **'Instagram önizleme'**
  String get ownerOnboardingInstagramPreview;

  /// L10n key: ownerOnboardingYoutubePreview
  ///
  /// In tr, this message translates to:
  /// **'YouTube önizleme'**
  String get ownerOnboardingYoutubePreview;

  /// L10n key: ownerOnboardingFacebookPreview
  ///
  /// In tr, this message translates to:
  /// **'Facebook önizleme'**
  String get ownerOnboardingFacebookPreview;

  /// L10n key: ownerOnboardingLinksPending
  ///
  /// In tr, this message translates to:
  /// **'Linkleri kaydetme adımı yakında eklenecek.'**
  String get ownerOnboardingLinksPending;

  /// L10n key: ownerOnboardingAmenitiesListNotFound
  ///
  /// In tr, this message translates to:
  /// **'Özellik listesi bulunamadı.'**
  String get ownerOnboardingAmenitiesListNotFound;

  /// L10n key: ownerOnboardingSelectAtLeastTwoAmenities
  ///
  /// In tr, this message translates to:
  /// **'En az 2 özellik seçmelisin.'**
  String get ownerOnboardingSelectAtLeastTwoAmenities;

  /// L10n key: ownerOnboardingMenuRequirement
  ///
  /// In tr, this message translates to:
  /// **'En az 1 bölüm ve 1 ürün gerekli.'**
  String get ownerOnboardingMenuRequirement;

  /// L10n key: ownerOnboardingMenuCount
  ///
  /// In tr, this message translates to:
  /// **'Menü sayısı: {count}'**
  String ownerOnboardingMenuCount(int count);

  /// L10n key: ownerOnboardingSectionCount
  ///
  /// In tr, this message translates to:
  /// **'Bölüm sayısı: {count}'**
  String ownerOnboardingSectionCount(int count);

  /// L10n key: ownerOnboardingItemCount
  ///
  /// In tr, this message translates to:
  /// **'Ürün sayısı: {count}'**
  String ownerOnboardingItemCount(int count);

  /// L10n key: ownerOnboardingNoShareWithoutMenu
  ///
  /// In tr, this message translates to:
  /// **'Menüsüz paylaşım olmaz.'**
  String get ownerOnboardingNoShareWithoutMenu;

  /// L10n key: ownerOnboardingGoToMenuManagement
  ///
  /// In tr, this message translates to:
  /// **'Menü yönetimine git'**
  String get ownerOnboardingGoToMenuManagement;

  /// L10n key: ownerOnboardingPreviewRequiresMenu
  ///
  /// In tr, this message translates to:
  /// **'Önizleme için önce menü oluştur.'**
  String get ownerOnboardingPreviewRequiresMenu;

  /// L10n key: ownerOnboardingPreviewNoItems
  ///
  /// In tr, this message translates to:
  /// **'Ürün bulunamadı.'**
  String get ownerOnboardingPreviewNoItems;

  /// L10n key: ownerOnboardingShareRequiresMenu
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım için önce menü oluştur.'**
  String get ownerOnboardingShareRequiresMenu;

  /// L10n key: ownerOnboardingShareLinkTitle
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım bağlantısı'**
  String get ownerOnboardingShareLinkTitle;

  /// L10n key: ownerOnboardingCopyLink
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kopyala'**
  String get ownerOnboardingCopyLink;

  /// L10n key: ownerOnboardingDownloadQr
  ///
  /// In tr, this message translates to:
  /// **'QR indir'**
  String get ownerOnboardingDownloadQr;

  /// L10n key: ownerOnboardingPreviewMenu
  ///
  /// In tr, this message translates to:
  /// **'Menü: {title}'**
  String ownerOnboardingPreviewMenu(String title);

  /// L10n key: ownerOnboardingLogoCoverRequired
  ///
  /// In tr, this message translates to:
  /// **'Logo ve kapak zorunlu.'**
  String get ownerOnboardingLogoCoverRequired;

  /// L10n key: ownerOnboardingHoursRequired
  ///
  /// In tr, this message translates to:
  /// **'Saatler zorunlu.'**
  String get ownerOnboardingHoursRequired;

  /// L10n key: ownerOnboardingQrNotReady
  ///
  /// In tr, this message translates to:
  /// **'QR henüz hazır değil.'**
  String get ownerOnboardingQrNotReady;

  /// L10n key: ownerOnboardingQrDownloadFailed
  ///
  /// In tr, this message translates to:
  /// **'QR indirilemedi.'**
  String get ownerOnboardingQrDownloadFailed;

  /// L10n key: ownerOnboardingWhatsappShareText
  ///
  /// In tr, this message translates to:
  /// **'Menümüz güncel. Buradan inceleyebilirsin: {link}'**
  String ownerOnboardingWhatsappShareText(String link);

  /// L10n key: ownerOnboardingXShareText
  ///
  /// In tr, this message translates to:
  /// **'Güncel menü ve doğrulanmış fiyatlar: {link}'**
  String ownerOnboardingXShareText(String link);

  /// L10n key: ownerOnboardingInstagramShareText
  ///
  /// In tr, this message translates to:
  /// **'Güncel menü ve doğrulanmış fiyatlar: {link}'**
  String ownerOnboardingInstagramShareText(String link);

  /// L10n key: ownerPriceSuggestionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Fiyat onayları'**
  String get ownerPriceSuggestionsTitle;

  /// L10n key: ownerPriceSuggestionsEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok'**
  String get ownerPriceSuggestionsEmptyTitle;

  /// L10n key: ownerPriceSuggestionsEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Yeni fiyat önerileri burada listelenecek.'**
  String get ownerPriceSuggestionsEmptyDescription;

  /// L10n key: ownerPriceSuggestionsApproveConfirm
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi onaylansın mı?'**
  String get ownerPriceSuggestionsApproveConfirm;

  /// L10n key: ownerPriceSuggestionsApproved
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı.'**
  String get ownerPriceSuggestionsApproved;

  /// L10n key: ownerPriceSuggestionsRejectReasonLabel
  ///
  /// In tr, this message translates to:
  /// **'Ret nedeni (en az 3 karakter)'**
  String get ownerPriceSuggestionsRejectReasonLabel;

  /// L10n key: ownerPriceSuggestionsRejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi.'**
  String get ownerPriceSuggestionsRejected;

  /// L10n key: ownerPriceSuggestionsConfidence
  ///
  /// In tr, this message translates to:
  /// **'Güven {pct}%'**
  String ownerPriceSuggestionsConfidence(int pct);

  /// L10n key: ownerPriceSuggestionsConflictCount
  ///
  /// In tr, this message translates to:
  /// **'Çakışma: {count} fiyat'**
  String ownerPriceSuggestionsConflictCount(int count);

  /// L10n key: ownerPriceSuggestionsAnomaly
  ///
  /// In tr, this message translates to:
  /// **'Anomali'**
  String get ownerPriceSuggestionsAnomaly;

  /// L10n key: ownerPriceSuggestionsAnomalyFlag
  ///
  /// In tr, this message translates to:
  /// **'Anomali: {flag}'**
  String ownerPriceSuggestionsAnomalyFlag(String flag);

  /// L10n key: ownerPriceSuggestionsConflictVariants
  ///
  /// In tr, this message translates to:
  /// **'Çakışma: aynı ürün için {count} farklı öneri var'**
  String ownerPriceSuggestionsConflictVariants(int count);

  /// L10n key: ownerGroupRequestsTitle
  ///
  /// In tr, this message translates to:
  /// **'Talepler'**
  String get ownerGroupRequestsTitle;

  /// L10n key: ownerGroupRequestsOpenRequests
  ///
  /// In tr, this message translates to:
  /// **'Açık talepler'**
  String get ownerGroupRequestsOpenRequests;

  /// L10n key: ownerGroupRequestsEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Talep yok'**
  String get ownerGroupRequestsEmptyTitle;

  /// L10n key: ownerGroupRequestsEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Açık grup yemeği talebi bulunamadı.'**
  String get ownerGroupRequestsEmptyDescription;

  /// L10n key: ownerGroupRequestsPartyBudget
  ///
  /// In tr, this message translates to:
  /// **'{partySize} kişi • {budget}'**
  String ownerGroupRequestsPartyBudget(int partySize, String budget);

  /// L10n key: ownerGroupRequestsOfferAction
  ///
  /// In tr, this message translates to:
  /// **'Teklif ver'**
  String get ownerGroupRequestsOfferAction;

  /// L10n key: ownerGroupRequestsMyOffers
  ///
  /// In tr, this message translates to:
  /// **'Tekliflerim'**
  String get ownerGroupRequestsMyOffers;

  /// L10n key: ownerGroupRequestsOffersEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Teklif yok'**
  String get ownerGroupRequestsOffersEmptyTitle;

  /// L10n key: ownerGroupRequestsOffersEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Verdiğin teklifler burada görünür.'**
  String get ownerGroupRequestsOffersEmptyDescription;

  /// L10n key: ownerGroupRequestsOfferStatus
  ///
  /// In tr, this message translates to:
  /// **'Durum: {status}'**
  String ownerGroupRequestsOfferStatus(String status);

  /// L10n key: ownerGroupRequestsTotalOfferLabel
  ///
  /// In tr, this message translates to:
  /// **'Toplam teklif (TL)'**
  String get ownerGroupRequestsTotalOfferLabel;

  /// L10n key: ownerGroupRequestsDessertIncluded
  ///
  /// In tr, this message translates to:
  /// **'Tatlı dahil'**
  String get ownerGroupRequestsDessertIncluded;

  /// L10n key: ownerGroupRequestsDrinksIncluded
  ///
  /// In tr, this message translates to:
  /// **'İçecek dahil'**
  String get ownerGroupRequestsDrinksIncluded;

  /// L10n key: ownerGroupRequestsMenuFixed
  ///
  /// In tr, this message translates to:
  /// **'Menü sabit'**
  String get ownerGroupRequestsMenuFixed;

  /// L10n key: ownerGroupRequestsEnterValidPrice
  ///
  /// In tr, this message translates to:
  /// **'Geçerli fiyat girin.'**
  String get ownerGroupRequestsEnterValidPrice;

  /// L10n key: ownerGroupRequestsOfferSent
  ///
  /// In tr, this message translates to:
  /// **'Teklif gönderildi.'**
  String get ownerGroupRequestsOfferSent;

  /// L10n key: search
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// L10n key: clear
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// L10n key: forbiddenTitle
  ///
  /// In tr, this message translates to:
  /// **'Erişim engellendi'**
  String get forbiddenTitle;

  /// L10n key: forbiddenDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu alana erişim yetkin bulunmuyor. Farklı bir panel veya işletme seçerek devam et.'**
  String get forbiddenDescription;

  /// L10n key: forbiddenDescriptionWithRoute
  ///
  /// In tr, this message translates to:
  /// **'Bu alana erişim yetkin bulunmuyor. İstenen adres: {route}'**
  String forbiddenDescriptionWithRoute(String route);

  /// L10n key: forbiddenBackHomeAction
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfaya dön'**
  String get forbiddenBackHomeAction;

  /// L10n key: forbiddenGoBusinessesAction
  ///
  /// In tr, this message translates to:
  /// **'İşletmelerime git'**
  String get forbiddenGoBusinessesAction;

  /// L10n key: ownerShellPanelTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme Paneli'**
  String get ownerShellPanelTitle;

  /// L10n key: ownerShellOverviewLabel
  ///
  /// In tr, this message translates to:
  /// **'Operasyon'**
  String get ownerShellOverviewLabel;

  /// L10n key: ownerShellGrowthLabel
  ///
  /// In tr, this message translates to:
  /// **'Büyüme'**
  String get ownerShellGrowthLabel;

  /// L10n key: ownerShellPriceSuggestionsLabel
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerileri'**
  String get ownerShellPriceSuggestionsLabel;

  /// L10n key: ownerShellSuspendedClaimsLabel
  ///
  /// In tr, this message translates to:
  /// **'Askıda talepler'**
  String get ownerShellSuspendedClaimsLabel;

  /// L10n key: ownerShellRequestsLabel
  ///
  /// In tr, this message translates to:
  /// **'Talepler'**
  String get ownerShellRequestsLabel;

  /// L10n key: ownerShellAuditLabel
  ///
  /// In tr, this message translates to:
  /// **'Denetim'**
  String get ownerShellAuditLabel;

  /// L10n key: ownerSelectedBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'Seçili işletme'**
  String get ownerSelectedBusinessTitle;

  /// L10n key: ownerBusinessSwitcherLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme değiştir'**
  String get ownerBusinessSwitcherLabel;

  /// L10n key: ownerGoBusinessesAction
  ///
  /// In tr, this message translates to:
  /// **'İşletmelerime git'**
  String get ownerGoBusinessesAction;

  /// L10n key: ownerBusinessContextEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Önce bir işletme seç'**
  String get ownerBusinessContextEmptyTitle;

  /// L10n key: ownerBusinessContextEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme bağlamı burada görünür. Menü, fiyat ve talepleri yönetmek için işletmelerim sayfasından seçim yap.'**
  String get ownerBusinessContextEmptyDescription;

  /// L10n key: ownerBusinessContextLoadError
  ///
  /// In tr, this message translates to:
  /// **'İşletme bağlamı yüklenemedi.'**
  String get ownerBusinessContextLoadError;

  /// L10n key: ownerNoBusinessPermissionTitle
  ///
  /// In tr, this message translates to:
  /// **'Bu işletme için erişimin yok'**
  String get ownerNoBusinessPermissionTitle;

  /// L10n key: ownerNoBusinessPermissionDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu işletmeyi yönetme yetkin doğrulanamadı. Başka bir işletme seç veya erişim durumunu kontrol et.'**
  String get ownerNoBusinessPermissionDescription;

  /// L10n key: ownerBusinessSelectionRequiredDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu ekran için önce yönetebildiğin bir işletme seçmen gerekiyor.'**
  String get ownerBusinessSelectionRequiredDescription;

  /// L10n key: adminTableStatusLabel
  ///
  /// In tr, this message translates to:
  /// **'Durum filtresi'**
  String get adminTableStatusLabel;

  /// L10n key: adminTableSavedViewsLabel
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı görünüm'**
  String get adminTableSavedViewsLabel;

  /// L10n key: adminTableNoSavedViews
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı görünüm yok'**
  String get adminTableNoSavedViews;

  /// L10n key: adminTableSaveViewAction
  ///
  /// In tr, this message translates to:
  /// **'Görünümü kaydet'**
  String get adminTableSaveViewAction;

  /// L10n key: adminTableDeleteViewAction
  ///
  /// In tr, this message translates to:
  /// **'Görünümü sil'**
  String get adminTableDeleteViewAction;

  /// L10n key: adminTableViewNameLabel
  ///
  /// In tr, this message translates to:
  /// **'Görünüm adı'**
  String get adminTableViewNameLabel;

  /// L10n key: adminTableViewNameHint
  ///
  /// In tr, this message translates to:
  /// **'Örn. Son 7 gün / Açık kayıtlar'**
  String get adminTableViewNameHint;

  /// L10n key: adminTablePickDateRangeAction
  ///
  /// In tr, this message translates to:
  /// **'Tarih aralığı seç'**
  String get adminTablePickDateRangeAction;

  /// L10n key: adminTableClearDateRangeAction
  ///
  /// In tr, this message translates to:
  /// **'Tarihi temizle'**
  String get adminTableClearDateRangeAction;

  /// L10n key: adminTableDateRangeValue
  ///
  /// In tr, this message translates to:
  /// **'{start} - {end}'**
  String adminTableDateRangeValue(String start, String end);

  /// L10n key: adminTableBulkSelectionCount
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt seçildi'**
  String adminTableBulkSelectionCount(int count);

  /// L10n key: adminTableRowsPerPageLabel
  ///
  /// In tr, this message translates to:
  /// **'Sayfa başına'**
  String get adminTableRowsPerPageLabel;

  /// L10n key: adminTablePageRange
  ///
  /// In tr, this message translates to:
  /// **'{start}-{end} / {total}'**
  String adminTablePageRange(int start, int end, int total);

  /// L10n key: adminTablePrevPageAction
  ///
  /// In tr, this message translates to:
  /// **'Önceki sayfa'**
  String get adminTablePrevPageAction;

  /// L10n key: adminTableNextPageAction
  ///
  /// In tr, this message translates to:
  /// **'Sonraki sayfa'**
  String get adminTableNextPageAction;

  /// L10n key: adminTableSavedViewCreated
  ///
  /// In tr, this message translates to:
  /// **'Görünüm kaydedildi.'**
  String get adminTableSavedViewCreated;

  /// L10n key: adminTableSavedViewDeleted
  ///
  /// In tr, this message translates to:
  /// **'Görünüm silindi.'**
  String get adminTableSavedViewDeleted;

  /// L10n key: adminQueueTitle
  ///
  /// In tr, this message translates to:
  /// **'Birleşik kuyruk'**
  String get adminQueueTitle;

  /// L10n key: adminQueueDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme başvurularını, raporları, fiyat önerilerini, sahiplik taleplerini ve medya ihbarlarını tek operatör kuyruğunda yönet.'**
  String get adminQueueDescription;

  /// L10n key: adminQueueErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Kuyruk yüklenemedi'**
  String get adminQueueErrorTitle;

  /// L10n key: adminQueueSearchHint
  ///
  /// In tr, this message translates to:
  /// **'İşletme, içerik veya açıklama ara'**
  String get adminQueueSearchHint;

  /// L10n key: adminQueueTypeLabel
  ///
  /// In tr, this message translates to:
  /// **'Kayıt tipi'**
  String get adminQueueTypeLabel;

  /// L10n key: adminQueueCityHint
  ///
  /// In tr, this message translates to:
  /// **'Şehir filtresi'**
  String get adminQueueCityHint;

  /// L10n key: adminQueueUnassignSelectedAction
  ///
  /// In tr, this message translates to:
  /// **'Seçililerin atamasını kaldır'**
  String get adminQueueUnassignSelectedAction;

  /// L10n key: adminQueueEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Seçili filtrelere uyan kuyruk kaydı bulunamadı.'**
  String get adminQueueEmptyDescription;

  /// L10n key: adminQueueColumnType
  ///
  /// In tr, this message translates to:
  /// **'Tip'**
  String get adminQueueColumnType;

  /// L10n key: adminQueueColumnTitle
  ///
  /// In tr, this message translates to:
  /// **'Kayıt'**
  String get adminQueueColumnTitle;

  /// L10n key: adminQueueColumnCreatedAt
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma'**
  String get adminQueueColumnCreatedAt;

  /// L10n key: adminQueueAssignToMeAction
  ///
  /// In tr, this message translates to:
  /// **'Bana ata'**
  String get adminQueueAssignToMeAction;

  /// L10n key: adminQueueUnassignAction
  ///
  /// In tr, this message translates to:
  /// **'Atamayı kaldır'**
  String get adminQueueUnassignAction;

  /// L10n key: adminQueueOpenDetailsAction
  ///
  /// In tr, this message translates to:
  /// **'Detayı aç'**
  String get adminQueueOpenDetailsAction;

  /// L10n key: adminQueueAssignedToMe
  ///
  /// In tr, this message translates to:
  /// **'Kayıt sana atandı.'**
  String get adminQueueAssignedToMe;

  /// L10n key: adminQueueUnassigned
  ///
  /// In tr, this message translates to:
  /// **'Kayıt atamadan çıkarıldı.'**
  String get adminQueueUnassigned;

  /// L10n key: adminQueueBulkAssignmentResult
  ///
  /// In tr, this message translates to:
  /// **'{applied} / {total} kayıt için atama güncellendi.'**
  String adminQueueBulkAssignmentResult(int applied, int total);

  /// L10n key: adminQueueBulkDecisionResult
  ///
  /// In tr, this message translates to:
  /// **'{applied} kayıt işlendi, {skipped} kayıt atlandı.'**
  String adminQueueBulkDecisionResult(int applied, int skipped);

  /// L10n key: adminQueueRejectDialogTitle
  ///
  /// In tr, this message translates to:
  /// **'Reddetme notu'**
  String get adminQueueRejectDialogTitle;

  /// L10n key: adminQueueRejectDialogLabel
  ///
  /// In tr, this message translates to:
  /// **'Operasyon notu'**
  String get adminQueueRejectDialogLabel;

  /// L10n key: adminQueueRejectDialogRequiredHint
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt tipi için red notu zorunlu.'**
  String get adminQueueRejectDialogRequiredHint;

  /// L10n key: adminQueueRejectDialogOptionalHint
  ///
  /// In tr, this message translates to:
  /// **'İstersen karar gerekçesi ekleyebilirsin.'**
  String get adminQueueRejectDialogOptionalHint;

  /// L10n key: adminQueueDetailTitle
  ///
  /// In tr, this message translates to:
  /// **'Kuyruk detayı'**
  String get adminQueueDetailTitle;

  /// L10n key: adminQueueOpenSourceAction
  ///
  /// In tr, this message translates to:
  /// **'Kaynak ekrana git'**
  String get adminQueueOpenSourceAction;

  /// L10n key: adminQueueDetailPayloadTitle
  ///
  /// In tr, this message translates to:
  /// **'Ham kayıt detayı'**
  String get adminQueueDetailPayloadTitle;

  /// L10n key: adminQueueExportCsvAction
  ///
  /// In tr, this message translates to:
  /// **'CSV dışa aktar'**
  String get adminQueueExportCsvAction;

  /// L10n key: adminQueueExportReady
  ///
  /// In tr, this message translates to:
  /// **'{count} kuyruk kaydı CSV olarak indirildi.'**
  String adminQueueExportReady(Object count);

  /// L10n key: adminQueuePreviewTitle
  ///
  /// In tr, this message translates to:
  /// **'Operasyon özeti'**
  String get adminQueuePreviewTitle;

  /// L10n key: adminQueuePreviewApplicantLabel
  ///
  /// In tr, this message translates to:
  /// **'Başvuran'**
  String get adminQueuePreviewApplicantLabel;

  /// L10n key: adminQueuePreviewCategoryLabel
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get adminQueuePreviewCategoryLabel;

  /// L10n key: adminQueuePreviewAddressLabel
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get adminQueuePreviewAddressLabel;

  /// L10n key: adminQueuePreviewPhoneLabel
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get adminQueuePreviewPhoneLabel;

  /// L10n key: adminQueuePreviewWebsiteLabel
  ///
  /// In tr, this message translates to:
  /// **'Web sitesi'**
  String get adminQueuePreviewWebsiteLabel;

  /// L10n key: adminQueuePreviewReasonLabel
  ///
  /// In tr, this message translates to:
  /// **'Gerekçe'**
  String get adminQueuePreviewReasonLabel;

  /// L10n key: adminQueuePreviewTargetTypeLabel
  ///
  /// In tr, this message translates to:
  /// **'Hedef tipi'**
  String get adminQueuePreviewTargetTypeLabel;

  /// L10n key: adminQueuePreviewTargetIdLabel
  ///
  /// In tr, this message translates to:
  /// **'Hedef kaydı'**
  String get adminQueuePreviewTargetIdLabel;

  /// L10n key: adminQueuePreviewDetailsLabel
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get adminQueuePreviewDetailsLabel;

  /// L10n key: adminQueuePreviewAdminNoteLabel
  ///
  /// In tr, this message translates to:
  /// **'Operasyon notu'**
  String get adminQueuePreviewAdminNoteLabel;

  /// L10n key: adminQueuePreviewEvidenceLabel
  ///
  /// In tr, this message translates to:
  /// **'Kanıt bağlantısı'**
  String get adminQueuePreviewEvidenceLabel;

  /// L10n key: adminQueuePreviewCurrentPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Mevcut fiyat'**
  String get adminQueuePreviewCurrentPriceLabel;

  /// L10n key: adminQueuePreviewSuggestedPriceLabel
  ///
  /// In tr, this message translates to:
  /// **'Önerilen fiyat'**
  String get adminQueuePreviewSuggestedPriceLabel;

  /// L10n key: adminQueuePreviewAnomalyLabel
  ///
  /// In tr, this message translates to:
  /// **'Anomali skoru'**
  String get adminQueuePreviewAnomalyLabel;

  /// L10n key: adminQueuePreviewConflictLabel
  ///
  /// In tr, this message translates to:
  /// **'Çakışma durumu'**
  String get adminQueuePreviewConflictLabel;

  /// L10n key: adminQueuePreviewCreatedByLabel
  ///
  /// In tr, this message translates to:
  /// **'Oluşturan'**
  String get adminQueuePreviewCreatedByLabel;

  /// L10n key: adminQueuePreviewMenuItemLabel
  ///
  /// In tr, this message translates to:
  /// **'Menü öğesi'**
  String get adminQueuePreviewMenuItemLabel;

  /// L10n key: adminQueueOpenFromReportsAction
  ///
  /// In tr, this message translates to:
  /// **'Kuyrukta aç'**
  String get adminQueueOpenFromReportsAction;

  /// L10n key: adminQueueOpenFromClaimsAction
  ///
  /// In tr, this message translates to:
  /// **'Kuyrukta aç'**
  String get adminQueueOpenFromClaimsAction;

  /// L10n key: adminQueueTypeBusinessSubmission
  ///
  /// In tr, this message translates to:
  /// **'İşletme başvurusu'**
  String get adminQueueTypeBusinessSubmission;

  /// L10n key: adminQueueTypeReport
  ///
  /// In tr, this message translates to:
  /// **'Rapor'**
  String get adminQueueTypeReport;

  /// L10n key: adminQueueTypePriceSuggestion
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi'**
  String get adminQueueTypePriceSuggestion;

  /// L10n key: adminQueueTypeClaim
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talebi'**
  String get adminQueueTypeClaim;

  /// L10n key: adminQueueTypeMediaFlag
  ///
  /// In tr, this message translates to:
  /// **'Medya ihbarı'**
  String get adminQueueTypeMediaFlag;

  /// L10n key: adminQueueStatusNew
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get adminQueueStatusNew;

  /// L10n key: adminQueueStatusOpen
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get adminQueueStatusOpen;

  /// L10n key: adminQueueStatusReviewing
  ///
  /// In tr, this message translates to:
  /// **'İnceleniyor'**
  String get adminQueueStatusReviewing;

  /// L10n key: adminQueueStatusClosed
  ///
  /// In tr, this message translates to:
  /// **'Kapandı'**
  String get adminQueueStatusClosed;

  /// L10n key: adminQueueSlaWaitingHours
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa bekliyor • SLA {slaHours} sa'**
  String adminQueueSlaWaitingHours(Object hours, int slaHours);

  /// L10n key: adminQueueDecisionSupportTitle
  ///
  /// In tr, this message translates to:
  /// **'Karar desteği'**
  String get adminQueueDecisionSupportTitle;

  /// L10n key: adminQueueDecisionSupportEmpty
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt için ek sinyal özeti bulunmuyor.'**
  String get adminQueueDecisionSupportEmpty;

  /// L10n key: adminQueuePendingReasonLabel
  ///
  /// In tr, this message translates to:
  /// **'Neden beklemede'**
  String get adminQueuePendingReasonLabel;

  /// L10n key: adminQueueAnomalyReasonLabel
  ///
  /// In tr, this message translates to:
  /// **'Neden anomali'**
  String get adminQueueAnomalyReasonLabel;

  /// L10n key: adminQueueDecisionSignalsLabel
  ///
  /// In tr, this message translates to:
  /// **'Sinyaller'**
  String get adminQueueDecisionSignalsLabel;

  /// L10n key: adminQueueDecisionHistoryTitle
  ///
  /// In tr, this message translates to:
  /// **'Benzer karar geçmişi'**
  String get adminQueueDecisionHistoryTitle;

  /// L10n key: adminQueueDecisionHistoryLoading
  ///
  /// In tr, this message translates to:
  /// **'Yakın karar geçmişi yükleniyor'**
  String get adminQueueDecisionHistoryLoading;

  /// L10n key: adminQueueDecisionHistoryEmpty
  ///
  /// In tr, this message translates to:
  /// **'Bu bağlam için son karar kaydı bulunamadı.'**
  String get adminQueueDecisionHistoryEmpty;

  /// L10n key: adminQueueDecisionHistoryError
  ///
  /// In tr, this message translates to:
  /// **'Karar geçmişi yüklenemedi'**
  String get adminQueueDecisionHistoryError;

  /// L10n key: adminQueueDecisionHistorySummary
  ///
  /// In tr, this message translates to:
  /// **'{relevantCount} ilgili kayıt • tam hedef {exactTargetCount} • onay {approvedCount} • red {rejectedCount}'**
  String adminQueueDecisionHistorySummary(
    int relevantCount,
    int exactTargetCount,
    int approvedCount,
    int rejectedCount,
  );

  /// L10n key: adminQueueDecisionHistoryAssignments
  ///
  /// In tr, this message translates to:
  /// **'Atama {assignedCount} • sonuçlanan {handledCount}'**
  String adminQueueDecisionHistoryAssignments(
    int assignedCount,
    int handledCount,
  );

  /// L10n key: adminQueueDecisionHistoryExactTarget
  ///
  /// In tr, this message translates to:
  /// **'Aynı kayıt'**
  String get adminQueueDecisionHistoryExactTarget;

  /// L10n key: adminQueueDecisionHistorySimilarRecord
  ///
  /// In tr, this message translates to:
  /// **'Benzer kayıt'**
  String get adminQueueDecisionHistorySimilarRecord;

  /// L10n key: adminQueuePendingReasonConflictAndAnomaly
  ///
  /// In tr, this message translates to:
  /// **'Çakışan fiyatlar ve yüksek anomali nedeniyle sırada.'**
  String get adminQueuePendingReasonConflictAndAnomaly;

  /// L10n key: adminQueuePendingReasonPriceConflict
  ///
  /// In tr, this message translates to:
  /// **'Aynı ürün için çakışan fiyat önerileri sıraya alındı.'**
  String get adminQueuePendingReasonPriceConflict;

  /// L10n key: adminQueuePendingReasonAnomalyQueue
  ///
  /// In tr, this message translates to:
  /// **'Anomali skoru eşik üzerinde olduğu için manuel incelemeye yönlendirildi.'**
  String get adminQueuePendingReasonAnomalyQueue;

  /// L10n key: adminQueuePendingReasonLowConfidence
  ///
  /// In tr, this message translates to:
  /// **'Güven skoru düşük olduğu için operatör kararı bekliyor.'**
  String get adminQueuePendingReasonLowConfidence;

  /// L10n key: adminQueuePendingReasonManualReview
  ///
  /// In tr, this message translates to:
  /// **'Kural motoru otomatik karar vermedi; operatör incelemesi gerekiyor.'**
  String get adminQueuePendingReasonManualReview;

  /// L10n key: adminQueuePendingReasonGreyArea
  ///
  /// In tr, this message translates to:
  /// **'Gri alanda kaldığı için operatör incelemesine bırakıldı.'**
  String get adminQueuePendingReasonGreyArea;

  /// L10n key: adminQueuePendingReasonMissingEvidence
  ///
  /// In tr, this message translates to:
  /// **'Kanıt bağlantısı eksik olduğu için doğrulama bekliyor.'**
  String get adminQueuePendingReasonMissingEvidence;

  /// L10n key: adminQueuePendingReasonClaimantAutoPending
  ///
  /// In tr, this message translates to:
  /// **'Başvuran güvenlik sinyalleri nedeniyle otomatik beklemeye alındı.'**
  String get adminQueuePendingReasonClaimantAutoPending;

  /// L10n key: adminQueuePendingReasonMissingSubmissionData
  ///
  /// In tr, this message translates to:
  /// **'Başvuru temel alanları eksik olduğu için onaylanmadı.'**
  String get adminQueuePendingReasonMissingSubmissionData;

  /// L10n key: adminQueueAnomalyReasonHighAnomalyScore
  ///
  /// In tr, this message translates to:
  /// **'Anomali skoru yüksek.'**
  String get adminQueueAnomalyReasonHighAnomalyScore;

  /// L10n key: adminQueueAnomalyReasonConflictingPrices
  ///
  /// In tr, this message translates to:
  /// **'Yakın zamanda birden fazla çakışan fiyat görüldü.'**
  String get adminQueueAnomalyReasonConflictingPrices;

  /// L10n key: adminQueueAnomalyReasonRiskyActor
  ///
  /// In tr, this message translates to:
  /// **'Gönderen hesabın risk skoru yüksek.'**
  String get adminQueueAnomalyReasonRiskyActor;

  /// L10n key: adminQueueAnomalyReasonLowBusinessQuality
  ///
  /// In tr, this message translates to:
  /// **'İşletmenin kalite skoru düşük.'**
  String get adminQueueAnomalyReasonLowBusinessQuality;

  /// L10n key: adminQueueAnomalyReasonAutoModerated
  ///
  /// In tr, this message translates to:
  /// **'Kayıt otomatik moderasyon zincirinden geçti.'**
  String get adminQueueAnomalyReasonAutoModerated;

  /// L10n key: adminQueueSignalQualityConfidence
  ///
  /// In tr, this message translates to:
  /// **'{value} güven'**
  String adminQueueSignalQualityConfidence(Object value);

  /// L10n key: adminQueueSignalAnomalyScore
  ///
  /// In tr, this message translates to:
  /// **'{value} anomali'**
  String adminQueueSignalAnomalyScore(Object value);

  /// L10n key: adminQueueSignalConflictVariants
  ///
  /// In tr, this message translates to:
  /// **'24 saatte {count} farklı fiyat'**
  String adminQueueSignalConflictVariants(int count);

  /// L10n key: adminQueueSignalAnomalyFlags
  ///
  /// In tr, this message translates to:
  /// **'Anomali işaretleri: {tags}'**
  String adminQueueSignalAnomalyFlags(Object tags);

  /// L10n key: adminQueueSignalActorReputation
  ///
  /// In tr, this message translates to:
  /// **'Katkı sağlayan itibar skoru {score}'**
  String adminQueueSignalActorReputation(int score);

  /// L10n key: adminQueueSignalActorRisk
  ///
  /// In tr, this message translates to:
  /// **'Hesap risk skoru {score}'**
  String adminQueueSignalActorRisk(int score);

  /// L10n key: adminQueueSignalBusinessQuality
  ///
  /// In tr, this message translates to:
  /// **'İşletme kalite skoru {score}'**
  String adminQueueSignalBusinessQuality(Object score);

  /// L10n key: adminQueueSignalAutoModerated
  ///
  /// In tr, this message translates to:
  /// **'Otomatik moderasyon sinyali bulundu'**
  String get adminQueueSignalAutoModerated;

  /// L10n key: adminQueueSignalShortDetails
  ///
  /// In tr, this message translates to:
  /// **'Açıklama çok kısa ({length} karakter)'**
  String adminQueueSignalShortDetails(int length);

  /// L10n key: adminQueueSignalMissingEvidence
  ///
  /// In tr, this message translates to:
  /// **'Kanıt bağlantısı eksik'**
  String get adminQueueSignalMissingEvidence;

  /// L10n key: adminQueueSignalMissingFields
  ///
  /// In tr, this message translates to:
  /// **'{count} eksik alan: {fields}'**
  String adminQueueSignalMissingFields(int count, Object fields);

  /// L10n key: adminQueueAuditActionBusinessSubmissionAssigned
  ///
  /// In tr, this message translates to:
  /// **'İşletme başvurusu atandı'**
  String get adminQueueAuditActionBusinessSubmissionAssigned;

  /// L10n key: adminQueueAuditActionBusinessSubmissionUnassigned
  ///
  /// In tr, this message translates to:
  /// **'İşletme başvurusu atamadan çıkarıldı'**
  String get adminQueueAuditActionBusinessSubmissionUnassigned;

  /// L10n key: adminQueueAuditActionPriceSuggestionAssigned
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi atandı'**
  String get adminQueueAuditActionPriceSuggestionAssigned;

  /// L10n key: adminQueueAuditActionPriceSuggestionUnassigned
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi atamadan çıkarıldı'**
  String get adminQueueAuditActionPriceSuggestionUnassigned;

  /// L10n key: adminQueueAuditActionReportAutoCloseDuplicate
  ///
  /// In tr, this message translates to:
  /// **'Mükerrer rapor otomatik kapatıldı'**
  String get adminQueueAuditActionReportAutoCloseDuplicate;

  /// L10n key: adminQueueAuditActionReportAutoRejectLowQuality
  ///
  /// In tr, this message translates to:
  /// **'Düşük kaliteli rapor otomatik reddedildi'**
  String get adminQueueAuditActionReportAutoRejectLowQuality;

  /// L10n key: adminQueueAuditActionReportAutoQueueGrey
  ///
  /// In tr, this message translates to:
  /// **'Gri alan raporu otomatik kuyruğa alındı'**
  String get adminQueueAuditActionReportAutoQueueGrey;

  /// L10n key: adminTableAssignToMeAction
  ///
  /// In tr, this message translates to:
  /// **'Seçilileri bana ata'**
  String get adminTableAssignToMeAction;

  /// L10n key: adminTableApproveSelectedAction
  ///
  /// In tr, this message translates to:
  /// **'Seçilileri onayla'**
  String get adminTableApproveSelectedAction;

  /// L10n key: adminTableRejectSelectedAction
  ///
  /// In tr, this message translates to:
  /// **'Seçilileri reddet'**
  String get adminTableRejectSelectedAction;

  /// L10n key: adminCommonStatusLabel
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get adminCommonStatusLabel;

  /// L10n key: adminCommonLocationLabel
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get adminCommonLocationLabel;

  /// L10n key: adminCommonActionsLabel
  ///
  /// In tr, this message translates to:
  /// **'Aksiyonlar'**
  String get adminCommonActionsLabel;

  /// L10n key: adminBusinessSubmissionsSearchHint
  ///
  /// In tr, this message translates to:
  /// **'İşletme adı, adres, kategori veya başvuran ara'**
  String get adminBusinessSubmissionsSearchHint;

  /// L10n key: adminBusinessSubmissionsBusinessColumn
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get adminBusinessSubmissionsBusinessColumn;

  /// L10n key: adminBusinessSubmissionsCategoryColumn
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get adminBusinessSubmissionsCategoryColumn;

  /// L10n key: adminBusinessSubmissionsApplicantColumn
  ///
  /// In tr, this message translates to:
  /// **'Başvuran'**
  String get adminBusinessSubmissionsApplicantColumn;

  /// L10n key: ownerDigitalMenuQrOpenStudioAction
  ///
  /// In tr, this message translates to:
  /// **'Dijital Menü & QR\'ı aç'**
  String get ownerDigitalMenuQrOpenStudioAction;

  /// L10n key: ownerDigitalMenuQrOpenStudioTooltip
  ///
  /// In tr, this message translates to:
  /// **'Dijital Menü & QR deneyimini yeni sekmede açar.'**
  String get ownerDigitalMenuQrOpenStudioTooltip;

  /// L10n key: ownerDigitalMenuOpenPublicMenuAction
  ///
  /// In tr, this message translates to:
  /// **'Canlı menüyü aç'**
  String get ownerDigitalMenuOpenPublicMenuAction;

  /// L10n key: ownerDigitalMenuOpenPublicMenuTooltip
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretçilere açık menüyü yeni sekmede açar.'**
  String get ownerDigitalMenuOpenPublicMenuTooltip;

  /// L10n key: ownerPublicMenuOpenedInNewTab
  ///
  /// In tr, this message translates to:
  /// **'Canlı menü yeni sekmede açıldı.'**
  String get ownerPublicMenuOpenedInNewTab;

  /// L10n key: ownerDigitalMenuOpenedInNewTab
  ///
  /// In tr, this message translates to:
  /// **'Dijital Menü & QR yeni sekmede açıldı.'**
  String get ownerDigitalMenuOpenedInNewTab;

  /// L10n key: ownerShellTeamLabel
  ///
  /// In tr, this message translates to:
  /// **'Ekip'**
  String get ownerShellTeamLabel;

  /// L10n key: ownerShellActivityLabel
  ///
  /// In tr, this message translates to:
  /// **'Aktivite'**
  String get ownerShellActivityLabel;

  /// L10n key: adminImpersonationBannerTitle
  ///
  /// In tr, this message translates to:
  /// **'{user} kullanıcısı olarak görüntüleniyor'**
  String adminImpersonationBannerTitle(String user);

  /// L10n key: adminImpersonationUsingActualRole
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcının gerçek rolü kullanılıyor'**
  String get adminImpersonationUsingActualRole;

  /// L10n key: adminImpersonationRoleOverride
  ///
  /// In tr, this message translates to:
  /// **'Rol override: {role}'**
  String adminImpersonationRoleOverride(String role);

  /// L10n key: adminImpersonationStopAction
  ///
  /// In tr, this message translates to:
  /// **'Durdur'**
  String get adminImpersonationStopAction;

  /// L10n key: adminImpersonationUseActualRoleOption
  ///
  /// In tr, this message translates to:
  /// **'Gerçek rolü kullan'**
  String get adminImpersonationUseActualRoleOption;

  /// L10n key: adminImpersonationRoleOverrideLabel
  ///
  /// In tr, this message translates to:
  /// **'Rol override'**
  String get adminImpersonationRoleOverrideLabel;

  /// L10n key: adminImpersonationRefreshAction
  ///
  /// In tr, this message translates to:
  /// **'Görüntülemeyi yenile'**
  String get adminImpersonationRefreshAction;

  /// L10n key: adminImpersonationStartAction
  ///
  /// In tr, this message translates to:
  /// **'Görüntülemeyi başlat'**
  String get adminImpersonationStartAction;

  /// L10n key: adminImpersonationStarted
  ///
  /// In tr, this message translates to:
  /// **'Görüntüleme başlatıldı.'**
  String get adminImpersonationStarted;

  /// L10n key: adminImpersonationStopped
  ///
  /// In tr, this message translates to:
  /// **'Görüntüleme durduruldu.'**
  String get adminImpersonationStopped;

  /// L10n key: ownerTeamRoleOwner
  ///
  /// In tr, this message translates to:
  /// **'Sahip'**
  String get ownerTeamRoleOwner;

  /// L10n key: ownerTeamRoleManager
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get ownerTeamRoleManager;

  /// L10n key: ownerTeamRoleEditor
  ///
  /// In tr, this message translates to:
  /// **'Editör'**
  String get ownerTeamRoleEditor;

  /// L10n key: ownerTeamRoleStaff
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get ownerTeamRoleStaff;

  /// L10n key: ownerTeamRoleViewer
  ///
  /// In tr, this message translates to:
  /// **'Görüntüleyici'**
  String get ownerTeamRoleViewer;

  /// L10n key: ownerTeamScopeThisBusiness
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca bu şube'**
  String get ownerTeamScopeThisBusiness;

  /// L10n key: ownerTeamScopeAllBranches
  ///
  /// In tr, this message translates to:
  /// **'Tüm şubeler'**
  String get ownerTeamScopeAllBranches;

  /// L10n key: ownerTeamTitle
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyeleri'**
  String get ownerTeamTitle;

  /// L10n key: ownerTeamDescription
  ///
  /// In tr, this message translates to:
  /// **'Şube ekibini davet et, rol ata ve erişimin yalnızca bu şubeyle mi yoksa tüm zincirle mi sınırlı olacağını belirle.'**
  String get ownerTeamDescription;

  /// L10n key: ownerTeamLoadErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyeleri yüklenemedi'**
  String get ownerTeamLoadErrorTitle;

  /// L10n key: ownerTeamEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz ekip üyesi yok'**
  String get ownerTeamEmptyTitle;

  /// L10n key: ownerTeamEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Şube bazlı yetkilendirmeyi başlatmak için ilk ekip üyesini ekle.'**
  String get ownerTeamEmptyDescription;

  /// L10n key: ownerTeamEmailRequired
  ///
  /// In tr, this message translates to:
  /// **'E-posta zorunludur.'**
  String get ownerTeamEmailRequired;

  /// L10n key: ownerTeamSaved
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyesi kaydedildi.'**
  String get ownerTeamSaved;

  /// L10n key: ownerTeamUpdated
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyesi güncellendi.'**
  String get ownerTeamUpdated;

  /// L10n key: ownerTeamRemoved
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyesi kaldırıldı.'**
  String get ownerTeamRemoved;

  /// L10n key: ownerTeamSelectedBranchFallback
  ///
  /// In tr, this message translates to:
  /// **'Seçili şube'**
  String get ownerTeamSelectedBranchFallback;

  /// L10n key: ownerTeamScopeAwareBadge
  ///
  /// In tr, this message translates to:
  /// **'Scope bazlı RBAC'**
  String get ownerTeamScopeAwareBadge;

  /// L10n key: ownerTeamInviteTitle
  ///
  /// In tr, this message translates to:
  /// **'Davet et veya yetki ver'**
  String get ownerTeamInviteTitle;

  /// L10n key: ownerTeamEmailLabel
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get ownerTeamEmailLabel;

  /// L10n key: ownerTeamEmailHint
  ///
  /// In tr, this message translates to:
  /// **'ornek@firma.com'**
  String get ownerTeamEmailHint;

  /// L10n key: ownerTeamRoleFieldLabel
  ///
  /// In tr, this message translates to:
  /// **'Rol'**
  String get ownerTeamRoleFieldLabel;

  /// L10n key: ownerTeamScopeFieldLabel
  ///
  /// In tr, this message translates to:
  /// **'Kapsam'**
  String get ownerTeamScopeFieldLabel;

  /// L10n key: ownerTeamSaveMemberAction
  ///
  /// In tr, this message translates to:
  /// **'Üyeyi kaydet'**
  String get ownerTeamSaveMemberAction;

  /// L10n key: ownerTeamStatusPendingInvite
  ///
  /// In tr, this message translates to:
  /// **'Davet bekliyor'**
  String get ownerTeamStatusPendingInvite;

  /// L10n key: ownerTeamStatusActive
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get ownerTeamStatusActive;

  /// L10n key: ownerTeamSourceValue
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: {source}'**
  String ownerTeamSourceValue(String source);

  /// L10n key: ownerTeamUpdateAction
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get ownerTeamUpdateAction;

  /// L10n key: ownerTeamRemoveAction
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get ownerTeamRemoveAction;

  /// L10n key: ownerTeamSourceOwnerClaim
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talebi'**
  String get ownerTeamSourceOwnerClaim;

  /// L10n key: ownerTeamSourceChainMembership
  ///
  /// In tr, this message translates to:
  /// **'Zincir üyeliği'**
  String get ownerTeamSourceChainMembership;

  /// L10n key: ownerTeamSourceDirect
  ///
  /// In tr, this message translates to:
  /// **'Doğrudan atama'**
  String get ownerTeamSourceDirect;

  /// L10n key: adminUserAccessForbiddenDescription
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca admin kullanıcılar erişim override veya impersonation yapabilir.'**
  String get adminUserAccessForbiddenDescription;

  /// L10n key: adminUserAccessTitle
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı erişim önizlemesi'**
  String get adminUserAccessTitle;

  /// L10n key: adminUserAccessDescription
  ///
  /// In tr, this message translates to:
  /// **'{userId} kullanıcısının işletme erişimini önizle. Rol override yalnızca önizleme ve impersonation bağlamını etkiler.'**
  String adminUserAccessDescription(String userId);

  /// L10n key: adminUserAccessLoadErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Erişim önizlemesi yüklenemedi'**
  String get adminUserAccessLoadErrorTitle;

  /// L10n key: adminUserAccessEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Erişilebilir işletme yok'**
  String get adminUserAccessEmptyTitle;

  /// L10n key: adminUserAccessEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcının panelde owner veya ekip erişimi görünmüyor.'**
  String get adminUserAccessEmptyDescription;

  /// L10n key: adminUserAccessBusinessMeta
  ///
  /// In tr, this message translates to:
  /// **'{city} / {district} • {role}'**
  String adminUserAccessBusinessMeta(String city, String district, String role);

  /// L10n key: adminUserAccessOpenOwnerPanelAction
  ///
  /// In tr, this message translates to:
  /// **'Owner panelini aç'**
  String get adminUserAccessOpenOwnerPanelAction;

  /// L10n key: ownerActivityTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme aktivitesi'**
  String get ownerActivityTitle;

  /// L10n key: ownerActivityDescription
  ///
  /// In tr, this message translates to:
  /// **'Seçili işletmedeki kritik değişiklikleri, ekip işlemlerini ve moderasyon sonuçlarını buradan takip edebilirsin.'**
  String get ownerActivityDescription;

  /// L10n key: ownerActivityMissingBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'Önce bir işletme seç'**
  String get ownerActivityMissingBusinessTitle;

  /// L10n key: ownerActivityMissingBusinessDescription
  ///
  /// In tr, this message translates to:
  /// **'Aktivite akışını görmek için önce yönetebildiğin bir işletme seçmen gerekiyor.'**
  String get ownerActivityMissingBusinessDescription;

  /// L10n key: adminAuditDescription
  ///
  /// In tr, this message translates to:
  /// **'Sistem genelindeki kritik değişiklikleri, moderasyon kararlarını ve güvenlik aksiyonlarını filtreleyip inceleyin.'**
  String get adminAuditDescription;

  /// L10n key: adminAuditErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Denetim kayıtları yüklenemedi'**
  String get adminAuditErrorTitle;

  /// L10n key: adminAuditSearchHint
  ///
  /// In tr, this message translates to:
  /// **'Aksiyon, hedef ID, kullanıcı ID veya meta içinde ara'**
  String get adminAuditSearchHint;

  /// L10n key: adminAuditDateRangeLabel
  ///
  /// In tr, this message translates to:
  /// **'Tarih aralığı'**
  String get adminAuditDateRangeLabel;

  /// L10n key: adminAuditDateRangeEmpty
  ///
  /// In tr, this message translates to:
  /// **'Tüm zamanlar'**
  String get adminAuditDateRangeEmpty;

  /// L10n key: adminAuditDateRangeValue
  ///
  /// In tr, this message translates to:
  /// **'{start} - {end}'**
  String adminAuditDateRangeValue(String start, String end);

  /// L10n key: adminAuditOnlyMyActions
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca benim aksiyonlarım'**
  String get adminAuditOnlyMyActions;

  /// L10n key: ownerActivityOnlyMyActions
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca benim işlemlerim'**
  String get ownerActivityOnlyMyActions;

  /// L10n key: ownerActivityPresetAll
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get ownerActivityPresetAll;

  /// L10n key: ownerActivityPresetToday
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get ownerActivityPresetToday;

  /// L10n key: ownerActivityPresetLast7Days
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün'**
  String get ownerActivityPresetLast7Days;

  /// L10n key: ownerActivityPresetTeamChanges
  ///
  /// In tr, this message translates to:
  /// **'Ekip değişiklikleri'**
  String get ownerActivityPresetTeamChanges;

  /// L10n key: adminAuditExportCsvAction
  ///
  /// In tr, this message translates to:
  /// **'CSV dışa aktar'**
  String get adminAuditExportCsvAction;

  /// L10n key: adminAuditExportReady
  ///
  /// In tr, this message translates to:
  /// **'Denetim CSV dosyası hazırlandı.'**
  String get adminAuditExportReady;

  /// L10n key: adminAuditIpLabel
  ///
  /// In tr, this message translates to:
  /// **'IP'**
  String get adminAuditIpLabel;

  /// L10n key: adminAuditUserAgentLabel
  ///
  /// In tr, this message translates to:
  /// **'User-Agent'**
  String get adminAuditUserAgentLabel;

  /// L10n key: adminAuditActorRoleAdmin
  ///
  /// In tr, this message translates to:
  /// **'Admin'**
  String get adminAuditActorRoleAdmin;

  /// L10n key: adminAuditActorRoleOwner
  ///
  /// In tr, this message translates to:
  /// **'Sahip'**
  String get adminAuditActorRoleOwner;

  /// L10n key: adminAuditActorRoleManager
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get adminAuditActorRoleManager;

  /// L10n key: adminAuditActorRoleEditor
  ///
  /// In tr, this message translates to:
  /// **'Editör'**
  String get adminAuditActorRoleEditor;

  /// L10n key: adminAuditActorRoleStaff
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get adminAuditActorRoleStaff;

  /// L10n key: adminAuditActorRoleViewer
  ///
  /// In tr, this message translates to:
  /// **'Görüntüleyici'**
  String get adminAuditActorRoleViewer;

  /// L10n key: adminAuditActorRoleUser
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get adminAuditActorRoleUser;

  /// L10n key: auditActionBusinessVerificationChanged
  ///
  /// In tr, this message translates to:
  /// **'İşletme doğrulama durumu değişti'**
  String get auditActionBusinessVerificationChanged;

  /// L10n key: auditActionBusinessMerge
  ///
  /// In tr, this message translates to:
  /// **'İşletme birleştirildi'**
  String get auditActionBusinessMerge;

  /// L10n key: auditActionBusinessMergeProposed
  ///
  /// In tr, this message translates to:
  /// **'İşletme birleştirme talebi kaydedildi'**
  String get auditActionBusinessMergeProposed;

  /// L10n key: auditActionMenuCreated
  ///
  /// In tr, this message translates to:
  /// **'Menü oluşturuldu'**
  String get auditActionMenuCreated;

  /// L10n key: auditActionMenuUpdated
  ///
  /// In tr, this message translates to:
  /// **'Menü güncellendi'**
  String get auditActionMenuUpdated;

  /// L10n key: auditActionMenuArchived
  ///
  /// In tr, this message translates to:
  /// **'Menü arşivlendi'**
  String get auditActionMenuArchived;

  /// L10n key: auditActionMenuPublished
  ///
  /// In tr, this message translates to:
  /// **'Menü yayına alındı'**
  String get auditActionMenuPublished;

  /// L10n key: auditActionMenuDeleted
  ///
  /// In tr, this message translates to:
  /// **'Menü silindi'**
  String get auditActionMenuDeleted;

  /// L10n key: auditActionMenuItemCreated
  ///
  /// In tr, this message translates to:
  /// **'Ürün oluşturuldu'**
  String get auditActionMenuItemCreated;

  /// L10n key: auditActionMenuItemUpdated
  ///
  /// In tr, this message translates to:
  /// **'Ürün güncellendi'**
  String get auditActionMenuItemUpdated;

  /// L10n key: auditActionMenuItemArchived
  ///
  /// In tr, this message translates to:
  /// **'Ürün arşivlendi'**
  String get auditActionMenuItemArchived;

  /// L10n key: auditActionMenuItemPublished
  ///
  /// In tr, this message translates to:
  /// **'Ürün yayına alındı'**
  String get auditActionMenuItemPublished;

  /// L10n key: auditActionMenuItemDeleted
  ///
  /// In tr, this message translates to:
  /// **'Ürün silindi'**
  String get auditActionMenuItemDeleted;

  /// L10n key: auditActionPriceSuggestionApproved
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi onaylandı'**
  String get auditActionPriceSuggestionApproved;

  /// L10n key: auditActionPriceSuggestionRejected
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi reddedildi'**
  String get auditActionPriceSuggestionRejected;

  /// L10n key: auditActionOwnerPriceSuggestionOverride
  ///
  /// In tr, this message translates to:
  /// **'Sahip fiyat önerisini override etti'**
  String get auditActionOwnerPriceSuggestionOverride;

  /// L10n key: auditActionOwnerPriceSuggestionRejected
  ///
  /// In tr, this message translates to:
  /// **'Sahip fiyat önerisini reddetti'**
  String get auditActionOwnerPriceSuggestionRejected;

  /// L10n key: auditActionTeamMemberSaved
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyesi eklendi veya güncellendi'**
  String get auditActionTeamMemberSaved;

  /// L10n key: auditActionTeamMemberUpdated
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyesi yetkisi güncellendi'**
  String get auditActionTeamMemberUpdated;

  /// L10n key: auditActionTeamMemberRemoved
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyesi kaldırıldı'**
  String get auditActionTeamMemberRemoved;

  /// L10n key: auditActionClaimApproved
  ///
  /// In tr, this message translates to:
  /// **'Talep onaylandı'**
  String get auditActionClaimApproved;

  /// L10n key: auditActionClaimRejected
  ///
  /// In tr, this message translates to:
  /// **'Talep reddedildi'**
  String get auditActionClaimRejected;

  /// L10n key: auditActionClaimAssigned
  ///
  /// In tr, this message translates to:
  /// **'Talep atandı'**
  String get auditActionClaimAssigned;

  /// L10n key: auditActionClaimUpdated
  ///
  /// In tr, this message translates to:
  /// **'Talep güncellendi'**
  String get auditActionClaimUpdated;

  /// L10n key: auditActionReportUpdated
  ///
  /// In tr, this message translates to:
  /// **'Rapor güncellendi'**
  String get auditActionReportUpdated;

  /// L10n key: auditActionReportBulkUpdated
  ///
  /// In tr, this message translates to:
  /// **'Raporlarda toplu güncelleme yapıldı'**
  String get auditActionReportBulkUpdated;

  /// L10n key: auditActionReportAssigned
  ///
  /// In tr, this message translates to:
  /// **'Rapor atandı'**
  String get auditActionReportAssigned;

  /// L10n key: auditActionReportHandled
  ///
  /// In tr, this message translates to:
  /// **'Rapor sonuçlandırıldı'**
  String get auditActionReportHandled;

  /// L10n key: auditActionReportExported
  ///
  /// In tr, this message translates to:
  /// **'Rapor CSV dışa aktarıldı'**
  String get auditActionReportExported;

  /// L10n key: auditActionUserSafetyAction
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı güvenlik aksiyonu uygulandı'**
  String get auditActionUserSafetyAction;

  /// L10n key: auditActionImpersonationStarted
  ///
  /// In tr, this message translates to:
  /// **'Impersonation başlatıldı'**
  String get auditActionImpersonationStarted;

  /// L10n key: auditActionImpersonationStopped
  ///
  /// In tr, this message translates to:
  /// **'Impersonation durduruldu'**
  String get auditActionImpersonationStopped;

  /// L10n key: auditTargetTypeBusiness
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get auditTargetTypeBusiness;

  /// L10n key: auditTargetTypeMenu
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get auditTargetTypeMenu;

  /// L10n key: auditTargetTypeMenuItem
  ///
  /// In tr, this message translates to:
  /// **'Ürün'**
  String get auditTargetTypeMenuItem;

  /// L10n key: auditTargetTypePriceSuggestion
  ///
  /// In tr, this message translates to:
  /// **'Fiyat önerisi'**
  String get auditTargetTypePriceSuggestion;

  /// L10n key: auditTargetTypeTeamMember
  ///
  /// In tr, this message translates to:
  /// **'Ekip üyesi'**
  String get auditTargetTypeTeamMember;

  /// L10n key: auditTargetTypeOwnerClaim
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talebi'**
  String get auditTargetTypeOwnerClaim;

  /// L10n key: auditTargetTypeReport
  ///
  /// In tr, this message translates to:
  /// **'Rapor'**
  String get auditTargetTypeReport;

  /// L10n key: auditTargetTypeUser
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get auditTargetTypeUser;

  /// L10n key: adminSearchTitle
  ///
  /// In tr, this message translates to:
  /// **'Yönetici araması'**
  String get adminSearchTitle;

  /// L10n key: adminSearchDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme, kullanıcı, rapor, başvuru, sahiplik talebi ve menü öğelerini tek arama yüzeyinden bul.'**
  String get adminSearchDescription;

  /// L10n key: adminSearchTopbarHint
  ///
  /// In tr, this message translates to:
  /// **'İşletme, kullanıcı veya moderasyon kaydı ara'**
  String get adminSearchTopbarHint;

  /// L10n key: adminSearchInputHint
  ///
  /// In tr, this message translates to:
  /// **'En az 2 karakter yaz. ID, e-posta, telefon veya isim ile arayabilirsin.'**
  String get adminSearchInputHint;

  /// L10n key: adminSearchRunAction
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get adminSearchRunAction;

  /// L10n key: adminSearchKeyboardHint
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlarda gezinmek için yukarı/aşağı oklarını, açmak için Enter tuşunu kullan.'**
  String get adminSearchKeyboardHint;

  /// L10n key: adminSearchStartTitle
  ///
  /// In tr, this message translates to:
  /// **'Aramayı başlat'**
  String get adminSearchStartTitle;

  /// L10n key: adminSearchStartDescription
  ///
  /// In tr, this message translates to:
  /// **'İşletme, kullanıcı veya moderasyon kaydı bulmak için en az 2 karakter gir.'**
  String get adminSearchStartDescription;

  /// L10n key: adminSearchEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get adminSearchEmptyTitle;

  /// L10n key: adminSearchEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'\"{query}\" için eşleşen kayıt bulunamadı.'**
  String adminSearchEmptyDescription(Object query);

  /// L10n key: adminSearchErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Arama yüklenemedi'**
  String get adminSearchErrorTitle;

  /// L10n key: adminSearchForbiddenDescription
  ///
  /// In tr, this message translates to:
  /// **'Global yönetici araması yalnızca admin kullanıcılar için kullanılabilir.'**
  String get adminSearchForbiddenDescription;

  /// L10n key: adminSearchCopiedId
  ///
  /// In tr, this message translates to:
  /// **'Kayıt kimliği panoya kopyalandı.'**
  String get adminSearchCopiedId;

  /// L10n key: adminSearchOpenInNewTabAction
  ///
  /// In tr, this message translates to:
  /// **'Yeni sekmede aç'**
  String get adminSearchOpenInNewTabAction;

  /// L10n key: adminSearchCopyIdAction
  ///
  /// In tr, this message translates to:
  /// **'Kimliği kopyala'**
  String get adminSearchCopyIdAction;

  /// L10n key: adminSearchCategoryBusinesses
  ///
  /// In tr, this message translates to:
  /// **'İşletmeler'**
  String get adminSearchCategoryBusinesses;

  /// L10n key: adminSearchCategoryUsers
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcılar'**
  String get adminSearchCategoryUsers;

  /// L10n key: adminSearchCategoryReports
  ///
  /// In tr, this message translates to:
  /// **'Raporlar'**
  String get adminSearchCategoryReports;

  /// L10n key: adminSearchCategorySubmissions
  ///
  /// In tr, this message translates to:
  /// **'İşletme başvuruları'**
  String get adminSearchCategorySubmissions;

  /// L10n key: adminSearchCategoryClaims
  ///
  /// In tr, this message translates to:
  /// **'Sahiplik talepleri'**
  String get adminSearchCategoryClaims;

  /// L10n key: adminSearchCategoryMenuItems
  ///
  /// In tr, this message translates to:
  /// **'Menü öğeleri'**
  String get adminSearchCategoryMenuItems;

  /// L10n key: ownerShellAnalyticsLabel
  ///
  /// In tr, this message translates to:
  /// **'Analitik'**
  String get ownerShellAnalyticsLabel;

  /// L10n key: ownerAnalyticsTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme analitiği'**
  String get ownerAnalyticsTitle;

  /// L10n key: ownerAnalyticsDescription
  ///
  /// In tr, this message translates to:
  /// **'QR taramaları, menü açılışları ve ürün ilgisini tek ekranda takip et.'**
  String get ownerAnalyticsDescription;

  /// L10n key: ownerAnalyticsMissingBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'Önce bir işletme seç'**
  String get ownerAnalyticsMissingBusinessTitle;

  /// L10n key: ownerAnalyticsMissingBusinessDescription
  ///
  /// In tr, this message translates to:
  /// **'Analitik verilerini görmek için üst bardan bir işletme seç.'**
  String get ownerAnalyticsMissingBusinessDescription;

  /// L10n key: ownerAnalyticsForbiddenTitle
  ///
  /// In tr, this message translates to:
  /// **'Bu veriyi görme iznin yok'**
  String get ownerAnalyticsForbiddenTitle;

  /// L10n key: ownerAnalyticsForbiddenDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu işletmenin analitik ekranı yalnızca görüntüleme izni olan ekip üyelerine açıktır.'**
  String get ownerAnalyticsForbiddenDescription;

  /// L10n key: ownerAnalyticsErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Analitik verileri yüklenemedi'**
  String get ownerAnalyticsErrorTitle;

  /// L10n key: ownerAnalyticsPreset7Days
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün'**
  String get ownerAnalyticsPreset7Days;

  /// L10n key: ownerAnalyticsPreset30Days
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün'**
  String get ownerAnalyticsPreset30Days;

  /// L10n key: ownerAnalyticsPreset90Days
  ///
  /// In tr, this message translates to:
  /// **'Son 90 gün'**
  String get ownerAnalyticsPreset90Days;

  /// L10n key: ownerAnalyticsPreset24Hours
  ///
  /// In tr, this message translates to:
  /// **'Son 24 saat'**
  String get ownerAnalyticsPreset24Hours;

  /// L10n key: ownerAnalyticsHourlyTrendTitle
  ///
  /// In tr, this message translates to:
  /// **'Son 24 saatlik akış'**
  String get ownerAnalyticsHourlyTrendTitle;

  /// L10n key: ownerAnalyticsBranchCompareToggle
  ///
  /// In tr, this message translates to:
  /// **'Şubeleri karşılaştır'**
  String get ownerAnalyticsBranchCompareToggle;

  /// L10n key: ownerAnalyticsQrScansTitle
  ///
  /// In tr, this message translates to:
  /// **'QR taramaları'**
  String get ownerAnalyticsQrScansTitle;

  /// L10n key: ownerAnalyticsMenuOpensTitle
  ///
  /// In tr, this message translates to:
  /// **'Menü açılışları'**
  String get ownerAnalyticsMenuOpensTitle;

  /// L10n key: ownerAnalyticsCategoryViewsTitle
  ///
  /// In tr, this message translates to:
  /// **'Kategori görüntülemeleri'**
  String get ownerAnalyticsCategoryViewsTitle;

  /// L10n key: ownerAnalyticsItemClicksTitle
  ///
  /// In tr, this message translates to:
  /// **'Ürün tıklamaları'**
  String get ownerAnalyticsItemClicksTitle;

  /// L10n key: ownerAnalyticsDailyTrendTitle
  ///
  /// In tr, this message translates to:
  /// **'Son {days} günün günlük akışı'**
  String ownerAnalyticsDailyTrendTitle(Object days);

  /// L10n key: ownerAnalyticsNoTrendDataDescription
  ///
  /// In tr, this message translates to:
  /// **'Seçilen tarih aralığında gösterilecek günlük trend verisi yok.'**
  String get ownerAnalyticsNoTrendDataDescription;

  /// L10n key: ownerAnalyticsTopItemsTitle
  ///
  /// In tr, this message translates to:
  /// **'En çok ilgi gören ürünler'**
  String get ownerAnalyticsTopItemsTitle;

  /// L10n key: ownerAnalyticsNoItemDataTitle
  ///
  /// In tr, this message translates to:
  /// **'Ürün verisi henüz oluşmadı'**
  String get ownerAnalyticsNoItemDataTitle;

  /// L10n key: ownerAnalyticsNoItemDataDescription
  ///
  /// In tr, this message translates to:
  /// **'Ürün bazlı etkileşim oluştuğunda burada en çok tıklanan ürünleri göreceksin.'**
  String get ownerAnalyticsNoItemDataDescription;

  /// L10n key: ownerAnalyticsTopCategoriesTitle
  ///
  /// In tr, this message translates to:
  /// **'En çok görüntülenen kategoriler'**
  String get ownerAnalyticsTopCategoriesTitle;

  /// L10n key: ownerAnalyticsNoCategoryDataTitle
  ///
  /// In tr, this message translates to:
  /// **'Kategori verisi henüz oluşmadı'**
  String get ownerAnalyticsNoCategoryDataTitle;

  /// L10n key: ownerAnalyticsNoCategoryDataDescription
  ///
  /// In tr, this message translates to:
  /// **'Kategori bazlı görüntüleme verileri geldikçe burada sıralanır.'**
  String get ownerAnalyticsNoCategoryDataDescription;

  /// L10n key: ownerAnalyticsSourceBreakdownTitle
  ///
  /// In tr, this message translates to:
  /// **'Kaynak dağılımı'**
  String get ownerAnalyticsSourceBreakdownTitle;

  /// L10n key: ownerAnalyticsNoSourceDataTitle
  ///
  /// In tr, this message translates to:
  /// **'Kaynak verisi bulunamadı'**
  String get ownerAnalyticsNoSourceDataTitle;

  /// L10n key: ownerAnalyticsNoSourceDataDescription
  ///
  /// In tr, this message translates to:
  /// **'QR kısa bağlantı ve normal menü girişleri oluştukça burada dağılımı göreceksin.'**
  String get ownerAnalyticsNoSourceDataDescription;

  /// L10n key: ownerAnalyticsSourceQrShortLink
  ///
  /// In tr, this message translates to:
  /// **'QR kısa bağlantı'**
  String get ownerAnalyticsSourceQrShortLink;

  /// L10n key: ownerAnalyticsSourceNormal
  ///
  /// In tr, this message translates to:
  /// **'Normal giriş'**
  String get ownerAnalyticsSourceNormal;

  /// L10n key: ownerAnalyticsBranchCompareTitle
  ///
  /// In tr, this message translates to:
  /// **'Şube karşılaştırması'**
  String get ownerAnalyticsBranchCompareTitle;

  /// L10n key: ownerAnalyticsBranchCompareEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırılacak şube verisi yok'**
  String get ownerAnalyticsBranchCompareEmptyTitle;

  /// L10n key: ownerAnalyticsBranchCompareEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Aynı zincirde erişimin olan başka şube bulunduğunda burada karşılaştırma göreceksin.'**
  String get ownerAnalyticsBranchCompareEmptyDescription;

  /// L10n key: ownerAnalyticsBranchCompareMetrics
  ///
  /// In tr, this message translates to:
  /// **'{menuOpens} menü açılışı • {qrScans} QR taraması • {menuViews} menü görüntülemesi'**
  String ownerAnalyticsBranchCompareMetrics(
    Object menuOpens,
    Object qrScans,
    Object menuViews,
  );

  /// L10n key: ownerDashboardAnalyticsTitle
  ///
  /// In tr, this message translates to:
  /// **'Gerçek değer analitiği'**
  String get ownerDashboardAnalyticsTitle;

  /// L10n key: ownerDashboardAnalyticsDescription
  ///
  /// In tr, this message translates to:
  /// **'QR, menü açılışı ve dönüşüm sinyallerini tek bakışta gör; detay için analitik ekranına geç.'**
  String get ownerDashboardAnalyticsDescription;

  /// L10n key: ownerDashboardOpenAnalyticsAction
  ///
  /// In tr, this message translates to:
  /// **'Analitiği aç'**
  String get ownerDashboardOpenAnalyticsAction;

  /// L10n key: ownerDashboardAnalyticsLoadErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Analytics özeti yüklenemedi'**
  String get ownerDashboardAnalyticsLoadErrorTitle;

  /// L10n key: ownerDashboardAnalyticsSelectBusiness
  ///
  /// In tr, this message translates to:
  /// **'Özet metriği görmek için önce bir işletme seç.'**
  String get ownerDashboardAnalyticsSelectBusiness;

  /// L10n key: ownerDashboardAnalyticsNotFound
  ///
  /// In tr, this message translates to:
  /// **'Bu işletme için gösterilecek analytics özeti yok.'**
  String get ownerDashboardAnalyticsNotFound;

  /// L10n key: ownerDashboardAnalyticsOutboundClicks
  ///
  /// In tr, this message translates to:
  /// **'Dış bağlantı tıklamaları'**
  String get ownerDashboardAnalyticsOutboundClicks;

  /// L10n key: ownerDashboardAnalyticsConversions
  ///
  /// In tr, this message translates to:
  /// **'Dönüşümler'**
  String get ownerDashboardAnalyticsConversions;

  /// L10n key: ownerGrowthTitle
  ///
  /// In tr, this message translates to:
  /// **'Büyüme merkezi'**
  String get ownerGrowthTitle;

  /// L10n key: ownerGrowthDescription
  ///
  /// In tr, this message translates to:
  /// **'Talep, görünürlük, dönüşüm ve sponsorlu görünürlük talepleri bu ekranda toplanır.'**
  String get ownerGrowthDescription;

  /// L10n key: ownerGrowthSignalsTitle
  ///
  /// In tr, this message translates to:
  /// **'Büyüme sinyalleri'**
  String get ownerGrowthSignalsTitle;

  /// L10n key: ownerGrowthSignalsDescription
  ///
  /// In tr, this message translates to:
  /// **'İlgi kaybı, fiyat pozisyonu ve dışa akış davranışı son 30 günde özetlenir.'**
  String get ownerGrowthSignalsDescription;

  /// L10n key: ownerGrowthCatalogTitle
  ///
  /// In tr, this message translates to:
  /// **'Sponsor katalogu'**
  String get ownerGrowthCatalogTitle;

  /// L10n key: ownerGrowthCatalogDescription
  ///
  /// In tr, this message translates to:
  /// **'Aktif paketler, boş slot durumu ve son kampanya erişimi buradan görülür.'**
  String get ownerGrowthCatalogDescription;

  /// L10n key: ownerGrowthCatalogLoadErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Sponsor katalogu yüklenemedi'**
  String get ownerGrowthCatalogLoadErrorTitle;

  /// L10n key: ownerGrowthCatalogEmpty
  ///
  /// In tr, this message translates to:
  /// **'Aktif sponsor paketi bulunmuyor.'**
  String get ownerGrowthCatalogEmpty;

  /// L10n key: ownerGrowthCatalogDurationLabel
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get ownerGrowthCatalogDurationLabel;

  /// L10n key: ownerGrowthCatalogInventoryLabel
  ///
  /// In tr, this message translates to:
  /// **'Boş slot'**
  String get ownerGrowthCatalogInventoryLabel;

  /// L10n key: ownerGrowthCatalogLiveUnitsLabel
  ///
  /// In tr, this message translates to:
  /// **'Canlı birimler'**
  String get ownerGrowthCatalogLiveUnitsLabel;

  /// L10n key: ownerGrowthCatalogReachLabel
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün erişim'**
  String get ownerGrowthCatalogReachLabel;

  /// L10n key: ownerGrowthCatalogInventoryValue
  ///
  /// In tr, this message translates to:
  /// **'{open} boş / limit {total}'**
  String ownerGrowthCatalogInventoryValue(Object open, Object total);

  /// L10n key: ownerGrowthCatalogLiveUnitsValue
  ///
  /// In tr, this message translates to:
  /// **'Yüzey {surfaceLive} • siz {businessLive}'**
  String ownerGrowthCatalogLiveUnitsValue(
    Object surfaceLive,
    Object businessLive,
  );

  /// L10n key: ownerGrowthCatalogReachValue
  ///
  /// In tr, this message translates to:
  /// **'{impressions} gösterim • {users} kullanıcı'**
  String ownerGrowthCatalogReachValue(Object impressions, Object users);

  /// L10n key: ownerGrowthCatalogLeadStatus
  ///
  /// In tr, this message translates to:
  /// **'Son lead durumu: {status}'**
  String ownerGrowthCatalogLeadStatus(Object status);

  /// L10n key: ownerGrowthCatalogLeadStatusNone
  ///
  /// In tr, this message translates to:
  /// **'Henüz talep yok'**
  String get ownerGrowthCatalogLeadStatusNone;

  /// L10n key: ownerGrowthConversionRateLabel
  ///
  /// In tr, this message translates to:
  /// **'Dönüşüm oranı'**
  String get ownerGrowthConversionRateLabel;

  /// L10n key: ownerGrowthDistrictGapLabel
  ///
  /// In tr, this message translates to:
  /// **'İlçe fiyat farkı'**
  String get ownerGrowthDistrictGapLabel;

  /// L10n key: ownerGrowthBarChartTitle
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün — günlük trafik'**
  String get ownerGrowthBarChartTitle;

  /// L10n key: ownerGrowthBarChartSubtitle
  ///
  /// In tr, this message translates to:
  /// **'Menü görüntüleme, QR tarama ve dışa tıklama karşılaştırması'**
  String get ownerGrowthBarChartSubtitle;

  /// L10n key: ownerShellTrashLabel
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusu'**
  String get ownerShellTrashLabel;

  /// L10n key: ownerTrashTitle
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusu'**
  String get ownerTrashTitle;

  /// L10n key: ownerTrashDescription
  ///
  /// In tr, this message translates to:
  /// **'Arşivlenen menüleri, silinen ürün fotoğraflarını ve geri alınabilir kayıtları buradan yönet.'**
  String get ownerTrashDescription;

  /// L10n key: ownerTrashMissingBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'Önce bir işletme seç'**
  String get ownerTrashMissingBusinessTitle;

  /// L10n key: ownerTrashMissingBusinessDescription
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusunu görmek için seçili işletme bağlamı gerekli.'**
  String get ownerTrashMissingBusinessDescription;

  /// L10n key: ownerTrashFilterAll
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get ownerTrashFilterAll;

  /// L10n key: ownerTrashFilterMenus
  ///
  /// In tr, this message translates to:
  /// **'Menüler'**
  String get ownerTrashFilterMenus;

  /// L10n key: ownerTrashFilterItems
  ///
  /// In tr, this message translates to:
  /// **'Ürünler'**
  String get ownerTrashFilterItems;

  /// L10n key: ownerTrashFilterPhotos
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraflar'**
  String get ownerTrashFilterPhotos;

  /// L10n key: ownerTrashLoadErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusu yüklenemedi'**
  String get ownerTrashLoadErrorTitle;

  /// L10n key: ownerTrashEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusu boş'**
  String get ownerTrashEmptyTitle;

  /// L10n key: ownerTrashEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu işletmede geri alınabilir silinmiş kayıt bulunmuyor.'**
  String get ownerTrashEmptyDescription;

  /// L10n key: ownerTrashEntityMenu
  ///
  /// In tr, this message translates to:
  /// **'menü'**
  String get ownerTrashEntityMenu;

  /// L10n key: ownerTrashEntityItem
  ///
  /// In tr, this message translates to:
  /// **'ürün'**
  String get ownerTrashEntityItem;

  /// L10n key: ownerTrashEntityPhoto
  ///
  /// In tr, this message translates to:
  /// **'fotoğraf'**
  String get ownerTrashEntityPhoto;

  /// L10n key: ownerTrashOccurredAt
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusuna alınma: {value}'**
  String ownerTrashOccurredAt(Object value);

  /// L10n key: ownerTrashRestoreAction
  ///
  /// In tr, this message translates to:
  /// **'Geri yükle'**
  String get ownerTrashRestoreAction;

  /// L10n key: ownerTrashDeleteForeverAction
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı sil'**
  String get ownerTrashDeleteForeverAction;

  /// L10n key: ownerTrashRestoreConfirm
  ///
  /// In tr, this message translates to:
  /// **'Bu {entity} geri yüklenecek.'**
  String ownerTrashRestoreConfirm(Object entity);

  /// L10n key: ownerTrashDeleteForeverConfirm
  ///
  /// In tr, this message translates to:
  /// **'Bu {entity} kalıcı olarak silinecek. Bu işlem geri alınamaz.'**
  String ownerTrashDeleteForeverConfirm(Object entity);

  /// L10n key: ownerTrashRestoreSuccess
  ///
  /// In tr, this message translates to:
  /// **'Kayıt geri yüklendi.'**
  String get ownerTrashRestoreSuccess;

  /// L10n key: ownerTrashDeleteForeverSuccess
  ///
  /// In tr, this message translates to:
  /// **'Kayıt kalıcı olarak silindi.'**
  String get ownerTrashDeleteForeverSuccess;

  /// L10n key: ownerTrashSearchLabel
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusunda ara'**
  String get ownerTrashSearchLabel;

  /// L10n key: ownerTrashSortLabel
  ///
  /// In tr, this message translates to:
  /// **'Sıralama'**
  String get ownerTrashSortLabel;

  /// L10n key: ownerTrashSortNewest
  ///
  /// In tr, this message translates to:
  /// **'En yeni önce'**
  String get ownerTrashSortNewest;

  /// L10n key: ownerTrashSortOldest
  ///
  /// In tr, this message translates to:
  /// **'En eski önce'**
  String get ownerTrashSortOldest;

  /// L10n key: ownerTrashSortTitle
  ///
  /// In tr, this message translates to:
  /// **'Ada göre'**
  String get ownerTrashSortTitle;

  /// L10n key: ownerTrashSortType
  ///
  /// In tr, this message translates to:
  /// **'Türe göre'**
  String get ownerTrashSortType;

  /// L10n key: ownerMenuVersionsAction
  ///
  /// In tr, this message translates to:
  /// **'Versiyonlar'**
  String get ownerMenuVersionsAction;

  /// L10n key: ownerMenuVersionsTitle
  ///
  /// In tr, this message translates to:
  /// **'Yayın snapshot\'ları'**
  String get ownerMenuVersionsTitle;

  /// L10n key: ownerMenuVersionsDescription
  ///
  /// In tr, this message translates to:
  /// **'Yayına alınan sürümleri incele ve gerekirse güvenli şekilde bu versiyona dön.'**
  String get ownerMenuVersionsDescription;

  /// L10n key: ownerMenuVersionsLoadErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Versiyonlar yüklenemedi'**
  String get ownerMenuVersionsLoadErrorTitle;

  /// L10n key: ownerMenuVersionsEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz snapshot yok'**
  String get ownerMenuVersionsEmptyTitle;

  /// L10n key: ownerMenuVersionsEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu menü ilk kez yayına alındığında versiyon geçmişi burada oluşur.'**
  String get ownerMenuVersionsEmptyDescription;

  /// L10n key: ownerMenuVersionLabel
  ///
  /// In tr, this message translates to:
  /// **'Versiyon {version}'**
  String ownerMenuVersionLabel(Object version);

  /// L10n key: ownerMenuVersionSummary
  ///
  /// In tr, this message translates to:
  /// **'{reason} • {createdAt}'**
  String ownerMenuVersionSummary(Object reason, Object createdAt);

  /// L10n key: ownerMenuVersionCounts
  ///
  /// In tr, this message translates to:
  /// **'{sectionCount} bölüm • {itemCount} ürün'**
  String ownerMenuVersionCounts(Object sectionCount, Object itemCount);

  /// L10n key: ownerMenuVersionReasonPublish
  ///
  /// In tr, this message translates to:
  /// **'Yayına alma'**
  String get ownerMenuVersionReasonPublish;

  /// L10n key: ownerMenuVersionReasonRestore
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme'**
  String get ownerMenuVersionReasonRestore;

  /// L10n key: ownerMenuVersionRestoreAction
  ///
  /// In tr, this message translates to:
  /// **'Bu versiyona dön'**
  String get ownerMenuVersionRestoreAction;

  /// L10n key: ownerMenuVersionDiffAction
  ///
  /// In tr, this message translates to:
  /// **'Farkları gör'**
  String get ownerMenuVersionDiffAction;

  /// L10n key: ownerMenuVersionRestoreConfirm
  ///
  /// In tr, this message translates to:
  /// **'Versiyon {version} baz alınarak yeni bir yayınlı menü oluşturulacak. Mevcut menü arşive alınır.'**
  String ownerMenuVersionRestoreConfirm(Object version);

  /// L10n key: ownerMenuVersionRestoreSuccess
  ///
  /// In tr, this message translates to:
  /// **'Geri yüklenen versiyon hazır. Menü listesine dönülüyor.'**
  String get ownerMenuVersionRestoreSuccess;

  /// L10n key: ownerMenuVersionDiffTitle
  ///
  /// In tr, this message translates to:
  /// **'Versiyon {version} fark özeti'**
  String ownerMenuVersionDiffTitle(Object version);

  /// L10n key: ownerMenuVersionDiffDescription
  ///
  /// In tr, this message translates to:
  /// **'Seçilen snapshot ile şu an açık olan menü arasındaki farkları incele.'**
  String get ownerMenuVersionDiffDescription;

  /// L10n key: ownerMenuVersionDiffLoadErrorTitle
  ///
  /// In tr, this message translates to:
  /// **'Versiyon farkları yüklenemedi'**
  String get ownerMenuVersionDiffLoadErrorTitle;

  /// L10n key: ownerMenuVersionDiffMenuMetaTitle
  ///
  /// In tr, this message translates to:
  /// **'Özet değişiklikler'**
  String get ownerMenuVersionDiffMenuMetaTitle;

  /// L10n key: ownerMenuVersionDiffMenuTitleLine
  ///
  /// In tr, this message translates to:
  /// **'Menü adı: şimdi \"{current}\" • snapshot \"{snapshot}\"'**
  String ownerMenuVersionDiffMenuTitleLine(Object current, Object snapshot);

  /// L10n key: ownerMenuVersionDiffMenuKindLine
  ///
  /// In tr, this message translates to:
  /// **'Menü tipi: şimdi \"{current}\" • snapshot \"{snapshot}\"'**
  String ownerMenuVersionDiffMenuKindLine(Object current, Object snapshot);

  /// L10n key: ownerMenuVersionDiffCountLine
  ///
  /// In tr, this message translates to:
  /// **'{label}: şimdi {currentCount} • snapshot {snapshotCount}'**
  String ownerMenuVersionDiffCountLine(
    Object label,
    Object currentCount,
    Object snapshotCount,
  );

  /// L10n key: ownerMenuVersionDiffEmptyValue
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmedi'**
  String get ownerMenuVersionDiffEmptyValue;

  /// L10n key: ownerMenuVersionDiffNoChangesTitle
  ///
  /// In tr, this message translates to:
  /// **'Belirgin fark yok'**
  String get ownerMenuVersionDiffNoChangesTitle;

  /// L10n key: ownerMenuVersionDiffNoChangesDescription
  ///
  /// In tr, this message translates to:
  /// **'Bu snapshot, mevcut menü yapısıyla aynı görünüyor.'**
  String get ownerMenuVersionDiffNoChangesDescription;

  /// L10n key: ownerMenuVersionDiffSectionsAddedTitle
  ///
  /// In tr, this message translates to:
  /// **'Snapshot\'ta olup şu an olmayan bölümler'**
  String get ownerMenuVersionDiffSectionsAddedTitle;

  /// L10n key: ownerMenuVersionDiffSectionsRemovedTitle
  ///
  /// In tr, this message translates to:
  /// **'Şu an olup snapshot\'ta olmayan bölümler'**
  String get ownerMenuVersionDiffSectionsRemovedTitle;

  /// L10n key: ownerMenuVersionDiffItemsAddedTitle
  ///
  /// In tr, this message translates to:
  /// **'Snapshot\'ta olup şu an olmayan ürünler'**
  String get ownerMenuVersionDiffItemsAddedTitle;

  /// L10n key: ownerMenuVersionDiffItemsRemovedTitle
  ///
  /// In tr, this message translates to:
  /// **'Şu an olup snapshot\'ta olmayan ürünler'**
  String get ownerMenuVersionDiffItemsRemovedTitle;

  /// L10n key: ownerMenuVersionDiffEmptyList
  ///
  /// In tr, this message translates to:
  /// **'Değişiklik yok'**
  String get ownerMenuVersionDiffEmptyList;

  /// L10n key: ownerMenuVersionDiffMoreItems
  ///
  /// In tr, this message translates to:
  /// **'+{count} kayıt daha'**
  String ownerMenuVersionDiffMoreItems(Object count);

  /// L10n key: adminShellTrashLabel
  ///
  /// In tr, this message translates to:
  /// **'Restore merkezi'**
  String get adminShellTrashLabel;

  /// L10n key: adminShellTrashDescription
  ///
  /// In tr, this message translates to:
  /// **'Silinen menü, ürün ve fotoğrafları business bazlı geri yükle.'**
  String get adminShellTrashDescription;

  /// L10n key: adminBusinessesTrashAction
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusu'**
  String get adminBusinessesTrashAction;

  /// L10n key: adminMenuRestoreTitle
  ///
  /// In tr, this message translates to:
  /// **'Menü restore merkezi'**
  String get adminMenuRestoreTitle;

  /// L10n key: adminMenuRestoreDescription
  ///
  /// In tr, this message translates to:
  /// **'Bir işletme seç, ardından silinen menü, ürün ve fotoğrafları geri yükle veya kalıcı olarak sil.'**
  String get adminMenuRestoreDescription;

  /// L10n key: adminMenuRestoreBusinessSearchLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme ara veya ID gir'**
  String get adminMenuRestoreBusinessSearchLabel;

  /// L10n key: adminMenuRestoreSearchEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme araması bekleniyor'**
  String get adminMenuRestoreSearchEmptyTitle;

  /// L10n key: adminMenuRestoreSearchEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Restore ekranını açmak için en az 2 karakterle işletme ara.'**
  String get adminMenuRestoreSearchEmptyDescription;

  /// L10n key: adminMenuRestoreNoBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme bulunamadı'**
  String get adminMenuRestoreNoBusinessTitle;

  /// L10n key: adminMenuRestoreNoBusinessDescription
  ///
  /// In tr, this message translates to:
  /// **'Arama sonucunda eşleşen işletme çıkmadı. Ad, telefon ya da işletme kimliğini kontrol et.'**
  String get adminMenuRestoreNoBusinessDescription;

  /// L10n key: adminMenuRestoreSelectBusinessAction
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get adminMenuRestoreSelectBusinessAction;

  /// L10n key: adminMenuRestoreSelectBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'Önce işletme seç'**
  String get adminMenuRestoreSelectBusinessTitle;

  /// L10n key: adminMenuRestoreSelectBusinessDescription
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki restore panelini kullanmak için arama sonucundan bir işletme seç.'**
  String get adminMenuRestoreSelectBusinessDescription;

  /// L10n key: adminMenuRestorePanelTitle
  ///
  /// In tr, this message translates to:
  /// **'Silinen kayıtlar'**
  String get adminMenuRestorePanelTitle;

  /// L10n key: adminMenuRestorePanelDescription
  ///
  /// In tr, this message translates to:
  /// **'Admin yetkisiyle seçili işletmenin çöp kutusunu yönet.'**
  String get adminMenuRestorePanelDescription;

  /// L10n key: ownerDeletePhotoToTrashConfirm
  ///
  /// In tr, this message translates to:
  /// **'Bu fotoğraf çöp kutusuna taşınacak. İstersen daha sonra geri yükleyebilirsin.'**
  String get ownerDeletePhotoToTrashConfirm;

  /// L10n key: ownerPhotoMovedToTrash
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf çöp kutusuna taşındı.'**
  String get ownerPhotoMovedToTrash;

  /// L10n key: ownerAiAnalysisTitle
  ///
  /// In tr, this message translates to:
  /// **'AI Menü Analizi'**
  String get ownerAiAnalysisTitle;

  /// L10n key: ownerAiAnalysisNoBusinessTitle
  ///
  /// In tr, this message translates to:
  /// **'İşletme seçilmedi'**
  String get ownerAiAnalysisNoBusinessTitle;

  /// L10n key: ownerAiAnalysisNoBusinessDescription
  ///
  /// In tr, this message translates to:
  /// **'AI analizini kullanmak için önce bir işletme seç.'**
  String get ownerAiAnalysisNoBusinessDescription;

  /// L10n key: ownerAiAnalysisDisclaimer
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgiler otomatik analiz ile oluşturulmuştur. Kesin bilgi değildir; lütfen işletmeden doğrulayınız.'**
  String get ownerAiAnalysisDisclaimer;

  /// L10n key: ownerAiAnalysisUploadTitle
  ///
  /// In tr, this message translates to:
  /// **'Menü Fotoğrafı Yükle'**
  String get ownerAiAnalysisUploadTitle;

  /// L10n key: ownerAiAnalysisUploadDescription
  ///
  /// In tr, this message translates to:
  /// **'JPG, PNG veya WEBP formatında menü görseli yükle. AI otomatik ürün, alerjen ve kalori bilgisi üretir.'**
  String get ownerAiAnalysisUploadDescription;

  /// L10n key: ownerAiAnalysisUploadAction
  ///
  /// In tr, this message translates to:
  /// **'Görsel Seç'**
  String get ownerAiAnalysisUploadAction;

  /// L10n key: ownerAiAnalysisUploading
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get ownerAiAnalysisUploading;

  /// L10n key: ownerAiAnalysisAnalyzing
  ///
  /// In tr, this message translates to:
  /// **'AI analiz yapıyor...'**
  String get ownerAiAnalysisAnalyzing;

  /// L10n key: ownerAiAnalysisComplete
  ///
  /// In tr, this message translates to:
  /// **'{count} ürün analiz edildi. Sonuçları incele ve onayla.'**
  String ownerAiAnalysisComplete(int count);

  /// L10n key: ownerAiAnalysisJobsTitle
  ///
  /// In tr, this message translates to:
  /// **'Son İşler'**
  String get ownerAiAnalysisJobsTitle;

  /// L10n key: ownerAiAnalysisResultsTitle
  ///
  /// In tr, this message translates to:
  /// **'Analiz Sonuçları'**
  String get ownerAiAnalysisResultsTitle;

  /// L10n key: ownerAiAnalysisEmptyTitle
  ///
  /// In tr, this message translates to:
  /// **'Henüz analiz yok'**
  String get ownerAiAnalysisEmptyTitle;

  /// L10n key: ownerAiAnalysisEmptyDescription
  ///
  /// In tr, this message translates to:
  /// **'Menü görseli yükle, AI alerjen ve kalori bilgisi üretsin.'**
  String get ownerAiAnalysisEmptyDescription;

  /// L10n key: ownerAiAnalysisFilterAll
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get ownerAiAnalysisFilterAll;

  /// L10n key: ownerAiAnalysisFilterPending
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get ownerAiAnalysisFilterPending;

  /// L10n key: ownerAiAnalysisFilterApproved
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get ownerAiAnalysisFilterApproved;

  /// L10n key: ownerAiAnalysisFilterRejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get ownerAiAnalysisFilterRejected;

  /// L10n key: ownerAiAnalysisReviewRequired
  ///
  /// In tr, this message translates to:
  /// **'Manuel inceleme gerekiyor'**
  String get ownerAiAnalysisReviewRequired;

  /// L10n key: ownerAiAnalysisApproveAction
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get ownerAiAnalysisApproveAction;

  /// L10n key: ownerAiAnalysisRejectAction
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get ownerAiAnalysisRejectAction;

  /// L10n key: ownerAiAnalysisApproved
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı.'**
  String get ownerAiAnalysisApproved;

  /// L10n key: ownerAiAnalysisRejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi.'**
  String get ownerAiAnalysisRejected;

  /// L10n key: ownerAiAnalysisStatusPending
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get ownerAiAnalysisStatusPending;

  /// L10n key: ownerAiAnalysisStatusApproved
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get ownerAiAnalysisStatusApproved;

  /// L10n key: ownerAiAnalysisStatusRejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get ownerAiAnalysisStatusRejected;

  /// L10n key: ownerShellAiAnalysisLabel
  ///
  /// In tr, this message translates to:
  /// **'AI Analiz'**
  String get ownerShellAiAnalysisLabel;

  /// L10n key: ownerShellReviewsLabel
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar'**
  String get ownerShellReviewsLabel;

  /// L10n key: ownerReviewsTitle
  ///
  /// In tr, this message translates to:
  /// **'Müşteri Yorumları'**
  String get ownerReviewsTitle;

  /// L10n key: ownerReviewsDescription
  ///
  /// In tr, this message translates to:
  /// **'Gelen yorumları görüntüle ve yanıtla'**
  String get ownerReviewsDescription;

  /// L10n key: ownerReviewsReplyButton
  ///
  /// In tr, this message translates to:
  /// **'Yanıtla'**
  String get ownerReviewsReplyButton;

  /// L10n key: ownerReviewsEditReplyButton
  ///
  /// In tr, this message translates to:
  /// **'Yanıtı düzenle'**
  String get ownerReviewsEditReplyButton;

  /// L10n key: ownerReviewsDeleteReplyButton
  ///
  /// In tr, this message translates to:
  /// **'Yanıtı sil'**
  String get ownerReviewsDeleteReplyButton;

  /// L10n key: ownerReviewsReplyHint
  ///
  /// In tr, this message translates to:
  /// **'Müşteriye yanıtınızı yazın…'**
  String get ownerReviewsReplyHint;

  /// L10n key: ownerReviewsReplySaved
  ///
  /// In tr, this message translates to:
  /// **'Yanıtınız kaydedildi.'**
  String get ownerReviewsReplySaved;

  /// L10n key: ownerReviewsReplyDeleted
  ///
  /// In tr, this message translates to:
  /// **'Yanıt silindi.'**
  String get ownerReviewsReplyDeleted;

  /// L10n key: ownerReviewsOwnerReplyLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme Yanıtı'**
  String get ownerReviewsOwnerReplyLabel;

  /// L10n key: ownerReviewsEmpty
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yok.'**
  String get ownerReviewsEmpty;

  /// L10n key: ownerReviewsReplyCancelButton
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get ownerReviewsReplyCancelButton;

  /// L10n key: ownerReviewsReplySaveButton
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get ownerReviewsReplySaveButton;

  /// Sort by newest
  ///
  /// In tr, this message translates to:
  /// **'En yeni'**
  String get sortNewest;

  /// Sort by most helpful
  ///
  /// In tr, this message translates to:
  /// **'En faydalı'**
  String get sortMostHelpful;

  /// Helpful vote count
  ///
  /// In tr, this message translates to:
  /// **'{count} faydalı'**
  String helpfulCount(int count);
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
