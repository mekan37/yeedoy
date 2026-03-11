// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Yeedoy';

  @override
  String get map => 'Harita';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get uploadPhoto => 'Fotoğraf Yükle';

  @override
  String get saving => 'Kaydediliyor...';

  @override
  String get preview => 'Önizleme';

  @override
  String get embed => 'Gömülü';

  @override
  String get share => 'Paylaş';

  @override
  String get invalidLinkMessage => 'Geçersiz bağlantı';

  @override
  String get browserOpened => 'Tarayıcıda açıldı';

  @override
  String get embedFailed => 'İçerik görüntülenemedi, tarayıcıya yönlendirdik.';

  @override
  String get embedUnsupported =>
      'Bu bağlantı gömülü olarak desteklenmiyor. Bağlantıyı kopyalayabilir veya tarayıcıda açabilirsin.';

  @override
  String get embedCopyLinkAction => 'Bağlantıyı kopyala';

  @override
  String get embedOpenBrowserAction => 'Tarayıcıda aç';

  @override
  String get back => 'Geri';

  @override
  String reviewsCount(int count) {
    return 'Yorum ($count)';
  }

  @override
  String get openNow => 'Şuan açık';

  @override
  String get verified => 'Doğrulandı';

  @override
  String get businessLabel => 'İşletme';

  @override
  String get menu => 'Menü';

  @override
  String get apply => 'Uygula';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get title => 'Başlık';

  @override
  String get approved => 'Onaylandı';

  @override
  String get tumu => 'Tümü';

  @override
  String get pending => 'Beklemede';

  @override
  String get rejected => 'Reddedildi';

  @override
  String get duzenle => 'Düzenle';

  @override
  String get sla => 'Geri Dönüş Süresi';

  @override
  String get yenile => 'Yenile';

  @override
  String get start => 'Başla';

  @override
  String get campaign => 'Kampanya';

  @override
  String get go => 'Git';

  @override
  String menuShareNotFoundTitle(String appName) {
    return 'Menü bulunamadı • $appName';
  }

  @override
  String get menuShareNotFoundDescription =>
      'Paylaşılan menü içeriği bulunamadı.';

  @override
  String get menuContentNotFound => 'Menü içeriği bulunamadı';

  @override
  String get openAppForBetterExperience =>
      'Daha iyi deneyim için uygulamayı aç.';

  @override
  String get openApp => 'Uygulamayı Aç';

  @override
  String nearbyPeopleViewed(int count) {
    return '$count kişi yakında görüntüledi';
  }

  @override
  String get verifiedPrices => 'Doğrulanmış fiyatlar';

  @override
  String get selectRatingFirst => 'Önce puan seç';

  @override
  String get thankYou => 'Teşekkürler';

  @override
  String get noProductsFound => 'Ürün bulunamadı';

  @override
  String preparedWithApp(String appName) {
    return '$appName ile hazırlandı';
  }

  @override
  String tableLabel(String tableNo) {
    return 'Masa $tableNo';
  }

  @override
  String tableServiceQuestion(String tableNo) {
    return 'Masa $tableNo servisi nasıldı?';
  }

  @override
  String get shortNoteOptional => 'Kısa not (opsiyonel)';

  @override
  String get submit => 'Gönder';

  @override
  String get submitted => 'Gönderildi';

  @override
  String get submitting => 'Gönderiliyor';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get login => 'Giriş Yap';

  @override
  String get cover => 'Kuver';

  @override
  String get note => 'Not';

  @override
  String get menuItemName => 'Ürün adı';

  @override
  String get price => 'Fiyat';

  @override
  String get priceStability => 'Fiyat istikrarı';

  @override
  String get ownerSections => 'Bölümler';

  @override
  String get ownerAddSection => 'Bölüm Ekle';

  @override
  String get ownerSectionNotFound => 'Henüz bölüm yok.';

  @override
  String get ownerEditSection => 'Bölümü Düzenle';

  @override
  String get ownerDeleteSection => 'Bölümü Sil';

  @override
  String get ownerSectionWillBeDeleted => 'Bu bölüm silinecek.';

  @override
  String get ownerArchiveItemsInSection => 'Bölümdeki ürünleri arşivle';

  @override
  String get ownerSectionAdded => 'Bölüm eklendi.';

  @override
  String get ownerSectionUpdated => 'Bölüm güncellendi.';

  @override
  String get ownerSectionDeleted => 'Bölüm silindi.';

  @override
  String get ownerEditMenu => 'Menüyü Düzenle';

  @override
  String get ownerMenuTypeOptional => 'Menü türü (opsiyonel)';

  @override
  String get ownerMenuUpdated => 'Menü güncellendi.';

  @override
  String get ownerArchiveMenuConfirm => 'Bu menüyü arşivlemek istiyor musun?';

  @override
  String get ownerPublishMenuConfirm => 'Bu menüyü yayına almak istiyor musun?';

  @override
  String get ownerSharePanel => 'Menü Paylaşım Paneli';

  @override
  String get ownerMenuLink => 'Menü bağlantısı';

  @override
  String get ownerQrPng => 'QR PNG';

  @override
  String get ownerQrPdf => 'QR PDF';

  @override
  String get ownerA6Pdf => 'A6 PDF';

  @override
  String get ownerFieldGainCardTitle => 'Sahada görünürlük kartı';

  @override
  String get ownerFieldGainCardLine1 =>
      'QR kartı yazdırıp müşterilere menüyü doğrulat.';

  @override
  String get ownerFieldGainCardLine2 =>
      'Menü ne kadar güncelse o kadar çok öne çıkarsın.';

  @override
  String get ownerCopyMiniDashboard => 'Mini panel bağlantısını kopyala';

  @override
  String get ownerMoatTitle => 'İşletme güven özeti';

  @override
  String ownerMoatSummary(int trust, int freshness, int accuracy) {
    return 'Güven: $trust | Menü güncelliği: $freshness | Fiyat doğruluğu: $accuracy';
  }

  @override
  String ownerMoatSignal(int validators, int evidencePct, int viewsToday) {
    return 'Sinyal: $validators doğrulayıcı, kanıt oranı %$evidencePct, bugün menü görüntüleme: $viewsToday';
  }

  @override
  String get ownerCopyMoatText => 'Özet metni kopyala';

  @override
  String get ownerWhatsappText => 'WhatsApp metni';

  @override
  String get ownerCopyWhatsapp => 'WhatsApp için kopyala';

  @override
  String get ownerXText => 'X (Twitter) metni';

  @override
  String get ownerCopyX => 'X için kopyala';

  @override
  String get ownerInstagramBio => 'Instagram biyografi metni';

  @override
  String get ownerCopyInstagram => 'Instagram için kopyala';

  @override
  String get ownerCopied => 'Kopyalandı';

  @override
  String ownerNearbyViewed(int count) {
    return '$count kişi yakında bu menüye baktı';
  }

  @override
  String ownerViewed(int count) {
    return '$count kişi baktı';
  }

  @override
  String get ownerCurrentMenuVerifiedPrices =>
      'Güncel menü ve doğrulanmış fiyatlar';

  @override
  String get ownerCurrentMenuVerifiedPricesColon =>
      'Güncel menü ve doğrulanmış fiyatlar:';

  @override
  String get ownerStatusPublished => 'Yayında';

  @override
  String get ownerStatusArchived => 'Arşivde';

  @override
  String get ownerStatusDraft => 'Taslak';

  @override
  String ownerMenuStatus(String status) {
    return 'Durum: $status';
  }

  @override
  String get ownerProducts => 'Ürünler';

  @override
  String get ownerApplying => 'Uygulanıyor...';

  @override
  String get ownerBulkPrice => 'Toplu Fiyat';

  @override
  String get ownerCsvImport => 'CSV İçe Aktar';

  @override
  String get ownerAddItem => 'Ürün Ekle';

  @override
  String get ownerProductNotFound => 'Henüz ürün yok.';

  @override
  String get ownerLoadMore => 'Daha fazla yükle';

  @override
  String get ownerEditItem => 'Ürünü Düzenle';

  @override
  String get ownerItemAdded => 'Ürün eklendi.';

  @override
  String get ownerItemUpdated => 'Ürün güncellendi.';

  @override
  String get ownerArchiveItemConfirm => 'Bu ürünü arşivlemek istiyor musun?';

  @override
  String get ownerItemArchived => 'Ürün arşivlendi.';

  @override
  String get ownerBulkPriceUpdate => 'Toplu fiyat güncelle';

  @override
  String get ownerMethod => 'Yöntem';

  @override
  String get ownerPercent => 'Yüzde';

  @override
  String get ownerFixedAmountTl => 'Sabit tutar (TL)';

  @override
  String get ownerOperation => 'İşlem';

  @override
  String get ownerIncrease => 'Artır';

  @override
  String get ownerDecrease => 'Azalt';

  @override
  String get ownerValuePercent => 'Değer (%)';

  @override
  String get ownerValueTl => 'Değer (TL)';

  @override
  String get ownerEnterValidValue => 'Lütfen geçerli bir değer gir.';

  @override
  String ownerUpdatedItemPrices(int count) {
    return '$count ürünün fiyatı güncellendi.';
  }

  @override
  String get ownerCsvFormatHint => 'Format: ad,fiyat,açıklama,para_birimi';

  @override
  String get ownerSelecting => 'Seçiliyor...';

  @override
  String get ownerSelectFile => 'Dosya Seç';

  @override
  String get ownerCsvExample => 'Döner,220,100 gr et,TRY';

  @override
  String get ownerImportContent => 'İçe Aktar';

  @override
  String get ownerNoValidRows => 'Geçerli satır bulunamadı.';

  @override
  String ownerImportedItems(int success) {
    return '$success ürün içe aktarıldı.';
  }

  @override
  String ownerImportedItemsWithSkipped(int success, int failed) {
    return '$success ürün eklendi, $failed satır atlandı.';
  }

  @override
  String get ownerAreYouSure => 'Emin misin?';

  @override
  String get ownerConfirm => 'Onayla';

  @override
  String get ownerArchiveAction => 'Arşivle';

  @override
  String get ownerPublishAction => 'Yayına Al';

  @override
  String get ownerDelete => 'Sil';

  @override
  String get ownerItemName => 'Ürün adı';

  @override
  String get ownerDescriptionOptional => 'Açıklama (opsiyonel)';

  @override
  String get ownerPriceTl => 'Fiyat (TL)';

  @override
  String get ownerCurrency => 'Para birimi';

  @override
  String get ownerCatalogSearch => 'Katalog ara';

  @override
  String get ownerCatalogSearchHint => 'Örn: Köfte, Burger...';

  @override
  String ownerSelectedCatalogId(int id) {
    return 'Seçili katalog ID: $id';
  }

  @override
  String get ownerItemNameMin2 => 'Ürün adı en az 2 karakter olmalı.';

  @override
  String get ownerInvalidPrice => 'Fiyat geçersiz.';

  @override
  String get ownerVariants => 'Varyantlar';

  @override
  String get ownerAddVariant => 'Varyant Ekle';

  @override
  String get ownerNoVariantsHint =>
      'Bu ürün için henüz varyant yok. Örnek: 80gr / 120gr';

  @override
  String get ownerDefaultVariant => 'Varsayılan';

  @override
  String get ownerSetDefault => 'Varsayılan yap';

  @override
  String get ownerLabelExample => 'Etiket (örn: 120gr)';

  @override
  String get ownerDefaultVariantSwitch => 'Varsayılan varyant';

  @override
  String get ownerPhotos => 'Fotoğraflar';

  @override
  String get ownerUploading => 'Yükleniyor...';

  @override
  String get ownerAddPhoto => 'Fotoğraf Ekle';

  @override
  String get ownerNoPhotoYet => 'Henüz fotoğraf yok.';

  @override
  String get ownerViewAll => 'Tümünü gör';

  @override
  String get ownerPhotoUploaded => 'Fotoğraf yüklendi.';

  @override
  String get ownerDeletePhoto => 'Fotoğrafı sil';

  @override
  String get ownerDeletePhotoConfirm => 'Bu fotoğraf silinecek.';

  @override
  String get ownerPhotoDeleted => 'Fotoğraf silindi.';

  @override
  String get adminAppealsTitle => 'İtiraz Kuyruğu';

  @override
  String get adminAppealsEmptySla =>
      'İtiraz yok. Hedef süre: rapor 24 saat, sahiplik talebi 48 saat.';

  @override
  String adminAppealSourceAndUser(String sourceId, String userId) {
    return 'Kaynak: $sourceId · Kullanıcı: $userId';
  }

  @override
  String adminAppealDecisionTitle(String id) {
    return 'İtiraz Kararı · $id';
  }

  @override
  String get adminAppealApproveAction => 'Onayla';

  @override
  String get adminAppealRejectAction => 'Reddet';

  @override
  String get adminAppealDecisionLabel => 'Karar';

  @override
  String get adminAppealTemplateLabel => 'Hazır şablon';

  @override
  String get adminAppealDecisionTextLabel => 'Karar metni';

  @override
  String get adminAppealDecisionTextHint =>
      'Kullanıcıya gösterilecek kısa açıklama';

  @override
  String get ownerNewBusinessTitle => 'Yeni işletme ekle';

  @override
  String get ownerNewBusinessIntro =>
      'Yeni işletmeni eklemek için bilgileri doldur.';

  @override
  String get ownerBusinessNameLabel => 'İşletme adı';

  @override
  String get ownerCategoryLabel => 'Kategori';

  @override
  String get ownerAddressLabel => 'Adres';

  @override
  String get ownerPhoneOptionalLabel => 'Telefon (opsiyonel)';

  @override
  String get ownerWebsiteOptionalLabel => 'Web sitesi (opsiyonel)';

  @override
  String get ownerSubmitApplication => 'Başvuruyu gönder';

  @override
  String get ownerSubmitting => 'Gönderiliyor...';

  @override
  String get ownerRequiredFieldsWarning => 'Lütfen zorunlu alanları doldur.';

  @override
  String get ownerApplicationReceived => 'Başvuru alındı.';

  @override
  String get ownerBusinessesTitle => 'İşletmelerim';

  @override
  String get ownerChainPage => 'Zincir sayfası';

  @override
  String get ownerMyApplications => 'Başvurularım';

  @override
  String get ownerLinksUpdated => 'Linkler güncellendi.';

  @override
  String get ownerReservationOrderLinksTitle =>
      'Rezervasyon ve sipariş linkleri';

  @override
  String get ownerReservationUrlLabel => 'Rezervasyon URL';

  @override
  String get ownerYemeksepetiUrlLabel => 'Yemeksepeti URL';

  @override
  String get ownerTrendyolGoUrlLabel => 'Trendyol Go URL';

  @override
  String get ownerGetirUrlLabel => 'Getir URL';

  @override
  String get ownerChainLabel => 'Marka/Zincir';

  @override
  String get ownerAllBranches => 'Tüm şubeler';

  @override
  String get ownerBranchLabel => 'Şube';

  @override
  String ownerChainPrefix(String chain) {
    return 'Zincir: $chain';
  }

  @override
  String get ownerPriceVerificationAction => 'Fiyat doğrulama';

  @override
  String get ownerRequestsAction => 'Talepler';

  @override
  String get ownerRequestsOwnerOnly => 'Talepler (yalnızca işletme sahibi)';

  @override
  String get ownerReservationOrderLinksAction =>
      'Rezervasyon ve sipariş linkleri';

  @override
  String get ownerStatsNotFound => 'İstatistik bulunamadı.';

  @override
  String get ownerPerformanceLast30Days => 'Son 30 gün performans';

  @override
  String get ownerMetricMenuViews => 'Menü görüntülenme';

  @override
  String get ownerMetricQrScans => 'QR tarama';

  @override
  String get ownerMetricSearchImpressions => 'Arama gösterimi';

  @override
  String get ownerMetricConversion => 'Dönüşüm';

  @override
  String get ownerMetricOutboundClicks => 'Dış bağlantı tıklamaları';

  @override
  String get ownerMetricPriceDropoff => 'Fiyat nedeniyle vazgeçme (tahmini)';

  @override
  String get ownerMetricPriceVsCompetitors => 'Rakibe göre fiyat';

  @override
  String ownerOutboundClicksValue(int outbound, int reservation, int order) {
    return '$outbound (Rez: $reservation, Sipariş: $order)';
  }

  @override
  String ownerPricePositionHigher(String pct) {
    return 'Daha pahalı$pct';
  }

  @override
  String ownerPricePositionLower(String pct) {
    return 'Daha uygun$pct';
  }

  @override
  String get ownerPricePositionSimilar => 'Pazarla uyumlu';

  @override
  String get ownerPricePositionNoData => 'Yeterli veri yok';

  @override
  String get ownerNoBusinessesTitle => 'Henüz işletme yok';

  @override
  String get ownerNoBusinessesDescription =>
      'Yeni işletme başvurusu oluşturabilirsin.';

  @override
  String get ownerRoleOwner => 'İşletme sahibi';

  @override
  String get ownerRoleManager => 'Yönetici';

  @override
  String get ownerMenuAction => 'Menü';

  @override
  String get city => 'Şehir';

  @override
  String get district => 'İlçe';

  @override
  String ownerActiveRange(String from, String to) {
    return 'Aktif: $from - $to';
  }

  @override
  String get webHomeSubtitle =>
      'Canlı menü, fiyat şeffaflığı ve topluluk doğrulama platformu.';

  @override
  String get webHomeNextLinkLabel => 'QR Menü Web (Next.js)';

  @override
  String get webHomeBusinessAreaTitle => 'İşletme Alanı';

  @override
  String get webHomeBusinessAreaSubtitle =>
      'Panele erişmek için işletme veya admin hesabınla giriş yap.';

  @override
  String get webHomeBusinessLogin => 'İşletme Girişi';

  @override
  String get webHomeBusinessRegister => 'İşletme Kaydı';

  @override
  String get businessAuthEmailLabel => 'E-posta';

  @override
  String get businessAuthPasswordLabel => 'Şifre';

  @override
  String get businessAuthPasswordRepeatLabel => 'Şifre (tekrar)';

  @override
  String get businessLoginTitle => 'İşletme Girişi';

  @override
  String get businessLoginIntro =>
      'İşletme sahibi veya admin paneline erişmek için giriş yap.';

  @override
  String get businessLoginNoPermissionError =>
      'Bu hesapta işletme veya admin yetkisi bulunamadı. İşletme kaydı ile devam edebilirsin.';

  @override
  String get businessLoginSubmitting => 'Giriş yapılıyor...';

  @override
  String get businessLoginGoRegister => 'İşletme Kaydına Git';

  @override
  String get businessRegisterTitle => 'İşletme Kaydı';

  @override
  String get businessRegisterIntro =>
      'İşletme paneline erişmek için kayıt oluştur.';

  @override
  String get businessRegisterPasswordMinError =>
      'Şifre en az 6 karakter olmalı.';

  @override
  String get businessRegisterPasswordMismatchError => 'Şifreler aynı değil.';

  @override
  String get businessRegisterSuccess =>
      'Kayıt oluşturuldu. Doğrulama adımını tamamladıktan sonra işletme girişi yapabilirsin.';

  @override
  String get businessRegisterSubmitting => 'Kayıt oluşturuluyor...';

  @override
  String get businessRegisterBackToLogin => 'İşletme Girişine Dön';

  @override
  String get close => 'Kapat';

  @override
  String get adminSponsorshipCreateTitle => 'Sponsorluk oluştur';

  @override
  String get adminSponsorshipSurfaceLabel => 'Gösterim alanı';

  @override
  String get adminSponsorshipSurfaceDiscovery => 'Keşfet';

  @override
  String get adminSponsorshipSurfaceBusinessPage => 'İşletme sayfası';

  @override
  String get adminSponsorshipPackageLabel => 'Paket';

  @override
  String adminSponsorshipPackageOption(String name, int days) {
    return '$name • $days gün';
  }

  @override
  String get adminSponsorshipStartDateLabel => 'Başlangıç (YYYY-MM-DD)';

  @override
  String get adminSponsorshipEndDateLabel => 'Bitiş (YYYY-MM-DD)';

  @override
  String get adminSponsorshipDailyCapLabel => 'Günlük limit';

  @override
  String get adminSponsorshipTotalCapLabel => 'Toplam limit';

  @override
  String get adminSponsorshipPriorityOptionalLabel => 'Öncelik (opsiyonel)';

  @override
  String get adminSponsorshipTargetingTitle => 'Hedefleme';

  @override
  String get adminSponsorshipSearchBusinessHint =>
      'İşletme ara (isim veya adres)';

  @override
  String get adminSponsorshipSearchAction => 'Ara';

  @override
  String get adminSponsorshipSearchingAction => 'Aranıyor...';

  @override
  String get adminSponsorshipRemoveBusinessAction => 'Kaldır';

  @override
  String get adminSponsorshipAddTargetingValueAction => 'Ekle';

  @override
  String get adminSponsorshipCreateAction => 'Oluştur';

  @override
  String get adminSponsorshipSavingAction => 'Kaydediliyor...';

  @override
  String get adminSponsorshipSelectBusinessError => 'İşletme seçin.';

  @override
  String get adminSponsorshipSelectPackageError => 'Paket seçin.';

  @override
  String get adminSponsorshipCreated => 'Sponsorluk oluşturuldu.';

  @override
  String adminNewItemsBannerLabel(String label, int count) {
    return '$label (+$count)';
  }

  @override
  String get adminRiskQueueTitle => 'Riskli kullanıcılar';

  @override
  String adminRiskQueueScoreThreshold(int score) {
    return 'Skor >= $score';
  }

  @override
  String get adminRiskQueueFilterLabel => 'Filtre';

  @override
  String get adminRiskQueueEmptyTitle => 'Riskli kullanıcı yok';

  @override
  String get adminRiskQueueEmptyDescription =>
      'Bu filtre için şu anda işlem gerektiren kullanıcı yok.';

  @override
  String get adminRiskQueueReasonDialogTitle => 'Aksiyon nedeni';

  @override
  String adminRiskQueueActionWithName(String action) {
    return 'Aksiyon: $action';
  }

  @override
  String get adminRiskQueueReasonLabel => 'Gerekçe (zorunlu)';

  @override
  String get adminRiskQueueReasonHint => 'Kısa bir açıklama girin';

  @override
  String get adminRiskQueueCopyUserId => 'Kullanıcı kimliğini kopyala';

  @override
  String adminRiskQueueSignalCount(int count) {
    return 'Sinyal: $count';
  }

  @override
  String adminRiskQueueNewAccountHits(int count) {
    return 'Yeni hesap: $count';
  }

  @override
  String adminRiskQueueDeviceChangeHits(int count) {
    return 'Cihaz değişimi: $count';
  }

  @override
  String adminRiskQueueSameIpHits(int count) {
    return 'IP yoğunluğu: $count';
  }

  @override
  String adminRiskQueueDuplicateTextHits(int count) {
    return 'Kopya metin: $count';
  }

  @override
  String adminRiskQueueSoftLimitAction(int minutes) {
    return 'Yumuşak limit $minutes dk';
  }

  @override
  String adminRiskQueueAutoPendingAction(int hours) {
    return 'Otomatik bekleme $hours sa';
  }

  @override
  String adminRiskQueueShadowBanAction(int hours) {
    return 'Gölge yasak $hours sa';
  }

  @override
  String get adminRiskQueueClearAction => 'Temizle';

  @override
  String adminRiskQueueScoreLabel(int score) {
    return 'Skor $score';
  }

  @override
  String get adminAuditTitle => 'Denetim kaydı';

  @override
  String get adminAuditOwnerTitle => 'İşlem geçmişi';

  @override
  String adminAuditRecordCount(int count) {
    return '$count kayıt';
  }

  @override
  String get adminAuditEmptyTitle => 'Kayıt bulunamadı';

  @override
  String get adminAuditEmptyDescription =>
      'Filtreleri genişletip tekrar deneyin.';

  @override
  String get adminAuditClearFilters => 'Filtreleri temizle';

  @override
  String get adminAuditCreatedAtColumn => 'Oluşturulma';

  @override
  String get adminAuditActionColumn => 'Aksiyon';

  @override
  String get adminAuditTargetTypeColumn => 'Hedef tür';

  @override
  String get adminAuditTargetIdColumn => 'Hedef ID';

  @override
  String get adminAuditActorColumn => 'Aktör';

  @override
  String get adminAuditDetailsAction => 'Detay';

  @override
  String get adminAuditCopyTargetId => 'Hedef kimliğini kopyala';

  @override
  String get adminAuditCopied => 'Kopyalandı.';

  @override
  String get adminAuditDetailsTitle => 'Denetim detayı';

  @override
  String get adminAuditActorIdLabel => 'Aktör ID';

  @override
  String get adminAuditActorRoleLabel => 'Aktör rolü';

  @override
  String get adminAuditBeforeAfterTitle => 'Önce / Sonra';

  @override
  String get adminAuditDiffFieldLabel => 'Alan';

  @override
  String get adminAuditDiffBeforeLabel => 'Önce';

  @override
  String get adminAuditDiffAfterLabel => 'Sonra';

  @override
  String get adminAuditDiffNoChanges =>
      'Alan bazlı fark bulunamadı. Gerekirse aşağıdaki ham JSON kaydını inceleyebilirsin.';

  @override
  String get adminAuditDiffRootField => 'Kayıt';

  @override
  String get adminAuditRawBeforeTitle => 'Ham önce verisi';

  @override
  String get adminAuditRawAfterTitle => 'Ham sonra verisi';

  @override
  String get adminAuditMetaTitle => 'Meta';

  @override
  String get adminAuditActionFilterAll => 'Aksiyon (tümü)';

  @override
  String get adminAuditTargetTypeFilterAll => 'Tablo (tümü)';

  @override
  String get adminAuditRelativeNow => 'Şimdi';

  @override
  String adminAuditRelativeMinutes(int count) {
    return '$count dk';
  }

  @override
  String adminAuditRelativeHours(int count) {
    return '$count sa';
  }

  @override
  String adminAuditRelativeDays(int count) {
    return '$count gün';
  }

  @override
  String adminAuditRelativeWeeks(int count) {
    return '$count hf';
  }

  @override
  String adminAuditRelativeMonths(int count) {
    return '$count ay';
  }

  @override
  String get adminB2bExportsTitle => 'B2B veri ihracı';

  @override
  String get adminB2bExportsSubtitle =>
      'B2B içgörüleri için fiyat endeksi ve bölgesel trend raporlarını CSV olarak indirebilirsiniz.';

  @override
  String get adminB2bExportsPriceIndexChip => 'Fiyat endeksi';

  @override
  String get adminB2bExportsRegionalTrendChip => 'Bölgesel trend';

  @override
  String get adminB2bExportsMenuInflationChip => 'Menü enflasyonu';

  @override
  String get adminB2bExportsPeriodLabel => 'Dönem:';

  @override
  String adminB2bExportsDayOption(int days) {
    return '$days gün';
  }

  @override
  String get adminB2bExportsAnonymousTrendsTitle => 'Anonim trend verisi';

  @override
  String get adminB2bExportsAnonymousTrendsDescription =>
      'Gün, şehir, ilçe ve etkinlik bazında anonimleştirilmiş trend kaydı.';

  @override
  String get adminB2bExportsRegionalPriceIndexTitle => 'Bölgesel fiyat endeksi';

  @override
  String get adminB2bExportsRegionalPriceIndexDescription =>
      'Şehir ve ilçe bazında ortalama, medyan fiyat ve önceki döneme göre değişim.';

  @override
  String get adminB2bExportsMenuInflationTitle => 'Menü enflasyonu raporu';

  @override
  String get adminB2bExportsMenuInflationDescription =>
      'Ürün bazında dönem içindeki ilk ve son fiyat ile enflasyon yüzdesi.';

  @override
  String get adminB2bExportsPriceAnomaliesTitle => 'Fiyat anomali raporu';

  @override
  String get adminB2bExportsPriceAnomaliesDescription =>
      'Kısa sürede aşırı fiyat artışı yaşayan ürünleri listeler.';

  @override
  String get adminB2bExportsPreparingAction => 'Hazırlanıyor...';

  @override
  String get adminB2bExportsDownloadCsvAction => 'CSV indir';

  @override
  String get adminB2bExportsGovernanceTitle => 'Veri urunu siniri';

  @override
  String get adminB2bExportsGovernanceDescription =>
      'Bu ekran tum exportlari ayni ticari seviyede gormez; her dataset hangi urun hattina ait oldugu ve ne kadar anonimlestirildigi ile siniflandirilir.';

  @override
  String get adminB2bExportsGovernanceAnonymousRule =>
      'Anonymous aggregate: ham kullanici kimligi, cihaz kimligi veya tek isletmeye geri donen izler disari cikmaz.';

  @override
  String get adminB2bExportsGovernanceRestrictedRule =>
      'Restricted aggregate: isletme veya urun seviyesinde sinyal vardir; owner premium raporlama icin adaydir, dis satista ek gozden gecirme gerekir.';

  @override
  String get adminB2bExportsGovernanceContractRule =>
      'Contract only: anomali ve hassas veri setleri varsayilan olarak yalnizca ic operasyon veya sozmeli analiz akisi icin kullanilir.';

  @override
  String get adminB2bExportsLaneLabel => 'Urun hatti';

  @override
  String get adminB2bExportsPrivacyLabel => 'Gizlilik sinifi';

  @override
  String get adminB2bExportsFreshnessLabel => 'Tazelik';

  @override
  String get adminB2bExportsLaneInternalOps => 'Ic operasyon';

  @override
  String get adminB2bExportsLanePremiumCandidate => 'Premium raporlama adayi';

  @override
  String get adminB2bExportsLaneExternalCandidate => 'Dis veri urunu adayi';

  @override
  String get adminB2bExportsPrivacyAnonymousAggregate => 'Anonymous aggregate';

  @override
  String get adminB2bExportsPrivacyRestrictedAggregate =>
      'Restricted aggregate';

  @override
  String get adminB2bExportsPrivacyContractOnly => 'Contract only';

  @override
  String get adminB2bExportsFreshnessDailySeries => 'Gunluk seri';

  @override
  String get adminB2bExportsFreshnessRollingWindow => 'Rolling window';

  @override
  String get adminB2bExportsStatusInternalReady => 'Ic kullanim hazir';

  @override
  String get adminB2bExportsStatusPremiumCandidate => 'Premium paket adayi';

  @override
  String get adminB2bExportsStatusExternalCandidate => 'Dis satis adayi';

  @override
  String get adminBusinessSubmissionsStatusLabel => 'Durum:';

  @override
  String get adminBusinessSubmissionsNewStatus => 'Yeni';

  @override
  String get adminBusinessSubmissionsEmpty => 'Başvuru bulunamadı.';

  @override
  String get adminBusinessSubmissionsApproveConfirm =>
      'Başvuruyu onaylamak istiyor musun?';

  @override
  String get adminBusinessSubmissionsOptionalNoteLabel => 'Not (opsiyonel)';

  @override
  String get adminBusinessesTitle => 'İşletmeler';

  @override
  String get adminBusinessesSearchHint => 'Ara (isim, adres)';

  @override
  String get adminBusinessesLogoColumn => 'Logo';

  @override
  String get adminBusinessesNameColumn => 'İsim';

  @override
  String get adminBusinessesRiskColumn => 'Risk';

  @override
  String get adminBusinessesCreatedAtColumn => 'Oluşturulma';

  @override
  String get adminBusinessesAssignedColumn => 'Atanan';

  @override
  String get adminBusinessesMergeAction => 'Birleştir';

  @override
  String get adminBusinessesQrMenuAction => 'Dijital Menü ve QR';

  @override
  String get adminBusinessesPublicMenuAction => 'Public menü linki';

  @override
  String get adminBusinessesEmpty => 'Kayıt bulunamadı.';

  @override
  String get adminBusinessesUpdated => 'Güncellendi.';

  @override
  String get adminBusinessesEditTitle => 'İşletmeyi düzenle';

  @override
  String get adminBusinessesPublicMenuLinkLabel => 'Public menü bağlantısı';

  @override
  String get adminBusinessesQrGenerationLinkLabel => 'QR üretim bağlantısı';

  @override
  String get adminBusinessesCopyMenuLinkAction => 'Menü linkini kopyala';

  @override
  String get adminBusinessesInfoTab => 'Bilgi';

  @override
  String get adminBusinessesMediaTab => 'Medya';

  @override
  String get adminBusinessesLatitudeLabel => 'Enlem';

  @override
  String get adminBusinessesLongitudeLabel => 'Boylam';

  @override
  String get adminBusinessesUploadMediaAction => 'Yükle';

  @override
  String get adminBusinessesClearAction => 'Temizle';

  @override
  String get adminBusinessesLogoUrlLabel => 'Logo URL';

  @override
  String get adminBusinessesCoverLabel => 'Kapak';

  @override
  String get adminBusinessesCoverUrlLabel => 'Kapak URL';

  @override
  String get adminBusinessesPublicMenuCopied => 'Public menü linki kopyalandı.';

  @override
  String get adminBusinessesStatusNeedsReview => 'İnceleme gerekli';

  @override
  String get adminBusinessesEmptyTitle => 'İşletme bulunamadı';

  @override
  String get adminBusinessesEmptyDescription =>
      'Filtreleri temizleyip farklı bir arama deneyin.';

  @override
  String get adminBusinessesErrorTitle => 'İşletmeler yüklenemedi';

  @override
  String adminBusinessesVerificationUpdatedCount(int count) {
    return 'Seçili $count işletmenin doğrulama durumu güncellendi.';
  }

  @override
  String adminBusinessesAssignedCount(int count) {
    return 'Seçili $count işletmenin atama durumu güncellendi.';
  }

  @override
  String get adminBusinessesBulkStatusLabel => 'Toplu durum';

  @override
  String get adminBusinessesBulkStatusVerified => 'Doğrulandı olarak işaretle';

  @override
  String get adminBusinessesBulkStatusNeedsReview =>
      'İnceleme gerekli olarak işaretle';

  @override
  String get adminBusinessesBulkStatusUnassigned => 'Atamayı kaldır';

  @override
  String get adminBusinessesNoMergeCandidates =>
      'Birleştirme adayı bulunamadı.';

  @override
  String get adminBusinessesMergeSuggestedNote =>
      'Aynı işletme kaydı olabilir. Birleştirme kontrolü önerildi.';

  @override
  String adminBusinessesMergeCandidateTitle(String name) {
    return '\"$name\" için birleştirme adayı seçin';
  }

  @override
  String get adminBusinessesMergeApplyNowTitle =>
      'Anında birleştir (zorla birleştir)';

  @override
  String get adminBusinessesMergeApplyNowDescription =>
      'Kapalıysa yalnızca merge talebi denetim kaydına yazılır.';

  @override
  String get adminBusinessesMergePreviewAction => 'Önizleme';

  @override
  String adminBusinessesMergePreviewSummary(
    int menus,
    int items,
    int reviews,
    int media,
  ) {
    return 'Önizleme: menüler $menus, ürünler $items, yorumlar $reviews, medya $media';
  }

  @override
  String get adminBusinessesMergeApplyNowAction => 'Birleştir ve uygula';

  @override
  String get adminBusinessesMergeCreateProposalAction =>
      'Birleştirme talebi oluştur';

  @override
  String get adminBusinessesMergeCompleted => 'Birleştirme tamamlandı.';

  @override
  String get adminBusinessesMergeProposalLogged =>
      'Birleştirme talebi denetim kaydına eklendi.';

  @override
  String get adminBusinessesRiskSuspicious => 'Şüpheli';

  @override
  String get adminBusinessesRiskMedium => 'Orta';

  @override
  String get adminBusinessesRiskLow => 'Düşük';

  @override
  String get adminBusinessesRiskMissing => 'yok';

  @override
  String get adminBusinessesRiskAvailable => 'var';

  @override
  String adminBusinessesRiskTooltip(
    String address,
    String phone,
    int photoCount,
    int engagementCount,
  ) {
    return 'Adres: $address • Telefon: $phone • Foto: $photoCount • Etkileşim: $engagementCount';
  }

  @override
  String get adminClaimsTitle => 'Sahiplik talepleri';

  @override
  String get adminClaimsExportingAction => 'İndiriliyor...';

  @override
  String get adminClaimsExportCsvAction => 'CSV dışa aktar';

  @override
  String get adminClaimsSearchHint => 'Ara (ID, isim, telefon)';

  @override
  String get adminClaimsAssignedUnassigned => 'Boşta';

  @override
  String get adminClaimsAssignedMine => 'Benim';

  @override
  String get adminClaimsAssignedAnotherAdmin => 'Başka admin';

  @override
  String get adminClaimsNewRecordsAvailable => 'Yeni kayıtlar var';

  @override
  String get adminClaimsBulkUpdated => 'Güncellendi.';

  @override
  String get adminClaimsSelectSamePhoneAction => 'Aynı telefonu seç';

  @override
  String get adminClaimsAssignSelectedToMeAction => 'Seçilileri bana ata';

  @override
  String get adminClaimsFullNameColumn => 'Ad Soyad';

  @override
  String get adminClaimsPriorityColumn => 'Öncelik';

  @override
  String get adminClaimsStatusColumn => 'Durum';

  @override
  String get adminClaimsAssignedColumn => 'Atanan';

  @override
  String get adminClaimsCreatedAtColumn => 'Oluşturulma';

  @override
  String get adminClaimsAgeColumn => 'Yaş';

  @override
  String get adminClaimsDetailsAction => 'Detay';

  @override
  String get adminClaimsAutoModeratedTooltip => 'Otomatik moderasyon uygulandı';

  @override
  String get adminClaimsEmpty => 'Kayıt bulunamadı.';

  @override
  String adminClaimsSlaBreached(String age) {
    return 'Bu kayıt SLA aştı: $age';
  }

  @override
  String get adminClaimsDetailTitle => 'Kayıt detayı';

  @override
  String get adminClaimsPhoneLabel => 'Telefon';

  @override
  String get adminClaimsEvidenceLabel => 'Kanıt';

  @override
  String get adminClaimsAdminNoteOptionalLabel => 'Admin notu (opsiyonel)';

  @override
  String get adminClaimsAutoRulesTitle => 'Otomatik kurallar';

  @override
  String get adminClaimsAutoRuleApplied => 'Otomatik kural uygulandı.';

  @override
  String get adminClaimsNoAutoRuleFound => 'Uygun otomatik kural bulunamadı.';

  @override
  String get adminClaimsApplyingAction => 'Uygulanıyor...';

  @override
  String get adminClaimsApplyRulesAction => 'Kuralları uygula';

  @override
  String get adminClaimsDone => 'İşlem bitti.';

  @override
  String get adminClaimsProcessingAction => 'İşleniyor...';

  @override
  String get adminClaimsAssignToMeAction => 'Bana ata';

  @override
  String get adminClaimsUnassignAction => 'Atamayı kaldır';

  @override
  String get adminClaimsAssignmentRemoved => 'Atama kaldırıldı.';

  @override
  String get adminClaimsApproved => 'Onaylandı.';

  @override
  String get adminClaimsRejected => 'Reddedildi.';

  @override
  String get adminClaimsSelectRowFirst => 'Satır seç';

  @override
  String get adminClaimsNoPhone => 'Bu kayıtta telefon yok.';

  @override
  String adminClaimsAssignedToYou(int count) {
    return '$count talep sana atandı.';
  }

  @override
  String adminClaimsSelectedCount(int count) {
    return 'Seçili: $count';
  }

  @override
  String get adminClaimsClearSelectionAction => 'Temizle';

  @override
  String adminClaimsAgeValue(String days) {
    return '$days gün';
  }

  @override
  String get adminClaimsDecisionTemplateApproved =>
      'Belge ve bilgiler doğrulandı, talep onaylandı.';

  @override
  String get adminClaimsDecisionTemplateRejected =>
      'Doğrulama kriterleri sağlanamadı, talep reddedildi.';

  @override
  String get adminClaimsDecisionTemplateNeedsDocuments =>
      'Ek belge gerekiyor, inceleme devam ediyor.';

  @override
  String get adminDashboardOverviewTitle => 'Genel Bakış';

  @override
  String get adminDashboardOverviewSubtitle => 'Operasyon ve büyüme metrikleri';

  @override
  String get adminDashboardOpenReports => 'Açık raporlar';

  @override
  String get adminDashboardPendingClaims => 'Bekleyen sahiplik';

  @override
  String get adminDashboardPendingSuggestions => 'Bekleyen öneriler';

  @override
  String get adminDashboardReportAssignMinutes => 'Rapor atama (dk)';

  @override
  String get adminDashboardReportCloseMinutes => 'Rapor kapanışı (dk)';

  @override
  String get adminDashboardClaimAssignMinutes => 'Sahiplik atama (dk)';

  @override
  String get adminDashboardClaimDecisionMinutes => 'Sahiplik karar (dk)';

  @override
  String get adminDashboardGrowth30Days => 'Büyüme (30 gün)';

  @override
  String get adminDashboardMenuLinkOpened => 'Menü link açıldı';

  @override
  String get adminDashboardQrScanned => 'QR okutuldu';

  @override
  String get adminDashboardMenuShared => 'Menü paylaşıldı';

  @override
  String get adminDashboardAppInstall => 'Uygulama kurulum';

  @override
  String get adminDashboardKpi30Days => 'KPI (30 gün)';

  @override
  String get adminDashboardDau => 'DAU';

  @override
  String get adminDashboardWau => 'WAU';

  @override
  String get adminDashboardDiscoveryCtr => 'Keşfet → İşletme CTR';

  @override
  String get adminDashboardBusinessToMenuRate => 'İşletme → Menü oranı';

  @override
  String get adminDashboardPriceVerificationConversion =>
      'Fiyat doğrulama dönüşümü';

  @override
  String get adminDashboardReportResolutionMinutes => 'Rapor çözüm süresi (dk)';

  @override
  String get adminDashboardQualityGateTitle => 'V3 Kalite ve Güven Kapısı (P0)';

  @override
  String get adminDashboardQualityGateSubtitle =>
      'Yanlış bilgiyi düşür, güveni yükselt. Büyüme için kaliteyi gevşetme.';

  @override
  String adminDashboardLiveGate(int passed, int total) {
    return 'Canlı kapı: $passed/$total';
  }

  @override
  String get adminDashboardGateAccuracyScores => 'Doğruluk skorları';

  @override
  String get adminDashboardGatePriceVerification => 'Fiyat doğrulama';

  @override
  String get adminDashboardGateMenuHistory => 'Menü versiyon/geçmiş';

  @override
  String get adminDashboardGateFalseInfoReporting => 'Yanlış bilgi bildirimi';

  @override
  String get adminDashboardGateBusinessLifecycle => 'İşletme yaşam döngüsü';

  @override
  String get adminDashboardGateReviewQuality => 'Yorum kalite sistemi';

  @override
  String get adminDashboardGateOpenNowCheck => 'Şimdi açık kontrolü';

  @override
  String get adminDashboardGateBusinessPanelCore => 'İşletme panel temel';

  @override
  String get adminDashboardGateAdminQueue => 'Admin kuyruk';

  @override
  String get adminDashboardGateInbox => 'Uygulama içi gelen kutusu';

  @override
  String adminDashboardGuardrailSummary(
    String requireLabel,
    String minTrust,
    String ownerDelete,
    String bypass,
  ) {
    return 'Korkuluk: sponsor etiketi=$requireLabel, min sponsor güveni=$minTrust, işletme yorum silme=$ownerDelete, kalite bypass=$bypass.';
  }

  @override
  String get adminDevToolsTitle => 'Geliştirici araçları';

  @override
  String get adminDevToolsSubtitle =>
      'Özellik, test kullanıcı ve test şehir ayarları.';

  @override
  String get adminDevToolsAchievementRequired =>
      'Kullanıcı ID ve Başarı ID zorunlu.';

  @override
  String adminDevToolsResetFailed(String error) {
    return 'Reset başarısız: $error';
  }

  @override
  String get adminDevToolsAchievementResetLogged =>
      'Başarı resetlendi ve denetim kayda yazıldı.';

  @override
  String get adminDevToolsNoRecordButLogged =>
      'Kayıt bulunmadı ama denetim kayda yazıldı.';

  @override
  String adminDevToolsError(String error) {
    return 'Hata: $error';
  }

  @override
  String get adminDevToolsAchievementModerationTitle => 'Başarı moderasyonu';

  @override
  String get adminDevToolsAchievementModerationDescription =>
      'Gerekirse başarı kaydını sil ve profile XP/seviyeyi yeniden hesapla.';

  @override
  String get adminDevToolsUserIdUuidLabel => 'Kullanıcı ID (UUID)';

  @override
  String get adminDevToolsWriterUserIdHint => 'yazar kullanıcı ID';

  @override
  String get adminDevToolsAchievementIdLabel => 'Başarı ID';

  @override
  String get adminDevToolsAchievementIdHint => 'örnek: trusted_contributor';

  @override
  String get adminDevToolsReasonOptionalLabel => 'Neden (opsiyonel)';

  @override
  String get adminDevToolsResettingAction => 'Resetleniyor...';

  @override
  String get adminDevToolsAchievementResetAction => 'Başarı resetle';

  @override
  String get adminDevToolsGuardrailThresholdsTitle => 'Korkuluk eşikleri';

  @override
  String get adminDevToolsGuardrailThresholdsDescription =>
      'Canlı kalite eşiklerini admin panelinden ayarla.';

  @override
  String get adminDevToolsRequireSponsoredLabel => 'Sponsor etiketi zorunlu';

  @override
  String get adminDevToolsOwnerCanDeleteReviews => 'İşletme yorum silebilir';

  @override
  String get adminDevToolsLowQualityGrowthBypass =>
      'Düşük kalite büyüme bypass';

  @override
  String get adminDevToolsMinSponsorTrustLabel => 'Min sponsor güveni (0-1)';

  @override
  String get adminDevToolsMinSponsorRatingLabel => 'Min sponsor puanı (0-5)';

  @override
  String get adminDevToolsEnterValidThresholds => 'Geçerli eşik değerleri gir.';

  @override
  String get adminDevToolsSaveThresholdsAction => 'Eşikleri kaydet';

  @override
  String get adminDevToolsDefaultAction => 'Varsayılan';

  @override
  String get adminDevToolsFeatureFlagsTitle => 'Özellik bayrakları';

  @override
  String get adminDevToolsTestUserTitle => 'Test kullanıcı';

  @override
  String adminDevToolsActiveUser(String userId) {
    return 'Aktif kullanıcı: $userId';
  }

  @override
  String get adminDevToolsTestUserUidLabel => 'Test kullanıcı UID';

  @override
  String get adminDevToolsClearAction => 'Temizle';

  @override
  String get adminDevToolsTestCityTitle => 'Test şehir';

  @override
  String get adminDevToolsTestCityDescription =>
      'Konum geçersiz bırakıldığında otomatik konum akışı devre dışı kalır.';

  @override
  String adminDevToolsActiveLocation(String city, String district) {
    return 'Aktif: $city / $district';
  }

  @override
  String get adminGroupRequestsRequestsTitle => 'Talepler';

  @override
  String get adminGroupRequestsOffersTitle => 'Teklifler';

  @override
  String get adminGroupRequestsNoRecords => 'Kayıt yok';

  @override
  String adminGroupRequestsRequestSummary(String city, int partySize) {
    return '$city • $partySize kişi';
  }

  @override
  String get adminGrowthTitle => 'Büyüme';

  @override
  String adminGrowthLastDays(int days) {
    return 'Son $days gün';
  }

  @override
  String get adminGrowthBusinessIdOptional => 'İşletme ID (opsiyonel)';

  @override
  String get adminGrowthNoData => 'Veri bulunamadı.';

  @override
  String get adminGrowthTodayBusinessTraffic => 'Bugün işletme trafiği';

  @override
  String get adminGrowthMenuLinkOpened => 'Menü link açıldı';

  @override
  String get adminGrowthQrScanned => 'QR okutuldu';

  @override
  String get adminGrowthMenuShared => 'Menü paylaşıldı';

  @override
  String get adminGrowthAppInstall => 'Uygulama kurulum';

  @override
  String get adminGrowthDailyTrafficTotal => 'Günlük trafik (toplam)';

  @override
  String get adminGrowthDayColumn => 'Gün';

  @override
  String get adminIncidentCenterTitle => 'Kriz müdahale merkezi';

  @override
  String get adminIncidentCenterSubtitle =>
      'Sahte işletme, yanlış fiyat ve medya krizleri için hızlı panel.';

  @override
  String get adminIncidentCenterNoLogs => 'Henüz kayıtlı kriz logu yok.';

  @override
  String get adminIncidentCenterTransparentLogTitle => 'Şeffaf log';

  @override
  String adminIncidentCenterHowFixed(String action) {
    return 'Nasıl düzelttik: $action';
  }

  @override
  String get adminIncidentCenterFillAllFields => 'Tüm alanları doldur.';

  @override
  String get adminIncidentCenterQuickPanelTitle => 'Hızlı müdahale paneli';

  @override
  String get adminIncidentCenterReportsQueueAction => 'Rapor kuyruğu';

  @override
  String get adminIncidentCenterReviewBusinessAction => 'İşletme incele';

  @override
  String get adminIncidentCenterAuditLogAction => 'Denetim log';

  @override
  String get adminIncidentCenterHowWeFixedAction => 'Nasıl düzelttik ekranı';

  @override
  String get adminIncidentCenterReadyResponsesTitle => 'Hazır cevaplar';

  @override
  String get adminIncidentCenterReadyResponseWrongPrice =>
      'Yanlış fiyat: Hata kaydı açıldı, ilgili menü geçici olarak geri plana alındı, doğrulama sonrası tekrar aktif.';

  @override
  String get adminIncidentCenterReadyResponseFakeBusiness =>
      'Sahte işletme: Kayıt incelemeye alındı, görünürlük düşürüldü, yinelenen ve sahte sinyalleri için otomatik kısıt uygulandı.';

  @override
  String get adminIncidentCenterReadyResponseMedia =>
      'Medya senaryosu: Açık zaman çizelgesi yayınlandı, yapılan düzeltmeler ve SLA adımları şeffaf şekilde paylaşıldı.';

  @override
  String get adminIncidentCenterLogEntryTitle => 'Şeffaf log girdisi';

  @override
  String get adminIncidentCenterIncidentKeyLabel => 'Olay anahtarı';

  @override
  String get adminIncidentCenterTitleLabel => 'Başlık';

  @override
  String get adminIncidentCenterWhatHappenedLabel => 'Ne oldu?';

  @override
  String get adminIncidentCenterHowDidWeFixLabel => 'Nasıl düzelttik?';

  @override
  String get adminIncidentCenterStatusOpen => 'Açık';

  @override
  String get adminIncidentCenterStatusMitigated => 'İyileştirildi';

  @override
  String get adminIncidentCenterStatusResolved => 'Çözüldü';

  @override
  String get adminIncidentCenterVisibilityPublic => 'Herkese açık';

  @override
  String get adminIncidentCenterVisibilityInternal => 'İç kullanım';

  @override
  String get adminIncidentCenterAddLogAction => 'Log ekle';

  @override
  String get adminCommonUpdated => 'Güncellendi.';

  @override
  String get adminCommonDownloading => 'İndiriliyor...';

  @override
  String get adminCommonExportCsv => 'CSV Dışa Aktar';

  @override
  String get adminCommonUnassigned => 'Boşta';

  @override
  String get adminCommonMine => 'Benim';

  @override
  String get adminCommonOtherAdmin => 'Başka admin';

  @override
  String get adminCommonNewRecordsAvailable => 'Yeni kayıtlar var';

  @override
  String get adminCommonAge => 'Yaş';

  @override
  String get adminCommonPriority => 'Öncelik';

  @override
  String get adminCommonAssigned => 'Atanan';

  @override
  String get adminCommonDetails => 'Detay';

  @override
  String get adminCommonNoRecordsFound => 'Kayıt bulunamadı.';

  @override
  String get adminCommonProcessing => 'İşleniyor...';

  @override
  String get adminCommonConfirmTitle => 'Emin misiniz?';

  @override
  String get adminCommonSelectRow => 'Satır seçin.';

  @override
  String get adminCommonClear => 'Temizle';

  @override
  String get adminLocationsTitle => 'Araçlar > Konumlar';

  @override
  String get adminLocationsTableBusinesses => 'İşletmeler';

  @override
  String get adminLocationsTableBusinessSuggestions => 'İşletme önerileri';

  @override
  String get adminLocationsTableLabel => 'Tablo';

  @override
  String get adminLocationsFieldLabel => 'Alan';

  @override
  String get adminLocationsCaseInsensitive => 'Büyük/küçük harf duyarsız';

  @override
  String get adminLocationsFromLabel => 'Eski değer';

  @override
  String get adminLocationsToLabel => 'Yeni değer';

  @override
  String adminLocationsAffectedCount(int count) {
    return 'Etkilenecek kayıt: $count';
  }

  @override
  String get adminLocationsChecking => 'Kontrol ediliyor...';

  @override
  String get adminLocationsValuesRequired =>
      'Eski değer ve yeni değer gerekli.';

  @override
  String get adminLocationsConfirmTitle => 'Değişikliği onayla';

  @override
  String adminLocationsConfirmMessage(String from, String to) {
    return '\"$from\" değeri \"$to\" olarak güncellenecek. Onaylıyor musunuz?';
  }

  @override
  String get adminLocationsApplying => 'Uygulanıyor...';

  @override
  String get adminObservabilityTitle => 'Observability';

  @override
  String get adminObservabilitySubtitle =>
      'Request trace, performans hedefleri ve yerel tercih görünürlüğü.';

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
  String get adminObservabilityGenerateRequestId => 'Yeni request_id üret';

  @override
  String get adminObservabilityPerfTitle =>
      'Performans SLO ve alarm simülasyonu';

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
  String get adminObservabilityCrashFreeInput => 'Crash-free oranı (0-1)';

  @override
  String get adminObservabilityHomeTtiInput => 'Home TTI p95 (ms)';

  @override
  String get adminObservabilityEdgeCurrentInput => 'Edge 429 mevcut pencere';

  @override
  String get adminObservabilityEdgeBaselineInput => 'Edge 429 baz pencere';

  @override
  String adminObservabilityConstantsSummary(
    int cold,
    int warm,
    int homeTti,
    int searchHit,
    int searchMiss,
  ) {
    return 'Sabitler: startup(cold=$cold, warm=$warm) home_tti=$homeTti, search_hit=$searchHit, search_miss=$searchMiss';
  }

  @override
  String adminObservabilityPrefsReadError(String error) {
    return 'Prefs okunamadı: $error';
  }

  @override
  String get adminObservabilityPrefsEmpty => 'Prefs verisi yok.';

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
  String get adminPriceSuggestionsTitle => 'Fiyat önerileri';

  @override
  String get adminPriceSuggestionsItemLabel => 'Öğe';

  @override
  String get adminPriceSuggestionsCurrentPrice => 'Mevcut';

  @override
  String get adminPriceSuggestionsSuggestedPrice => 'Önerilen';

  @override
  String adminPriceSuggestionsSlaExceeded(String age) {
    return 'SLA aşıldı: $age';
  }

  @override
  String get adminPriceSuggestionsDetailTitle => 'Fiyat önerisi detayı';

  @override
  String adminPriceSuggestionsLocationValue(String city, String district) {
    return 'Konum: $city / $district';
  }

  @override
  String get adminPriceSuggestionsCurrencyLabel => 'Para birimi';

  @override
  String get adminPriceSuggestionsCreatedBy => 'Oluşturan';

  @override
  String get adminPriceSuggestionsMetaTitle => 'Meta';

  @override
  String get adminPriceSuggestionsRejectNoteLabel =>
      'Reddetme notu (en az 3 karakter)';

  @override
  String get adminPriceSuggestionsApproveConfirm => 'Öneri onaylansın mı?';

  @override
  String get adminPriceSuggestionsRejectConfirm => 'Öneri reddedilsin mi?';

  @override
  String get adminPriceSuggestionsGoToBusiness => 'İşletme sayfasına git';

  @override
  String get adminPriceSuggestionsGoToItem => 'Öğe sayfasına git';

  @override
  String get adminReceiptSubmissionsTitle => 'Fiş doğrulamaları';

  @override
  String adminReceiptSubmissionsMatchSummary(int count, String date) {
    return 'Eşleşme: $count • $date';
  }

  @override
  String get adminReceiptSubmissionsSubtitle =>
      'Receipt/OCR akışlarını tek listede değil, saha triage workbench\'i olarak yönet.';

  @override
  String get adminReceiptSubmissionsSearchHint =>
      'İşletme, şehir, ilçe veya zincir ara';

  @override
  String get adminReceiptSubmissionsStatusAll => 'Tümü';

  @override
  String get adminReceiptSubmissionsStatusPending => 'Bekliyor';

  @override
  String get adminReceiptSubmissionsStatusReviewed => 'İncelendi';

  @override
  String get adminReceiptSubmissionsStatusNeedsFollowup => 'Takip gerekli';

  @override
  String get adminReceiptSubmissionsOnlyUnmatched => 'Sadece eşleşmesiz';

  @override
  String get adminReceiptSubmissionsSummaryTotal => 'Toplam kayıt';

  @override
  String get adminReceiptSubmissionsSummaryPending => 'Bekleyen';

  @override
  String get adminReceiptSubmissionsSummaryNeedsFollowup => 'Takip gereken';

  @override
  String get adminReceiptSubmissionsSummaryZeroMatch => 'Sıfır eşleşme';

  @override
  String get adminReceiptSubmissionsSummaryRecent24h => 'Son 24 saat';

  @override
  String get adminReceiptSubmissionsSummaryBusinesses => 'İşletme sayısı';

  @override
  String get adminReceiptSubmissionsBatchTitle => 'Toplu inceleme fırsatları';

  @override
  String get adminReceiptSubmissionsBatchDescription =>
      'Aynı işletme veya zincirde biriken fişler operatöre toplu menü güncelleme adayını gösterir.';

  @override
  String get adminReceiptSubmissionsBatchEmpty =>
      'Şu an öne çıkan toplu inceleme kümesi yok.';

  @override
  String adminReceiptSubmissionsBatchValue(
    int pending,
    int zeroMatch,
    String date,
  ) {
    return '$pending bekleyen • $zeroMatch sıfır eşleşme • son $date';
  }

  @override
  String get adminReceiptSubmissionsEmptyTitle => 'Fiş kuyruğu boş';

  @override
  String get adminReceiptSubmissionsEmptyDescription =>
      'Bu filtrelerle işlem bekleyen receipt kaydı bulunamadı.';

  @override
  String get adminReceiptSubmissionsDetailEmptyTitle => 'Kayıt seçin';

  @override
  String get adminReceiptSubmissionsDetailEmptyDescription =>
      'Soldaki listeden bir fiş seçildiğinde OCR eşleşmeleri ve review alanı burada görünür.';

  @override
  String get adminReceiptSubmissionsReviewAction => 'Review aç';

  @override
  String get adminReceiptSubmissionsOpenBusinessAction => 'Public işletmeyi aç';

  @override
  String get adminReceiptSubmissionsOpenBusinessAdminAction =>
      'Admin işletme kaydını aç';

  @override
  String get adminReceiptSubmissionsDetailMatches => 'OCR eşleşmesi';

  @override
  String get adminReceiptSubmissionsDetailSubmittedAt => 'Gönderim';

  @override
  String get adminReceiptSubmissionsDetailUser => 'Gönderen';

  @override
  String get adminReceiptSubmissionsMatchTableTitle => 'OCR eşleşme tablosu';

  @override
  String get adminReceiptSubmissionsMatchTableDescription =>
      'Tespit edilen fiyat ile sistemdeki mevcut fiyat farkı birlikte görülür.';

  @override
  String get adminReceiptSubmissionsNoMatches =>
      'Bu kayıt için menü item eşleşmesi bulunamadı. Takip veya saha incelemesi gerekebilir.';

  @override
  String get adminReceiptSubmissionsMatchItemColumn => 'Ürün';

  @override
  String get adminReceiptSubmissionsMatchDetectedColumn => 'Tespit edilen';

  @override
  String get adminReceiptSubmissionsMatchCurrentColumn => 'Sistemdeki fiyat';

  @override
  String get adminReceiptSubmissionsMatchDeltaColumn => 'Fark';

  @override
  String get adminReceiptSubmissionsReviewSheetTitle => 'Receipt review';

  @override
  String get adminReceiptSubmissionsReviewStatusLabel => 'Review durumu';

  @override
  String get adminReceiptSubmissionsReviewNoteLabel => 'Operatör notu';

  @override
  String get adminReceiptSubmissionsSaveReview => 'Review kaydet';

  @override
  String get adminReceiptSubmissionsSaved => 'Receipt review kaydedildi.';

  @override
  String get adminReportsOtherReason => 'Diğer';

  @override
  String get adminReportsTitle => 'Raporlar';

  @override
  String get adminReportsSearchHint => 'Ara (ID, sebep, detay)';

  @override
  String get adminReportsStatusOpen => 'Açık';

  @override
  String get adminReportsStatusInvestigating => 'İnceleniyor';

  @override
  String get adminReportsStatusClosed => 'Kapandı';

  @override
  String get adminReportsSelectSameReporter => 'Aynı hesabı seç';

  @override
  String get adminReportsAssignSelectedToMe => 'Seçili kayıtları bana ata';

  @override
  String get adminReportsCloseSpamWave => 'Spam dalgasını kapat';

  @override
  String get adminReportsReasonColumn => 'Sebep';

  @override
  String get adminReportsStatusColumn => 'Durum';

  @override
  String get adminReportsCreatedAtColumn => 'Oluşturulma';

  @override
  String get adminReportsPhotoColumn => 'Foto';

  @override
  String get adminReportsAutoModerationApplied =>
      'Otomatik moderasyon uygulandı';

  @override
  String get adminReportsMenuPhotoTooltip => 'Menü fotoğrafı';

  @override
  String get adminReportsBusinessPhotoTooltip => 'Mekan fotoğrafı';

  @override
  String adminReportsSlaExceeded(String age) {
    return 'Bu kayıt SLA aştı: $age';
  }

  @override
  String get adminReportsDetailTitle => 'Rapor detayı';

  @override
  String get adminReportsReviewLabel => 'İnceleme';

  @override
  String get adminReportsMenuPhotoLabel => 'Menü fotoğrafı';

  @override
  String get adminReportsBusinessPhotoLabel => 'Mekan fotoğrafı';

  @override
  String adminReportsTargetValue(String targetType, String targetId) {
    return 'Hedef: $targetType / $targetId';
  }

  @override
  String get adminReportsOpenPhoto => 'Fotoğrafı aç';

  @override
  String get adminReportsReasonLabel => 'Sebep';

  @override
  String get adminReportsAdminNoteOptional => 'Admin notu (opsiyonel)';

  @override
  String get adminReportsAutomaticRulesTitle => 'Otomatik kurallar';

  @override
  String get adminReportsAutomaticRuleApplied => 'Otomatik kural uygulandı.';

  @override
  String get adminReportsAutomaticRuleNotFound =>
      'Uygun otomatik kural bulunamadı.';

  @override
  String get adminReportsApplyingRules => 'Uygulanıyor...';

  @override
  String get adminReportsApplyRules => 'Kuralları uygula';

  @override
  String get adminReportsClaimed => 'Üzerine alındı.';

  @override
  String get adminReportsAssignToMe => 'Bana ata';

  @override
  String get adminReportsAssignmentRemoved => 'Atama kaldırıldı.';

  @override
  String get adminReportsUnassign => 'Atamayı kaldır';

  @override
  String get adminReportsMissingReporterInfo =>
      'Bu kayıtta reporter bilgisi yok.';

  @override
  String get adminReportsBulkSpamNote =>
      'Toplu: spam dalgası nedeniyle kapatıldı';

  @override
  String get adminReportsSelectedClosed => 'Seçili raporlar kapatıldı.';

  @override
  String adminReportsAssignedCount(int count) {
    return '$count rapor sana atandı.';
  }

  @override
  String adminReportsModerationScanComplete(int photoGroups, int menuGroups) {
    return 'Tarama tamamlandı. Benzer foto grup: $photoGroups, menü kopya grup: $menuGroups';
  }

  @override
  String adminReportsReasonDistribution(int total) {
    return 'Sebep dağılımı ($total)';
  }

  @override
  String adminReportsModerationSummary(
    int duplicatePhotoGroups,
    int copiedMenuGroups,
  ) {
    return 'Moderasyon: benzer foto grup $duplicatePhotoGroups, kopya menü grup $copiedMenuGroups';
  }

  @override
  String get adminReportsScanning => 'Taranıyor...';

  @override
  String get adminReportsScan => 'Tara';

  @override
  String adminReportsSelectedCount(int count) {
    return 'Seçili: $count';
  }

  @override
  String adminReportsHoursValue(String hours) {
    return '$hours saat';
  }

  @override
  String get adminReportsDecisionTemplateViolationConfirmed =>
      'İhlal teyit edildi, gerekli işlem uygulandı.';

  @override
  String get adminReportsDecisionTemplateInsufficientEvidence =>
      'Kanıt yetersiz, rapor kapatıldı.';

  @override
  String get adminReportsDecisionTemplateNeedsMoreInfo =>
      'Ek bilgi gerekiyor, kayıt inceleniyor.';

  @override
  String get adminReportsPhotoNotFound => 'Fotoğraf bulunamadı.';

  @override
  String adminReportsVisibilityLoading(String label) {
    return '$label · görünürlük yükleniyor...';
  }

  @override
  String adminReportsVisibilityUnknown(String label) {
    return '$label · görünürlük bilinmiyor';
  }

  @override
  String adminReportsVisibilityHidden(String label) {
    return '$label · gölge (gizli)';
  }

  @override
  String adminReportsVisibilityNormal(String label) {
    return '$label · normal (açık)';
  }

  @override
  String get adminCommonSaved => 'Kaydedildi.';

  @override
  String get adminShellAdminTitle => 'Admin';

  @override
  String get adminShellWebOnlyMessage =>
      'Bu ekran sadece web üzerinde kullanılabilir.';

  @override
  String get adminShellAccessCheckFailed => 'Admin erişimi doğrulanamadı.';

  @override
  String get adminShellAccessDenied => 'Bu sayfaya erişim iznin yok.';

  @override
  String adminShellProjectInfo(String projectRef, String userId) {
    return 'Proje: $projectRef • UID: $userId';
  }

  @override
  String get adminShellDashboardLabel => 'Genel bakış';

  @override
  String get adminShellDashboardDescription =>
      'Admin panel genel görünümü ve hızlı aksiyonlar.';

  @override
  String get adminShellQueueLabel => 'Birleşik kuyruk';

  @override
  String get adminShellQueueDescription =>
      'Rapor, claim, fiyat ve medya moderasyonunu tek kuyrukta yönet.';

  @override
  String get adminShellReportsLabel => 'Raporlar';

  @override
  String get adminShellReportsDescription =>
      'Kullanıcı bildirimlerini incele, durum ve atama yönet.';

  @override
  String get adminShellAppealsLabel => 'İtirazlar';

  @override
  String get adminShellAppealsDescription =>
      'Moderasyon kararlarına gelen itirazları değerlendir.';

  @override
  String get adminShellGrowthLabel => 'Büyüme';

  @override
  String get adminShellGrowthDescription =>
      'Menü linki ve QR trafiğini günlük bazda takip et.';

  @override
  String get adminShellClaimsLabel => 'Sahiplik talepleri';

  @override
  String get adminShellClaimsDescription =>
      'İşletme sahipliği taleplerini onayla ya da reddet.';

  @override
  String get adminShellSuspendedClaimsLabel => 'Askıdaki talepler';

  @override
  String get adminShellSuspendedClaimsDescription =>
      'Askıdaki yemek taleplerini doğrula ve sonuçlandır.';

  @override
  String get adminShellPriceSuggestionsLabel => 'Fiyat onayları';

  @override
  String get adminShellPriceSuggestionsDescription =>
      'Fiyat önerilerini değerlendir, onayla veya reddet.';

  @override
  String get adminShellReceiptSubmissionsLabel => 'Fiş doğrulama';

  @override
  String get adminShellReceiptSubmissionsDescription =>
      'Fiş doğrulama gönderimlerini listele ve kontrol et.';

  @override
  String get adminShellSuggestionsLabel => 'İşletme önerileri';

  @override
  String get adminShellSuggestionsDescription =>
      'Yeni işletme önerilerini kontrol edip işleme al.';

  @override
  String get adminShellBusinessesLabel => 'İşletmeler';

  @override
  String get adminShellBusinessesDescription =>
      'İşletme kayıtlarını düzenle, doğrula ve güncelle.';

  @override
  String get adminShellBusinessSubmissionsLabel => 'İşletme başvuruları';

  @override
  String get adminShellBusinessSubmissionsDescription =>
      'Yeni işletme başvurularını onayla veya reddet.';

  @override
  String get adminShellSponsorshipsLabel => 'Sponsorlu gösterimler';

  @override
  String get adminShellSponsorshipsDescription =>
      'Sponsorlu işletme gösterimlerini yönet ve durum değiştir.';

  @override
  String get adminShellSponsorshipPackagesLabel => 'Paketler';

  @override
  String get adminShellSponsorshipPackagesDescription =>
      'Sponsor paketlerini oluştur ve fiyatlandırmayı yönet.';

  @override
  String get adminShellSponsorshipLeadsLabel => 'Lead\'ler';

  @override
  String get adminShellSponsorshipLeadsDescription =>
      'Sponsor satış taleplerini takip et ve kapat.';

  @override
  String get adminShellVerifiedLabel => 'Doğrulama';

  @override
  String get adminShellVerifiedDescription =>
      'İşletme doğrulama ve premium statüsünü yönet.';

  @override
  String get adminShellLocationsLabel => 'Araçlar > Konumlar';

  @override
  String get adminShellLocationsDescription =>
      'Konum verilerini toplu düzelt ve güncelle.';

  @override
  String get adminShellAuditLabel => 'Denetim kayıtları';

  @override
  String get adminShellAuditDescription =>
      'Sistem içi işlem kayıtlarını incele.';

  @override
  String get adminShellTableFeedbackLabel => 'Masa geri bildirim';

  @override
  String get adminShellTableFeedbackDescription =>
      'Masa QR geri bildirimlerini görüntüle ve filtrele.';

  @override
  String get adminShellGroupRequestsLabel => 'Grup talepleri';

  @override
  String get adminShellGroupRequestsDescription =>
      'Grup yemeği taleplerini ve teklifleri gözlemle.';

  @override
  String get adminShellDevToolsLabel => 'Dev tools';

  @override
  String get adminShellDevToolsDescription =>
      'Feature flag ve test override ayarları.';

  @override
  String get adminShellObservabilityLabel => 'Observability';

  @override
  String get adminShellObservabilityDescription =>
      'Request trace, perf SLO ve prefs görünümü.';

  @override
  String get adminShellB2bExportsLabel => 'B2B veri ihracı';

  @override
  String get adminShellB2bExportsDescription =>
      'Anonim trend, bölgesel fiyat endeksi ve menü enflasyonu çıktıları.';

  @override
  String get adminShellIncidentCenterLabel => 'Kriz müdahale';

  @override
  String get adminShellIncidentCenterDescription =>
      'Şeffaf log, hazır cevaplar ve hızlı müdahale aksiyonları.';

  @override
  String get adminShellTempUploadsLabel => 'Geçici yükleme inceleme';

  @override
  String get adminShellTempUploadsDescription =>
      'Bekleyen geçici menü yüklemelerini incele.';

  @override
  String get adminSponsorshipLeadsTitle => 'Sponsor talepleri';

  @override
  String get adminSponsorshipLeadsContactColumn => 'İletişim';

  @override
  String get adminSponsorshipLeadsOwnerColumn => 'İşletme sahibi';

  @override
  String get adminSponsorshipLeadsCreatedAtColumn => 'Oluşturma';

  @override
  String get adminSponsorshipLeadsDetailTitle => 'Lead detayı';

  @override
  String get adminSponsorshipLeadsPhoneLabel => 'Telefon';

  @override
  String get adminSponsorshipLeadsMessageLabel => 'Mesaj';

  @override
  String get adminSponsorshipLeadsTargetingLabel => 'Hedefleme';

  @override
  String get adminSponsorshipLeadsCreateSponsorship => 'Sponsorluk oluştur';

  @override
  String get adminSponsorshipLeadStatusNew => 'Yeni';

  @override
  String get adminSponsorshipLeadStatusContacted => 'İletişime geçildi';

  @override
  String get adminSponsorshipLeadStatusClosed => 'Kapandı';

  @override
  String get adminSponsorshipPackagesTitle => 'Sponsor paketleri';

  @override
  String get adminSponsorshipPackagesNewPackage => 'Yeni paket';

  @override
  String get adminSponsorshipPackagesEditPackage => 'Paket düzenle';

  @override
  String get adminSponsorshipPackagesNameColumn => 'İsim';

  @override
  String get adminSponsorshipPackagesDurationColumn => 'Süre';

  @override
  String get adminSponsorshipPackagesPriceColumn => 'Fiyat';

  @override
  String get adminSponsorshipPackagesActiveColumn => 'Aktif';

  @override
  String get adminSponsorshipPackagesCreatedAtColumn => 'Oluşturma';

  @override
  String adminSponsorshipPackagesDurationValue(int days) {
    return '$days gün';
  }

  @override
  String get adminSponsorshipPackagesDurationInput => 'Süre (gün)';

  @override
  String get adminSponsorshipPackagesPriceInput => 'Fiyat gösterimi';

  @override
  String get adminSponsorshipPackagesPriceAmountInput => 'Fiyat (kuruş)';

  @override
  String get adminSponsorshipPackagesCurrencyInput => 'Para birimi';

  @override
  String get adminSponsorshipPackagesInventoryInput => 'Envanter limiti';

  @override
  String get adminSponsorshipPackagesSurfaceDiscovery => 'Keşfet';

  @override
  String get adminSponsorshipPackagesSurfaceBusinessPage => 'İşletme sayfası';

  @override
  String get adminSponsorshipPackagesSurfaceStories => 'Hikayeler';

  @override
  String get adminSponsorshipPackagesSurfaceVerified => 'Doğrulandı';

  @override
  String get adminSponsorshipPackagesSurfacePremium => 'Premium';

  @override
  String get adminSponsorshipPackagesInventoryColumn => 'Envanter';

  @override
  String get adminSponsorshipsTitle => 'Sponsorluklar';

  @override
  String get adminSponsorshipsNewAction => 'Yeni sponsorluk';

  @override
  String get adminSponsorshipsOverviewTitle => 'Portföy özeti';

  @override
  String get adminSponsorshipsOverviewDescription =>
      'Aktif sponsorluk, açık lead, erişim ve tahmini gelir tek ekranda izlenir.';

  @override
  String get adminSponsorshipsInventoryTitle => 'Yüzey envanteri';

  @override
  String get adminSponsorshipsInventoryDescription =>
      'Her gösterim yüzeyinde canlı doluluk, boş slot ve son 30 gün performansı görünür.';

  @override
  String get adminSponsorshipsSurfaceColumn => 'Yüzey';

  @override
  String get adminSponsorshipsStatusColumn => 'Durum';

  @override
  String get adminSponsorshipsDateRangeColumn => 'Tarih';

  @override
  String get adminSponsorshipsPackageColumn => 'Paket';

  @override
  String get adminSponsorshipsQuotaColumn => 'Kota';

  @override
  String get adminSponsorshipsCreatedAtColumn => 'Oluşturma';

  @override
  String get adminSponsorshipsMetricActive => 'Aktif sponsorluk';

  @override
  String get adminSponsorshipsMetricPending => 'Bekleyen sponsorluk';

  @override
  String get adminSponsorshipsMetricOpenLeads => 'Açık lead';

  @override
  String get adminSponsorshipsMetricImpressions30d => '30 gün gösterim';

  @override
  String get adminSponsorshipsMetricUniqueUsers30d => '30 gün tekil kullanıcı';

  @override
  String get adminSponsorshipsMetricEstimatedRevenue => 'Tahmini aktif gelir';

  @override
  String get adminSponsorshipsInventoryPackagesColumn => 'Paketler';

  @override
  String get adminSponsorshipsInventoryUnitsColumn => 'Canlı / boş';

  @override
  String get adminSponsorshipsInventoryDemandColumn => 'Talep';

  @override
  String get adminSponsorshipsInventoryPerformanceColumn => 'Performans';

  @override
  String adminSponsorshipsInventoryPackagesValue(
    Object active,
    Object total,
    Object inventory,
  ) {
    return '$active aktif / $total toplam • limit $inventory';
  }

  @override
  String adminSponsorshipsInventoryUnitsValue(Object live, Object open) {
    return '$live canlı • $open boş';
  }

  @override
  String adminSponsorshipsInventoryDemandValue(Object pending, Object leads) {
    return '$pending bekleyen • $leads lead';
  }

  @override
  String adminSponsorshipsInventoryPerformanceValue(
    Object impressions,
    Object users,
  ) {
    return '$impressions gösterim • $users kullanıcı';
  }

  @override
  String get adminSponsorshipsActivateAction => 'Aktif et';

  @override
  String get adminSponsorshipsPauseAction => 'Duraklat';

  @override
  String get adminSponsorshipsEndAction => 'Bitir';

  @override
  String get adminSponsorshipsStatusActive => 'Aktif';

  @override
  String get adminSponsorshipsStatusPaused => 'Duraklatıldı';

  @override
  String get adminSponsorshipsStatusEnded => 'Bitti';

  @override
  String adminSponsorshipsQuotaValue(String daily, String total) {
    return 'D:$daily / T:$total';
  }

  @override
  String get adminSponsorshipsInfinity => 'Sınırsız';

  @override
  String adminSponsorshipsDateRangeValue(String start, String end) {
    return '$start -> $end';
  }

  @override
  String get adminSuggestionsTitle => 'Öneriler';

  @override
  String get adminSuggestionsSearchHint => 'Ara (isim, şehir, ilçe)';

  @override
  String get adminSuggestionsNameColumn => 'İsim';

  @override
  String get adminSuggestionsStatusColumn => 'Durum';

  @override
  String get adminSuggestionsCreatedAtColumn => 'Oluşturma';

  @override
  String adminSuggestionsSlaExceeded(String age) {
    return 'Bu kayıt SLA aştı: $age';
  }

  @override
  String get adminSuggestionsDetailTitle => 'Öneri detayı';

  @override
  String get adminSuggestionsCategoryLabel => 'Kategori';

  @override
  String get adminSuggestionsLocationLabel => 'Konum';

  @override
  String get adminSuggestionsAdminNoteOptional => 'Admin notu (opsiyonel)';

  @override
  String get adminSuggestionsAssignedToMe => 'Öneri bana atandı.';

  @override
  String get adminSuggestionsPossibleDuplicatesTitle => 'Muhtemel kopyalar';

  @override
  String get adminSuggestionsNoSimilarBusiness => 'Benzer işletme bulunamadı.';

  @override
  String get adminSuggestionsCreatedNewBusiness => 'Yeni işletme oluşturuldu.';

  @override
  String get adminSuggestionsCreateNewBusiness => 'Yeni işletme oluştur';

  @override
  String get adminSuggestionsLinkExistingConfirmTitle =>
      'Mevcut işletmeyle eşleştirilsin mi?';

  @override
  String get adminSuggestionsLinkedToExisting =>
      'Mevcut işletmeyle eşleştirildi.';

  @override
  String get adminSuggestionsRejectSelected => 'Seçilileri reddet';

  @override
  String get adminSuggestionsLinkToThisBusiness => 'Bu işletmeyle eşleştir';

  @override
  String get adminSuggestionsNoLocation => 'Konum yok';

  @override
  String adminSuggestionsDaysValue(String days) {
    return '$days gün';
  }

  @override
  String get adminSuspendedClaimsTitle => 'Askıdaki talepler';

  @override
  String get adminSuspendedClaimsAmountColumn => 'Miktar';

  @override
  String get adminSuspendedClaimsClaimantColumn => 'Davacı';

  @override
  String adminSuspendedClaimsSlaExceeded(String age) {
    return 'SLA aşıldı: $age';
  }

  @override
  String get adminSuspendedClaimsDetailTitle => 'Talep detayı';

  @override
  String get adminSuspendedClaimsMealLabel => 'Meal';

  @override
  String get adminSuspendedClaimsRejectNoteOptional =>
      'Reddetme notu (opsiyonel)';

  @override
  String get adminSuspendedClaimsApproveConfirm => 'Talep onaylansın mı?';

  @override
  String get adminSuspendedClaimsRejectConfirm => 'Talep reddedilsin mi?';

  @override
  String get adminTableFeedbackTitle => 'Masa geri bildirimleri';

  @override
  String adminTableFeedbackTableAndRating(String tableNo, String rating) {
    return 'Masa $tableNo • Puan $rating';
  }

  @override
  String get adminTempUploadsTitle => 'Geçici yükleme inceleme';

  @override
  String get adminTempUploadsPromoted => 'Menüye aktarıldı.';

  @override
  String get adminTempUploadsRejectReasonHint => 'Red nedeni (opsiyonel)';

  @override
  String get adminTempUploadsRejected => 'Kayıt reddedildi.';

  @override
  String get adminTempUploadsEmptyTitle => 'Bekleyen geçici yükleme yok';

  @override
  String get adminTempUploadsEmptyDescription =>
      'Yeni gönderimler geldiğinde burada listelenir.';

  @override
  String adminTempUploadsBusinessId(String businessId) {
    return 'business_id: $businessId';
  }

  @override
  String get adminTempUploadsPromoteAction => 'Menüye aktar';

  @override
  String get adminVerifiedTitle => 'Doğrulama / Premium';

  @override
  String get adminVerifiedSearchHint => 'İşletme ara (isim/adres)';

  @override
  String get adminVerifiedSearching => 'Aranıyor...';

  @override
  String get adminVerifiedSearchAction => 'Ara';

  @override
  String get adminVerifiedVerificationColumn => 'Doğrulama';

  @override
  String get adminVerifiedYes => 'Evet';

  @override
  String get adminVerifiedNo => 'Hayır';

  @override
  String get adminVerifiedSettingsTitle => 'Doğrulama ayarları';

  @override
  String get adminVerifiedTierVerified => 'Doğrulandı';

  @override
  String get adminVerifiedTierPremium => 'Premium';

  @override
  String get adminVerifiedTierLabel => 'Tier';

  @override
  String get adminVerifiedEndsAtLabel => 'Bitiş (YYYY-MM-DD)';

  @override
  String get loginSubmitting => 'Giriş yapılıyor...';

  @override
  String get loginRegisterSubmitting => 'Kayıt oluşturuluyor...';

  @override
  String get loginRegisterSuccess =>
      'Kayıt oluşturuldu. E-posta/telefon doğrulamasını tamamla.';

  @override
  String get loginActionFailedTitle => 'İşlem tamamlanamadı';

  @override
  String loginActionFailedDescription(String error) {
    return '$error\nBağlantını kontrol edip tekrar dene.';
  }

  @override
  String get legalTitle => 'Yasal ve Güven';

  @override
  String get legalPrivacySectionTitle => 'KVKK / GDPR';

  @override
  String legalPrivacyIntro(String appName) {
    return '$appName kişisel verileri yalnızca hizmeti sunmak için işler. Açık rıza gerektiren işlemler için onay alınır, talep halinde veriler silinir veya taşınabilir şekilde paylaşılır.';
  }

  @override
  String get legalPrivacyCategoriesAndRights =>
      'Veri kategorileri: profil, konum, cihaz bilgisi, kullanım analitiği. Haklar: erişim, düzeltme, silme, itiraz, taşınabilirlik.';

  @override
  String get legalPrivacyPolicyAction => 'Gizlilik Politikası';

  @override
  String get legalKvkkAction => 'KVKK Metni';

  @override
  String get legalGdprAction => 'GDPR Metni';

  @override
  String get legalPrivacyApplicationHint =>
      'Başvuru: e-posta ile talep oluştur.';

  @override
  String get legalCopyrightSectionTitle => 'Foto Telif Bildirimi';

  @override
  String get legalCopyrightIntro =>
      'Menü ve mekan fotoğrafları telif hakkına tabi olabilir. İhlal gördüğünde Bildir > Telif ile iletebilirsin.';

  @override
  String get legalCopyrightBody =>
      'Telif bildirimi için içerik bağlantısı, kanıt ve kısa açıklama yeterlidir. Doğrulanan ihlaller içerikten kaldırılır.';

  @override
  String get legalCopyrightPolicyAction => 'Telif Politikası';

  @override
  String get legalOwnershipAppealSectionTitle => 'İşletme Sahipliği İtirazı';

  @override
  String get legalOwnershipAppealIntro =>
      'Sahiplik talebi reddedildiyse itiraz edebilirsin. Belgelerin tekrar incelenir.';

  @override
  String get legalOwnershipAppealRequirementsTitle =>
      'İtiraz için gerekli bilgiler:';

  @override
  String get legalOwnershipAppealRequirementsBody =>
      '• İşyeri ünvanı ve vergi/ruhsat bilgisi\n• Yetkilendirme belgesi\n• İletişim telefonu';

  @override
  String get legalOwnershipAppealMailAction => 'İtiraz e-postası gönder';

  @override
  String legalOwnershipAppealMailSubject(String appName) {
    return '$appName - Sahiplik İtirazı';
  }

  @override
  String get legalProductPrinciplesSectionTitle => 'Ürün İlkeleri';

  @override
  String get legalProductPrinciplesDontsTitle => 'Yapılmaması gerekenler:';

  @override
  String get legalProductPrinciplesDontsBody =>
      '• Herkese her şeyi açmak\n• Sponsorlu içeriği gizlemek\n• Owner hesaba yorum silme yetkisi vermek\n• Büyüme için kalite eşiğini gevşetmek';

  @override
  String legalProductPrinciplesPolicy(
    String requireSponsoredLabel,
    String minSponsoredTrust,
    String ownerCanDeleteReviews,
  ) {
    return 'Policy: sponsor etiketi zorunlu=$requireSponsoredLabel, min sponsor trust=$minSponsoredTrust, owner yorum silme=$ownerCanDeleteReviews.';
  }

  @override
  String get legalFooterNote =>
      'Güncel politika metinleri ve detaylar web sitesinde yayımlanır.';

  @override
  String get ownerBusinessSubmissionsEmptyTitle => 'Henüz başvuru yok';

  @override
  String get ownerBusinessSubmissionsEmptyDescription =>
      'Yeni işletme başvuruları burada listelenecek.';

  @override
  String get ownerPublicMenuLinkAction => 'Public menü linki';

  @override
  String get ownerCatalogLabel => 'Katalog';

  @override
  String ownerSortOrder(int order) {
    return 'Sıra: $order';
  }

  @override
  String get ownerUploadRequiresOwnership =>
      'Bu işlem için işletme sahibi olmalısın.';

  @override
  String get ownerUploadRateLimited =>
      'Çok sık denedin, lütfen biraz sonra tekrar dene.';

  @override
  String get ownerUploadFailed => 'Yükleme başarısız.';

  @override
  String get ownerDashboardNoPermission => 'Bu işletme için yetkin yok.';

  @override
  String get ownerDashboardOverview => 'Operasyon özeti';

  @override
  String get ownerDashboardOperationsDescription =>
      'Menü kalitesi, güven sinyalleri ve günlük owner işleri bu ekranda toplanır.';

  @override
  String get ownerDashboardOperationsActionsTitle => 'Operasyon aksiyonları';

  @override
  String get ownerDashboardOperationsActionsDescription =>
      'Seçili işletme için müdahale gerektiren akışlara kısa yol.';

  @override
  String get ownerDashboardSelectBusinessForActions =>
      'Önce bir işletme seç. Ardından menü, ekip ve askıda taleplere bu merkezden geç.';

  @override
  String get ownerDashboardKpiLoading => 'KPI yükleniyor...';

  @override
  String get ownerDashboardSelectBusinessForKpi =>
      'KPI için önce bir işletme seç.';

  @override
  String get ownerDashboardKpiNotFound => 'KPI bulunamadı.';

  @override
  String get ownerDashboardKpiLast30Days => 'KPI (30 gün)';

  @override
  String get ownerDashboardViews => 'Görüntülenme';

  @override
  String get ownerDashboardClicks => 'Tıklama';

  @override
  String get ownerDashboardDirections => 'Yol tarifi';

  @override
  String get ownerDashboardSearchImpressions => 'Arama gösterimi';

  @override
  String get ownerDashboardQualityScoreLoading => 'Kalite skoru yükleniyor...';

  @override
  String get ownerDashboardSelectBusinessForScore =>
      'Skoru görmek için önce bir işletme seç.';

  @override
  String get ownerDashboardScoreNotFound => 'Skor bulunamadı.';

  @override
  String ownerDashboardMenuQualityScore(int score) {
    return 'Menü kalite skoru: $score';
  }

  @override
  String get ownerDashboardScoreGood => 'Skor iyi seviyede.';

  @override
  String get ownerDashboardScoreTarget =>
      'Hedef 80+: aşağıdaki görevleri tamamla.';

  @override
  String get ownerDashboardNoExtraTasks => 'Şu an için ek görev yok.';

  @override
  String get ownerDashboardProTitle => 'Yeedoy Pro';

  @override
  String get ownerDashboardProDescription =>
      'Yeedoy Pro: kampanya ve görünürlük araçları.';

  @override
  String get ownerDashboardProFeatureSponsoredLabel =>
      'Sponsorlu etiket ve şeffaf görünüm';

  @override
  String get ownerDashboardProFeatureAdvancedAnalytics =>
      'Gelişmiş analiz ve dönüşüm metrikleri';

  @override
  String get ownerDashboardProFeatureCampaignAreas =>
      'Kampanya ve duyuru alanları';

  @override
  String get ownerDashboardProFeatureFeaturedPlacement =>
      'Öne çıkan alan ve ölçümlü yerleşim';

  @override
  String get ownerDashboardProFeatureMultiBranch =>
      'Çok şubeyi tek panelden yönetme';

  @override
  String get ownerDashboardProDisclaimer =>
      'Sponsorlu alanlar organik kalite sırasını bozmaz.';

  @override
  String get ownerDashboardSurfaceDiscovery => 'Keşfet';

  @override
  String get ownerDashboardSurfaceBusinessPage => 'İşletme sayfası';

  @override
  String get ownerDashboardSurfaceStories => 'Hikayeler';

  @override
  String get ownerDashboardSurfaceVerified => 'Doğrulandı';

  @override
  String get ownerDashboardSurfacePremium => 'Premium';

  @override
  String get ownerDashboardPreferredSurface => 'Tercih edilen alan';

  @override
  String get ownerDashboardTargetCities => 'Hedef şehirler (virgülle)';

  @override
  String get ownerDashboardTargetDistricts => 'Hedef ilçeler (virgülle)';

  @override
  String get ownerDashboardTargetCategories => 'Hedef kategoriler (virgülle)';

  @override
  String get ownerDashboardMonthlyBudgetOptional => 'Aylık bütçe (opsiyonel)';

  @override
  String get ownerDashboardMonthlyImpressionsOptional =>
      'Aylık gösterim hedefi (opsiyonel)';

  @override
  String get ownerDashboardPhoneOptional => 'Telefon (opsiyonel)';

  @override
  String get ownerDashboardNoteHint => 'Hedef bölge veya kampanya notu...';

  @override
  String get ownerDashboardSubmitting => 'Gönderiliyor...';

  @override
  String get ownerDashboardSubmitProLead => 'Pro talebi gönder';

  @override
  String get ownerDashboardSelectBusinessFirst =>
      'Önce bir işletme seçmelisin.';

  @override
  String get ownerDashboardRequestReceived => 'Talebini aldık.';

  @override
  String get ownerDashboardMoatLoading => 'Savunma özeti yükleniyor...';

  @override
  String get ownerDashboardSelectBusinessForMoat =>
      'Skorları görmek için önce bir işletme seç.';

  @override
  String get ownerDashboardMoatNotFound => 'Skor verisi bulunamadı.';

  @override
  String ownerDashboardSignals(int validators) {
    return 'Sinyaller: $validators doğrulayıcı';
  }

  @override
  String ownerDashboardLastVerification(String date) {
    return 'son doğrulama $date';
  }

  @override
  String get ownerDashboardLongTermDefense => 'Uzun vadeli savunma duvarı';

  @override
  String get ownerDashboardLongTermDefenseDescription =>
      'Bu skorlar arama sıralaması, öne çıkarma ve sponsor filtrelerinde kullanılır.';

  @override
  String get ownerDashboardBusinessTrust => 'İşletme güveni';

  @override
  String get ownerDashboardMenuFreshness => 'Menü güncelliği';

  @override
  String get ownerDashboardPriceAccuracy => 'Fiyat doğruluğu';

  @override
  String get ownerDashboardContributionTrust => 'Katkı güveni';

  @override
  String ownerDashboardEvidenceSummary(int evidencePct, int qualityPct) {
    return 'Kanıt oranı: %$evidencePct - Geçmiş katkı kalitesi: %$qualityPct';
  }

  @override
  String ownerDashboardLocalMicroData(int viewsToday) {
    return 'Yerel mikro veri: bugün menü bakma $viewsToday';
  }

  @override
  String ownerDashboardLocalMicroDataWithRank(int viewsToday, int rank) {
    return 'Yerel mikro veri: bugün menü bakma $viewsToday - ilçe sırası #$rank';
  }

  @override
  String get ownerMenuManagementTitle => 'Menü yönetimi';

  @override
  String get ownerApprovedBusinessNotFound => 'Onaylı işletme bulunamadı.';

  @override
  String get ownerMenuNotFound => 'Henüz menü yok.';

  @override
  String get ownerCreateMenuAction => 'Yeni menü oluştur';

  @override
  String get ownerCreateMenuTitle => 'Yeni menü';

  @override
  String get ownerCreateAction => 'Oluştur';

  @override
  String get ownerMenuCreated => 'Menü oluşturuldu.';

  @override
  String get ownerMenuArchived => 'Menü arşivlendi.';

  @override
  String get ownerMenuPublished => 'Menü yayına alındı.';

  @override
  String get ownerDigitalMenuStudioTitle => 'Dijital Menü & QR Studio';

  @override
  String get ownerDigitalMenuStudioSubtitle =>
      'Panelden başlat, tema, dil, bağlantı ve QR çıktısını tek yerden yönet.';

  @override
  String get ownerAmenitiesTitle => 'Özellikler';

  @override
  String get ownerAmenitiesUpdated => 'Özellikler güncellendi.';

  @override
  String get ownerProfileCompletionTitle => 'Profil tamamlama';

  @override
  String ownerProfileCompletionPercent(int pct) {
    return '%$pct tamamlandı';
  }

  @override
  String get ownerSponsoredRequestsSoon =>
      'Sponsor talepleri yakında açılacak.';

  @override
  String get ownerSponsoredVisibilityAction => 'Sponsorlu görünürlük al';

  @override
  String get ownerMenuErrorNotOwner => 'Bu işlem için yetkin yok.';

  @override
  String get ownerMenuErrorNotFound => 'Kayıt bulunamadı.';

  @override
  String get ownerMenuErrorHasItems => 'Bölümde ürünler var.';

  @override
  String get ownerMenuErrorGeneric => 'Bir hata oluştu.';

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
    return '$businessName | Güven skoru $trust/100 | Menü güncelliği $freshness/100 | Fiyat doğruluğu $accuracy/100 | $validators doğrulayıcı | Kanıt oranı %$evidencePct | Bugün menü bakma $viewsToday\n$link';
  }

  @override
  String get ownerApproveAction => 'Onayla';

  @override
  String get ownerRejectAction => 'Reddet';

  @override
  String get ownerOnboardingTitle => 'Kurulum';

  @override
  String get ownerOnboardingContinue => 'Devam';

  @override
  String get ownerOnboardingFinish => 'Bitir';

  @override
  String get ownerOnboardingStepProfile => 'Profil';

  @override
  String get ownerOnboardingStepAmenities => 'Özellikler';

  @override
  String get ownerOnboardingStepMenu => 'Menü';

  @override
  String get ownerOnboardingStepPreview => 'Önizleme';

  @override
  String get ownerOnboardingStepShare => 'Paylaş';

  @override
  String get ownerOnboardingUrlHint => 'https://...';

  @override
  String get ownerOnboardingPasteAction => 'Yapıştır';

  @override
  String get ownerOnboardingProfileIntro =>
      'Logo ve kapak ekleyin, çalışma saatlerini belirleyin.';

  @override
  String get ownerOnboardingLogoUrl => 'Logo URL';

  @override
  String get ownerOnboardingCoverUrl => 'Kapak URL';

  @override
  String get ownerOnboardingSelectOpenTime => 'Açılış saatini seç';

  @override
  String ownerOnboardingOpenTime(String time) {
    return 'Açılış: $time';
  }

  @override
  String get ownerOnboardingSelectCloseTime => 'Kapanış saatini seç';

  @override
  String ownerOnboardingCloseTime(String time) {
    return 'Kapanış: $time';
  }

  @override
  String get ownerOnboardingHoursHint => 'Saatler tüm günlere uygulanır.';

  @override
  String get ownerOnboardingBusinessLinks =>
      'İşletme linkleri (Instagram / YouTube / Facebook)';

  @override
  String get ownerOnboardingInstagramPreview => 'Instagram önizleme';

  @override
  String get ownerOnboardingYoutubePreview => 'YouTube önizleme';

  @override
  String get ownerOnboardingFacebookPreview => 'Facebook önizleme';

  @override
  String get ownerOnboardingLinksPending =>
      'Linkleri kaydetme adımı yakında eklenecek.';

  @override
  String get ownerOnboardingAmenitiesListNotFound =>
      'Özellik listesi bulunamadı.';

  @override
  String get ownerOnboardingSelectAtLeastTwoAmenities =>
      'En az 2 özellik seçmelisin.';

  @override
  String get ownerOnboardingMenuRequirement =>
      'En az 1 bölüm ve 1 ürün gerekli.';

  @override
  String ownerOnboardingMenuCount(int count) {
    return 'Menü sayısı: $count';
  }

  @override
  String ownerOnboardingSectionCount(int count) {
    return 'Bölüm sayısı: $count';
  }

  @override
  String ownerOnboardingItemCount(int count) {
    return 'Ürün sayısı: $count';
  }

  @override
  String get ownerOnboardingNoShareWithoutMenu => 'Menüsüz paylaşım olmaz.';

  @override
  String get ownerOnboardingGoToMenuManagement => 'Menü yönetimine git';

  @override
  String get ownerOnboardingPreviewRequiresMenu =>
      'Önizleme için önce menü oluştur.';

  @override
  String get ownerOnboardingPreviewNoItems => 'Ürün bulunamadı.';

  @override
  String get ownerOnboardingShareRequiresMenu =>
      'Paylaşım için önce menü oluştur.';

  @override
  String get ownerOnboardingShareLinkTitle => 'Paylaşım bağlantısı';

  @override
  String get ownerOnboardingCopyLink => 'Bağlantıyı kopyala';

  @override
  String get ownerOnboardingDownloadQr => 'QR indir';

  @override
  String ownerOnboardingPreviewMenu(String title) {
    return 'Menü: $title';
  }

  @override
  String get ownerOnboardingLogoCoverRequired => 'Logo ve kapak zorunlu.';

  @override
  String get ownerOnboardingHoursRequired => 'Saatler zorunlu.';

  @override
  String get ownerOnboardingQrNotReady => 'QR henüz hazır değil.';

  @override
  String get ownerOnboardingQrDownloadFailed => 'QR indirilemedi.';

  @override
  String ownerOnboardingWhatsappShareText(String link) {
    return 'Menümüz güncel. Buradan inceleyebilirsin: $link';
  }

  @override
  String ownerOnboardingXShareText(String link) {
    return 'Güncel menü ve doğrulanmış fiyatlar: $link';
  }

  @override
  String ownerOnboardingInstagramShareText(String link) {
    return 'Güncel menü ve doğrulanmış fiyatlar: $link';
  }

  @override
  String get ownerPriceSuggestionsTitle => 'Fiyat onayları';

  @override
  String get ownerPriceSuggestionsEmptyTitle => 'Kayıt yok';

  @override
  String get ownerPriceSuggestionsEmptyDescription =>
      'Yeni fiyat önerileri burada listelenecek.';

  @override
  String get ownerPriceSuggestionsApproveConfirm =>
      'Fiyat önerisi onaylansın mı?';

  @override
  String get ownerPriceSuggestionsApproved => 'Onaylandı.';

  @override
  String get ownerPriceSuggestionsRejectReasonLabel =>
      'Ret nedeni (en az 3 karakter)';

  @override
  String get ownerPriceSuggestionsRejected => 'Reddedildi.';

  @override
  String ownerPriceSuggestionsConfidence(int pct) {
    return 'Güven $pct%';
  }

  @override
  String ownerPriceSuggestionsConflictCount(int count) {
    return 'Çakışma: $count fiyat';
  }

  @override
  String get ownerPriceSuggestionsAnomaly => 'Anomali';

  @override
  String ownerPriceSuggestionsAnomalyFlag(String flag) {
    return 'Anomali: $flag';
  }

  @override
  String ownerPriceSuggestionsConflictVariants(int count) {
    return 'Çakışma: aynı ürün için $count farklı öneri var';
  }

  @override
  String get ownerGroupRequestsTitle => 'Talepler';

  @override
  String get ownerGroupRequestsOpenRequests => 'Açık talepler';

  @override
  String get ownerGroupRequestsEmptyTitle => 'Talep yok';

  @override
  String get ownerGroupRequestsEmptyDescription =>
      'Açık grup yemeği talebi bulunamadı.';

  @override
  String ownerGroupRequestsPartyBudget(int partySize, String budget) {
    return '$partySize kişi • $budget';
  }

  @override
  String get ownerGroupRequestsOfferAction => 'Teklif ver';

  @override
  String get ownerGroupRequestsMyOffers => 'Tekliflerim';

  @override
  String get ownerGroupRequestsOffersEmptyTitle => 'Teklif yok';

  @override
  String get ownerGroupRequestsOffersEmptyDescription =>
      'Verdiğin teklifler burada görünür.';

  @override
  String ownerGroupRequestsOfferStatus(String status) {
    return 'Durum: $status';
  }

  @override
  String get ownerGroupRequestsTotalOfferLabel => 'Toplam teklif (TL)';

  @override
  String get ownerGroupRequestsDessertIncluded => 'Tatlı dahil';

  @override
  String get ownerGroupRequestsDrinksIncluded => 'İçecek dahil';

  @override
  String get ownerGroupRequestsMenuFixed => 'Menü sabit';

  @override
  String get ownerGroupRequestsEnterValidPrice => 'Geçerli fiyat girin.';

  @override
  String get ownerGroupRequestsOfferSent => 'Teklif gönderildi.';

  @override
  String get search => 'Ara';

  @override
  String get clear => 'Temizle';

  @override
  String get forbiddenTitle => 'Erişim engellendi';

  @override
  String get forbiddenDescription =>
      'Bu alana erişim yetkin bulunmuyor. Farklı bir panel veya işletme seçerek devam et.';

  @override
  String forbiddenDescriptionWithRoute(String route) {
    return 'Bu alana erişim yetkin bulunmuyor. İstenen adres: $route';
  }

  @override
  String get forbiddenBackHomeAction => 'Ana sayfaya dön';

  @override
  String get forbiddenGoBusinessesAction => 'İşletmelerime git';

  @override
  String get ownerShellPanelTitle => 'İşletme Paneli';

  @override
  String get ownerShellOverviewLabel => 'Operasyon';

  @override
  String get ownerShellGrowthLabel => 'Büyüme';

  @override
  String get ownerShellPriceSuggestionsLabel => 'Fiyat önerileri';

  @override
  String get ownerShellSuspendedClaimsLabel => 'Askıda talepler';

  @override
  String get ownerShellRequestsLabel => 'Talepler';

  @override
  String get ownerShellAuditLabel => 'Denetim';

  @override
  String get ownerSelectedBusinessTitle => 'Seçili işletme';

  @override
  String get ownerBusinessSwitcherLabel => 'İşletme değiştir';

  @override
  String get ownerGoBusinessesAction => 'İşletmelerime git';

  @override
  String get ownerBusinessContextEmptyTitle => 'Önce bir işletme seç';

  @override
  String get ownerBusinessContextEmptyDescription =>
      'İşletme bağlamı burada görünür. Menü, fiyat ve talepleri yönetmek için işletmelerim sayfasından seçim yap.';

  @override
  String get ownerBusinessContextLoadError => 'İşletme bağlamı yüklenemedi.';

  @override
  String get ownerNoBusinessPermissionTitle => 'Bu işletme için erişimin yok';

  @override
  String get ownerNoBusinessPermissionDescription =>
      'Bu işletmeyi yönetme yetkin doğrulanamadı. Başka bir işletme seç veya erişim durumunu kontrol et.';

  @override
  String get ownerBusinessSelectionRequiredDescription =>
      'Bu ekran için önce yönetebildiğin bir işletme seçmen gerekiyor.';

  @override
  String get adminTableStatusLabel => 'Durum filtresi';

  @override
  String get adminTableSavedViewsLabel => 'Kayıtlı görünüm';

  @override
  String get adminTableNoSavedViews => 'Kayıtlı görünüm yok';

  @override
  String get adminTableSaveViewAction => 'Görünümü kaydet';

  @override
  String get adminTableDeleteViewAction => 'Görünümü sil';

  @override
  String get adminTableViewNameLabel => 'Görünüm adı';

  @override
  String get adminTableViewNameHint => 'Örn. Son 7 gün / Açık kayıtlar';

  @override
  String get adminTablePickDateRangeAction => 'Tarih aralığı seç';

  @override
  String get adminTableClearDateRangeAction => 'Tarihi temizle';

  @override
  String adminTableDateRangeValue(String start, String end) {
    return '$start - $end';
  }

  @override
  String adminTableBulkSelectionCount(int count) {
    return '$count kayıt seçildi';
  }

  @override
  String get adminTableRowsPerPageLabel => 'Sayfa başına';

  @override
  String adminTablePageRange(int start, int end, int total) {
    return '$start-$end / $total';
  }

  @override
  String get adminTablePrevPageAction => 'Önceki sayfa';

  @override
  String get adminTableNextPageAction => 'Sonraki sayfa';

  @override
  String get adminTableSavedViewCreated => 'Görünüm kaydedildi.';

  @override
  String get adminTableSavedViewDeleted => 'Görünüm silindi.';

  @override
  String get adminQueueTitle => 'Birleşik kuyruk';

  @override
  String get adminQueueDescription =>
      'İşletme başvurularını, raporları, fiyat önerilerini, sahiplik taleplerini ve medya ihbarlarını tek operatör kuyruğunda yönet.';

  @override
  String get adminQueueErrorTitle => 'Kuyruk yüklenemedi';

  @override
  String get adminQueueSearchHint => 'İşletme, içerik veya açıklama ara';

  @override
  String get adminQueueTypeLabel => 'Kayıt tipi';

  @override
  String get adminQueueCityHint => 'Şehir filtresi';

  @override
  String get adminQueueUnassignSelectedAction => 'Seçililerin atamasını kaldır';

  @override
  String get adminQueueEmptyDescription =>
      'Seçili filtrelere uyan kuyruk kaydı bulunamadı.';

  @override
  String get adminQueueColumnType => 'Tip';

  @override
  String get adminQueueColumnTitle => 'Kayıt';

  @override
  String get adminQueueColumnCreatedAt => 'Oluşturulma';

  @override
  String get adminQueueAssignToMeAction => 'Bana ata';

  @override
  String get adminQueueUnassignAction => 'Atamayı kaldır';

  @override
  String get adminQueueOpenDetailsAction => 'Detayı aç';

  @override
  String get adminQueueAssignedToMe => 'Kayıt sana atandı.';

  @override
  String get adminQueueUnassigned => 'Kayıt atamadan çıkarıldı.';

  @override
  String adminQueueBulkAssignmentResult(int applied, int total) {
    return '$applied / $total kayıt için atama güncellendi.';
  }

  @override
  String adminQueueBulkDecisionResult(int applied, int skipped) {
    return '$applied kayıt işlendi, $skipped kayıt atlandı.';
  }

  @override
  String get adminQueueRejectDialogTitle => 'Reddetme notu';

  @override
  String get adminQueueRejectDialogLabel => 'Operasyon notu';

  @override
  String get adminQueueRejectDialogRequiredHint =>
      'Bu kayıt tipi için red notu zorunlu.';

  @override
  String get adminQueueRejectDialogOptionalHint =>
      'İstersen karar gerekçesi ekleyebilirsin.';

  @override
  String get adminQueueDetailTitle => 'Kuyruk detayı';

  @override
  String get adminQueueOpenSourceAction => 'Kaynak ekrana git';

  @override
  String get adminQueueDetailPayloadTitle => 'Ham kayıt detayı';

  @override
  String get adminQueueExportCsvAction => 'CSV dışa aktar';

  @override
  String adminQueueExportReady(Object count) {
    return '$count kuyruk kaydı CSV olarak indirildi.';
  }

  @override
  String get adminQueuePreviewTitle => 'Operasyon özeti';

  @override
  String get adminQueuePreviewApplicantLabel => 'Başvuran';

  @override
  String get adminQueuePreviewCategoryLabel => 'Kategori';

  @override
  String get adminQueuePreviewAddressLabel => 'Adres';

  @override
  String get adminQueuePreviewPhoneLabel => 'Telefon';

  @override
  String get adminQueuePreviewWebsiteLabel => 'Web sitesi';

  @override
  String get adminQueuePreviewReasonLabel => 'Gerekçe';

  @override
  String get adminQueuePreviewTargetTypeLabel => 'Hedef tipi';

  @override
  String get adminQueuePreviewTargetIdLabel => 'Hedef kaydı';

  @override
  String get adminQueuePreviewDetailsLabel => 'Detay';

  @override
  String get adminQueuePreviewAdminNoteLabel => 'Operasyon notu';

  @override
  String get adminQueuePreviewEvidenceLabel => 'Kanıt bağlantısı';

  @override
  String get adminQueuePreviewCurrentPriceLabel => 'Mevcut fiyat';

  @override
  String get adminQueuePreviewSuggestedPriceLabel => 'Önerilen fiyat';

  @override
  String get adminQueuePreviewAnomalyLabel => 'Anomali skoru';

  @override
  String get adminQueuePreviewConflictLabel => 'Çakışma durumu';

  @override
  String get adminQueuePreviewCreatedByLabel => 'Oluşturan';

  @override
  String get adminQueuePreviewMenuItemLabel => 'Menü öğesi';

  @override
  String get adminQueueOpenFromReportsAction => 'Kuyrukta aç';

  @override
  String get adminQueueOpenFromClaimsAction => 'Kuyrukta aç';

  @override
  String get adminQueueTypeBusinessSubmission => 'İşletme başvurusu';

  @override
  String get adminQueueTypeReport => 'Rapor';

  @override
  String get adminQueueTypePriceSuggestion => 'Fiyat önerisi';

  @override
  String get adminQueueTypeClaim => 'Sahiplik talebi';

  @override
  String get adminQueueTypeMediaFlag => 'Medya ihbarı';

  @override
  String get adminQueueStatusNew => 'Yeni';

  @override
  String get adminQueueStatusOpen => 'Açık';

  @override
  String get adminQueueStatusReviewing => 'İnceleniyor';

  @override
  String get adminQueueStatusClosed => 'Kapandı';

  @override
  String adminQueueSlaWaitingHours(Object hours, int slaHours) {
    return '$hours sa bekliyor • SLA $slaHours sa';
  }

  @override
  String get adminQueueDecisionSupportTitle => 'Karar desteği';

  @override
  String get adminQueueDecisionSupportEmpty =>
      'Bu kayıt için ek sinyal özeti bulunmuyor.';

  @override
  String get adminQueuePendingReasonLabel => 'Neden beklemede';

  @override
  String get adminQueueAnomalyReasonLabel => 'Neden anomali';

  @override
  String get adminQueueDecisionSignalsLabel => 'Sinyaller';

  @override
  String get adminQueueDecisionHistoryTitle => 'Benzer karar geçmişi';

  @override
  String get adminQueueDecisionHistoryLoading =>
      'Yakın karar geçmişi yükleniyor';

  @override
  String get adminQueueDecisionHistoryEmpty =>
      'Bu bağlam için son karar kaydı bulunamadı.';

  @override
  String get adminQueueDecisionHistoryError => 'Karar geçmişi yüklenemedi';

  @override
  String adminQueueDecisionHistorySummary(
    int relevantCount,
    int exactTargetCount,
    int approvedCount,
    int rejectedCount,
  ) {
    return '$relevantCount ilgili kayıt • tam hedef $exactTargetCount • onay $approvedCount • red $rejectedCount';
  }

  @override
  String adminQueueDecisionHistoryAssignments(
    int assignedCount,
    int handledCount,
  ) {
    return 'Atama $assignedCount • sonuçlanan $handledCount';
  }

  @override
  String get adminQueueDecisionHistoryExactTarget => 'Aynı kayıt';

  @override
  String get adminQueueDecisionHistorySimilarRecord => 'Benzer kayıt';

  @override
  String get adminQueuePendingReasonConflictAndAnomaly =>
      'Çakışan fiyatlar ve yüksek anomali nedeniyle sırada.';

  @override
  String get adminQueuePendingReasonPriceConflict =>
      'Aynı ürün için çakışan fiyat önerileri sıraya alındı.';

  @override
  String get adminQueuePendingReasonAnomalyQueue =>
      'Anomali skoru eşik üzerinde olduğu için manuel incelemeye yönlendirildi.';

  @override
  String get adminQueuePendingReasonLowConfidence =>
      'Güven skoru düşük olduğu için operatör kararı bekliyor.';

  @override
  String get adminQueuePendingReasonManualReview =>
      'Kural motoru otomatik karar vermedi; operatör incelemesi gerekiyor.';

  @override
  String get adminQueuePendingReasonGreyArea =>
      'Gri alanda kaldığı için operatör incelemesine bırakıldı.';

  @override
  String get adminQueuePendingReasonMissingEvidence =>
      'Kanıt bağlantısı eksik olduğu için doğrulama bekliyor.';

  @override
  String get adminQueuePendingReasonClaimantAutoPending =>
      'Başvuran güvenlik sinyalleri nedeniyle otomatik beklemeye alındı.';

  @override
  String get adminQueuePendingReasonMissingSubmissionData =>
      'Başvuru temel alanları eksik olduğu için onaylanmadı.';

  @override
  String get adminQueueAnomalyReasonHighAnomalyScore => 'Anomali skoru yüksek.';

  @override
  String get adminQueueAnomalyReasonConflictingPrices =>
      'Yakın zamanda birden fazla çakışan fiyat görüldü.';

  @override
  String get adminQueueAnomalyReasonRiskyActor =>
      'Gönderen hesabın risk skoru yüksek.';

  @override
  String get adminQueueAnomalyReasonLowBusinessQuality =>
      'İşletmenin kalite skoru düşük.';

  @override
  String get adminQueueAnomalyReasonAutoModerated =>
      'Kayıt otomatik moderasyon zincirinden geçti.';

  @override
  String adminQueueSignalQualityConfidence(Object value) {
    return '$value güven';
  }

  @override
  String adminQueueSignalAnomalyScore(Object value) {
    return '$value anomali';
  }

  @override
  String adminQueueSignalConflictVariants(int count) {
    return '24 saatte $count farklı fiyat';
  }

  @override
  String adminQueueSignalAnomalyFlags(Object tags) {
    return 'Anomali işaretleri: $tags';
  }

  @override
  String adminQueueSignalActorReputation(int score) {
    return 'Katkı sağlayan itibar skoru $score';
  }

  @override
  String adminQueueSignalActorRisk(int score) {
    return 'Hesap risk skoru $score';
  }

  @override
  String adminQueueSignalBusinessQuality(Object score) {
    return 'İşletme kalite skoru $score';
  }

  @override
  String get adminQueueSignalAutoModerated =>
      'Otomatik moderasyon sinyali bulundu';

  @override
  String adminQueueSignalShortDetails(int length) {
    return 'Açıklama çok kısa ($length karakter)';
  }

  @override
  String get adminQueueSignalMissingEvidence => 'Kanıt bağlantısı eksik';

  @override
  String adminQueueSignalMissingFields(int count, Object fields) {
    return '$count eksik alan: $fields';
  }

  @override
  String get adminQueueAuditActionBusinessSubmissionAssigned =>
      'İşletme başvurusu atandı';

  @override
  String get adminQueueAuditActionBusinessSubmissionUnassigned =>
      'İşletme başvurusu atamadan çıkarıldı';

  @override
  String get adminQueueAuditActionPriceSuggestionAssigned =>
      'Fiyat önerisi atandı';

  @override
  String get adminQueueAuditActionPriceSuggestionUnassigned =>
      'Fiyat önerisi atamadan çıkarıldı';

  @override
  String get adminQueueAuditActionReportAutoCloseDuplicate =>
      'Mükerrer rapor otomatik kapatıldı';

  @override
  String get adminQueueAuditActionReportAutoRejectLowQuality =>
      'Düşük kaliteli rapor otomatik reddedildi';

  @override
  String get adminQueueAuditActionReportAutoQueueGrey =>
      'Gri alan raporu otomatik kuyruğa alındı';

  @override
  String get adminTableAssignToMeAction => 'Seçilileri bana ata';

  @override
  String get adminTableApproveSelectedAction => 'Seçilileri onayla';

  @override
  String get adminTableRejectSelectedAction => 'Seçilileri reddet';

  @override
  String get adminCommonStatusLabel => 'Durum';

  @override
  String get adminCommonLocationLabel => 'Konum';

  @override
  String get adminCommonActionsLabel => 'Aksiyonlar';

  @override
  String get adminBusinessSubmissionsSearchHint =>
      'İşletme adı, adres, kategori veya başvuran ara';

  @override
  String get adminBusinessSubmissionsBusinessColumn => 'İşletme';

  @override
  String get adminBusinessSubmissionsCategoryColumn => 'Kategori';

  @override
  String get adminBusinessSubmissionsApplicantColumn => 'Başvuran';

  @override
  String get ownerDigitalMenuQrOpenStudioAction => 'Dijital Menü & QR\'ı aç';

  @override
  String get ownerDigitalMenuQrOpenStudioTooltip =>
      'Dijital Menü & QR deneyimini yeni sekmede açar.';

  @override
  String get ownerDigitalMenuOpenPublicMenuAction => 'Canlı menüyü aç';

  @override
  String get ownerDigitalMenuOpenPublicMenuTooltip =>
      'Ziyaretçilere açık menüyü yeni sekmede açar.';

  @override
  String get ownerPublicMenuOpenedInNewTab => 'Canlı menü yeni sekmede açıldı.';

  @override
  String get ownerDigitalMenuOpenedInNewTab =>
      'Dijital Menü & QR yeni sekmede açıldı.';

  @override
  String get ownerShellTeamLabel => 'Ekip';

  @override
  String get ownerShellActivityLabel => 'Aktivite';

  @override
  String adminImpersonationBannerTitle(String user) {
    return '$user kullanıcısı olarak görüntüleniyor';
  }

  @override
  String get adminImpersonationUsingActualRole =>
      'Kullanıcının gerçek rolü kullanılıyor';

  @override
  String adminImpersonationRoleOverride(String role) {
    return 'Rol override: $role';
  }

  @override
  String get adminImpersonationStopAction => 'Durdur';

  @override
  String get adminImpersonationUseActualRoleOption => 'Gerçek rolü kullan';

  @override
  String get adminImpersonationRoleOverrideLabel => 'Rol override';

  @override
  String get adminImpersonationRefreshAction => 'Görüntülemeyi yenile';

  @override
  String get adminImpersonationStartAction => 'Görüntülemeyi başlat';

  @override
  String get adminImpersonationStarted => 'Görüntüleme başlatıldı.';

  @override
  String get adminImpersonationStopped => 'Görüntüleme durduruldu.';

  @override
  String get ownerTeamRoleOwner => 'Sahip';

  @override
  String get ownerTeamRoleManager => 'Yönetici';

  @override
  String get ownerTeamRoleEditor => 'Editör';

  @override
  String get ownerTeamRoleStaff => 'Personel';

  @override
  String get ownerTeamRoleViewer => 'Görüntüleyici';

  @override
  String get ownerTeamScopeThisBusiness => 'Yalnızca bu şube';

  @override
  String get ownerTeamScopeAllBranches => 'Tüm şubeler';

  @override
  String get ownerTeamTitle => 'Ekip üyeleri';

  @override
  String get ownerTeamDescription =>
      'Şube ekibini davet et, rol ata ve erişimin yalnızca bu şubeyle mi yoksa tüm zincirle mi sınırlı olacağını belirle.';

  @override
  String get ownerTeamLoadErrorTitle => 'Ekip üyeleri yüklenemedi';

  @override
  String get ownerTeamEmptyTitle => 'Henüz ekip üyesi yok';

  @override
  String get ownerTeamEmptyDescription =>
      'Şube bazlı yetkilendirmeyi başlatmak için ilk ekip üyesini ekle.';

  @override
  String get ownerTeamEmailRequired => 'E-posta zorunludur.';

  @override
  String get ownerTeamSaved => 'Ekip üyesi kaydedildi.';

  @override
  String get ownerTeamUpdated => 'Ekip üyesi güncellendi.';

  @override
  String get ownerTeamRemoved => 'Ekip üyesi kaldırıldı.';

  @override
  String get ownerTeamSelectedBranchFallback => 'Seçili şube';

  @override
  String get ownerTeamScopeAwareBadge => 'Scope bazlı RBAC';

  @override
  String get ownerTeamInviteTitle => 'Davet et veya yetki ver';

  @override
  String get ownerTeamEmailLabel => 'E-posta';

  @override
  String get ownerTeamEmailHint => 'ornek@firma.com';

  @override
  String get ownerTeamRoleFieldLabel => 'Rol';

  @override
  String get ownerTeamScopeFieldLabel => 'Kapsam';

  @override
  String get ownerTeamSaveMemberAction => 'Üyeyi kaydet';

  @override
  String get ownerTeamStatusPendingInvite => 'Davet bekliyor';

  @override
  String get ownerTeamStatusActive => 'Aktif';

  @override
  String ownerTeamSourceValue(String source) {
    return 'Kaynak: $source';
  }

  @override
  String get ownerTeamUpdateAction => 'Güncelle';

  @override
  String get ownerTeamRemoveAction => 'Kaldır';

  @override
  String get ownerTeamSourceOwnerClaim => 'Sahiplik talebi';

  @override
  String get ownerTeamSourceChainMembership => 'Zincir üyeliği';

  @override
  String get ownerTeamSourceDirect => 'Doğrudan atama';

  @override
  String get adminUserAccessForbiddenDescription =>
      'Yalnızca admin kullanıcılar erişim override veya impersonation yapabilir.';

  @override
  String get adminUserAccessTitle => 'Kullanıcı erişim önizlemesi';

  @override
  String adminUserAccessDescription(String userId) {
    return '$userId kullanıcısının işletme erişimini önizle. Rol override yalnızca önizleme ve impersonation bağlamını etkiler.';
  }

  @override
  String get adminUserAccessLoadErrorTitle => 'Erişim önizlemesi yüklenemedi';

  @override
  String get adminUserAccessEmptyTitle => 'Erişilebilir işletme yok';

  @override
  String get adminUserAccessEmptyDescription =>
      'Bu kullanıcının panelde owner veya ekip erişimi görünmüyor.';

  @override
  String adminUserAccessBusinessMeta(
    String city,
    String district,
    String role,
  ) {
    return '$city / $district • $role';
  }

  @override
  String get adminUserAccessOpenOwnerPanelAction => 'Owner panelini aç';

  @override
  String get ownerActivityTitle => 'İşletme aktivitesi';

  @override
  String get ownerActivityDescription =>
      'Seçili işletmedeki kritik değişiklikleri, ekip işlemlerini ve moderasyon sonuçlarını buradan takip edebilirsin.';

  @override
  String get ownerActivityMissingBusinessTitle => 'Önce bir işletme seç';

  @override
  String get ownerActivityMissingBusinessDescription =>
      'Aktivite akışını görmek için önce yönetebildiğin bir işletme seçmen gerekiyor.';

  @override
  String get adminAuditDescription =>
      'Sistem genelindeki kritik değişiklikleri, moderasyon kararlarını ve güvenlik aksiyonlarını filtreleyip inceleyin.';

  @override
  String get adminAuditErrorTitle => 'Denetim kayıtları yüklenemedi';

  @override
  String get adminAuditSearchHint =>
      'Aksiyon, hedef ID, kullanıcı ID veya meta içinde ara';

  @override
  String get adminAuditDateRangeLabel => 'Tarih aralığı';

  @override
  String get adminAuditDateRangeEmpty => 'Tüm zamanlar';

  @override
  String adminAuditDateRangeValue(String start, String end) {
    return '$start - $end';
  }

  @override
  String get adminAuditOnlyMyActions => 'Yalnızca benim aksiyonlarım';

  @override
  String get ownerActivityOnlyMyActions => 'Yalnızca benim işlemlerim';

  @override
  String get ownerActivityPresetAll => 'Tümü';

  @override
  String get ownerActivityPresetToday => 'Bugün';

  @override
  String get ownerActivityPresetLast7Days => 'Son 7 gün';

  @override
  String get ownerActivityPresetTeamChanges => 'Ekip değişiklikleri';

  @override
  String get adminAuditExportCsvAction => 'CSV dışa aktar';

  @override
  String get adminAuditExportReady => 'Denetim CSV dosyası hazırlandı.';

  @override
  String get adminAuditIpLabel => 'IP';

  @override
  String get adminAuditUserAgentLabel => 'User-Agent';

  @override
  String get adminAuditActorRoleAdmin => 'Admin';

  @override
  String get adminAuditActorRoleOwner => 'Sahip';

  @override
  String get adminAuditActorRoleManager => 'Yönetici';

  @override
  String get adminAuditActorRoleEditor => 'Editör';

  @override
  String get adminAuditActorRoleStaff => 'Personel';

  @override
  String get adminAuditActorRoleViewer => 'Görüntüleyici';

  @override
  String get adminAuditActorRoleUser => 'Kullanıcı';

  @override
  String get auditActionBusinessVerificationChanged =>
      'İşletme doğrulama durumu değişti';

  @override
  String get auditActionBusinessMerge => 'İşletme birleştirildi';

  @override
  String get auditActionBusinessMergeProposed =>
      'İşletme birleştirme talebi kaydedildi';

  @override
  String get auditActionMenuCreated => 'Menü oluşturuldu';

  @override
  String get auditActionMenuUpdated => 'Menü güncellendi';

  @override
  String get auditActionMenuArchived => 'Menü arşivlendi';

  @override
  String get auditActionMenuPublished => 'Menü yayına alındı';

  @override
  String get auditActionMenuDeleted => 'Menü silindi';

  @override
  String get auditActionMenuItemCreated => 'Ürün oluşturuldu';

  @override
  String get auditActionMenuItemUpdated => 'Ürün güncellendi';

  @override
  String get auditActionMenuItemArchived => 'Ürün arşivlendi';

  @override
  String get auditActionMenuItemPublished => 'Ürün yayına alındı';

  @override
  String get auditActionMenuItemDeleted => 'Ürün silindi';

  @override
  String get auditActionPriceSuggestionApproved => 'Fiyat önerisi onaylandı';

  @override
  String get auditActionPriceSuggestionRejected => 'Fiyat önerisi reddedildi';

  @override
  String get auditActionOwnerPriceSuggestionOverride =>
      'Sahip fiyat önerisini override etti';

  @override
  String get auditActionOwnerPriceSuggestionRejected =>
      'Sahip fiyat önerisini reddetti';

  @override
  String get auditActionTeamMemberSaved =>
      'Ekip üyesi eklendi veya güncellendi';

  @override
  String get auditActionTeamMemberUpdated => 'Ekip üyesi yetkisi güncellendi';

  @override
  String get auditActionTeamMemberRemoved => 'Ekip üyesi kaldırıldı';

  @override
  String get auditActionClaimApproved => 'Talep onaylandı';

  @override
  String get auditActionClaimRejected => 'Talep reddedildi';

  @override
  String get auditActionClaimAssigned => 'Talep atandı';

  @override
  String get auditActionClaimUpdated => 'Talep güncellendi';

  @override
  String get auditActionReportUpdated => 'Rapor güncellendi';

  @override
  String get auditActionReportBulkUpdated =>
      'Raporlarda toplu güncelleme yapıldı';

  @override
  String get auditActionReportAssigned => 'Rapor atandı';

  @override
  String get auditActionReportHandled => 'Rapor sonuçlandırıldı';

  @override
  String get auditActionReportExported => 'Rapor CSV dışa aktarıldı';

  @override
  String get auditActionUserSafetyAction =>
      'Kullanıcı güvenlik aksiyonu uygulandı';

  @override
  String get auditActionImpersonationStarted => 'Impersonation başlatıldı';

  @override
  String get auditActionImpersonationStopped => 'Impersonation durduruldu';

  @override
  String get auditTargetTypeBusiness => 'İşletme';

  @override
  String get auditTargetTypeMenu => 'Menü';

  @override
  String get auditTargetTypeMenuItem => 'Ürün';

  @override
  String get auditTargetTypePriceSuggestion => 'Fiyat önerisi';

  @override
  String get auditTargetTypeTeamMember => 'Ekip üyesi';

  @override
  String get auditTargetTypeOwnerClaim => 'Sahiplik talebi';

  @override
  String get auditTargetTypeReport => 'Rapor';

  @override
  String get auditTargetTypeUser => 'Kullanıcı';

  @override
  String get adminSearchTitle => 'Yönetici araması';

  @override
  String get adminSearchDescription =>
      'İşletme, kullanıcı, rapor, başvuru, sahiplik talebi ve menü öğelerini tek arama yüzeyinden bul.';

  @override
  String get adminSearchTopbarHint =>
      'İşletme, kullanıcı veya moderasyon kaydı ara';

  @override
  String get adminSearchInputHint =>
      'En az 2 karakter yaz. ID, e-posta, telefon veya isim ile arayabilirsin.';

  @override
  String get adminSearchRunAction => 'Ara';

  @override
  String get adminSearchKeyboardHint =>
      'Sonuçlarda gezinmek için yukarı/aşağı oklarını, açmak için Enter tuşunu kullan.';

  @override
  String get adminSearchStartTitle => 'Aramayı başlat';

  @override
  String get adminSearchStartDescription =>
      'İşletme, kullanıcı veya moderasyon kaydı bulmak için en az 2 karakter gir.';

  @override
  String get adminSearchEmptyTitle => 'Sonuç bulunamadı';

  @override
  String adminSearchEmptyDescription(Object query) {
    return '\"$query\" için eşleşen kayıt bulunamadı.';
  }

  @override
  String get adminSearchErrorTitle => 'Arama yüklenemedi';

  @override
  String get adminSearchForbiddenDescription =>
      'Global yönetici araması yalnızca admin kullanıcılar için kullanılabilir.';

  @override
  String get adminSearchCopiedId => 'Kayıt kimliği panoya kopyalandı.';

  @override
  String get adminSearchOpenInNewTabAction => 'Yeni sekmede aç';

  @override
  String get adminSearchCopyIdAction => 'Kimliği kopyala';

  @override
  String get adminSearchCategoryBusinesses => 'İşletmeler';

  @override
  String get adminSearchCategoryUsers => 'Kullanıcılar';

  @override
  String get adminSearchCategoryReports => 'Raporlar';

  @override
  String get adminSearchCategorySubmissions => 'İşletme başvuruları';

  @override
  String get adminSearchCategoryClaims => 'Sahiplik talepleri';

  @override
  String get adminSearchCategoryMenuItems => 'Menü öğeleri';

  @override
  String get ownerShellAnalyticsLabel => 'Analitik';

  @override
  String get ownerAnalyticsTitle => 'İşletme analitiği';

  @override
  String get ownerAnalyticsDescription =>
      'QR taramaları, menü açılışları ve ürün ilgisini tek ekranda takip et.';

  @override
  String get ownerAnalyticsMissingBusinessTitle => 'Önce bir işletme seç';

  @override
  String get ownerAnalyticsMissingBusinessDescription =>
      'Analitik verilerini görmek için üst bardan bir işletme seç.';

  @override
  String get ownerAnalyticsForbiddenTitle => 'Bu veriyi görme iznin yok';

  @override
  String get ownerAnalyticsForbiddenDescription =>
      'Bu işletmenin analitik ekranı yalnızca görüntüleme izni olan ekip üyelerine açıktır.';

  @override
  String get ownerAnalyticsErrorTitle => 'Analitik verileri yüklenemedi';

  @override
  String get ownerAnalyticsPreset7Days => 'Son 7 gün';

  @override
  String get ownerAnalyticsPreset30Days => 'Son 30 gün';

  @override
  String get ownerAnalyticsPreset90Days => 'Son 90 gün';

  @override
  String get ownerAnalyticsBranchCompareToggle => 'Şubeleri karşılaştır';

  @override
  String get ownerAnalyticsQrScansTitle => 'QR taramaları';

  @override
  String get ownerAnalyticsMenuOpensTitle => 'Menü açılışları';

  @override
  String get ownerAnalyticsCategoryViewsTitle => 'Kategori görüntülemeleri';

  @override
  String get ownerAnalyticsItemClicksTitle => 'Ürün tıklamaları';

  @override
  String ownerAnalyticsDailyTrendTitle(Object days) {
    return 'Son $days günün günlük akışı';
  }

  @override
  String get ownerAnalyticsNoTrendDataDescription =>
      'Seçilen tarih aralığında gösterilecek günlük trend verisi yok.';

  @override
  String get ownerAnalyticsTopItemsTitle => 'En çok ilgi gören ürünler';

  @override
  String get ownerAnalyticsNoItemDataTitle => 'Ürün verisi henüz oluşmadı';

  @override
  String get ownerAnalyticsNoItemDataDescription =>
      'Ürün bazlı etkileşim oluştuğunda burada en çok tıklanan ürünleri göreceksin.';

  @override
  String get ownerAnalyticsTopCategoriesTitle =>
      'En çok görüntülenen kategoriler';

  @override
  String get ownerAnalyticsNoCategoryDataTitle =>
      'Kategori verisi henüz oluşmadı';

  @override
  String get ownerAnalyticsNoCategoryDataDescription =>
      'Kategori bazlı görüntüleme verileri geldikçe burada sıralanır.';

  @override
  String get ownerAnalyticsSourceBreakdownTitle => 'Kaynak dağılımı';

  @override
  String get ownerAnalyticsNoSourceDataTitle => 'Kaynak verisi bulunamadı';

  @override
  String get ownerAnalyticsNoSourceDataDescription =>
      'QR kısa bağlantı ve normal menü girişleri oluştukça burada dağılımı göreceksin.';

  @override
  String get ownerAnalyticsSourceQrShortLink => 'QR kısa bağlantı';

  @override
  String get ownerAnalyticsSourceNormal => 'Normal giriş';

  @override
  String get ownerAnalyticsBranchCompareTitle => 'Şube karşılaştırması';

  @override
  String get ownerAnalyticsBranchCompareEmptyTitle =>
      'Karşılaştırılacak şube verisi yok';

  @override
  String get ownerAnalyticsBranchCompareEmptyDescription =>
      'Aynı zincirde erişimin olan başka şube bulunduğunda burada karşılaştırma göreceksin.';

  @override
  String ownerAnalyticsBranchCompareMetrics(
    Object menuOpens,
    Object qrScans,
    Object menuViews,
  ) {
    return '$menuOpens menü açılışı • $qrScans QR taraması • $menuViews menü görüntülemesi';
  }

  @override
  String get ownerDashboardAnalyticsTitle => 'Gerçek değer analitiği';

  @override
  String get ownerDashboardAnalyticsDescription =>
      'QR, menü açılışı ve dönüşüm sinyallerini tek bakışta gör; detay için analitik ekranına geç.';

  @override
  String get ownerDashboardOpenAnalyticsAction => 'Analitiği aç';

  @override
  String get ownerDashboardAnalyticsLoadErrorTitle =>
      'Analytics özeti yüklenemedi';

  @override
  String get ownerDashboardAnalyticsSelectBusiness =>
      'Özet metriği görmek için önce bir işletme seç.';

  @override
  String get ownerDashboardAnalyticsNotFound =>
      'Bu işletme için gösterilecek analytics özeti yok.';

  @override
  String get ownerDashboardAnalyticsOutboundClicks =>
      'Dış bağlantı tıklamaları';

  @override
  String get ownerDashboardAnalyticsConversions => 'Dönüşümler';

  @override
  String get ownerGrowthTitle => 'Büyüme merkezi';

  @override
  String get ownerGrowthDescription =>
      'Talep, görünürlük, dönüşüm ve sponsorlu görünürlük talepleri bu ekranda toplanır.';

  @override
  String get ownerGrowthSignalsTitle => 'Büyüme sinyalleri';

  @override
  String get ownerGrowthSignalsDescription =>
      'İlgi kaybı, fiyat pozisyonu ve dışa akış davranışı son 30 günde özetlenir.';

  @override
  String get ownerGrowthCatalogTitle => 'Sponsor katalogu';

  @override
  String get ownerGrowthCatalogDescription =>
      'Aktif paketler, boş slot durumu ve son kampanya erişimi buradan görülür.';

  @override
  String get ownerGrowthCatalogLoadErrorTitle => 'Sponsor katalogu yüklenemedi';

  @override
  String get ownerGrowthCatalogEmpty => 'Aktif sponsor paketi bulunmuyor.';

  @override
  String get ownerGrowthCatalogDurationLabel => 'Süre';

  @override
  String get ownerGrowthCatalogInventoryLabel => 'Boş slot';

  @override
  String get ownerGrowthCatalogLiveUnitsLabel => 'Canlı birimler';

  @override
  String get ownerGrowthCatalogReachLabel => 'Son 30 gün erişim';

  @override
  String ownerGrowthCatalogInventoryValue(Object open, Object total) {
    return '$open boş / limit $total';
  }

  @override
  String ownerGrowthCatalogLiveUnitsValue(
    Object surfaceLive,
    Object businessLive,
  ) {
    return 'Yüzey $surfaceLive • siz $businessLive';
  }

  @override
  String ownerGrowthCatalogReachValue(Object impressions, Object users) {
    return '$impressions gösterim • $users kullanıcı';
  }

  @override
  String ownerGrowthCatalogLeadStatus(Object status) {
    return 'Son lead durumu: $status';
  }

  @override
  String get ownerGrowthCatalogLeadStatusNone => 'Henüz talep yok';

  @override
  String get ownerGrowthConversionRateLabel => 'Dönüşüm oranı';

  @override
  String get ownerGrowthDistrictGapLabel => 'İlçe fiyat farkı';

  @override
  String get ownerShellTrashLabel => 'Çöp kutusu';

  @override
  String get ownerTrashTitle => 'Çöp kutusu';

  @override
  String get ownerTrashDescription =>
      'Arşivlenen menüleri, silinen ürün fotoğraflarını ve geri alınabilir kayıtları buradan yönet.';

  @override
  String get ownerTrashMissingBusinessTitle => 'Önce bir işletme seç';

  @override
  String get ownerTrashMissingBusinessDescription =>
      'Çöp kutusunu görmek için seçili işletme bağlamı gerekli.';

  @override
  String get ownerTrashFilterAll => 'Tümü';

  @override
  String get ownerTrashFilterMenus => 'Menüler';

  @override
  String get ownerTrashFilterItems => 'Ürünler';

  @override
  String get ownerTrashFilterPhotos => 'Fotoğraflar';

  @override
  String get ownerTrashLoadErrorTitle => 'Çöp kutusu yüklenemedi';

  @override
  String get ownerTrashEmptyTitle => 'Çöp kutusu boş';

  @override
  String get ownerTrashEmptyDescription =>
      'Bu işletmede geri alınabilir silinmiş kayıt bulunmuyor.';

  @override
  String get ownerTrashEntityMenu => 'menü';

  @override
  String get ownerTrashEntityItem => 'ürün';

  @override
  String get ownerTrashEntityPhoto => 'fotoğraf';

  @override
  String ownerTrashOccurredAt(Object value) {
    return 'Çöp kutusuna alınma: $value';
  }

  @override
  String get ownerTrashRestoreAction => 'Geri yükle';

  @override
  String get ownerTrashDeleteForeverAction => 'Kalıcı sil';

  @override
  String ownerTrashRestoreConfirm(Object entity) {
    return 'Bu $entity geri yüklenecek.';
  }

  @override
  String ownerTrashDeleteForeverConfirm(Object entity) {
    return 'Bu $entity kalıcı olarak silinecek. Bu işlem geri alınamaz.';
  }

  @override
  String get ownerTrashRestoreSuccess => 'Kayıt geri yüklendi.';

  @override
  String get ownerTrashDeleteForeverSuccess => 'Kayıt kalıcı olarak silindi.';

  @override
  String get ownerTrashSearchLabel => 'Çöp kutusunda ara';

  @override
  String get ownerTrashSortLabel => 'Sıralama';

  @override
  String get ownerTrashSortNewest => 'En yeni önce';

  @override
  String get ownerTrashSortOldest => 'En eski önce';

  @override
  String get ownerTrashSortTitle => 'Ada göre';

  @override
  String get ownerTrashSortType => 'Türe göre';

  @override
  String get ownerMenuVersionsAction => 'Versiyonlar';

  @override
  String get ownerMenuVersionsTitle => 'Yayın snapshot\'ları';

  @override
  String get ownerMenuVersionsDescription =>
      'Yayına alınan sürümleri incele ve gerekirse güvenli şekilde bu versiyona dön.';

  @override
  String get ownerMenuVersionsLoadErrorTitle => 'Versiyonlar yüklenemedi';

  @override
  String get ownerMenuVersionsEmptyTitle => 'Henüz snapshot yok';

  @override
  String get ownerMenuVersionsEmptyDescription =>
      'Bu menü ilk kez yayına alındığında versiyon geçmişi burada oluşur.';

  @override
  String ownerMenuVersionLabel(Object version) {
    return 'Versiyon $version';
  }

  @override
  String ownerMenuVersionSummary(Object reason, Object createdAt) {
    return '$reason • $createdAt';
  }

  @override
  String ownerMenuVersionCounts(Object sectionCount, Object itemCount) {
    return '$sectionCount bölüm • $itemCount ürün';
  }

  @override
  String get ownerMenuVersionReasonPublish => 'Yayına alma';

  @override
  String get ownerMenuVersionReasonRestore => 'Geri yükleme';

  @override
  String get ownerMenuVersionRestoreAction => 'Bu versiyona dön';

  @override
  String get ownerMenuVersionDiffAction => 'Farkları gör';

  @override
  String ownerMenuVersionRestoreConfirm(Object version) {
    return 'Versiyon $version baz alınarak yeni bir yayınlı menü oluşturulacak. Mevcut menü arşive alınır.';
  }

  @override
  String get ownerMenuVersionRestoreSuccess =>
      'Geri yüklenen versiyon hazır. Menü listesine dönülüyor.';

  @override
  String ownerMenuVersionDiffTitle(Object version) {
    return 'Versiyon $version fark özeti';
  }

  @override
  String get ownerMenuVersionDiffDescription =>
      'Seçilen snapshot ile şu an açık olan menü arasındaki farkları incele.';

  @override
  String get ownerMenuVersionDiffLoadErrorTitle =>
      'Versiyon farkları yüklenemedi';

  @override
  String get ownerMenuVersionDiffMenuMetaTitle => 'Özet değişiklikler';

  @override
  String ownerMenuVersionDiffMenuTitleLine(Object current, Object snapshot) {
    return 'Menü adı: şimdi \"$current\" • snapshot \"$snapshot\"';
  }

  @override
  String ownerMenuVersionDiffMenuKindLine(Object current, Object snapshot) {
    return 'Menü tipi: şimdi \"$current\" • snapshot \"$snapshot\"';
  }

  @override
  String ownerMenuVersionDiffCountLine(
    Object label,
    Object currentCount,
    Object snapshotCount,
  ) {
    return '$label: şimdi $currentCount • snapshot $snapshotCount';
  }

  @override
  String get ownerMenuVersionDiffEmptyValue => 'Belirtilmedi';

  @override
  String get ownerMenuVersionDiffNoChangesTitle => 'Belirgin fark yok';

  @override
  String get ownerMenuVersionDiffNoChangesDescription =>
      'Bu snapshot, mevcut menü yapısıyla aynı görünüyor.';

  @override
  String get ownerMenuVersionDiffSectionsAddedTitle =>
      'Snapshot\'ta olup şu an olmayan bölümler';

  @override
  String get ownerMenuVersionDiffSectionsRemovedTitle =>
      'Şu an olup snapshot\'ta olmayan bölümler';

  @override
  String get ownerMenuVersionDiffItemsAddedTitle =>
      'Snapshot\'ta olup şu an olmayan ürünler';

  @override
  String get ownerMenuVersionDiffItemsRemovedTitle =>
      'Şu an olup snapshot\'ta olmayan ürünler';

  @override
  String get ownerMenuVersionDiffEmptyList => 'Değişiklik yok';

  @override
  String ownerMenuVersionDiffMoreItems(Object count) {
    return '+$count kayıt daha';
  }

  @override
  String get adminShellTrashLabel => 'Restore merkezi';

  @override
  String get adminShellTrashDescription =>
      'Silinen menü, ürün ve fotoğrafları business bazlı geri yükle.';

  @override
  String get adminBusinessesTrashAction => 'Çöp kutusu';

  @override
  String get adminMenuRestoreTitle => 'Menü restore merkezi';

  @override
  String get adminMenuRestoreDescription =>
      'Bir işletme seç, ardından silinen menü, ürün ve fotoğrafları geri yükle veya kalıcı olarak sil.';

  @override
  String get adminMenuRestoreBusinessSearchLabel => 'İşletme ara veya ID gir';

  @override
  String get adminMenuRestoreSearchEmptyTitle => 'İşletme araması bekleniyor';

  @override
  String get adminMenuRestoreSearchEmptyDescription =>
      'Restore ekranını açmak için en az 2 karakterle işletme ara.';

  @override
  String get adminMenuRestoreNoBusinessTitle => 'İşletme bulunamadı';

  @override
  String get adminMenuRestoreNoBusinessDescription =>
      'Arama sonucunda eşleşen işletme çıkmadı. Ad, telefon ya da işletme kimliğini kontrol et.';

  @override
  String get adminMenuRestoreSelectBusinessAction => 'Seç';

  @override
  String get adminMenuRestoreSelectBusinessTitle => 'Önce işletme seç';

  @override
  String get adminMenuRestoreSelectBusinessDescription =>
      'Aşağıdaki restore panelini kullanmak için arama sonucundan bir işletme seç.';

  @override
  String get adminMenuRestorePanelTitle => 'Silinen kayıtlar';

  @override
  String get adminMenuRestorePanelDescription =>
      'Admin yetkisiyle seçili işletmenin çöp kutusunu yönet.';

  @override
  String get ownerDeletePhotoToTrashConfirm =>
      'Bu fotoğraf çöp kutusuna taşınacak. İstersen daha sonra geri yükleyebilirsin.';

  @override
  String get ownerPhotoMovedToTrash => 'Fotoğraf çöp kutusuna taşındı.';
}
