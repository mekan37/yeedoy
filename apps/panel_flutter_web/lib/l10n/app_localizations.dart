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

  /// L10n key: appName
  ///
  /// In tr, this message translates to:
  /// **'Yeedoy'**
  String get appName;

  /// L10n key: map
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get map;

  /// L10n key: save
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// L10n key: cancel
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// L10n key: logout
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// L10n key: uploadPhoto
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf Yükle'**
  String get uploadPhoto;

  /// L10n key: saving
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get saving;

  /// L10n key: preview
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get preview;

  /// L10n key: embed
  ///
  /// In tr, this message translates to:
  /// **'Gömülü'**
  String get embed;

  /// L10n key: share
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// L10n key: invalidLinkMessage
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz bağlantı'**
  String get invalidLinkMessage;

  /// L10n key: browserOpened
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda açıldı'**
  String get browserOpened;

  /// L10n key: embedFailed
  ///
  /// In tr, this message translates to:
  /// **'İçerik görüntülenemedi, tarayıcıya yönlendirdik.'**
  String get embedFailed;

  /// L10n key: back
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// L10n key: reviewsCount
  ///
  /// In tr, this message translates to:
  /// **'Yorum ({count})'**
  String reviewsCount(int count);

  /// L10n key: openNow
  ///
  /// In tr, this message translates to:
  /// **'Şuan açık'**
  String get openNow;

  /// L10n key: verified
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get verified;

  /// L10n key: businessLabel
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get businessLabel;

  /// L10n key: menu
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get menu;

  /// L10n key: apply
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// L10n key: unknown
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknown;

  /// L10n key: title
  ///
  /// In tr, this message translates to:
  /// **'title'**
  String get title;

  /// L10n key: approved
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get approved;

  /// L10n key: tumu
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get tumu;

  /// L10n key: pending
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get pending;

  /// L10n key: rejected
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get rejected;

  /// L10n key: duzenle
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get duzenle;

  /// L10n key: sla
  ///
  /// In tr, this message translates to:
  /// **'Geri Dönüş Süresi'**
  String get sla;

  /// L10n key: yenile
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get yenile;

  /// L10n key: start
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get start;

  /// L10n key: campaign
  ///
  /// In tr, this message translates to:
  /// **'Kampanya'**
  String get campaign;

  /// L10n key: go
  ///
  /// In tr, this message translates to:
  /// **'Git'**
  String get go;

  /// L10n key: menuShareNotFoundTitle
  ///
  /// In tr, this message translates to:
  /// **'Menü bulunamadı • {appName}'**
  String menuShareNotFoundTitle(String appName);

  /// L10n key: menuShareNotFoundDescription
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan menü içeriği bulunamadı.'**
  String get menuShareNotFoundDescription;

  /// L10n key: menuContentNotFound
  ///
  /// In tr, this message translates to:
  /// **'Menü içeriği bulunamadı'**
  String get menuContentNotFound;

  /// L10n key: openAppForBetterExperience
  ///
  /// In tr, this message translates to:
  /// **'Daha iyi deneyim için uygulamayı aç.'**
  String get openAppForBetterExperience;

  /// L10n key: openApp
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Aç'**
  String get openApp;

  /// L10n key: nearbyPeopleViewed
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi yakında görüntüledi'**
  String nearbyPeopleViewed(int count);

  /// L10n key: verifiedPrices
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış fiyatlar'**
  String get verifiedPrices;

  /// L10n key: selectRatingFirst
  ///
  /// In tr, this message translates to:
  /// **'Önce puan seç'**
  String get selectRatingFirst;

  /// L10n key: thankYou
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler'**
  String get thankYou;

  /// L10n key: noProductsFound
  ///
  /// In tr, this message translates to:
  /// **'Ürün bulunamadı'**
  String get noProductsFound;

  /// L10n key: preparedWithApp
  ///
  /// In tr, this message translates to:
  /// **'{appName} ile hazırlandı'**
  String preparedWithApp(String appName);

  /// L10n key: tableLabel
  ///
  /// In tr, this message translates to:
  /// **'Masa {tableNo}'**
  String tableLabel(String tableNo);

  /// L10n key: tableServiceQuestion
  ///
  /// In tr, this message translates to:
  /// **'Masa {tableNo} servisi nasıldı?'**
  String tableServiceQuestion(String tableNo);

  /// L10n key: shortNoteOptional
  ///
  /// In tr, this message translates to:
  /// **'Kısa not (opsiyonel)'**
  String get shortNoteOptional;

  /// L10n key: submit
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get submit;

  /// L10n key: submitted
  ///
  /// In tr, this message translates to:
  /// **'Gönderildi'**
  String get submitted;

  /// L10n key: submitting
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor'**
  String get submitting;

  /// L10n key: retry
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// L10n key: register
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// L10n key: login
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// L10n key: cover
  ///
  /// In tr, this message translates to:
  /// **'Kuver'**
  String get cover;

  /// L10n key: note
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get note;

  /// L10n key: menuItemName
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı'**
  String get menuItemName;

  /// L10n key: price
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get price;

  /// L10n key: priceStability
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
